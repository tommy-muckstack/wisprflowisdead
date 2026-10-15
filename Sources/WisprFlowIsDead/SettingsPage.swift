import AppKit
import FlowCore
import FlowVoice
import ServiceManagement
import SwiftUI

struct SettingsPage: View {
    @ObservedObject var controller: DictationController
    @State private var editingShortcuts = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle(title: "Settings")
            section("General") {
                row("Shortcuts", detail: "Push to talk: " + (controller.settings.shortcuts.shortcuts(for: .pushToTalk).first?.display ?? "none")) {
                    Button("Change") { editingShortcuts = true }.buttonStyle(PillButtonStyle(prominent: false))
                }
                row("Speech engine", detail: "Runs on this Mac. Nothing is uploaded.") {
                    Picker("", selection: $controller.settings.engine) {
                        ForEach(SpeechEngineChoice.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().frame(width: 260)
                    .onChange(of: controller.settings.engine) { _, _ in controller.loadModel() }
                }
                row("Microphone", detail: "Uses your system default input.") {
                    Button("Sound Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension")!)
                    }.buttonStyle(PillButtonStyle(prominent: false))
                }
            }
            section("System") {
                toggle("Launch at login", $controller.settings.launchAtLogin)
                    .onChange(of: controller.settings.launchAtLogin) { _, on in
                        try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    }
                toggle("Show app in Dock", $controller.settings.showInDock)
                toggle("Show Flow Bar at all times", $controller.settings.showFlowBarAlways)
                toggle("Sound effects", $controller.settings.soundEffects)
                row("Flow Bar position", detail: nil) {
                    Picker("", selection: $controller.settings.flowBarDock) {
                        ForEach(FlowBarDock.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }.labelsHidden().pickerStyle(.segmented).frame(width: 220)
                }
            }
            section("Experimental") {
                toggle("Command Mode", $controller.settings.commandModeEnabled)
                Text(CommandRunner.isAvailable
                     ? "Hold \(controller.settings.shortcuts.shortcuts(for: .commandMode).first?.display ?? "") and say what to do with the selected text."
                     : "Needs macOS 26 with Apple Intelligence turned on. Search commands work everywhere.")
                    .font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
            section("Data & Privacy") {
                row("Dictation history", detail: "Stored only on this Mac.") {
                    Picker("", selection: $controller.settings.retention) {
                        ForEach(RetentionPolicy.allCases, id: \.self) { Text($0.title).tag($0) }
                    }.labelsHidden().frame(width: 200)
                }
                Button("Delete all history") { controller.clearHistory() }
                    .buttonStyle(PillButtonStyle(prominent: false))
            }
            section("Permissions") {
                row("Microphone", detail: VoiceEngine.microphoneAuthorized ? "Allowed" : "Not allowed") {
                    Button("Open") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                    }.buttonStyle(PillButtonStyle(prominent: false))
                }
                row("Accessibility", detail: VoiceEngine.accessibilityTrusted ? "Allowed" : "Needed to type into other apps") {
                    Button("Open") { VoiceEngine.promptAccessibility() }.buttonStyle(PillButtonStyle(prominent: false))
                }
            }
        }
        .sheet(isPresented: $editingShortcuts) {
            ShortcutEditor(controller: controller) { editingShortcuts = false }
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(Theme.font(11, .semibold)).foregroundStyle(Theme.muted)
            Card { content() }
        }
    }

    private func row<C: View>(_ title: String, detail: String?, @ViewBuilder _ trailing: () -> C) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.font(14, .medium))
                if let detail { Text(detail).font(Theme.font(12)).foregroundStyle(Theme.muted) }
            }
            Spacer()
            trailing()
        }
    }

    private func toggle(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) { Text(title).font(Theme.font(14, .medium)) }
            .toggleStyle(.switch).tint(Theme.ink)
    }
}

