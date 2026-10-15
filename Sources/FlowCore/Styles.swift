import Foundation

/// Where the text is going. Picked from the frontmost app or website.
public enum AppCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case personal, work, email, other
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .personal: return "Personal messages"
        case .work: return "Work messages"
        case .email: return "Email"
        case .other: return "Other"
        }
    }
    public var isMessaging: Bool { self == .personal || self == .work }

    static let personalApps = ["com.apple.mobilesms", "net.whatsapp", "whatsapp", "discord", "signal",
                               "telegram", "instagram", "messenger"]
    static let workApps = ["com.tinyspeck.slackmacgap", "slack", "com.microsoft.teams", "teams",
                           "linkedin", "zoom.us", "googlechat"]
    static let emailApps = ["com.apple.mail", "outlook", "superhuman", "missive", "spark",
                            "airmail", "mimestream", "hey.com", "gmail", "mail.google"]

    /// Classify by bundle identifier and, for browsers, the page URL host.
    public static func classify(bundleID: String?, url: String? = nil) -> AppCategory {
        let haystacks = [bundleID, url].compactMap { $0?.lowercased() }
        func matches(_ list: [String]) -> Bool {
            haystacks.contains { h in list.contains { h.contains($0) } }
        }
        if matches(emailApps) { return .email }
        if matches(workApps) { return .work }
        if matches(personalApps) { return .personal }
        return .other
    }
}

/// Wispr's four writing styles. Clone copy, our own wording.
public enum WritingStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case formal, casual, veryCasual, excited
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .formal: return "Formal."
        case .casual: return "Casual"
        case .veryCasual: return "very casual"
        case .excited: return "Excited!"
        }
    }
    public var detail: String {
        switch self {
        case .formal: return "Capitals and full punctuation."
        case .casual: return "Capitals, lighter punctuation."
        case .veryCasual: return "no capitals, barely any punctuation"
        case .excited: return "Upbeat, with exclamation points!"
        }
    }
    public func sample(for category: AppCategory) -> String {
        let base: String
        switch category {
        case .personal: base = "Hey, are we still on for dinner tonight?"
        case .work: base = "I pushed the fix. Can you take a look when you get a sec?"
        case .email: base = "Hi Sam, thanks for the update. I will send the deck by Friday."
        case .other: base = "Remember to book flights before the price goes up."
        }
        return WritingStyler.apply(self, to: base, category: category)
    }
}

/// Auto Cleanup level (Style tab).
public enum CleanupLevel: String, CaseIterable, Codable, Sendable, Identifiable {
    case none, light, medium, high
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
    public var detail: String {
        switch self {
        case .none: return "Exactly what you said, mistakes included"
        case .light: return "Removes filler words and fixes grammar"
        case .medium: return "Edits for clarity and concision"
        case .high: return "Rewrites for brevity and polish"
        }
    }
}

public enum WritingStyler {
    /// Apply style rules to already-cleaned text.
    public static func apply(_ style: WritingStyle, to text: String, category: AppCategory) -> String {
        var out = text
        switch style {
        case .formal:
            return out
        case .casual:
            if category.isMessaging { out = dropTrailingPeriod(out, maxSentences: 10) }
            return out
        case .veryCasual:
            out = lowercasingSentenceStarts(out)
            return dropTrailingPeriod(out, maxSentences: Int.max)
        case .excited:
            return excite(out)
        }
    }

    static func sentenceCount(_ text: String) -> Int {
        text.split(whereSeparator: { ".!?".contains($0) }).filter {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }.count
    }

    /// Remove a single trailing period on the last line (never "..." and
    /// never other punctuation).
    static func dropTrailingPeriod(_ text: String, maxSentences: Int) -> String {
        guard sentenceCount(text) <= maxSentences else { return text }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix("."), !trimmed.hasSuffix("..") else { return text }
        let lastLine = trimmed.split(separator: "\n").last.map(String.init) ?? trimmed
        // Lists keep their punctuation.
        if lastLine.range(of: #"^\s*(\d+\.|[-•])\s"#, options: .regularExpression) != nil { return text }
        return String(trimmed.dropLast())
    }

    /// Lowercase the first letter of each sentence, but keep "I", acronyms
    /// and words that are capitalized mid-sentence (names).
    static func lowercasingSentenceStarts(_ text: String) -> String {
        var result = ""
        var atStart = true
        var word = ""
        func flush() {
            if atStart && !word.isEmpty {
                let isAcronym = word.count > 1 && word == word.uppercased() && word.contains(where: \.isLetter)
                let isPronounI = word == "I" || word.hasPrefix("I'")
                if !isAcronym && !isPronounI, let first = word.first {
                    word = first.lowercased() + word.dropFirst()
                }
                atStart = false
            }
            result += word
            word = ""
        }
        for ch in text {
            if ch.isLetter || ch.isNumber || ch == "'" {
                word.append(ch)
            } else {
                flush()
                result.append(ch)
                if ".!?\n".contains(ch) { atStart = true }
            }
        }
        flush()
        return result
    }

    static func excite(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        // Turn the final sentence's period into "!" and leave questions alone.
        if trimmed.hasSuffix(".") && !trimmed.hasSuffix("..") { return String(trimmed.dropLast()) + "!" }
        if trimmed.last.map({ $0.isLetter || $0.isNumber }) == true { return trimmed + "!" }
        return trimmed
    }
}
