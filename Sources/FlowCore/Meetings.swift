import Foundation

/// Notetaker: a recorded meeting with two speaker tracks (you, others).
public struct Meeting: Codable, Equatable, Identifiable, Sendable {
    public struct Segment: Codable, Equatable, Sendable {
        public var speaker: String   // "You" or "Others"
        public var start: Double     // seconds from meeting start
        public var text: String
        public init(speaker: String, start: Double, text: String) {
            self.speaker = speaker; self.start = start; self.text = text
        }
    }
    public enum Status: String, Codable, Sendable { case recording, transcribing, complete }

    public var id: UUID
    public var title: String
    public var started: Date
    public var duration: Double
    public var segments: [Segment]
    public var summary: String
    public var myNotes: String
    public var status: Status

    public init(id: UUID = UUID(), title: String, started: Date = Date()) {
        self.id = id; self.title = title; self.started = started; self.duration = 0
        self.segments = []; self.summary = ""; self.myNotes = ""; self.status = .recording
    }

    /// Ordered by time; consecutive pieces from one speaker are merged.
    public static func merge(_ segments: [Segment]) -> [Segment] {
        var out: [Segment] = []
        for s in segments.sorted(by: { $0.start < $1.start }) where !s.text.isEmpty {
            if let last = out.last, last.speaker == s.speaker {
                out[out.count - 1].text += " " + s.text
            } else {
                out.append(s)
            }
        }
        return out
    }

    public static func timestamp(_ seconds: Double) -> String {
        let s = Int(seconds)
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
                         : String(format: "%d:%02d", s / 60, s % 60)
    }

    public var transcriptText: String {
        Meeting.merge(segments).map { "[\(Meeting.timestamp($0.start))] \($0.speaker): \($0.text)" }
            .joined(separator: "\n")
    }

    /// Fallback summary when no on-device model is available: sentences
    /// that carry commitments or decisions.
    public static func extractiveSummary(_ segments: [Segment], maxItems: Int = 8) -> String {
        let cues = ["will ", "i'll ", "we'll ", "let's ", "decided", "agree", "next step", "follow up",
                    "action item", "deadline", "by friday", "by monday", "send ", "need to "]
        var items: [String] = []
        for s in merge(segments) {
            for sentence in s.text.split(whereSeparator: { ".!?".contains($0) }) {
                let t = sentence.trimmingCharacters(in: .whitespaces)
                if t.split(separator: " ").count >= 4, cues.contains(where: { t.lowercased().contains($0) }) {
                    items.append("- \(s.speaker): \(t).")
                    if items.count >= maxItems { return items.joined(separator: "\n") }
                }
            }
        }
        return items.isEmpty ? "No decisions or follow-ups detected." : items.joined(separator: "\n")
    }

    public var markdown: String {
        var md = "# \(title)\n\n"
        let f = ISO8601DateFormatter()
        md += "Date: \(f.string(from: started))  \nDuration: \(Meeting.timestamp(duration))\n\n"
        if !summary.isEmpty { md += "## Summary\n\n\(summary)\n\n" }
        if !myNotes.isEmpty { md += "## My notes\n\n\(myNotes)\n\n" }
        md += "## Transcript\n\n\(transcriptText)\n"
        return md
    }
}
