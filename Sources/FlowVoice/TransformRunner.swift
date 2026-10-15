import FlowCore
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Runs a Transform with Apple's on-device model, or its rules fallback.
public enum TransformRunner {
    public static func run(_ transform: TextTransform, on text: String) async -> String? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            let session = LanguageModelSession(instructions: transform.instructions())
            if let out = try? await session.respond(to: "<<<TEXT\n\(text)\nTEXT>>>").content {
                let trimmed = out.replacingOccurrences(of: "<<<TEXT", with: "")
                    .replacingOccurrences(of: "TEXT>>>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        #endif
        return transform.fallback(text)
    }

    /// Meeting summary: decisions, follow-ups (who owes what), open questions.
    public static func summarize(_ meeting: Meeting) async -> String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            let transcript = String(meeting.transcriptText.suffix(12_000))
            let session = LanguageModelSession(instructions: """
            Summarize this meeting transcript as Markdown with three short sections: \
            Topics, Decisions, Follow-ups (who owes what). Use only facts from the transcript.
            """)
            if let out = try? await session.respond(to: transcript).content, !out.isEmpty { return out }
        }
        #endif
        return Meeting.extractiveSummary(meeting.segments)
    }
}
