import AppKit
import FlowCore
import FlowVoice
import SwiftUI

/// What the Flow Bar shows.
enum BarPhase: Equatable {
    case resting
    case recording(handsFree: Bool, command: Bool)
    case processing(command: Bool)
}

struct Notice: Identifiable, Equatable {
    enum Kind { case info, warning, error }
    struct Action: Equatable {
        var title: String
        var id: String
    }
    let id = UUID()
    var kind: Kind
    var title: String
    var body: String?
    var actions: [Action] = []
}

/// The app's single source of truth: settings, data, and the dictation loop.
@MainActor
final class DictationController: ObservableObject {
    @Published var phase: BarPhase = .resting
    @Published var levels: [CGFloat] = Array(repeating: 0, count: 11)
    @Published var notice: Notice?
    @Published var hovering = false
    @Published var modelProgress: Double?
    @Published var hiddenUntil: Date?

    @Published var settings: FlowSettings { didSet { store.settings = settings; onSettingsChange?() } }
    @Published var history: [Transcript] { didSet { store.history = history } }
    @Published var dictionary: [DictionaryEntry] { didSet { store.dictionary = dictionary } }
    @Published var snippets: [Snippet] { didSet { store.snippets = snippets } }
    @Published var notes: [ScratchNote] { didSet { store.notes = notes } }
    @Published var meetings: [Meeting] { didSet { store.meetings = meetings } }
    @Published var microphones: [Microphone] = []
    let recorder = MeetingRecorder()
    var toggleScratchpad: (() -> Void)?
    /// Set while the Scratchpad window is key: dictation goes straight in.
    var scratchSink: ((String) -> Void)?

    var onSettingsChange: (() -> Void)?
    /// Practice field in onboarding receives text directly instead of typing.
    var practiceSink: ((String) -> Void)?

    let store: FlowStore
    private let voice = VoiceEngine.shared
    private var machine = HotkeyStateMachine()
    private var target: NSRunningApplication?
    private var startedAt = Date()
    private var mode: RecordingMode = .dictation
    private var levelTimer: Timer?
    private var capTimer: Timer?
    private var noticeTask: Task<Void, Never>?
    private let clock = ProcessInfo.processInfo
    private var contextTerms: [String] = []

    init(store: FlowStore = FlowStore(directory: FlowStore.defaultDirectory)) {
        self.store = store
        self.settings = store.settings
        self.dictionary = store.dictionary
        self.snippets = store.snippets
        self.notes = store.notes
        self.meetings = store.meetings.map { m in
            var m = m
            if m.status != .complete { m.status = .complete } // interrupted by quit
            return m
        }
        self.history = store.settings.retention.prune(store.history)
    }

    private var now: Double { clock.systemUptime }

    // MARK: Model

    func loadModel() {
        Task {
            modelProgress = 0
            await voice.loadModel(settings.engine) { p in
                Task { @MainActor in self.modelProgress = p }
            }
            modelProgress = nil
        }
    }

    // MARK: Input events (from HotkeyMonitor and the Flow Bar)

    func pushToTalkDown(command: Bool = false) {
        if command && !settings.commandModeEnabled {
            show(Notice(kind: .info, title: "Command Mode is off",
                        body: "Turn it on in Settings → Experimental.",
                        actions: [.init(title: "Go to settings", id: "settings")]))
            return
        }
        handle(machine.pressHold(at: now, mode: command ? .command : .dictation))
    }
    func pushToTalkUp() { handle(machine.releaseHold(at: now)) }
    func handsFreePressed() { handle(machine.pressHandsFree(at: now)) }
    func barClicked() { handle(machine.clickBar(at: now)) }
    func cancelPressed() { handle(machine.pressCancel()) }

    func pasteLast() {
        guard let last = history.first(where: { $0.status != .cancelled }) else { return }
        _ = Inserter.insert(last.displayText, into: nil, method: settings.insertion)
    }
    func copyLast() {
        guard let last = history.first(where: { $0.status != .cancelled }) else { return }
        VoiceEngine.copyToClipboard(last.displayText)
        show(Notice(kind: .info, title: "Copied last transcript"))
    }

    var isRecording: Bool { machine.isRecording }

    // MARK: Commands

    private func handle(_ commands: [DictationCommand]) {
        for c in commands {
            switch c {
            case .startRecording(let mode): start(mode: mode)
            case .lockHandsFree:
                if case .recording(_, let command) = phase { phase = .recording(handsFree: true, command: command) }
            case .stopAndInsert: finish()
            case .cancel: cancel()
            case .showHoldTip:
                let key = settings.shortcuts.shortcuts(for: .pushToTalk).first?.display ?? "fn"
                show(Notice(kind: .info, title: "Hold \(key) while you talk",
                            body: "Let go when you're done. Double-tap for hands-free."))
            case .ignoredBusy:
                show(Notice(kind: .info, title: "Still working on your last dictation"))
            }
        }
        // A short tap waits for a possible second press.
        if case .awaitingSecondPress = machine.state {
            DispatchQueue.main.asyncAfter(deadline: .now() + HotkeyStateMachine.tapThreshold + 0.05) { [weak self] in
                guard let self else { return }
                self.handle(self.machine.tick(at: self.now))
            }
        }
    }

