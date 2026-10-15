import Foundation

/// What the dictation controller should do in response to hotkey input.
public enum DictationCommand: Equatable, Sendable {
    case startRecording(mode: RecordingMode)
    case lockHandsFree           // a held recording became hands-free
    case stopAndInsert
    case cancel
    case showHoldTip             // tap too short, no second press arrived
    case ignoredBusy             // previous transcript still processing
}

public enum RecordingMode: String, Equatable, Sendable { case dictation, command }

/// Wispr Flow's press/hold/double-tap rules, independent of how key events
/// arrive. Feed it press/release events with timestamps (seconds).
///
/// - Hold PTT >= 0.5 s then release: insert.
/// - Tap PTT < 0.5 s: wait up to 0.5 s for a second press; otherwise cancel
///   and show the hold tip.
/// - Second press inside 0.5 s: lock hands-free. A third quick press cancels;
///   a later press stops and inserts.
/// - Hands-free shortcut: toggles start / stop.
/// - Cancel shortcut: cancels any active recording.
public struct HotkeyStateMachine: Sendable {
    public enum State: Equatable, Sendable {
        case idle
        case holding(since: Double, mode: RecordingMode)
        case awaitingSecondPress(releasedAt: Double, mode: RecordingMode)
        case handsFree(since: Double, mode: RecordingMode)
        case processing
    }

    public static let tapThreshold = 0.5
    public private(set) var state: State = .idle

    public init() {}

    public mutating func pressHold(at t: Double, mode: RecordingMode = .dictation) -> [DictationCommand] {
        switch state {
        case .idle:
            state = .holding(since: t, mode: mode)
            return [.startRecording(mode: mode)]
        case .awaitingSecondPress(let releasedAt, let m) where t - releasedAt <= Self.tapThreshold:
            state = .handsFree(since: t, mode: m)
            return [.lockHandsFree]
        case .awaitingSecondPress:
            // Window passed without a tick; treat as a fresh start.
            state = .holding(since: t, mode: mode)
            return [.cancel, .startRecording(mode: mode)]
        case .handsFree(let since, _):
            // A third press right after locking cancels instead of inserting.
            if t - since <= Self.tapThreshold { state = .idle; return [.cancel] }
            state = .processing
            return [.stopAndInsert]
        case .holding:
            return []
        case .processing:
            return [.ignoredBusy]
        }
    }

    public mutating func releaseHold(at t: Double) -> [DictationCommand] {
        guard case .holding(let since, let mode) = state else { return [] }
        if t - since < Self.tapThreshold {
            state = .awaitingSecondPress(releasedAt: t, mode: mode)
            return []
        }
        state = .processing
        return [.stopAndInsert]
    }

    /// Call periodically (or from a timer scheduled at release + threshold).
    public mutating func tick(at t: Double) -> [DictationCommand] {
        if case .awaitingSecondPress(let releasedAt, _) = state, t - releasedAt > Self.tapThreshold {
            state = .idle
            return [.cancel, .showHoldTip]
        }
        return []
    }

    public mutating func pressHandsFree(at t: Double) -> [DictationCommand] {
        switch state {
        case .idle:
            state = .handsFree(since: t, mode: .dictation)
            return [.startRecording(mode: .dictation)]
        case .handsFree:
            state = .processing
            return [.stopAndInsert]
        case .holding(_, let mode):
            // Fn held, then Space: the hold becomes hands-free.
            state = .handsFree(since: -Double.infinity, mode: mode)
            return [.lockHandsFree]
        case .processing:
            return [.ignoredBusy]
        case .awaitingSecondPress:
            return []
        }
    }

    /// Clicking the Flow Bar behaves like the hands-free shortcut, except a
    /// second click inside 0.5 s of starting cancels.
    public mutating func clickBar(at t: Double) -> [DictationCommand] {
        if case .handsFree(let since, _) = state, t - since <= Self.tapThreshold {
            state = .idle
            return [.cancel]
        }
        return pressHandsFree(at: t)
    }

    public mutating func pressCancel() -> [DictationCommand] {
        switch state {
        case .idle: return []
        default:
            state = .idle
            return [.cancel]
        }
    }

    /// The controller calls this when insertion (or a cancel) has finished.
    public mutating func finishedProcessing() {
        if state == .processing { state = .idle }
    }

    public var isRecording: Bool {
        switch state {
        case .holding, .handsFree, .awaitingSecondPress: return true
        default: return false
        }
    }
}
