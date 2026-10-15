import AppKit
import CoreGraphics
import FlowCore
import FlowVoice

/// Watches the keyboard and extra mouse buttons system-wide with a
/// listen-only event tap (needs Accessibility / Input Monitoring) and turns
/// the set of held keys into Flow actions.
@MainActor
final class HotkeyMonitor {
    private weak var controller: DictationController?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var held: Set<ShortcutKey> = []
    private var pttActive = false
    private var commandActive = false
    /// Set while the shortcut editor records, so keys don't trigger actions.
    var recorder: ((Set<ShortcutKey>, _ released: Bool) -> Void)?

    init(controller: DictationController) { self.controller = controller }

    var isRunning: Bool { tap != nil }

    func start() {
        guard tap == nil else { return }
        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.otherMouseUp.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: mask,
                                          callback: { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let button = Int(event.getIntegerValueField(.mouseEventButtonNumber))
            let flags = event.flags
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            let swallow = MainActor.assumeIsolated {
                monitor.handle(type: type, keyCode: keyCode, button: button, flags: flags, isRepeat: isRepeat)
            }
            return swallow ? nil : Unmanaged.passUnretained(event)
        }, userInfo: refcon) else { return }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil; source = nil; held = []
    }

    /// Returns true when the event should not reach other apps: Esc while
    /// dictating, a lone fn used as push to talk (no emoji picker), the
    /// non-modifier key that completes a Flow shortcut, and bound mouse buttons.
    private func handle(type: CGEventType, keyCode: Int, button: Int, flags: CGEventFlags, isRepeat: Bool) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        if isRepeat { return swallowedKeys.contains(keyCode) }
        var released = false
        switch type {
        case .flagsChanged:
            guard let key = Self.modifierKey(keyCode) else { return false }
            let down: Bool
            switch key {
            case .fn: down = flags.contains(.maskSecondaryFn)
            case .capsLock: down = flags.contains(.maskAlphaShift)
            default: down = !held.contains(key)
            }
            if down { held.insert(key) } else { held.remove(key); released = true }
        case .keyDown:
            guard let key = Self.key(keyCode) else { return false }
            held.insert(key)
        case .keyUp:
            guard let key = Self.key(keyCode) else { return false }
            held.remove(key); released = true
            if recorder == nil, swallowedKeys.remove(keyCode) != nil { evaluate(released: true); return true }
        case .otherMouseDown:
            held.insert(.mouse(button + 1))
        case .otherMouseUp:
            held.remove(.mouse(button + 1)); released = true
        default:
            return false
        }
        // Fn is reported in flags of every arrow/F-key event too; keep it
        // in sync with the real flag.
        if !flags.contains(.maskSecondaryFn) { held.remove(.fn) }

        if let recorder { recorder(held, released); return type != .flagsChanged }
        let wasRecording = controller?.isRecording ?? false
        let fired = evaluate(released: released)
        switch type {
        case .keyDown:
            if Self.key(keyCode) == .escape, wasRecording { swallowedKeys.insert(keyCode); return true }
            if fired { swallowedKeys.insert(keyCode); return true }
            return false
        case .otherMouseDown, .otherMouseUp:
            return isBound(.mouse(button + 1))
        case .flagsChanged:
            // A lone fn bound to push to talk: keep macOS from showing the
            // emoji / input-source picker on release.
            return keyCode == 63 && (fnAlonePushToTalk || (wasRecording && !released))
        default:
            return false
        }
    }

    private var swallowedKeys: Set<Int> = []

    private var fnAlonePushToTalk: Bool {
        controller?.settings.shortcuts.shortcuts(for: .pushToTalk).contains { $0.keys == [.fn] } ?? false
    }

    private func isBound(_ key: ShortcutKey) -> Bool {
        guard let c = controller else { return false }
        return c.settings.shortcuts.bindings.values.contains { $0.contains { $0.keys.contains(key) } }
    }

    private func matches(_ action: ShortcutAction) -> Bool {
        guard let controller else { return false }
        return controller.settings.shortcuts.shortcuts(for: action).contains { $0.keys == held }
    }

    private func contains(_ action: ShortcutAction) -> Bool {
        guard let controller else { return false }
        return controller.settings.shortcuts.shortcuts(for: action).contains { $0.keys.isSubset(of: held) }
    }

    /// Returns true when a shortcut fired.
    @discardableResult
    private func evaluate(released: Bool) -> Bool {
        guard let controller, controller.settings.onboardingComplete || controller.practiceSink != nil else { return false }
        if pttActive && !contains(.pushToTalk) {
            pttActive = false
            controller.pushToTalkUp()
        }
        if commandActive && !contains(.commandMode) {
            commandActive = false
            controller.pushToTalkUp()
        }
        guard !released else { return false }
        if matches(.cancel), controller.isRecording { controller.cancelPressed(); return true }
        if matches(.handsFree) { controller.handsFreePressed(); return true }
        if matches(.commandMode), !commandActive {
            // Fn+Ctrl starts with Fn, which already began a dictation.
            if pttActive { pttActive = false; controller.cancelPressed() }
            commandActive = true
            controller.pushToTalkDown(command: true)
            return true
        }
        if matches(.pushToTalk), !commandActive {
            pttActive = true
            controller.pushToTalkDown()
            return true
        }
        if matches(.pasteLast) { controller.pasteLast(); return true }
        if matches(.copyLast) { controller.copyLast(); return true }
        if matches(.openScratchpad) { controller.toggleScratchpad?(); return true }
        if matches(.runTransform) { controller.runTransform(nil); return true }
        if matches(.pressEnter) { FlowVoiceBridge.pressEnter(); return true }
        return false
    }

    // MARK: Key codes (ANSI layout)

    static func modifierKey(_ code: Int) -> ShortcutKey? {
        switch code {
        case 59: return .control
        case 62: return .rightControl
        case 58: return .option
        case 61: return .rightOption
        case 55: return .command
        case 54: return .rightCommand
        case 56: return .shift
        case 60: return .rightShift
        case 63, 179: return .fn
        case 57: return .capsLock
        default: return nil
        }
    }

    static let letters: [Int: String] = [
        0: "a", 11: "b", 8: "c", 2: "d", 14: "e", 3: "f", 5: "g", 4: "h", 34: "i", 38: "j",
        40: "k", 37: "l", 46: "m", 45: "n", 31: "o", 35: "p", 12: "q", 15: "r", 1: "s", 17: "t",
        32: "u", 9: "v", 13: "w", 7: "x", 16: "y", 6: "z",
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9",
        27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'", 43: ",", 47: ".", 44: "/", 42: "\\", 50: "`",
        123: "←", 124: "→", 125: "↓", 126: "↑",
    ]
    static let functionKeys: [Int: Int] = [
        122: 1, 120: 2, 99: 3, 118: 4, 96: 5, 97: 6, 98: 7, 100: 8, 101: 9, 109: 10,
        103: 11, 111: 12, 105: 13, 107: 14, 113: 15, 106: 16, 64: 17, 79: 18, 80: 19, 90: 20,
    ]

    static func key(_ code: Int) -> ShortcutKey? {
        switch code {
        case 49: return .space
        case 53: return .escape
        case 36, 76: return .enter
        case 51: return .backspace
        case 117: return .delete
        case 48: return .tab
        default:
            if let f = functionKeys[code] { return .function(f) }
            if let c = letters[code] { return .character(c) }
            return nil
        }
    }
}

@MainActor
enum FlowVoiceBridge {
    static func pressEnter() { VoiceEngine.pressEnter() }
}
