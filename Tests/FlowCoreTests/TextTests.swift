import XCTest
@testable import FlowCore

final class TextTests: XCTestCase {
    func testCategoryClassification() {
        XCTAssertEqual(AppCategory.classify(bundleID: "com.tinyspeck.slackmacgap"), .work)
        XCTAssertEqual(AppCategory.classify(bundleID: "com.apple.MobileSMS"), .personal)
        XCTAssertEqual(AppCategory.classify(bundleID: "com.apple.mail"), .email)
        XCTAssertEqual(AppCategory.classify(bundleID: "com.google.Chrome", url: "https://mail.google.com/mail/u/0"), .email)
        XCTAssertEqual(AppCategory.classify(bundleID: "com.apple.TextEdit"), .other)
    }

    func testStyles() {
        let text = "Are we still on for tonight. I think so."
        XCTAssertEqual(WritingStyler.apply(.formal, to: text, category: .personal), text)
        XCTAssertEqual(WritingStyler.apply(.casual, to: text, category: .personal),
                       "Are we still on for tonight. I think so")
        XCTAssertEqual(WritingStyler.apply(.casual, to: text, category: .email), text)
        XCTAssertEqual(WritingStyler.apply(.veryCasual, to: "Sounds good. NASA called. I agree.", category: .other),
                       "sounds good. NASA called. I agree")
        XCTAssertEqual(WritingStyler.apply(.excited, to: "See you there.", category: .personal), "See you there!")
        XCTAssertEqual(WritingStyler.apply(.excited, to: "Ready?", category: .personal), "Ready?")
    }

    func testCasualKeepsListPunctuation() {
        let list = "Groceries:\n1. Milk\n2. Eggs."
        XCTAssertEqual(WritingStyler.apply(.casual, to: list, category: .work), list)
    }

    func testScratchThat() {
        XCTAssertEqual(Backtrack.apply("Let's meet at noon. Actually let's do lunch scratch that. See you at five."),
                       "Let's meet at noon. See you at five.")
        XCTAssertEqual(Backtrack.apply("buy some milk scratch that buy eggs"), "Buy eggs")
    }

    func testNoWaitCorrection() {
        XCTAssertEqual(Backtrack.apply("Let's meet on Tuesday, no wait, Wednesday."), "Let's meet on Wednesday.")
        XCTAssertEqual(Backtrack.apply("Send it to Sam I mean Alex"), "Send it to Alex")
    }

    func testActuallyAloneIsKept() {
        XCTAssertEqual(Backtrack.apply("I actually liked it."), "I actually liked it.")
    }

    func testNumberedList() {
        XCTAssertEqual(ListFormatter.apply("My goals are first ship the app, second write docs, and third launch."),
                       "My goals are:\n1. Ship the app\n2. Write docs\n3. Launch.")
        XCTAssertEqual(ListFormatter.apply("This is the first time."), "This is the first time.")
    }

    func testSnippets() {
        let link = Snippet(cue: "my calendar link", expansion: "https://yourappisdead.com/calendlyisdead/tommy")
        let (out, fired) = SnippetExpander.expand("Grab a time here my calendar link.", snippets: [link])
        XCTAssertEqual(out, "Grab a time here https://yourappisdead.com/calendlyisdead/tommy")
        XCTAssertEqual(fired, [link.id])
    }

    func testDictionarySoundsLike() {
        let e = DictionaryEntry(term: "MuckStack", soundsLike: ["muck stack"])
        let (out, used) = PersonalDictionary.apply("I work at muck stack.", entries: [e])
        XCTAssertEqual(out, "I work at MuckStack.")
        XCTAssertEqual(used, [e.id])
    }

    func testLearnCorrection() {
        let learned = PersonalDictionary.learnCorrection(original: "ping Vignear today", edited: "ping Vignir today", existing: [])
        XCTAssertEqual(learned?.term, "Vignir")
        XCTAssertEqual(learned?.soundsLike, ["Vignear"])
        XCTAssertNil(PersonalDictionary.learnCorrection(original: "dont go", edited: "don't go", existing: []))
    }

