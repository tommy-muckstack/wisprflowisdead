import Foundation

/// A key or mouse button that can be part of a Flow shortcut.
public enum ShortcutKey: Hashable, Codable, Sendable {
    case fn, control, option, command, shift
    case rightControl, rightOption, rightCommand, rightShift
    case capsLock, escape, space, enter, backspace, delete, tab
    case function(Int)          // F1...F20
    case character(String)      // letters, digits, punctuation, arrows by name
    case mouse(Int)             // 3 = middle, 4...10

    public var isModifier: Bool {
        switch self {
        case .fn, .control, .option, .command, .shift,
             .rightControl, .rightOption, .rightCommand, .rightShift: return true
        default: return false
        }
    }

    public var isMouseButton: Bool {
        if case .mouse(let n) = self { return (3...10).contains(n) }
        return false
    }

    /// Left and right versions of one modifier share a family.
    var modifierFamily: String? {
        switch self {
        case .control, .rightControl: return "control"
        case .option, .rightOption: return "option"
        case .command, .rightCommand: return "command"
        case .shift, .rightShift: return "shift"
        case .fn: return "fn"
        default: return nil
        }
    }

    public var symbol: String {
        switch self {
        case .fn: return "fn"
        case .control, .rightControl: return "⌃"
        case .option, .rightOption: return "⌥"
        case .command, .rightCommand: return "⌘"
        case .shift, .rightShift: return "⇧"
        case .capsLock: return "⇪"
        case .escape: return "esc"
        case .space: return "space"
        case .enter: return "↩"
        case .backspace: return "⌫"
        case .delete: return "⌦"
        case .tab: return "⇥"
        case .function(let n): return "F\(n)"
        case .character(let c): return c.uppercased()
        case .mouse(let n): return n == 3 ? "Middle Click" : "Mouse \(n)"
        }
    }

    /// Sort order used for display: modifiers first, in macOS order.
    var displayRank: Int {
        switch self {
        case .fn: return 0
        case .control, .rightControl: return 1
        case .option, .rightOption: return 2
        case .shift, .rightShift: return 3
        case .command, .rightCommand: return 4
        default: return 10
        }
    }
}

public struct Shortcut: Hashable, Codable, Sendable {
    public var keys: Set<ShortcutKey>
    public init(_ keys: Set<ShortcutKey>) { self.keys = keys }
    public init(_ keys: ShortcutKey...) { self.keys = Set(keys) }

    public var display: String {
        keys.sorted { ($0.displayRank, $0.symbol) < ($1.displayRank, $1.symbol) }
            .map(\.symbol).joined(separator: " ")
    }

    /// True when every key of `self` is also in `other` (and it is smaller).
    public func isStrictSubset(of other: Shortcut) -> Bool {
        keys.isStrictSubset(of: other.keys)
    }
}

public enum ShortcutAction: String, CaseIterable, Codable, Sendable, Identifiable {
    case pushToTalk, handsFree, commandMode, pasteLast, copyLast, cancel, pressEnter
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .pushToTalk: return "Push to talk"
        case .handsFree: return "Hands-free mode"
        case .commandMode: return "Command Mode"
        case .pasteLast: return "Paste last transcript"
        case .copyLast: return "Copy last transcript"
        case .cancel: return "Cancel"
        case .pressEnter: return "Press Enter"
        }
    }

    public var maxBindings: Int { self == .cancel ? 1 : 4 }
    /// Actions that must always keep at least one binding.
    public var requiresBinding: Bool {
        switch self {
        case .pushToTalk, .commandMode, .pasteLast, .copyLast, .cancel: return true
        case .handsFree, .pressEnter: return false
        }
    }
}

public enum ShortcutError: Error, Equatable, CustomStringConvertible {
    case notAllowed(String)
    case alreadyInUse
    case tooManyKeys
    case needsModifier
    case leftAndRight
    case tooManyBindings
    case lastBinding

    public var description: String {
        switch self {
        case .notAllowed(let k): return "This shortcut is not allowed: \(k)"
        case .alreadyInUse: return "This shortcut is already in use"
        case .tooManyKeys: return "Shortcut must contain 3 or fewer keys"
        case .needsModifier: return "Shortcut must include a modifier key or a valid mouse button"
        case .leftAndRight: return "Shortcut cannot contain both left and right version of the same key"
        case .tooManyBindings: return "This action already has the maximum number of shortcuts"
        case .lastBinding: return "This action needs at least one shortcut"
        }
    }
}