/// Shortcuts dialog: click a binding (or +) and press keys; saves on release.
struct ShortcutEditor: View {
    @ObservedObject var controller: DictationController
    var done: () -> Void
    @State private var recording: (ShortcutAction, Shortcut?)?
    @State private var pending: Set<ShortcutKey> = []
    @State private var message: (String, Bool)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shortcuts").font(Theme.font(20, .bold))
            if let hint = handsFreeHint {
                Text(hint).font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
            ForEach(ShortcutAction.allCases) { action in
                HStack(alignment: .center) {
                    Text(action.title).font(Theme.font(14, .medium)).frame(width: 170, alignment: .leading)
                    let list = controller.settings.shortcuts.shortcuts(for: action)
                    ForEach(list, id: \.self) { s in
                        HStack(spacing: 4) {
                            Button { begin(action, s) } label: {
                                if isRecording(action, s) { Text(pendingText).font(Theme.font(12)) }
                                else { ShortcutLabel(shortcut: s) }
                            }.buttonStyle(.plain)
                            if !(action.requiresBinding && list.count <= 1) {
                                Button { remove(s, action) } label: { Image(systemName: "trash").font(.system(size: 10)) }
                                    .buttonStyle(.plain).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    if list.count < action.maxBindings {
                        Button { begin(action, nil) } label: {
                            if isRecording(action, nil) { Text(pendingText).font(Theme.font(12)) }
                            else { Text(list.isEmpty ? "Click to add a shortcut" : "+").font(Theme.font(12)) }
                        }
                        .buttonStyle(.plain).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }
            }
            if controller.settings.shortcuts.handsFreeOverlapsPushToTalk {
                Text("Your hands-free shortcut is part of a push-to-talk shortcut. That may cause conflicts.")
                    .font(Theme.font(12)).foregroundStyle(Theme.errorInk)
            }
            if let m = message {
                Text(m.0).font(Theme.font(12, .medium)).foregroundStyle(m.1 ? Theme.successInk : Theme.errorInk)
            }
            HStack {
                Button("Reset to default") {
                    controller.settings.shortcuts = .defaults()
                    message = ("Shortcuts reset", true)
                }.buttonStyle(PillButtonStyle(prominent: false))
                Spacer()
                Button("Done") { stopRecording(); done() }.buttonStyle(PillButtonStyle())
            }
        }
        .padding(24)
        .frame(width: 620)
        .background(Theme.cream)
        .foregroundStyle(Theme.ink)
        .onDisappear { stopRecording() }
    }

    private var handsFreeHint: String? {
        guard let ptt = controller.settings.shortcuts.shortcuts(for: .pushToTalk).first else { return nil }
        return "Tip: double-tap \(ptt.display) to start hands-free."
    }

    private var pendingText: String {
        pending.isEmpty ? "Press keys…" : Shortcut(pending).display
    }

    private func isRecording(_ action: ShortcutAction, _ s: Shortcut?) -> Bool {
        guard let r = recording else { return false }
        return r.0 == action && r.1 == s
    }

    private var monitor: HotkeyMonitor? { (NSApp.delegate as? AppDelegate)?.hotkeys }

    private func begin(_ action: ShortcutAction, _ existing: Shortcut?) {
        recording = (action, existing)
        pending = []
        message = nil
        var peak: Set<ShortcutKey> = []
        monitor?.recorder = { held, released in
            Task { @MainActor in
                // Escape alone leaves the binding unchanged (except on Cancel).
                if held == [.escape] && action != .cancel { stopRecording(); return }
                peak.formUnion(held)
                pending = peak
                let isMouse = peak.contains { $0.isMouseButton }
                if released || isMouse { save(Shortcut(peak), for: action, replacing: existing) }
            }
        }
    }

    private func save(_ s: Shortcut, for action: ShortcutAction, replacing old: Shortcut?) {
        var set = controller.settings.shortcuts
        do {
            if let old { try set.replace(old, with: s, for: action) } else { try set.add(s, to: action) }
            controller.settings.shortcuts = set
            message = ("Shortcut saved", true)
        } catch let e as ShortcutError {
            message = (e.description, false)
        } catch {}
        stopRecording()
    }

    private func remove(_ s: Shortcut, _ action: ShortcutAction) {
        var set = controller.settings.shortcuts
        do { try set.remove(s, from: action); controller.settings.shortcuts = set }
        catch let e as ShortcutError { message = (e.description, false) } catch {}
    }

    private func stopRecording() {
        monitor?.recorder = nil
        recording = nil
        pending = []
    }
}
