import AppKit
import FlowCore
import FlowVoice
import SwiftUI

enum HubPage: String, CaseIterable, Identifiable {
    case home, meetings, insights, dictionary, snippets, style, transforms, scratchpad, settings, help
    var id: String { rawValue }
    var title: String { self == .meetings ? "Notetaker" : rawValue.capitalized }
    var icon: String {
        switch self {
        case .home: return "house"
        case .meetings: return "person.2.wave.2"
        case .transforms: return "wand.and.stars"
        case .scratchpad: return "note.text"
        case .insights: return "chart.bar"
        case .dictionary: return "character.book.closed"
        case .snippets: return "text.badge.plus"
        case .style: return "textformat"
        case .settings: return "gearshape"
        case .help: return "questionmark.circle"
        }
    }
    static let main: [HubPage] = [.home, .meetings, .insights, .dictionary, .snippets, .style, .transforms, .scratchpad]
}

final class HubNavigation: ObservableObject {
    @Published var page: HubPage = .home
}

struct HubView: View {
    @ObservedObject var controller: DictationController
    @ObservedObject var nav: HubNavigation

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(Theme.hairline)
            ScrollView {
                page.padding(32).frame(maxWidth: 820, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cream)
        }
        .font(Theme.font(14))
        .foregroundStyle(Theme.ink)
        .frame(minWidth: 860, minHeight: 600)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                AppMark().frame(width: 22, height: 22)
                Text("WisprFlowIsDead").font(Theme.display(19))
            }
                .padding(.horizontal, 12).padding(.top, 36).padding(.bottom, 18)
            ForEach(HubPage.main) { item(for: $0) }
            Spacer()
            item(for: .settings)
            item(for: .help)
            Text("Free forever · on-device")
                .font(Theme.font(11)).foregroundStyle(Theme.muted)
                .padding(12)
        }
        .padding(.horizontal, 10)
        .frame(width: 210)
        .background(Theme.paper)
    }

    private func item(for p: HubPage) -> some View {
        Button { nav.page = p } label: {
            HStack(spacing: 10) {
                Image(systemName: p.icon).frame(width: 18)
                Text(p.title).font(Theme.font(14, nav.page == p ? .semibold : .regular))
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(nav.page == p ? Theme.lavender : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var page: some View {
        switch nav.page {
        case .home: HomePage(controller: controller)
        case .meetings: MeetingsPage(controller: controller, recorder: controller.recorder)
        case .transforms: TransformsPage(controller: controller)
        case .scratchpad: ScratchpadView(controller: controller)
        case .insights: InsightsPage(controller: controller)
        case .dictionary: DictionaryPage(controller: controller)
        case .snippets: SnippetsPage(controller: controller)
        case .style: StylePage(controller: controller)
        case .settings: SettingsPage(controller: controller)
        case .help: HelpPage()
        }
    }
}

struct PageTitle: View {
    var title: String
    var subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.display(28))
            if let subtitle { Text(subtitle).font(Theme.font(14)).foregroundStyle(Theme.muted) }
        }
        .padding(.bottom, 12)
    }
}

// MARK: Home

struct HomePage: View {
    @ObservedObject var controller: DictationController
    @ObservedObject private var playback = AudioPlayback.shared
    @State private var hovered: UUID?