public struct ShortcutSet: Codable, Equatable, Sendable {
    public var bindings: [ShortcutAction: [Shortcut]]

    public init(bindings: [ShortcutAction: [Shortcut]]) { self.bindings = bindings }

    public static func defaults(hasFnKey: Bool = true) -> ShortcutSet {
        var b: [ShortcutAction: [Shortcut]] = [
            .pasteLast: [Shortcut(.command, .control, .character("v"))],
            .copyLast: [Shortcut(.command, .control, .character("c"))],
            .cancel: [Shortcut(.escape)],
            .pressEnter: [],
        ]
        if hasFnKey {
            b[.pushToTalk] = [Shortcut(.fn)]
            b[.handsFree] = [Shortcut(.fn, .space)]
            b[.commandMode] = [Shortcut(.fn, .control)]
        } else {
            b[.pushToTalk] = [Shortcut(.control, .option)]
            b[.handsFree] = [Shortcut(.control, .option, .space)]
            b[.commandMode] = [Shortcut(.command, .control, .option)]
        }
        return ShortcutSet(bindings: b)
    }

    public func shortcuts(for action: ShortcutAction) -> [Shortcut] { bindings[action] ?? [] }

    static let reserved: [Shortcut] = [
        Shortcut(.command, .backspace), Shortcut(.command, .delete),
        Shortcut(.command, .space), Shortcut(.command, .control, .character("f")),
        Shortcut(.command, .character("c")), Shortcut(.command, .character("v")),
        Shortcut(.command, .character("x")), Shortcut(.command, .character("q")),
    ]

    /// Validate `shortcut` for `action`, ignoring the binding being replaced.
    public func validate(_ shortcut: Shortcut, for action: ShortcutAction,
                         replacing old: Shortcut? = nil) -> ShortcutError? {
        let keys = shortcut.keys
        if keys.count > 3 { return .tooManyKeys }
        // Standalone exceptions.
        if keys == [.escape] { return action == .cancel ? nil : .notAllowed("esc") }
        if keys == [.capsLock] {
            return (action == .pushToTalk || action == .handsFree) ? nil : .notAllowed("⇪")
        }
        let families = keys.compactMap(\.modifierFamily)
        if Set(families).count != families.count { return .leftAndRight }
        if Self.reserved.contains(shortcut) { return .notAllowed(shortcut.display) }
        if !keys.contains(where: { $0.isModifier || $0.isMouseButton }) {
            if keys.count == 1, let only = keys.first { return .notAllowed(only.symbol) }
            return .needsModifier
        }
        for (other, list) in bindings {
            for existing in list where existing == shortcut {
                if other == action && existing == old { continue }
                return .alreadyInUse
            }
        }
        return nil
    }

    public mutating func add(_ shortcut: Shortcut, to action: ShortcutAction) throws {
        if let error = validate(shortcut, for: action) { throw error }
        var list = shortcuts(for: action)
        if list.count >= action.maxBindings { throw ShortcutError.tooManyBindings }
        list.append(shortcut)
        bindings[action] = list
    }

    public mutating func replace(_ old: Shortcut, with new: Shortcut, for action: ShortcutAction) throws {
        if let error = validate(new, for: action, replacing: old) { throw error }
        var list = shortcuts(for: action)
        guard let index = list.firstIndex(of: old) else { return try add(new, to: action) }
        list[index] = new
        bindings[action] = list
    }

    public mutating func remove(_ shortcut: Shortcut, from action: ShortcutAction) throws {
        var list = shortcuts(for: action)
        if action.requiresBinding && list.count <= 1 { throw ShortcutError.lastBinding }
        list.removeAll { $0 == shortcut }
        bindings[action] = list
    }

    /// The overlap warning Wispr shows: a hands-free binding contained in a
    /// push-to-talk binding.
    public var handsFreeOverlapsPushToTalk: Bool {
        shortcuts(for: .handsFree).contains { hf in
            shortcuts(for: .pushToTalk).contains { hf.isStrictSubset(of: $0) }
        }
    }
}