    func testRanking() {
        let a = DictionaryEntry(term: "Alpha", uses: 1)
        let b = DictionaryEntry(term: "Beta", uses: 5)
        let c = DictionaryEntry(term: "Gamma", starred: true)
        XCTAssertEqual(PersonalDictionary.ranked([a, b, c]).map(\.term), ["Gamma", "Beta", "Alpha"])
    }

    func testPipelineEndToEnd() {
        var settings = FlowSettings()
        settings.styles[.work] = .casual
        let p = DictationPipeline(settings: settings, bundleID: "com.tinyspeck.slackmacgap",
                                  snippets: [], dictionary: [])
        let r = p.process("um so let's ship it on Tuesday, no wait, Thursday.")
        XCTAssertFalse(r.text.lowercased().contains("um "))
        XCTAssertTrue(r.text.contains("Thursday"))
        XCTAssertFalse(r.text.contains("Tuesday"))
        XCTAssertFalse(r.text.hasSuffix("."))
    }

    func testPipelineNoneIsVerbatim() {
        var settings = FlowSettings()
        settings.cleanupLevel = .none
        let p = DictationPipeline(settings: settings, bundleID: nil, snippets: [], dictionary: [])
        XCTAssertEqual(p.process("um hello there").text, "um hello there")
    }
}

final class HistoryTests: XCTestCase {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }

    func testSections() {
        let now = ISO8601DateFormatter().date(from: "2026-10-14T18:00:00Z")!
        let items = [
            Transcript(date: now.addingTimeInterval(-60), raw: "a", polished: "a", durationSeconds: 1),
            Transcript(date: now.addingTimeInterval(-86_400), raw: "b", polished: "b", durationSeconds: 1),
            Transcript(date: now.addingTimeInterval(-3 * 86_400), raw: "c", polished: "c", durationSeconds: 1),
        ]
        let s = HistoryGrouping.sections(items, now: now, calendar: calendar)
        XCTAssertEqual(s.map(\.title), ["Today", "Yesterday", "Sunday, Oct 11"])
    }

    func testRetention() {
        let now = Date()
        let old = Transcript(date: now.addingTimeInterval(-20 * 86_400), raw: "x", polished: "x",
                             durationSeconds: 1, audioFile: "x.caf")
        let fresh = Transcript(date: now.addingTimeInterval(-3600), raw: "y", polished: "y", durationSeconds: 1)
        XCTAssertNil(RetentionPolicy.normal.prune([old], now: now).first?.audioFile)
        XCTAssertEqual(RetentionPolicy.delete24h.prune([old, fresh], now: now).map(\.raw), ["y"])
        XCTAssertTrue(RetentionPolicy.never.prune([fresh], now: now).isEmpty)
    }

    func testInsights() {
        let now = ISO8601DateFormatter().date(from: "2026-10-14T18:00:00Z")!
        let items = [
            Transcript(date: now, raw: "um one two three four", polished: "one two three four",
                       appName: "Slack", durationSeconds: 2),
            Transcript(date: now.addingTimeInterval(-86_400), raw: "a b", polished: "a b",
                       appName: "Mail", durationSeconds: 1),
            Transcript(date: now.addingTimeInterval(-3 * 86_400), raw: "z", polished: "z",
                       durationSeconds: 1, status: .cancelled),
        ]
        let s = InsightsSummary.compute(items, now: now, calendar: calendar)
        XCTAssertEqual(s.totalWords, 6)
        XCTAssertEqual(s.wordsPerMinute, 120)
        XCTAssertEqual(s.dayStreak, 2)
        XCTAssertEqual(s.topApps.first?.name, "Slack")
        XCTAssertEqual(s.wordsCleaned, 1)
    }

    func testStoreRoundTrip() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let store = FlowStore(directory: dir)
        var settings = store.settings
        settings.commandModeEnabled = true
        settings.styles[.email] = .excited
        store.settings = settings
        store.history = [Transcript(raw: "r", polished: "p", durationSeconds: 1)]
        XCTAssertEqual(store.settings, settings)
        XCTAssertEqual(store.history.first?.polished, "p")
    }
}
