import AppKit
import AVFoundation
import FlowCore
import FlowVoice
import SwiftUI

/// One shared player so starting a row stops the previous one.
@MainActor
final class AudioPlayback: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayback()
    @Published var playing: URL?
    private var player: AVAudioPlayer?

    func toggle(_ url: URL) {
        if playing == url { player?.stop(); playing = nil; return }
        player?.stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.play()
        playing = player == nil ? nil : url
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.playing = nil }
    }
}

/// The app mark drawn in code (no image assets): a dark pill with five
/// sound bars, the last one tipped over.
struct AppMark: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.24, style: .continuous).fill(Theme.ink)
                HStack(alignment: .bottom, spacing: w * 0.04) {
                    ForEach([0.25, 0.42, 0.33, 0.47], id: \.self) { h in
                        Capsule().fill(Theme.cream).frame(width: w * 0.064, height: w * h)
                    }
                    Capsule().fill(Theme.orange).frame(width: w * 0.27, height: w * 0.064)
                }
                .offset(y: w * 0.04)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: Notetaker

struct MeetingsPage: View {
    @ObservedObject var controller: DictationController
    @ObservedObject var recorder: MeetingRecorder
    @State private var title = ""
    @State private var open: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Notetaker", subtitle: "Record any call or conversation. No bot joins, nothing leaves this Mac.")
            Card {
                if recorder.isRecording {
                    HStack {
                        Circle().fill(Theme.orange).frame(width: 10, height: 10)
                        Text("Recording · \(Meeting.timestamp(recorder.elapsed))").font(Theme.font(15, .semibold))
                        Spacer()
                        Button("Stop and summarize") { controller.stopMeeting(title: title); title = "" }
                            .buttonStyle(PillButtonStyle())
                    }
                    ForEach(Array(recorder.segments.suffix(6).enumerated()), id: \.offset) { _, s in
                        Text("\(s.speaker): \(s.text)").font(Theme.font(13)).foregroundStyle(Theme.muted)
                    }
                } else {
                    HStack {
                        TextField("Meeting name", text: $title).textFieldStyle(.roundedBorder)
                        Button("Start recording") { controller.startMeeting() }.buttonStyle(PillButtonStyle())
                    }
                    Toggle("Also record what other people say (system audio)",
                           isOn: $controller.settings.notetakerIncludeSystemAudio)
                        .font(Theme.font(13)).toggleStyle(.switch).tint(Theme.ink)
                    Text("Tell people before you record them.").font(Theme.font(12)).foregroundStyle(Theme.muted)
                }
            }
            ForEach(controller.meetings) { m in
                Card {
                    Button { open = open == m.id ? nil : m.id } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.title).font(Theme.font(16, .semibold))
                                Text("\(m.started.formatted(date: .abbreviated, time: .shortened)) · \(Meeting.timestamp(m.duration))")
                                    .font(Theme.font(12)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            if m.status != .complete { ProgressView().controlSize(.small) }
                            Image(systemName: open == m.id ? "chevron.up" : "chevron.down")
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if open == m.id {
                        if !m.summary.isEmpty {
                            Text("Summary").font(Theme.font(13, .semibold))
                            Text(m.summary).textSelection(.enabled)
                        }
                        Text("My notes").font(Theme.font(13, .semibold))
                        TextEditor(text: binding(m.id, \.myNotes)).font(Theme.font(13)).frame(height: 80)
                        Text("Transcript").font(Theme.font(13, .semibold))
                        Text(m.transcriptText.isEmpty ? "Nothing was transcribed." : m.transcriptText)
                            .font(Theme.font(12)).textSelection(.enabled)
                        HStack {
                            Button("Copy as Markdown") { VoiceEngine.copyToClipboard(m.markdown) }
                                .buttonStyle(PillButtonStyle(prominent: false))
                            Button("Delete", role: .destructive) { controller.meetings.removeAll { $0.id == m.id } }
                                .buttonStyle(PillButtonStyle(prominent: false))
                        }
                    }
                }
            }
        }
    }

    private func binding(_ id: UUID, _ key: WritableKeyPath<Meeting, String>) -> Binding<String> {
        Binding(get: { controller.meetings.first { $0.id == id }?[keyPath: key] ?? "" },
                set: { v in if let i = controller.meetings.firstIndex(where: { $0.id == id }) { controller.meetings[i][keyPath: key] = v } })
    }
}

// MARK: Transforms

struct TransformsPage: View {
    @ObservedObject var controller: DictationController
    @State private var name = ""
    @State private var prompt = ""

