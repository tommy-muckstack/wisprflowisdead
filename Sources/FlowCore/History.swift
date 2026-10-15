import Foundation

public struct Transcript: Codable, Equatable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable { case inserted, copied, failed, cancelled }
    public var id: UUID
    public var date: Date
    /// What the speech engine heard.
    public var raw: String
    /// What was inserted (after cleanup, style, snippets, dictionary).
    public var polished: String
    /// "Undo AI edit" shows `raw` in place of `polished`.
    public var showingRaw: Bool
    public var appName: String?
    public var bundleID: String?
    public var durationSeconds: Double
    public var status: Status
    public var mode: RecordingMode
    public var audioFile: String?

    public init(id: UUID = UUID(), date: Date = Date(), raw: String, polished: String,
                appName: String? = nil, bundleID: String? = nil, durationSeconds: Double,
                status: Status = .inserted, mode: RecordingMode = .dictation, audioFile: String? = nil) {
        self.id = id; self.date = date; self.raw = raw; self.polished = polished
        self.showingRaw = false; self.appName = appName; self.bundleID = bundleID
        self.durationSeconds = durationSeconds; self.status = status; self.mode = mode
        self.audioFile = audioFile
    }

    public var displayText: String { showingRaw ? raw : polished }
    public var wordCount: Int { polished.split(whereSeparator: \.isWhitespace).count }
}

extension RecordingMode: Codable {}

public enum HistoryGrouping {
    public struct Section: Identifiable, Equatable {
        public var id: String { title }
        public var title: String
        public var items: [Transcript]
    }

    /// Newest first, grouped as Today / Yesterday / "Monday, Oct 12".
    public static func sections(_ items: [Transcript], now: Date = Date(),
                                calendar: Calendar = .current) -> [Section] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMM d"
        var order: [String] = []
        var map: [String: [Transcript]] = [:]
        for t in items.sorted(by: { $0.date > $1.date }) {
            let title: String
            if calendar.isDate(t.date, inSameDayAs: now) { title = "Today" }
            else if let y = calendar.date(byAdding: .day, value: -1, to: now),
                    calendar.isDate(t.date, inSameDayAs: y) { title = "Yesterday" }
            else { title = formatter.string(from: t.date) }
            if map[title] == nil { order.append(title) }
            map[title, default: []].append(t)
        }
        return order.map { Section(title: $0, items: map[$0]!) }
    }
}

public enum RetentionPolicy: String, Codable, CaseIterable, Sendable {
    case normal, delete24h, never
    public var title: String {
        switch self {
        case .normal: return "Save normally"
        case .delete24h: return "Delete after 24 hours"
        case .never: return "Never store"
        }
    }

    /// Apply retention; audio older than 14 days is dropped even when normal.
    public func prune(_ items: [Transcript], now: Date = Date()) -> [Transcript] {
        switch self {
        case .never: return []
        case .delete24h: return items.filter { now.timeIntervalSince($0.date) < 86_400 }
        case .normal:
            return items.map { t in
                var t = t
                if now.timeIntervalSince(t.date) > 14 * 86_400 { t.audioFile = nil }
                return t
            }
        }
    }
}

public struct InsightsSummary: Equatable, Sendable {
    public var totalWords: Int
    public var wordsThisWeek: Int
    public var wordsPerMinute: Int
    public var dayStreak: Int
    public var topApps: [(name: String, words: Int)]
    public var wordsCleaned: Int

    public static func == (a: Self, b: Self) -> Bool {
        a.totalWords == b.totalWords && a.wordsThisWeek == b.wordsThisWeek &&
        a.wordsPerMinute == b.wordsPerMinute && a.dayStreak == b.dayStreak &&
        a.wordsCleaned == b.wordsCleaned &&
        a.topApps.map(\.name) == b.topApps.map(\.name) && a.topApps.map(\.words) == b.topApps.map(\.words)
    }

    public static func compute(_ items: [Transcript], now: Date = Date(),
                               calendar: Calendar = .current) -> InsightsSummary {
        let done = items.filter { $0.status == .inserted || $0.status == .copied }
        let total = done.reduce(0) { $0 + $1.wordCount }
        let weekAgo = now.addingTimeInterval(-7 * 86_400)
        let week = done.filter { $0.date > weekAgo }.reduce(0) { $0 + $1.wordCount }
        let seconds = done.reduce(0.0) { $0 + $1.durationSeconds }
        let wpm = seconds > 0 ? Int((Double(total) / (seconds / 60)).rounded()) : 0
        var byApp: [String: Int] = [:]
        for t in done { byApp[t.appName ?? "Other", default: 0] += t.wordCount }
        let top = byApp.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(5).map { (name: $0.key, words: $0.value) }
        let cleaned = done.reduce(0) { acc, t in
            let r = t.raw.split(whereSeparator: \.isWhitespace).count
            return acc + max(0, r - t.wordCount)
        }
        // Streak: consecutive days ending today (or yesterday) with a dictation.
        let days = Set(done.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var day = calendar.startOfDay(for: now)
        if !days.contains(day), let y = calendar.date(byAdding: .day, value: -1, to: day) { day = y }
        while days.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return InsightsSummary(totalWords: total, wordsThisWeek: week, wordsPerMinute: wpm,
                               dayStreak: streak, topApps: Array(top), wordsCleaned: cleaned)
    }
}
