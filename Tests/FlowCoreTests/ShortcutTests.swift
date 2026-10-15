import XCTest
@testable import FlowCore

final class ShortcutTests: XCTestCase {
    func testDefaultsWithFnKey() {
        let s = ShortcutSet.defaults()
        XCTAssertEqual(s.shortcuts(for: .pushToTalk), [Shortcut(.fn)])
        XCTAssertEqual(s.shortcuts(for: .handsFree), [Shortcut(.fn, .space)])
        XCTAssertEqual(s.shortcuts(for: .commandMode), [Shortcut(.fn, .control)])
        XCTAssertEqual(s.shortcuts(for: .cancel), [Shortcut(.escape)])
    }

    func testDefaultsWithoutFnKey() {
        let s = ShortcutSet.defaults(hasFnKey: false)
        XCTAssertEqual(s.shortcuts(for: .pushToTalk), [Shortcut(.control, .option)])
        XCTAssertEqual(s.shortcuts(for: .commandMode), [Shortcut(.command, .control, .option)])
    }

    func testValidationRules() {
        let s = ShortcutSet.defaults()
        XCTAssertEqual(s.validate(Shortcut(.character("a")), for: .pushToTalk), .notAllowed("A"))
        XCTAssertEqual(s.validate(Shortcut(.control, .option, .shift, .character("a")), for: .pushToTalk), .tooManyKeys)
        XCTAssertEqual(s.validate(Shortcut(.control, .rightControl), for: .pushToTalk), .leftAndRight)
        XCTAssertEqual(s.validate(Shortcut(.command, .space), for: .pushToTalk), .notAllowed("⌘ space"))
        XCTAssertEqual(s.validate(Shortcut(.fn), for: .commandMode), .alreadyInUse)
        XCTAssertEqual(s.validate(Shortcut(.character("a"), .space), for: .pushToTalk), .needsModifier)
        XCTAssertNil(s.validate(Shortcut(.mouse(4)), for: .pushToTalk))
        XCTAssertNil(s.validate(Shortcut(.capsLock), for: .handsFree))
        XCTAssertEqual(s.validate(Shortcut(.capsLock), for: .commandMode), .notAllowed("⇪"))
        XCTAssertEqual(s.validate(Shortcut(.escape), for: .pushToTalk), .notAllowed("esc"))
    }

    func testBindingLimitsAndRemoval() throws {
        var s = ShortcutSet.defaults()
        try s.add(Shortcut(.control, .option), to: .pushToTalk)
        try s.add(Shortcut(.mouse(4)), to: .pushToTalk)
        try s.add(Shortcut(.mouse(5)), to: .pushToTalk)
        XCTAssertThrowsError(try s.add(Shortcut(.mouse(6)), to: .pushToTalk))
        XCTAssertThrowsError(try s.add(Shortcut(.control, .escape), to: .cancel))
        try s.remove(Shortcut(.fn, .space), from: .handsFree)
        XCTAssertTrue(s.shortcuts(for: .handsFree).isEmpty)
        XCTAssertThrowsError(try s.remove(Shortcut(.escape), from: .cancel)) { error in
            XCTAssertEqual(error as? ShortcutError, .lastBinding)
        }
    }

    func testReplaceKeepsOwnBinding() throws {
        var s = ShortcutSet.defaults()
        try s.replace(Shortcut(.fn), with: Shortcut(.rightOption), for: .pushToTalk)
        XCTAssertEqual(s.shortcuts(for: .pushToTalk), [Shortcut(.rightOption)])
    }

    func testOverlapWarning() throws {
        var s = ShortcutSet.defaults()
        XCTAssertFalse(s.handsFreeOverlapsPushToTalk)
        try s.replace(Shortcut(.fn, .space), with: Shortcut(.control), for: .handsFree)
        try s.replace(Shortcut(.fn), with: Shortcut(.control, .option), for: .pushToTalk)
        XCTAssertTrue(s.handsFreeOverlapsPushToTalk)
    }

    func testCodableRoundTrip() throws {
        let s = ShortcutSet.defaults()
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(ShortcutSet.self, from: data), s)
    }
}

final class HotkeyStateMachineTests: XCTestCase {
    func testHoldAndRelease() {
        var m = HotkeyStateMachine()
        XCTAssertEqual(m.pressHold(at: 0), [.startRecording(mode: .dictation)])
        XCTAssertEqual(m.releaseHold(at: 2), [.stopAndInsert])
        XCTAssertEqual(m.pressHold(at: 2.1), [.ignoredBusy])
        m.finishedProcessing()
        XCTAssertEqual(m.state, .idle)
    }

    func testShortTapCancelsWithTip() {
        var m = HotkeyStateMachine()
        _ = m.pressHold(at: 0)
        XCTAssertEqual(m.releaseHold(at: 0.2), [])
        XCTAssertEqual(m.tick(at: 0.5), [])
        XCTAssertEqual(m.tick(at: 0.8), [.cancel, .showHoldTip])
        XCTAssertEqual(m.state, .idle)
    }

    func testDoubleTapLocksHandsFreeThenStops() {
        var m = HotkeyStateMachine()
        _ = m.pressHold(at: 0)
        _ = m.releaseHold(at: 0.1)
        XCTAssertEqual(m.pressHold(at: 0.3), [.lockHandsFree])
        XCTAssertEqual(m.pressHold(at: 5), [.stopAndInsert])
    }

    func testThirdQuickPressCancels() {
        var m = HotkeyStateMachine()
        _ = m.pressHold(at: 0)
        _ = m.releaseHold(at: 0.1)
        _ = m.pressHold(at: 0.3)
        XCTAssertEqual(m.pressHold(at: 0.5), [.cancel])
        XCTAssertEqual(m.state, .idle)
    }

    func testHandsFreeShortcutAndCancel() {
        var m = HotkeyStateMachine()
        XCTAssertEqual(m.pressHandsFree(at: 0), [.startRecording(mode: .dictation)])
        XCTAssertEqual(m.pressCancel(), [.cancel])
        XCTAssertEqual(m.pressCancel(), [])
    }

    func testBarClickQuickSecondClickCancels() {
        var m = HotkeyStateMachine()
        _ = m.clickBar(at: 0)
        XCTAssertEqual(m.clickBar(at: 0.3), [.cancel])
        _ = m.clickBar(at: 1)
        XCTAssertEqual(m.clickBar(at: 4), [.stopAndInsert])
    }

    func testHoldThenHandsFreeKeyLocks() {
        var m = HotkeyStateMachine()
        _ = m.pressHold(at: 0)
        XCTAssertEqual(m.pressHandsFree(at: 0.2), [.lockHandsFree])
        XCTAssertEqual(m.releaseHold(at: 0.4), [])
        XCTAssertEqual(m.pressHandsFree(at: 3), [.stopAndInsert])
    }

    func testCommandModeHold() {
        var m = HotkeyStateMachine()
        XCTAssertEqual(m.pressHold(at: 0, mode: .command), [.startRecording(mode: .command)])
        XCTAssertEqual(m.releaseHold(at: 1), [.stopAndInsert])
    }
}
