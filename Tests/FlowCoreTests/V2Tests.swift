import XCTest
@testable import FlowCore

final class V2Tests: XCTestCase {
    func testWAVRoundTrip() {
        let samples: [Float] = [0, 0.5, -0.5, 1, -1, 0.25]
        let data = WAV.encode(samples)
        XCTAssertEqual(data.count, 44 + samples.count * 2)
        let decoded = WAV.decode(data)
        XCTAssertEqual(decoded?.sampleRate, 16_000)
        XCTAssertEqual(decoded?.samples.count, samples.count)
        for (a, b) in zip(samples, decoded!.samples) { XCTAssertEqual(a, b, accuracy: 0.001) }
        XCTAssertNil(WAV.decode(Data("nope".utf8)))
    }

    func testContextTerms() {
        let terms = ContextTerms.extract(from: [
            "Hi Vignir, thanks for the notes on HuddleUp. Loop in sam@muckstack.com and @jevbot.",
            "Re: Launch plan - Tommy Keeley",
        ])
        XCTAssertTrue(terms.contains("HuddleUp"))
        XCTAssertTrue(terms.contains("sam@muckstack.com"))
        XCTAssertTrue(terms.contains("@jevbot"))
        XCTAssertTrue(terms.contains("Vignir"))
        XCTAssertFalse(terms.contains("Hi"))
    }

    func testEditedSpan() {
        XCTAssertEqual(CorrectionFinder.editedSpan(inserted: "ping Vignear about the launch",
                                                   fieldValue: "Hey team, ping Vignir about the launch. Thanks"),
                       "ping Vignir about the launch.")
        XCTAssertNil(CorrectionFinder.editedSpan(inserted: "all good here", fieldValue: "yes all good here"))
        XCTAssertNil(CorrectionFinder.editedSpan(inserted: "one two three", fieldValue: "totally different words now"))
    }

    func testEditedSpanFeedsLearning() {
        let span = CorrectionFinder.editedSpan(inserted: "ping Vignear today", fieldValue: "ping Vignir today")!
        XCTAssertEqual(PersonalDictionary.learnCorrection(original: "ping Vignear today", edited: span, existing: [])?.term, "Vignir")
    }

    func testMicrophoneRanking() {
        XCTAssertEqual(MicrophoneRanking.choose(ranking: ["usb", "builtin"], available: ["builtin", "usb"]), "usb")
        XCTAssertEqual(MicrophoneRanking.choose(ranking: ["usb", "builtin"], available: ["builtin"]), "builtin")
        XCTAssertNil(MicrophoneRanking.choose(ranking: [], available: ["builtin"]))
        XCTAssertEqual(MicrophoneRanking.merge(ranking: ["usb"], available: ["builtin", "usb"]), ["usb", "builtin"])
    }

    func testTransformFallbacks() {
        let pe = TextTransform.builtIns[1]
        let out = pe.fallback("Write a launch tweet. Mention it is free. Keep it short")!
        XCTAssertTrue(out.hasPrefix("Goal: Write a launch tweet."))
        XCTAssertTrue(out.contains("- Mention it is free"))
        XCTAssertNotNil(TextTransform.builtIns[0].fallback("um so yeah"))
        XCTAssertNil(TextTransform(name: "Pirate", prompt: "Talk like a pirate").fallback("hi"))
    }

    func testScratchSearch() {
        var a = ScratchNote(body: "Groceries\nmilk"); a.updated = Date(timeIntervalSince1970: 10)
        var b = ScratchNote(body: "Ideas\nvoice app"); b.updated = Date(timeIntervalSince1970: 20)
        var c = ScratchNote(body: "Pinned thing", pinned: true); c.updated = Date(timeIntervalSince1970: 1)
        XCTAssertEqual(ScratchNote.search([a, b, c], query: "").map(\.title), ["Pinned thing", "Ideas", "Groceries"])
        XCTAssertEqual(ScratchNote.search([a, b, c], query: "MILK").map(\.title), ["Groceries"])
        XCTAssertEqual(ScratchNote().title, "New note")
    }

    func testMeetingMergeAndSummary() {
        let segs = [
            Meeting.Segment(speaker: "Others", start: 5, text: "Sounds good."),
            Meeting.Segment(speaker: "You", start: 0, text: "Hey there."),
            Meeting.Segment(speaker: "Others", start: 9, text: "I'll send the contract by Friday."),
            Meeting.Segment(speaker: "You", start: 70, text: "Great, thanks."),
        ]
        let merged = Meeting.merge(segs)
        XCTAssertEqual(merged.map(\.speaker), ["You", "Others", "You"])
        XCTAssertEqual(merged[1].text, "Sounds good. I'll send the contract by Friday.")
        XCTAssertEqual(Meeting.timestamp(70), "1:10")
        XCTAssertEqual(Meeting.timestamp(3725), "1:02:05")
        XCTAssertEqual(Meeting.extractiveSummary(segs), "- Others: I'll send the contract by Friday.")
        var m = Meeting(title: "Sync")
        m.segments = segs
        XCTAssertTrue(m.markdown.contains("[0:09]") || m.markdown.contains("[0:05] Others"))
    }

    func testSettingsDecodeOldFileKeepsValuesAndDefaults() throws {
        let old = #"{"onboardingComplete":true,"cleanupLevel":"high"}"#
        let s = try JSONDecoder().decode(FlowSettings.self, from: Data(old.utf8))
        XCTAssertTrue(s.onboardingComplete)
        XCTAssertEqual(s.cleanupLevel, .high)
        XCTAssertEqual(s.insertion, .paste)
        XCTAssertEqual(s.transforms.count, 2)
    }

    func testShortcutsGetNewActionDefaults() throws {
        var old = ShortcutSet.defaults()
        old.bindings[.openScratchpad] = nil
        let data = try JSONEncoder().encode(old)
        let decoded = try JSONDecoder().decode(ShortcutSet.self, from: data)
        XCTAssertEqual(decoded.shortcuts(for: .openScratchpad), [Shortcut(.option, .character("s"))])
    }

    func testPipelineContextTerms() {
        var p = DictationPipeline(style: .formal, category: .other, cleanup: .light, snippets: [], dictionary: [])
        p.contextTerms = ["Vignir"]
        XCTAssertTrue(p.process("ask vignear about it").text.contains("Vignir"))
    }
}
