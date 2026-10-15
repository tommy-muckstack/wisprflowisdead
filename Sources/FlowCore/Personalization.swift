import Foundation

public struct Snippet: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var cue: String
    public var expansion: String
    public var uses: Int
    public init(id: UUID = UUID(), cue: String, expansion: String, uses: Int = 0) {
        self.id = id; self.cue = cue; self.expansion = expansion; self.uses = uses
    }
}

public struct DictionaryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    /// The correct spelling.
    public var term: String
    /// Optional misheard forms that should become `term`.
    public var soundsLike: [String]
    public var starred: Bool
    public var uses: Int
    public var autoAdded: Bool
    public init(id: UUID = UUID(), term: String, soundsLike: [String] = [], starred: Bool = false,
                uses: Int = 0, autoAdded: Bool = false) {
        self.id = id; self.term = term; self.soundsLike = soundsLike
        self.starred = starred; self.uses = uses; self.autoAdded = autoAdded
    }
}

public enum SnippetExpander {
    /// Replace each spoken cue (whole phrase, case-insensitive, trailing
    /// punctuation absorbed) with its expansion. Returns ids that fired.
    public static func expand(_ text: String, snippets: [Snippet]) -> (String, [UUID]) {
        var out = text
        var fired: [UUID] = []
        // Longest cue first so "my calendar link" beats "calendar".
        for s in snippets.sorted(by: { $0.cue.count > $1.cue.count }) where !s.cue.isEmpty {
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: s.cue))\\b[.!]?"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            if regex.firstMatch(in: out, range: range) != nil {
                out = regex.stringByReplacingMatches(in: out, range: range,
                                                     withTemplate: NSRegularExpression.escapedTemplate(for: s.expansion))
                fired.append(s.id)
            }
        }
        return (out, fired)
    }
}

public enum PersonalDictionary {
    /// Apply explicit "sounds like" replacements, then fuzzy-restore the
    /// spelling of each term using MyMan's vocabulary matcher.
    public static func apply(_ text: String, entries: [DictionaryEntry]) -> (String, [UUID]) {
        var out = text
        var used: [UUID] = []
        for e in entries {
            for wrong in e.soundsLike where !wrong.isEmpty {
                let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: wrong))\\b"
                if out.range(of: pattern, options: .regularExpression) != nil {
                    out = out.replacingOccurrences(of: pattern, with: e.term, options: .regularExpression)
                    used.append(e.id)
                }
            }
        }
        // Starred terms first so they win ties.
        let terms = entries.sorted { $0.starred && !$1.starred }.map(\.term)
        let restored = DictationCleanup.applyVocabulary(out, terms: terms)
        for e in entries where !used.contains(e.id) {
            if restored.range(of: e.term, options: .caseInsensitive) != nil &&
                out.range(of: e.term, options: .caseInsensitive) == nil {
                used.append(e.id)
            }
        }
        return (restored, used)
    }

    /// When the user edits a pasted word, learn the corrected spelling.
    /// Returns the new term if one should be auto-added.
    public static func learnCorrection(original: String, edited: String,
                                       existing: [DictionaryEntry]) -> DictionaryEntry? {
        let a = original.split(separator: " ").map(String.init)
        let b = edited.split(separator: " ").map(String.init)
        guard a.count == b.count else { return nil }
        let diffs = zip(a, b).filter { $0 != $1 }
        guard diffs.count == 1, let (wrong, right) = diffs.first else { return nil }
        let clean = right.trimmingCharacters(in: .punctuationCharacters)
        let wrongClean = wrong.trimmingCharacters(in: .punctuationCharacters)
        // Apostrophe and case variants are not new words.
        func norm(_ s: String) -> String { s.lowercased().replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "’", with: "") }
        guard norm(clean) != norm(wrongClean), clean.count > 1 else { return nil }
        guard !existing.contains(where: { norm($0.term) == norm(clean) }) else { return nil }
        return DictionaryEntry(term: clean, soundsLike: [wrongClean], autoAdded: true)
    }

    /// Sorted for display: starred, then by usage, then alphabetically.
    public static func ranked(_ entries: [DictionaryEntry]) -> [DictionaryEntry] {
        entries.sorted {
            if $0.starred != $1.starred { return $0.starred }
            if $0.uses != $1.uses { return $0.uses > $1.uses }
            return $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending
        }
    }
}
