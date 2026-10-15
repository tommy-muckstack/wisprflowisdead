import Foundation

/// Raw speech-engine text in, insertable text out. Order:
/// 1. backtrack ("no wait", "scratch that")
/// 2. MyMan's deterministic cleanup (fillers, stutters, spoken punctuation,
///    numbers, emails, vocabulary), skipped at cleanup level None
/// 3. snippets  4. personal dictionary  5. lists  6. writing style
/// The optional on-device model polish (macOS 26) runs in FlowVoice.
public struct DictationPipeline: Sendable {
    public struct Result: Equatable, Sendable {
        public var text: String
        public var snippetsUsed: [UUID]
        public var dictionaryUsed: [UUID]
    }

    public var style: WritingStyle
    public var category: AppCategory
    public var cleanup: CleanupLevel
    public var snippets: [Snippet]
    public var dictionary: [DictionaryEntry]

    public init(style: WritingStyle, category: AppCategory, cleanup: CleanupLevel,
                snippets: [Snippet], dictionary: [DictionaryEntry]) {
        self.style = style; self.category = category; self.cleanup = cleanup
        self.snippets = snippets; self.dictionary = dictionary
    }

    public init(settings: FlowSettings, bundleID: String?, url: String? = nil,
                snippets: [Snippet], dictionary: [DictionaryEntry]) {
        let category = AppCategory.classify(bundleID: bundleID, url: url)
        self.init(style: settings.styles[category] ?? .formal, category: category,
                  cleanup: settings.cleanupLevel, snippets: snippets, dictionary: dictionary)
    }

    public func process(_ raw: String) -> Result {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return Result(text: "", snippetsUsed: [], dictionaryUsed: []) }
        if cleanup != .none {
            text = Backtrack.apply(text)
            text = DictationCleanup.deterministicCleanup(text, terms: dictionary.map(\.term))
        }
        let (expanded, fired) = SnippetExpander.expand(text, snippets: snippets)
        let (spelled, used) = PersonalDictionary.apply(expanded, entries: dictionary)
        text = spelled
        if cleanup != .none {
            text = ListFormatter.apply(text)
            text = WritingStyler.apply(style, to: text, category: category)
        }
        return Result(text: text, snippetsUsed: fired, dictionaryUsed: used)
    }

    /// Prompt for the on-device model at each cleanup level.
    public var modelInstruction: String? {
        switch cleanup {
        case .none, .light: return nil
        case .medium: return "Edit for clarity and concision. Keep the speaker's meaning, facts and voice."
        case .high: return "Rewrite for brevity and polish. Keep every fact, name and number."
        }
    }
}
