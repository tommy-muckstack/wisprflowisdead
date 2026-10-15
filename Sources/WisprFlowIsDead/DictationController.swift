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

    init(store: FlowStore = FlowStore(directory: FlowStore.defaultDirectory)) {
        self.store = store
        self.settings = store.settings
        self.dictionary = store.dictionary
        self.snippets = store.snippets
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
        voice.insert(last.displayText, into: nil)
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
            let raw = await voice.transcribe(samples)
            guard !raw.isEmpty else {
                show(Notice(kind: .warning, title: "We couldn't make out any words"))
                return
            }
            if command { await runCommand(raw, duration: duration) }
            else { await insertDictation(raw, duration: duration) }
        }
    }

    private func insertDictation(_ raw: String, duration: Double) async {
        let bundleID = target?.bundleIdentifier
        let pipeline = DictationPipeline(settings: settings, bundleID: bundleID,
                                         snippets: snippets, dictionary: dictionary)
        let polished = await ModelPolish.polish(raw, level: settings.cleanupLevel, bundleID: bundleID)
        let result = pipeline.process(polished)
        var status = Transcript.Status.inserted
        if let sink = practiceSink {
            sink(result.text)
        } else if VoiceEngine.accessibilityTrusted {
            voice.insert(result.text, into: target)
        } else {
            VoiceEngine.copyToClipboard(result.text)
            status = .copied
            show(Notice(kind: .warning, title: "Copied to your clipboard",
                        body: "Allow Accessibility so we can type into apps for you.",
                        actions: [.init(title: "Open Settings", id: "open-ax")]))
        }
        bumpUsage(snippets: result.snippetsUsed, dictionary: result.dictionaryUsed)
        record(Transcript(raw: raw, polished: result.text, appName: target?.localizedName,
                          bundleID: bundleID, durationSeconds: duration, status: status))
    }

    private func runCommand(_ instruction: String, duration: Double) async {
        let field = VoiceEngine.focusedText()
        let outcome = await CommandRunner.run(instruction: instruction, selected: field.selected,
                                              fieldValue: field.value, editable: field.editable)
        switch outcome {
        case .replace(let text):
            if field.selected?.isEmpty ?? true { VoiceEngine.selectAllInFocusedField() }
            voice.insert(text, into: target)
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
    func delete(_ t: Transcript) { history.removeAll { $0.id == t.id } }
    func clearHistory() { history = [] }

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
        case "settings":
            (NSApp.delegate as? AppDelegate)?.showHub(page: .settings)
        default: break
        }
    }
}