    var body: some View {
        let key = controller.settings.shortcuts.shortcuts(for: .runTransform).first?.display ?? "a shortcut"
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Transforms", subtitle: "Select text anywhere and press \(key), or hover the Flow Bar and click the wand.")
            ForEach($controller.settings.transforms) { $t in
                Card {
                    HStack {
                        Text(t.name).font(Theme.font(16, .semibold))
                        if t.builtIn { Tag(text: "Built in") }
                        if t.id == controller.settings.transforms.first?.id { Tag(text: "Shortcut") }
                        Spacer()
                        if t.id != controller.settings.transforms.first?.id {
                            Button("Use for shortcut") { makeDefault(t.id) }.buttonStyle(PillButtonStyle(prominent: false))
                        }
                        if !t.builtIn {
                            Button { controller.settings.transforms.removeAll { $0.id == t.id } } label: { Image(systemName: "trash") }
                                .buttonStyle(.plain).foregroundStyle(Theme.muted)
                        }
                    }
                    Text(t.prompt).font(Theme.font(13)).foregroundStyle(Theme.muted)
                    Toggle("Run after every dictation", isOn: $t.runAfterDictation)
                        .font(Theme.font(13)).toggleStyle(.switch).tint(Theme.ink)
                }
            }
            Card {
                Text("New transform").font(Theme.font(15, .semibold))
                TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                TextField("What should it do? e.g. “Translate to Spanish”", text: $prompt).textFieldStyle(.roundedBorder)
                Button("Add") {
                    controller.settings.transforms.append(TextTransform(name: name, prompt: prompt))
                    name = ""; prompt = ""
                }.buttonStyle(PillButtonStyle()).disabled(name.isEmpty || prompt.isEmpty)
                Text(CommandRunner.isAvailable ? "Runs on Apple's on-device model."
                     : "Custom transforms need macOS 26 with Apple Intelligence. Polish and Prompt Engineer have simpler built-in fallbacks.")
                    .font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
        }
    }

    private func makeDefault(_ id: UUID) {
        guard let i = controller.settings.transforms.firstIndex(where: { $0.id == id }) else { return }
        let t = controller.settings.transforms.remove(at: i)
        controller.settings.transforms.insert(t, at: 0)
    }
}

// MARK: Scratchpad

struct ScratchpadView: View {
    @ObservedObject var controller: DictationController
    @State private var selected: UUID?
    @State private var query = ""

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TextField("Search", text: $query).textFieldStyle(.roundedBorder)
                    Button { newNote() } label: { Image(systemName: "square.and.pencil") }.buttonStyle(.plain)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        let list = ScratchNote.search(controller.notes, query: query)
                        if list.isEmpty { Text(query.isEmpty ? "No notes yet" : "No matching notes").foregroundStyle(Theme.muted) }
                        ForEach(list) { n in
                            Button { selected = n.id } label: {
                                HStack {
                                    if n.pinned { Image(systemName: "pin.fill").font(.system(size: 9)) }
                                    Text(n.title).lineLimit(1)
                                    Spacer()
                                }
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(selected == n.id ? Theme.lavender : .clear))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(10)
            .frame(width: 190)
            .background(Theme.paper)
            Divider()
            if let id = selected, let i = controller.notes.firstIndex(where: { $0.id == id }) {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Button { controller.notes[i].pinned.toggle() } label: {
                            Image(systemName: controller.notes[i].pinned ? "pin.slash" : "pin")
                        }.buttonStyle(.plain)
                        Button { controller.notes.remove(at: i); selected = nil } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain)
                    }
                    TextEditor(text: Binding(get: { controller.notes[i].body },
                                             set: { controller.notes[i].body = $0; controller.notes[i].updated = Date() }))
                        .font(Theme.font(15))
                        .scrollContentBackground(.hidden)
                }
                .padding(12)
            } else {
                VStack(spacing: 10) {
                    Text("Jot it down, or hold your dictation key and talk.").foregroundStyle(Theme.muted)
                    Button("New note") { newNote() }.buttonStyle(PillButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 560, minHeight: 380)
        .background(Theme.cream)
        .foregroundStyle(Theme.ink)
        .font(Theme.font(14))
        .onAppear { if selected == nil { selected = ScratchNote.search(controller.notes, query: "").first?.id } }
    }

    private func newNote() {
        let n = ScratchNote()
        controller.notes.insert(n, at: 0)
        selected = n.id
    }

    /// Appends dictated text to the open note (the panel sets this as the sink).
    static func append(_ text: String, to controller: DictationController, noteID: UUID?) {
        if let id = noteID, let i = controller.notes.firstIndex(where: { $0.id == id }) {
            let body = controller.notes[i].body
            controller.notes[i].body = body + (body.isEmpty || body.hasSuffix("\n") ? "" : " ") + text
            controller.notes[i].updated = Date()
        } else {
            controller.notes.insert(ScratchNote(body: text), at: 0)
        }
    }
}