    private func start(mode: RecordingMode) {
        guard VoiceEngine.microphoneAuthorized else {
            machine = HotkeyStateMachine()
            show(Notice(kind: .error, title: "Microphone access is off",
                        body: "Allow it in System Settings → Privacy & Security → Microphone.",
                        actions: [.init(title: "Open Settings", id: "open-mic")]))
            return
        }
        self.mode = mode
        let front = NSWorkspace.shared.frontmostApplication
        target = front?.bundleIdentifier == Bundle.main.bundleIdentifier ? nil : front
        startedAt = Date()
        refreshMicrophones()
        Microphones.select(uid: MicrophoneRanking.choose(ranking: settings.microphoneRanking,
                                                         available: microphones.map(\.uid)))
        contextTerms = settings.contextAwareness && target != nil
            ? ContextTerms.extract(from: Inserter.contextTexts(of: target)) : []
        phase = .recording(handsFree: false, command: mode == .command)
        if settings.soundEffects { NSSound(named: "Tink")?.play() }
        ModelPolish.prepare(level: settings.cleanupLevel)
        Task {
            do { try await voice.start() } catch {
                machine = HotkeyStateMachine()
                phase = .resting
                show(Notice(kind: .error, title: "Unable to access the microphone",
                            body: "Close other apps using it, or pick another mic."))
            }
        }
        levelTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sampleLevel() }
        }
        capTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkSessionCap() }
        }
    }

    private func sampleLevel() {
        let level = CGFloat(min(1, voice.level() * 8))
        var next = levels
        next.removeFirst()
        next.append(level)
        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) { levels = next }
    }

    private func checkSessionCap() {
        let elapsed = Date().timeIntervalSince(startedAt)
        if elapsed >= 20 * 60 {
            show(Notice(kind: .warning, title: "Sessions can run up to 20 minutes",
                        body: "Inserting what you said so far."))
            machine = HotkeyStateMachine()
            finish()
        } else if elapsed >= 19 * 60 {
            show(Notice(kind: .warning, title: "One minute left in this session"))
        }
    }

    private func stopTimers() {
        levelTimer?.invalidate(); levelTimer = nil
        capTimer?.invalidate(); capTimer = nil
        levels = Array(repeating: 0, count: levels.count)
    }

    private func cancel() {
        stopTimers()
        voice.cancel()
        phase = .resting
        machine.finishedProcessing()
        if settings.soundEffects { NSSound(named: "Pop")?.play() }
    }

    private func finish() {
        stopTimers()
        let duration = Date().timeIntervalSince(startedAt)
        let (samples, peak) = voice.stop()
        let command = mode == .command
        phase = .processing(command: command)
        if settings.soundEffects { NSSound(named: "Pop")?.play() }
        Task {
            defer {
                phase = .resting
                machine.finishedProcessing()
            }
            guard peak > 0.003, !samples.isEmpty else {
                show(Notice(kind: .warning, title: "Is your microphone muted?",
                            body: "We didn't hear anything, so nothing was inserted."))
                return
            }
            if !voice.isModelReady {
                show(Notice(kind: .info, title: "Downloading the speech model",
                            body: "One time only. Try again when it finishes."))
                loadModel()
                return
            }
            let pendingID = command ? nil : savePending(samples, duration: duration)
            let raw = await voice.transcribe(samples)
            guard !raw.isEmpty else {
                if let pendingID { update(pendingID) { $0.status = .failed } }
                show(Notice(kind: .warning, title: "We couldn't make out any words",
                            body: "The audio is saved in History if you want to retry."))
                return
            }
            if command { await runCommand(raw, duration: duration) }
            else { await insertDictation(raw, duration: duration, replacing: pendingID) }
        }
    }

    private func polishedText(_ raw: String, bundleID: String?) async -> DictationPipeline.Result {
        var pipeline = DictationPipeline(settings: settings, bundleID: bundleID,
                                         snippets: snippets, dictionary: dictionary)
        pipeline.contextTerms = contextTerms
        let polished = await ModelPolish.polish(raw, level: settings.cleanupLevel, bundleID: bundleID)
        var result = pipeline.process(polished)
        for t in settings.transforms where t.runAfterDictation {
            if let out = await TransformRunner.run(t, on: result.text) { result.text = out }
        }
        return result
    }

    private func insertDictation(_ raw: String, duration: Double, replacing pendingID: UUID? = nil) async {
        let bundleID = target?.bundleIdentifier
        let result = await polishedText(raw, bundleID: bundleID)
        var status = Transcript.Status.inserted
        if let sink = practiceSink ?? scratchSink {
            sink(result.text)
        } else if Inserter.insert(result.text, into: target, method: settings.insertion) == .inserted {
            if settings.autoAddToDictionary { watchForCorrections(of: result.text) }
        } else {
            status = .copied
            show(Notice(kind: .warning, title: "Copied to your clipboard",
                        body: VoiceEngine.accessibilityTrusted
                            ? "Click into a text field and press ⌘V."
                            : "Allow Accessibility so we can type into apps for you.",
                        actions: VoiceEngine.accessibilityTrusted ? [] : [.init(title: "Open Settings", id: "open-ax")]))
        }
        bumpUsage(snippets: result.snippetsUsed, dictionary: result.dictionaryUsed)
        if let pendingID, history.contains(where: { $0.id == pendingID }) {
            update(pendingID) {
                $0.raw = raw; $0.polished = result.text; $0.status = status
                $0.appName = self.target?.localizedName; $0.bundleID = bundleID
            }
        } else {
            record(Transcript(raw: raw, polished: result.text, appName: target?.localizedName,
                              bundleID: bundleID, durationSeconds: duration, status: status))
        }
    }

    // MARK: Saved audio, Retry and Recover

    /// Writes the take to disk and adds a pending row before transcription,
    /// so a crash or quit mid-way can be recovered from History.
    private func savePending(_ samples: [Float], duration: Double) -> UUID? {
        guard settings.keepAudio, settings.retention != .never else { return nil }
        let id = UUID()
        let name = "\(id.uuidString).wav"
        do { try WAV.encode(samples).write(to: store.audioDirectory.appendingPathComponent(name)) } catch { return nil }
        history.insert(Transcript(id: id, raw: "", polished: "", appName: target?.localizedName,
                                  bundleID: target?.bundleIdentifier, durationSeconds: duration,
                                  status: .pending, audioFile: name), at: 0)
        return id
    }

    func audioURL(_ t: Transcript) -> URL? {
        guard let f = t.audioFile else { return nil }
        let url = store.audioDirectory.appendingPathComponent(f)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Re-run a saved take; the result goes to the clipboard and the row.
    func retry(_ t: Transcript) {
        guard let url = audioURL(t) else { return }
        Task {
            if !voice.isModelReady { await voice.loadModel(settings.engine) }
            guard let raw = await voice.transcribe(fileAt: url), !raw.isEmpty else {
                update(t.id) { $0.status = .failed }
                show(Notice(kind: .error, title: "Still couldn't make out any words"))
                return
            }
            let result = await polishedText(raw, bundleID: t.bundleID)
            update(t.id) { $0.raw = raw; $0.polished = result.text; $0.status = .copied; $0.showingRaw = false }
            VoiceEngine.copyToClipboard(result.text)
            show(Notice(kind: .info, title: "Recovered and copied", body: "Press ⌘V to paste it."))
        }
    }

    private func update(_ id: UUID, _ change: (inout Transcript) -> Void) {
        guard let i = history.firstIndex(where: { $0.id == id }) else { return }
        change(&history[i])
    }

    // MARK: Learn from corrections

    /// After inserting, look at the field twice; if the user fixed exactly
    /// one word, add the fixed spelling to the dictionary.
    private func watchForCorrections(of inserted: String) {
        for delay in [8.0, 20.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, let value = VoiceEngine.focusedText().value,
                      let edited = CorrectionFinder.editedSpan(inserted: inserted, fieldValue: value),
                      let entry = PersonalDictionary.learnCorrection(original: inserted, edited: edited,
                                                                     existing: self.dictionary) else { return }
                self.dictionary.append(entry)
                self.show(Notice(kind: .info, title: "Added “\(entry.term)” to your dictionary",
                                 actions: [.init(title: "Undo", id: "undo-dict:\(entry.id.uuidString)")]))
            }
        }
    }

    // MARK: Microphones

    func refreshMicrophones() {
        microphones = Microphones.all()
        let merged = MicrophoneRanking.merge(ranking: settings.microphoneRanking,
                                             available: microphones.filter { !$0.isVirtual }.map(\.uid))
        if merged != settings.microphoneRanking { settings.microphoneRanking = merged }
    }

    // MARK: Transforms

    /// Rewrites the selected text in the focused app.
    func runTransform(_ transform: TextTransform?) {
        guard let t = transform ?? settings.transforms.first else { return }
        let field = VoiceEngine.focusedText()
        guard let selected = field.selected, !selected.isEmpty else {
            show(Notice(kind: .info, title: "Select some text first", body: "Then run \(t.name) again."))
            return
        }
        let app = NSWorkspace.shared.frontmostApplication
        phase = .processing(command: true)
        Task {
            defer { phase = .resting }
            guard let out = await TransformRunner.run(t, on: selected) else {
                show(Notice(kind: .error, title: "\(t.name) needs Apple's on-device model",
                            body: "Custom transforms run on macOS 26 with Apple Intelligence on."))
                return
            }
            if field.editable { _ = Inserter.insert(out, into: app, method: settings.insertion) }
            else {
                VoiceEngine.copyToClipboard(out)
                show(Notice(kind: .info, title: "Copied the rewrite"))
            }
            record(Transcript(raw: selected, polished: out, appName: app?.localizedName,
                              bundleID: app?.bundleIdentifier, durationSeconds: 0, mode: .command))
        }
    }

    // MARK: Notetaker

    func startMeeting() {
        Task {
            if !voice.isModelReady { await voice.loadModel(settings.engine) }
            do { try await recorder.start(includeSystemAudio: settings.notetakerIncludeSystemAudio) }
            catch { show(Notice(kind: .error, title: "Couldn't start recording", body: error.localizedDescription)) }
            objectWillChange.send()
        }
    }

    func stopMeeting(title: String) {
        Task {
            let started = Date().addingTimeInterval(-recorder.elapsed)
            var m = Meeting(title: title.isEmpty ? "Meeting" : title, started: started)
            m.status = .transcribing
            let (segments, duration) = await recorder.stop()
            m.segments = segments
            m.duration = duration
            meetings.insert(m, at: 0)
            let summary = await TransformRunner.summarize(m)
            if let i = meetings.firstIndex(where: { $0.id == m.id }) {
                meetings[i].summary = summary
                meetings[i].status = .complete
            }
        }
    }

    private func runCommand(_ instruction: String, duration: Double) async {
        let field = VoiceEngine.focusedText()
        let outcome = await CommandRunner.run(instruction: instruction, selected: field.selected,
                                              fieldValue: field.value, editable: field.editable)
        switch outcome {
        case .replace(let text):
            if field.selected?.isEmpty ?? true { VoiceEngine.selectAllInFocusedField() }
            _ = Inserter.insert(text, into: target, method: settings.insertion)
            record(Transcript(raw: instruction, polished: text, appName: target?.localizedName,
                              bundleID: target?.bundleIdentifier, durationSeconds: duration, mode: .command))
        case .show(let text):
            VoiceEngine.copyToClipboard(text)
            show(Notice(kind: .info, title: "Copied the result", body: String(text.prefix(240))))
        case .openSearch(let url):
            NSWorkspace.shared.open(url)
        case .unavailable(let message):
            show(Notice(kind: .error, title: "Command Mode couldn't run", body: message))
        }
    }

    private func bumpUsage(snippets fired: [UUID], dictionary used: [UUID]) {
        if !fired.isEmpty {
            snippets = snippets.map { s in var s = s; if fired.contains(s.id) { s.uses += 1 }; return s }
        }
        if !used.isEmpty {
            dictionary = dictionary.map { e in var e = e; if used.contains(e.id) { e.uses += 1 }; return e }
        }
    }

    private func record(_ t: Transcript) {
        guard settings.retention != .never else { return }
        history.insert(t, at: 0)
    }

    // MARK: History actions

    func toggleRaw(_ t: Transcript) {
        guard let i = history.firstIndex(where: { $0.id == t.id }) else { return }
        history[i].showingRaw.toggle()
    }
    func delete(_ t: Transcript) {
        if let url = audioURL(t) { try? FileManager.default.removeItem(at: url) }
        history.removeAll { $0.id == t.id }
    }
    func clearHistory() {
        try? FileManager.default.removeItem(at: store.audioDirectory)
        history = []
    }

    // MARK: Notices

    func show(_ n: Notice) {
        notice = n
        noticeTask?.cancel()
        noticeTask = Task {
            try? await Task.sleep(nanoseconds: n.actions.isEmpty ? 3_500_000_000 : 8_000_000_000)
            if !Task.isCancelled, notice?.id == n.id { notice = nil }
        }
    }

    func perform(_ action: Notice.Action) {
        notice = nil
        switch action.id {
        case "open-mic":
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
        case "open-ax":
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        case let id where id.hasPrefix("undo-dict:"):
            let uuid = UUID(uuidString: String(id.dropFirst("undo-dict:".count)))
            dictionary.removeAll { $0.id == uuid }
        case "settings":
            (NSApp.delegate as? AppDelegate)?.showHub(page: .settings)
        default: break
        }
    }
}
