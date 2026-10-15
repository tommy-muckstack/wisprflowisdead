import Foundation

public enum FlowBarDock: String, Codable, CaseIterable, Sendable { case bottom, left, right }

public enum SpeechEngineChoice: String, Codable, CaseIterable, Sendable {
    case parakeet, qwen3, apple
    public var title: String {
        switch self {
        case .parakeet: return "Fast (Parakeet, ~600 MB)"
        case .qwen3: return "Accurate (Qwen3, ~1.5 GB, macOS 15+)"
        case .apple: return "Built-in (Apple, macOS 26+)"
        }
    }
}

/// Everything the user can change. Stored as one JSON file; keys missing
/// from an older file fall back to their defaults.
public struct FlowSettings: Codable, Equatable, Sendable {
    public var onboardingComplete: Bool = false
    public var shortcuts: ShortcutSet = ShortcutSet.defaults()
    public var styles: [AppCategory: WritingStyle] = [.personal: .casual, .work: .casual, .email: .formal, .other: .formal]
    public var cleanupLevel: CleanupLevel = .light
    public var engine: SpeechEngineChoice = .parakeet
    public var languages: [String] = ["en"]
    public var microphoneRanking: [String] = []
    public var launchAtLogin: Bool = false
    public var showInDock: Bool = false
    public var showFlowBarAlways: Bool = true
    public var flowBarDock: FlowBarDock = .bottom
    public var soundEffects: Bool = true
    public var muteMusicWhileDictating: Bool = false
    public var commandModeEnabled: Bool = false
    public var retention: RetentionPolicy = .normal
    public var keepAudio: Bool = true
    public var autoAddToDictionary: Bool = true
    public var insertion: InsertionMethod = .paste
    public var contextAwareness: Bool = true
    public var transforms: [TextTransform] = TextTransform.builtIns
    public var showScratchpadButton: Bool = false
    public var notetakerIncludeSystemAudio: Bool = true

    public init() {}

    enum CodingKeys: String, CodingKey {
        case onboardingComplete, shortcuts, styles, cleanupLevel, engine, languages, microphoneRanking, launchAtLogin, showInDock, showFlowBarAlways, flowBarDock, soundEffects, muteMusicWhileDictating, commandModeEnabled, retention, keepAudio, autoAddToDictionary, insertion, contextAwareness, transforms, showScratchpadButton, notetakerIncludeSystemAudio
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .onboardingComplete) { onboardingComplete = v }
        if let v = try? c.decodeIfPresent(ShortcutSet.self, forKey: .shortcuts) { shortcuts = v }
        if let v = try? c.decodeIfPresent([AppCategory: WritingStyle].self, forKey: .styles) { styles = v }
        if let v = try? c.decodeIfPresent(CleanupLevel.self, forKey: .cleanupLevel) { cleanupLevel = v }
        if let v = try? c.decodeIfPresent(SpeechEngineChoice.self, forKey: .engine) { engine = v }
        if let v = try? c.decodeIfPresent([String].self, forKey: .languages) { languages = v }
        if let v = try? c.decodeIfPresent([String].self, forKey: .microphoneRanking) { microphoneRanking = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) { launchAtLogin = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .showInDock) { showInDock = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .showFlowBarAlways) { showFlowBarAlways = v }
        if let v = try? c.decodeIfPresent(FlowBarDock.self, forKey: .flowBarDock) { flowBarDock = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .soundEffects) { soundEffects = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .muteMusicWhileDictating) { muteMusicWhileDictating = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .commandModeEnabled) { commandModeEnabled = v }
        if let v = try? c.decodeIfPresent(RetentionPolicy.self, forKey: .retention) { retention = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .keepAudio) { keepAudio = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .autoAddToDictionary) { autoAddToDictionary = v }
        if let v = try? c.decodeIfPresent(InsertionMethod.self, forKey: .insertion) { insertion = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .contextAwareness) { contextAwareness = v }
        if let v = try? c.decodeIfPresent([TextTransform].self, forKey: .transforms) { transforms = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .showScratchpadButton) { showScratchpadButton = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .notetakerIncludeSystemAudio) { notetakerIncludeSystemAudio = v }
    }
}

/// How dictated text gets into the other app.
public enum InsertionMethod: String, Codable, CaseIterable, Sendable {
    /// Put it on the clipboard, press Cmd+V, then restore the old clipboard.
    case paste
    /// Type it as keystrokes; the clipboard is never touched.
    case type
    public var title: String { self == .paste ? "Paste (restores your clipboard)" : "Type it out" }
}

/// JSON file store for settings, history, dictionary and snippets.
public final class FlowStore: @unchecked Sendable {
    public let directory: URL
    private let lock = NSLock()

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public static var defaultDirectory: URL { Brain.root }

    private func url(_ name: String) -> URL { directory.appendingPathComponent(name) }

    public func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        lock.lock(); defer { lock.unlock() }
        guard let data = try? Data(contentsOf: url(name)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    public func save<T: Encodable>(_ value: T, to name: String) {
        lock.lock(); defer { lock.unlock() }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(name), options: .atomic)
    }

    public var settings: FlowSettings {
        get { load(FlowSettings.self, from: "settings.json") ?? FlowSettings() }
        set { save(newValue, to: "settings.json") }
    }
    public var history: [Transcript] {
        get { load([Transcript].self, from: "history.json") ?? [] }
        set { save(newValue, to: "history.json") }
    }
    public var dictionary: [DictionaryEntry] {
        get { load([DictionaryEntry].self, from: "dictionary.json") ?? [] }
        set { save(newValue, to: "dictionary.json") }
    }
    public var notes: [ScratchNote] {
        get { load([ScratchNote].self, from: "scratchpad.json") ?? [] }
        set { save(newValue, to: "scratchpad.json") }
    }
    public var meetings: [Meeting] {
        get { load([Meeting].self, from: "meetings.json") ?? [] }
        set { save(newValue, to: "meetings.json") }
    }
    public var audioDirectory: URL {
        let dir = directory.appendingPathComponent("audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    public var snippets: [Snippet] {
        get { load([Snippet].self, from: "snippets.json") ?? [] }
        set { save(newValue, to: "snippets.json") }
    }
}