    var body: some View {
        let stats = InsightsSummary.compute(controller.history)
        let key = controller.settings.shortcuts.shortcuts(for: .pushToTalk).first?.display ?? "fn"
        VStack(alignment: .leading, spacing: 20) {
            PageTitle(title: "Welcome back", subtitle: "Hold \(key) and talk in any app.")
            HStack(spacing: 12) {
                Stat(value: "\(stats.wordsThisWeek)", label: "words this week")
                Stat(value: "\(stats.wordsPerMinute)", label: "words per minute")
                Stat(value: "\(stats.dayStreak)", label: stats.dayStreak == 1 ? "day streak" : "day streak")
            }
            if let p = controller.modelProgress {
                Card {
                    Text("Downloading the speech model").font(Theme.font(14, .semibold))
                    ProgressView(value: p).tint(Theme.ink)
                }
            }
            if controller.history.isEmpty {
                Card {
                    Text("Your dictations will show up here.").font(Theme.font(15, .semibold))
                    Text("Click into any text field, hold \(key), say something, and let go.")
                        .foregroundStyle(Theme.muted)
                }
            }
            ForEach(HistoryGrouping.sections(controller.history)) { section in
                VStack(alignment: .leading, spacing: 0) {
                    Text(section.title.uppercased())
                        .font(Theme.font(11, .semibold)).foregroundStyle(Theme.muted)
                        .padding(.bottom, 8)
                    VStack(spacing: 0) {
                        ForEach(section.items) { t in row(t); Divider().overlay(Theme.hairline) }
                    }
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1))
                }
            }
        }
    }

    private func row(_ t: Transcript) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(t.date.formatted(date: .omitted, time: .shortened))
                .font(Theme.font(12)).foregroundStyle(Theme.muted)
                .frame(width: 64, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                if t.status == .pending || t.status == .failed {
                    HStack {
                        Text(t.status == .pending ? "Interrupted \(Meeting.timestamp(t.durationSeconds)) dictation"
                                                  : "Retry your \(Meeting.timestamp(t.durationSeconds)) transcript")
                            .foregroundStyle(Theme.orange)
                        if controller.audioURL(t) != nil {
                            Button(t.status == .pending ? "Recover" : "Retry") { controller.retry(t) }
                                .buttonStyle(PillButtonStyle(prominent: false))
                        }
                    }
                } else {
                    Text(t.displayText).textSelection(.enabled)
                }
                HStack(spacing: 6) {
                    if t.mode == .command { Tag(text: "Command") }
                    if t.showingRaw { Tag(text: "Original") }
                    if t.status == .copied { Tag(text: "Copied") }
                    if let app = t.appName { Text(app).font(Theme.font(11)).foregroundStyle(Theme.muted) }
                }
            }
            Spacer()
            if hovered == t.id {
                HStack(spacing: 10) {
                    if let url = controller.audioURL(t) {
                        Button { playback.toggle(url) } label: {
                            Image(systemName: playback.playing == url ? "pause.fill" : "play.fill")
                        }.help("Play audio")
                    }
                    Button { VoiceEngine.copyToClipboard(t.displayText) } label: { Image(systemName: "doc.on.doc") }
                        .help("Copy")
                    Menu {
                        Button(t.showingRaw ? "Redo AI edit" : "Undo AI edit") { controller.toggleRaw(t) }
                        if controller.audioURL(t) != nil { Button("Retry transcription") { controller.retry(t) } }
                        Button("Delete", role: .destructive) { controller.delete(t) }
                    } label: { Image(systemName: "ellipsis") }
                        .menuStyle(.borderlessButton).frame(width: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .contentShape(Rectangle())
        .onHover { hovered = $0 ? t.id : (hovered == t.id ? nil : hovered) }
    }
}

struct Stat: View {
    var value: String
    var label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.display(26))
            Text(label).font(Theme.font(12)).foregroundStyle(Theme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }
}

struct Tag: View {
    var text: String
    var body: some View {
        Text(text).font(Theme.font(10, .semibold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(Theme.lavender))
    }
}

// MARK: Insights

struct InsightsPage: View {
    @ObservedObject var controller: DictationController
    var body: some View {
        let s = InsightsSummary.compute(controller.history)
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Insights", subtitle: "Your usage. It never leaves this Mac.")
            HStack(spacing: 12) {
                Stat(value: "\(s.totalWords)", label: "total words")
                Stat(value: "\(s.wordsPerMinute)", label: "words per minute")
                Stat(value: "\(s.wordsCleaned)", label: "words cleaned up")
            }
            Card {
                Text("Top apps").font(Theme.font(15, .semibold))
                if s.topApps.isEmpty { Text("Nothing yet.").foregroundStyle(Theme.muted) }
                ForEach(s.topApps, id: \.name) { app in
                    HStack {
                        Text(app.name)
                        Spacer()
                        Text("\(app.words) words").foregroundStyle(Theme.muted)
                    }
                }
            }
            Card {
                Text("Streak").font(Theme.font(15, .semibold))
                StreakGrid(history: controller.history)
            }
        }
    }
}

