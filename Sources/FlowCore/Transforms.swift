import Foundation

/// Rewrite any selected text with a prompt (Wispr calls these Transforms).
public struct TextTransform: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var prompt: String
    public var builtIn: Bool
    public var runAfterDictation: Bool

    public init(id: UUID = UUID(), name: String, prompt: String, builtIn: Bool = false, runAfterDictation: Bool = false) {
        self.id = id; self.name = name; self.prompt = prompt; self.builtIn = builtIn
        self.runAfterDictation = runAfterDictation
    }

    public static let polishID = UUID(uuidString: "6F1C2A10-0000-4000-8000-000000000001")!
    public static let promptEngineerID = UUID(uuidString: "6F1C2A10-0000-4000-8000-000000000002")!

    public static let builtIns: [TextTransform] = [
        TextTransform(id: polishID, name: "Polish",
                      prompt: "Make this clearer and more concise. Fix grammar. Keep the meaning, facts and tone.",
                      builtIn: true),
        TextTransform(id: promptEngineerID, name: "Prompt Engineer",
                      prompt: """
                      Restructure this into a well-formatted prompt for an AI assistant: a one-line goal, \
                      then Context, Requirements and Output format sections as short bullet lists. \
                      Keep every detail the user gave. Do not answer the prompt.
                      """, builtIn: true),
    ]

    /// Full instruction for the on-device model.
    public func instructions() -> String {
        "\(prompt)\nReturn only the rewritten text, with no preamble or quotes."
    }

    /// Without a model: Polish falls back to the rules-based cleanup;
    /// Prompt Engineer to a simple template; custom transforms do nothing.
    public func fallback(_ text: String) -> String? {
        switch id {
        case Self.polishID:
            return DictationCleanup.deterministicCleanup(text)
        case Self.promptEngineerID:
            let sentences = text.split(whereSeparator: { ".!?\n".contains($0) })
                .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard let goal = sentences.first else { return nil }
            let rest = sentences.dropFirst().map { "- \($0)" }.joined(separator: "\n")
            return "Goal: \(goal).\n\nRequirements:\n\(rest.isEmpty ? "- (none given)" : rest)\n\nOutput format:\n- Concise and direct."
        default:
            return nil
        }
    }
}

/// Scratchpad: a floating notepad. Each note is plain text with a title
/// taken from its first line.
public struct ScratchNote: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var body: String
    public var pinned: Bool
    public var created: Date
    public var updated: Date
    public init(id: UUID = UUID(), body: String = "", pinned: Bool = false, created: Date = Date()) {
        self.id = id; self.body = body; self.pinned = pinned; self.created = created; self.updated = created
    }
    public var title: String {
        let first = body.split(separator: "\n").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? ""
        return first.isEmpty ? "New note" : String(first.prefix(60))
    }

    public static func search(_ notes: [ScratchNote], query: String) -> [ScratchNote] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let filtered = q.isEmpty ? notes : notes.filter { $0.body.localizedCaseInsensitiveContains(q) }
        return filtered.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.updated > $1.updated
        }
    }
}
