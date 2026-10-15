import Foundation

/// Context awareness: proper nouns visible around the cursor (the field's
/// text, the window title) become extra spelling hints for this dictation.
public enum ContextTerms {
    static let common: Set<String> = [
        "The", "This", "That", "These", "Those", "There", "Then", "Thanks", "Thank", "Hi", "Hey", "Hello",
        "Dear", "Best", "Regards", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
        "Sunday", "January", "February", "March", "April", "May", "June", "July", "August", "September",
        "October", "November", "December", "And", "But", "So", "If", "When", "What", "Why", "How", "We",
        "You", "They", "It", "Yes", "No", "Okay", "OK", "Sure", "Re", "Fwd", "Inbox", "Untitled",
    ]

    /// CamelCase words, capitalized words away from sentence starts, emails
    /// and @handles. Ordered by first appearance, max `limit`.
    public static func extract(from texts: [String], limit: Int = 40) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        func add(_ s: String) {
            let t = s.trimmingCharacters(in: CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "@.")))
            guard t.count > 2, !common.contains(t), seen.insert(t.lowercased()).inserted else { return }
            out.append(t)
        }
        for text in texts {
            let ns = text as NSString
            let patterns = [
                #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
                #"@[A-Za-z][A-Za-z0-9_]{2,}"#,
                #"\b[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]+)+\b"#,
                #"(?<=[a-z,;:]\s)[A-Z][a-zA-Z'-]{2,}(?:\s[A-Z][a-zA-Z'-]{2,})*"#,
            ]
            for p in patterns {
                guard let regex = try? NSRegularExpression(pattern: p) else { continue }
                for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                    add(ns.substring(with: m.range))
                    if out.count >= limit { return out }
                }
            }
        }
        return out
    }
}

/// Learn from correction: find what the user changed in the text we inserted.
public enum CorrectionFinder {
    /// The span of `fieldValue` that best matches `inserted` with the same
    /// word count (the user's edited version), or nil when it is unchanged
    /// or can no longer be found.
    static func bare(_ w: String) -> String { w.trimmingCharacters(in: .punctuationCharacters) }

    public static func editedSpan(inserted: String, fieldValue: String) -> String? {
        let target = inserted.split(whereSeparator: \.isWhitespace).map(String.init)
        let words = fieldValue.split(whereSeparator: \.isWhitespace).map(String.init)
        guard target.count >= 2, words.count >= target.count else { return nil }
        if fieldValue.contains(inserted) { return nil }
        var best: (score: Int, start: Int)?
        for start in 0...(words.count - target.count) {
            var score = 0
            for i in 0..<target.count where bare(words[start + i]) == bare(target[i]) { score += 1 }
            if best == nil || score > best!.score { best = (score, start) }
        }
        guard let b = best, b.score >= target.count - 1, b.score < target.count else { return nil }
        return words[b.start..<(b.start + target.count)].joined(separator: " ")
    }
}

/// Ranked microphone choice: the highest-ranked device that is connected.
public enum MicrophoneRanking {
    public static func choose(ranking: [String], available: [String]) -> String? {
        ranking.first { available.contains($0) }
    }

    /// New devices are appended; unknown ranking entries are kept so a
    /// headset ranks correctly the next time it is plugged in.
    public static func merge(ranking: [String], available: [String]) -> [String] {
        ranking + available.filter { !ranking.contains($0) }
    }
}
