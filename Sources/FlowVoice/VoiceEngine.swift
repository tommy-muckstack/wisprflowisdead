import AppKit
import ApplicationServices
import AVFoundation
import FlowCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Public face of the audio, speech and insertion code vendored from MyMan.
@MainActor
public final class VoiceEngine {
    public static let shared = VoiceEngine()
    private var session: UUID?

    public init() {}

    // MARK: Model

    public var isModelReady: Bool { TranscriptionService.shared.isReady }

    public func loadModel(_ choice: SpeechEngineChoice,
                          progress: @escaping @Sendable (Double) -> Void = { _ in }) async {
        let kind: SttEngineKind
        switch choice {
        case .parakeet: kind = .parakeet
        case .qwen3: kind = .qwen3
        case .apple: kind = .apple
        }
        await TranscriptionService.shared.load(kind: kind, progress: progress)
    }

    // MARK: Microphone

    public static var microphoneAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    public static func requestMicrophone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    public func warmMicrophone() { AudioCapture.shared.warm() }

    public var isRecording: Bool { session != nil }

    public func start() async throws {
        guard session == nil else { return }
        session = try await AudioCapture.shared.begin(.voiceProcessed)
    }

    /// RMS of the last 0.1 s, 0...1-ish. Poll at 30 Hz for the Flow Bar.
    public func level() -> Float {
        guard let session else { return 0 }
        return AudioCapture.shared.currentLevel(for: session)
    }

    /// Ends the take. `peak` is the loudest raw sample, before normalization,
    /// so callers can tell silence from speech.
    public func stop() -> (samples: [Float], peak: Float) {
        guard let id = session else { return ([], 0) }
        session = nil
        let samples = AudioCapture.shared.end(id)
        return (samples, AudioCapture.shared.lastTakeRawPeak)
    }

    public func cancel() { _ = stop() }

    // MARK: Speech to text

    /// 16 kHz mono in, text out. Long takes go in 60 s pieces like MyMan.
    public func transcribe(_ samples: [Float]) async -> String {
        let chunk = 16_000 * 60
        guard samples.count > chunk else { return await TranscriptionService.shared.transcribe(samples) }
        var parts: [String] = []
        var index = 0
        while index < samples.count {
            let end = min(index + chunk, samples.count)
            parts.append(await TranscriptionService.shared.transcribe(Array(samples[index..<end])))
            index = end
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Retry / Recover: transcribe a take saved by `WAV.encode`.
    public func transcribe(fileAt url: URL) async -> String? {
        guard let data = try? Data(contentsOf: url), let wav = WAV.decode(data) else { return nil }
        return await transcribe(wav.samples)
    }

    // MARK: Insertion

    public static var accessibilityTrusted: Bool { AXIsProcessTrusted() }

    public static func promptAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Types the text into `app` (or the frontmost app). Falls back to the
    /// clipboard when Accessibility is missing.
    public func insert(_ text: String, into app: NSRunningApplication?) {
        pasteText(text, into: app)
    }

    public static func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    /// Selected text and full value of the focused field, via Accessibility.
    public static func focusedText() -> (selected: String?, value: String?, editable: Bool) {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused else { return (nil, nil, false) }
        let el = element as! AXUIElement
        var selected: CFTypeRef?
        var value: CFTypeRef?
        var settable: DarwinBoolean = false
        AXUIElementCopyAttributeValue(el, kAXSelectedTextAttribute as CFString, &selected)
        AXUIElementCopyAttributeValue(el, kAXValueAttribute as CFString, &value)
        AXUIElementIsAttributeSettable(el, kAXValueAttribute as CFString, &settable)
        return (selected as? String, value as? String, settable.boolValue)
    }
}

/// Command Mode: a spoken instruction applied to the selection (or the whole
/// field) by the on-device model. macOS 26+ with Apple Intelligence on.
public enum CommandRunner {
    public enum Outcome: Equatable {
        case replace(String)
        case show(String)
        case openSearch(URL)
        case unavailable(String)
    }

    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    public static func run(instruction: String, selected: String?, fieldValue: String?, editable: Bool) async -> Outcome {
        let lower = instruction.lowercased()
        if lower.hasPrefix("search") || lower.hasPrefix("look up") || lower.hasPrefix("google") {
            var query = instruction
            for prefix in ["search for", "search", "look up", "google"] where lower.hasPrefix(prefix) {
                query = String(instruction.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
            if let selected, !selected.isEmpty { query += " " + selected }
            var c = URLComponents(string: "https://duckduckgo.com/")!
            c.queryItems = [URLQueryItem(name: "q", value: query)]
            return .openSearch(c.url!)
        }
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            let source = (selected?.isEmpty == false ? selected : fieldValue) ?? ""
            let session = LanguageModelSession(instructions: """
            You edit or write text for the user. Follow the instruction exactly. \
            Output only the resulting text, with no preamble, quotes or explanation.
            """)
            let prompt = source.isEmpty
                ? "Instruction: \(instruction)"
                : "Instruction: \(instruction)\n<<<TEXT\n\(source)\nTEXT>>>"
            do {
                let result = try await session.respond(to: prompt).content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return editable ? .replace(result) : .show(result)
            } catch {
                return .unavailable("The on-device model could not finish that command.")
            }
        }
        #endif
        return .unavailable("Command Mode needs macOS 26 with Apple Intelligence turned on.")
    }
}

extension VoiceEngine {
    /// Cmd+A in the focused field, so Command Mode output replaces the whole
    /// field when nothing was selected.
    public static func selectAllInFocusedField() {
        let source = CGEventSource(stateID: .privateState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
        usleep(30_000)
    }

    /// Press Return (the "Press Enter" action).
    public static func pressEnter() {
        let source = CGEventSource(stateID: .privateState)
        CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)?.post(tap: .cgSessionEventTap)
        CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)?.post(tap: .cgSessionEventTap)
    }
}
