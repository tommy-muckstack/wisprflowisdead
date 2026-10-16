import AppKit
import FlowCore
import FlowVoice
import SwiftUI

/// Welcome → permissions → mic test → shortcut → practice → style → done.
struct OnboardingView: View {
    @ObservedObject var controller: DictationController
    var finish: () -> Void
    @State private var step = 0
    @State private var micOK = VoiceEngine.microphoneAuthorized
    @State private var axOK = VoiceEngine.accessibilityTrusted
    @State private var hasFnKey = true
    @State private var practiceText = ""
    @State private var testing = false
    @State private var level: CGFloat = 0
    private let poll = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private let meter = Timer.publish(every: 1.0 / 20, on: .main, in: .common).autoconnect()

    private let steps = ["Welcome", "Permissions", "Microphone", "Shortcut", "Practice", "Style"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule().fill(i <= step ? Theme.ink : Theme.creamDark).frame(height: 4)
                }
            }
            .padding(.bottom, 28)
            Group {
                switch step {
                case 0: welcome
                case 1: permissions
                case 2: micTest
                case 3: shortcut
                case 4: practice
                default: style
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack {
                if step > 0 { Button("Back") { step -= 1 }.buttonStyle(PillButtonStyle(prominent: false)) }
                Spacer()
                Button(step == steps.count - 1 ? "Start flowing" : "Continue") { next() }
                    .buttonStyle(PillButtonStyle())
                    .disabled(step == 1 && !micOK)
            }
        }
        .padding(40)
        .frame(width: 640, height: 520)
        .background(Theme.cream)
        .foregroundStyle(Theme.ink)
        .font(Theme.font(14))
        .onReceive(poll) { _ in
            micOK = VoiceEngine.microphoneAuthorized
            axOK = VoiceEngine.accessibilityTrusted
        }
        .onReceive(meter) { _ in
            if testing { level = CGFloat(min(1, VoiceEngine.shared.level() * 8)) }
        }
        .onDisappear { stopMicTest(); controller.practiceSink = nil }
    }

    private func next() {
        if step == 2 { stopMicTest() }
        if step == 3 { controller.settings.shortcuts = .defaults(hasFnKey: hasFnKey) }
        if step == 4 { controller.practiceSink = nil }
        if step == steps.count - 1 {
            controller.settings.onboardingComplete = true
            finish()
            return
        }
        step += 1
        if step == 4 { controller.practiceSink = { text in practiceText += (practiceText.isEmpty ? "" : " ") + text } }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppMark().frame(width: 56, height: 56)
            Text("Talk. We'll type.").font(Theme.display(36))
            Text("Hold a key, say what you mean, and clean, punctuated text lands wherever your cursor is. Free, open source, and everything runs on this Mac.")
                .font(Theme.font(16)).foregroundStyle(Theme.muted)
            if let p = controller.modelProgress {
                Text("Downloading the speech model in the background…").font(Theme.font(12)).foregroundStyle(Theme.muted)
                ProgressView(value: p).tint(Theme.ink)
            }
        }
    }

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Two permissions").font(Theme.display(28))
            permissionRow(title: "Microphone", detail: "So we can hear you. Only while you hold the key.", ok: micOK) {
                Task { micOK = await VoiceEngine.requestMicrophone() }
            }
            permissionRow(title: "Accessibility", detail: "So we can type into other apps. Without it, text goes to your clipboard.", ok: axOK) {
                VoiceEngine.promptAccessibility()
            }
        }
    }

    private func permissionRow(title: String, detail: String, ok: Bool, grant: @escaping () -> Void) -> some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(Theme.font(16, .semibold))
                    Text(detail).font(Theme.font(13)).foregroundStyle(Theme.muted)
                }
                Spacer()
                if ok {
                    Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.successInk)
                } else {
                    Button("Allow", action: grant).buttonStyle(PillButtonStyle())
                }
            }
        }
    }

    private var micTest: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test your microphone").font(Theme.display(28))
            Text("Say something. The bars should move.").foregroundStyle(Theme.muted)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<24, id: \.self) { i in
                    let on = CGFloat(i) / 24 < level
                    RoundedRectangle(cornerRadius: 2)
                        .fill(on ? Theme.forest : Theme.creamDark)
                        .frame(width: 10, height: 10 + CGFloat(i) * 2)
                }
            }
            .animation(.easeOut(duration: 0.1), value: level)
            Button(testing ? "Stop" : "Start test") { testing ? stopMicTest() : startMicTest() }
                .buttonStyle(PillButtonStyle(prominent: !testing))
            Button("Change microphone") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension")!)
            }.buttonStyle(PillButtonStyle(prominent: false))
        }
    }

    private func startMicTest() {
        Task {
            do { try await VoiceEngine.shared.start(); testing = true } catch { testing = false }
        }
    }

    private func stopMicTest() {
        guard testing else { return }
        VoiceEngine.shared.cancel()
        testing = false
        level = 0
    }

    private var shortcut: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your dictation key").font(Theme.display(28))
            Toggle("My keyboard has an fn (🌐) key", isOn: $hasFnKey).toggleStyle(.switch).tint(Theme.ink)
            let set = ShortcutSet.defaults(hasFnKey: hasFnKey)
            Card {
                ForEach([ShortcutAction.pushToTalk, .handsFree, .commandMode], id: \.self) { a in
                    HStack {
                        Text(a.title)
                        Spacer()
                        if let s = set.shortcuts(for: a).first { ShortcutLabel(shortcut: s) }
                    }
                }
            }
            Text("You can change these any time in Settings.").font(Theme.font(12)).foregroundStyle(Theme.muted)
        }
    }

    private var practice: some View {
        let key = controller.settings.shortcuts.shortcuts(for: .pushToTalk).first?.display ?? "fn"
        return VStack(alignment: .leading, spacing: 16) {
            Text("Give it a try").font(Theme.display(28))
            Text("Hold \(key) and say: “Let's grab lunch on Tuesday, no wait, Wednesday.” Then let go.")
                .foregroundStyle(Theme.muted)
            Text(practiceText.isEmpty ? "Your words show up here." : practiceText)
                .font(Theme.font(16))
                .foregroundStyle(practiceText.isEmpty ? Theme.muted : Theme.ink)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
            if controller.modelProgress != nil {
                Text("The speech model is still downloading. It only happens once.")
                    .font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
        }
    }

    private var style: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How do you write?").font(Theme.display(28))
            ForEach(AppCategory.allCases) { c in
                HStack {
                    Text(c.title).frame(width: 150, alignment: .leading)
                    Picker("", selection: Binding(
                        get: { controller.settings.styles[c] ?? .formal },
                        set: { controller.settings.styles[c] = $0 })) {
                        ForEach(WritingStyle.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented).labelsHidden()
                }
            }
        }
    }
}