/// 12 weeks of days, darker when more words were dictated.
struct StreakGrid: View {
    var history: [Transcript]
    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var words: [Date: Int] = [:]
        for t in history { words[cal.startOfDay(for: t.date), default: 0] += t.wordCount }
        let maxWords = max(1, words.values.max() ?? 1)
        return HStack(spacing: 3) {
            ForEach((0..<12).reversed(), id: \.self) { week in
                VStack(spacing: 3) {
                    ForEach((0..<7).reversed(), id: \.self) { day in
                        let date = cal.date(byAdding: .day, value: -(week * 7 + day), to: today)!
                        let w = words[date] ?? 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(w == 0 ? Theme.creamDark : Theme.forest.opacity(0.3 + 0.7 * Double(w) / Double(maxWords)))
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
    }
}

// MARK: Dictionary

struct DictionaryPage: View {
    @ObservedObject var controller: DictationController
    @State private var query = ""
    @State private var newTerm = ""
    @State private var newSoundsLike = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Dictionary", subtitle: "Names, jargon and spellings we should always get right.")
            Card {
                HStack {
                    TextField("Word or phrase", text: $newTerm).textFieldStyle(.roundedBorder)
                    TextField("Often heard as (optional)", text: $newSoundsLike).textFieldStyle(.roundedBorder)
                    Button("Add") { add() }.buttonStyle(PillButtonStyle()).disabled(newTerm.isEmpty)
                }
            }
            TextField("Search", text: $query).textFieldStyle(.roundedBorder)
            let list = PersonalDictionary.ranked(controller.dictionary).filter {
                query.isEmpty || $0.term.localizedCaseInsensitiveContains(query)
            }
            VStack(spacing: 0) {
                ForEach(list) { e in
                    HStack {
                        Button { toggleStar(e) } label: {
                            Image(systemName: e.starred ? "star.fill" : "star")
                                .foregroundStyle(e.starred ? Theme.amber : Theme.muted)
                        }.buttonStyle(.plain)
                        VStack(alignment: .leading) {
                            Text(e.term).font(Theme.font(14, .semibold))
                            if !e.soundsLike.isEmpty {
                                Text("from “\(e.soundsLike.joined(separator: "”, “"))”")
                                    .font(Theme.font(12)).foregroundStyle(Theme.muted)
                            }
                        }
                        Spacer()
                        if e.autoAdded { Tag(text: "Auto") }
                        Text("\(e.uses)×").font(Theme.font(12)).foregroundStyle(Theme.muted)
                        Button { controller.dictionary.removeAll { $0.id == e.id } } label: {
                            Image(systemName: "trash")
                        }.buttonStyle(.plain).foregroundStyle(Theme.muted)
                    }
                    .padding(12)
                    Divider().overlay(Theme.hairline)
                }
            }
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
    }

    private func add() {
        let alts = newSoundsLike.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        controller.dictionary.append(DictionaryEntry(term: newTerm.trimmingCharacters(in: .whitespaces), soundsLike: alts))
        newTerm = ""; newSoundsLike = ""
    }

    private func toggleStar(_ e: DictionaryEntry) {
        guard let i = controller.dictionary.firstIndex(where: { $0.id == e.id }) else { return }
        controller.dictionary[i].starred.toggle()
    }
}

// MARK: Snippets

struct SnippetsPage: View {
    @ObservedObject var controller: DictationController
    @State private var cue = ""
    @State private var expansion = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Snippets", subtitle: "Say the cue and we'll drop in the full text.")
            Card {
                TextField("Cue, e.g. “my calendar link”", text: $cue).textFieldStyle(.roundedBorder)
                TextEditor(text: $expansion)
                    .font(Theme.font(13))
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 0.5))
                Button("Add snippet") {
                    controller.snippets.append(Snippet(cue: cue, expansion: expansion))
                    cue = ""; expansion = ""
                }
                .buttonStyle(PillButtonStyle()).disabled(cue.isEmpty || expansion.isEmpty)
            }
            ForEach(controller.snippets) { s in
                Card {
                    HStack {
                        Text("“\(s.cue)”").font(Theme.font(14, .semibold))
                        Spacer()
                        Text("\(s.uses)×").font(Theme.font(12)).foregroundStyle(Theme.muted)
                        Button { controller.snippets.removeAll { $0.id == s.id } } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain).foregroundStyle(Theme.muted)
                    }
                    Text(s.expansion).foregroundStyle(Theme.muted).textSelection(.enabled)
                }
            }
        }
    }
}

// MARK: Style

struct StylePage: View {
    @ObservedObject var controller: DictationController
    @State private var category: AppCategory = .personal

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Style", subtitle: "How you sound, by where you're writing. English only.")
            Picker("", selection: $category) {
                ForEach(AppCategory.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()
            HStack(alignment: .top, spacing: 12) {
                ForEach(WritingStyle.allCases) { style in
                    let selected = controller.settings.styles[category] == style
                    Button { controller.settings.styles[category] = style } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(style.title).font(Theme.font(16, .bold))
                            Text(style.detail).font(Theme.font(12)).foregroundStyle(Theme.muted)
                            Text(style.sample(for: category))
                                .font(Theme.font(13))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.paper))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(selected ? Theme.lavender : Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .stroke(selected ? Theme.ink : Theme.hairline, lineWidth: selected ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Card {
                Text("Auto Cleanup").font(Theme.font(15, .semibold))
                Picker("", selection: $controller.settings.cleanupLevel) {
                    ForEach(CleanupLevel.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden()
                Text(controller.settings.cleanupLevel.detail).font(Theme.font(12)).foregroundStyle(Theme.muted)
                if controller.settings.cleanupLevel == .medium || controller.settings.cleanupLevel == .high {
                    Text("Medium and High use Apple's on-device model on macOS 26. Older systems get Light.")
                        .font(Theme.font(12)).foregroundStyle(Theme.muted)
                }
            }
        }
    }
}

// MARK: Help

struct HelpPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Help")
            Card {
                Text("Hold your push-to-talk key, talk, let go. Double-tap it for hands-free.")
                Text("Say “scratch that” to drop what you just said, or “no wait” to correct a word.")
                Text("Say “first … second …” to get a numbered list.")
            }
            Card {
                Text("WisprFlowIsDead is free and open source (Apache-2.0). It is not affiliated with Wispr.")
                Link("github.com/tommy-muckstack/wisprflowisdead",
                     destination: URL(string: "https://github.com/tommy-muckstack/wisprflowisdead")!)
            }
        }
    }
}
