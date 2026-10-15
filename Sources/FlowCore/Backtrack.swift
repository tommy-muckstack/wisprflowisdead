import Foundation

/// Spoken self-corrections. "Tuesday, no wait, Wednesday" keeps only the
/// replacement; "scratch that" drops the sentence it follows. A bare
/// "actually" is not a correction, and "never mind" inside content stays.
public enum Backtrack {
    static let cues = ["no wait", "no, wait", "wait no", "wait, no", "sorry I mean", "sorry, I mean",
                       "I mean", "or rather", "correction"]

    public static func apply(_ text: String) -> String {
        var result = applyScratchThat(text)
        result = applyCorrections(result)
        return result.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// "scratch that" removes the preceding sentence (or everything before it
    /// in the current sentence) plus the cue.
    static func applyScratchThat(_ text: String) -> String {
        let pattern = #"(?i)[,.]?\s*\bscratch that\b[,.!]?\s*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var current = text
        while let match = regex.firstMatch(in: current, range: NSRange(current.startIndex..., in: current)),
              let range = Range(match.range, in: current) {
            let before = String(current[..<range.lowerBound])
            let after = String(current[range.upperBound...])
            // Keep everything up to the last sentence end before the cue.
            let keep: String
            if let end = before.lastIndex(where: { ".!?\n".contains($0) }) {
                keep = String(before[...end]) + " "
            } else {
                keep = ""
            }
            current = keep + capitalizedFirst(after)
        }
        return current
    }

    /// "<X>, no wait, <Y>": replace the last word-span of X that matches the
    /// length of Y. Conservative: only short replacements (1-4 words).
    static func applyCorrections(_ text: String) -> String {
        var current = text
        for cue in cues {
            let escaped = NSRegularExpression.escapedPattern(for: cue)
            let pattern = "(?i)(\\S+(?:\\s+\\S+){0,3}?)[,]?\\s+\(escaped)[,]?\\s+([^.,!?]{1,40}?)([.,!?]|$)"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            while let m = regex.firstMatch(in: current, range: NSRange(current.startIndex..., in: current)),
                  let whole = Range(m.range, in: current),
                  let wrongR = Range(m.range(at: 1), in: current),
                  let rightR = Range(m.range(at: 2), in: current),
                  let endR = Range(m.range(at: 3), in: current) {
                let right = current[rightR].trimmingCharacters(in: .whitespaces)
                let rightCount = right.split(separator: " ").count
                guard rightCount >= 1, rightCount <= 4 else { break }
                // Drop as many trailing words of the wrong span as the fix has.
                var wrongWords = current[wrongR].split(separator: " ").map(String.init)
                wrongWords.removeLast(min(rightCount, wrongWords.count))
                let kept = (wrongWords + [right]).joined(separator: " ")
                current.replaceSubrange(whole, with: kept + current[endR])
            }
        }
        return current
    }

    static func capitalizedFirst(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.uppercased() + s.dropFirst()
    }
}

/// "first ... second ... third" or "one ... two ... three" spoken as a list
/// becomes a numbered list when there are at least two items.
public enum ListFormatter {
    static let ordinalSets: [[String]] = [
        ["first", "second", "third", "fourth", "fifth", "sixth"],
        ["one", "two", "three", "four", "five", "six"],
        ["number one", "number two", "number three", "number four", "number five", "number six"],
    ]

    public static func apply(_ text: String) -> String {
        for set in ordinalSets.reversed() {
            if let list = tryList(text, markers: set) { return list }
        }
        return text
    }

    static func tryList(_ text: String, markers: [String]) -> String? {
        let lower = text.lowercased()
        var positions: [(Range<String.Index>, Int)] = []
        var searchFrom = lower.startIndex
        for (i, marker) in markers.enumerated() {
            let pattern = "\\b\(marker)\\b[,:]?"
            guard let r = lower.range(of: pattern, options: .regularExpression, range: searchFrom..<lower.endIndex) else { break }
            positions.append((r, i))
            searchFrom = r.upperBound
        }
        guard positions.count >= 2, positions[0].1 == 0 else { return nil }
        // Markers must start clauses: previous char is start, ':' , '.', ',' or space after those.
        let intro = text[text.startIndex..<positions[0].0.lowerBound]
            .trimmingCharacters(in: .whitespaces)
        var items: [String] = []
        for (n, (range, _)) in positions.enumerated() {
            let end = n + 1 < positions.count ? positions[n + 1].0.lowerBound : text.endIndex
            var item = text[range.upperBound..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            item = item.trimmingCharacters(in: CharacterSet(charactersIn: ",;"))
                .trimmingCharacters(in: .whitespaces)
            if item.hasSuffix(", and") { item = String(item.dropLast(5)) }
            if item.hasSuffix(" and") { item = String(item.dropLast(4)) }
            item = item.trimmingCharacters(in: CharacterSet(charactersIn: ",; "))
            guard !item.isEmpty, item.split(separator: " ").count <= 20 else { return nil }
            items.append(Backtrack.capitalizedFirst(item))
        }
        var lines: [String] = []
        if !intro.isEmpty {
            var head = intro
            if head.hasSuffix(",") { head = String(head.dropLast()) }
            if !head.hasSuffix(":") { head += ":" }
            lines.append(head)
        }
        for (i, item) in items.enumerated() { lines.append("\(i + 1). \(item)") }
        return lines.joined(separator: "\n")
    }
}
