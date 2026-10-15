import Foundation

/// Optional on-device model pass (Apple Foundation Models, macOS 26+), via
/// MyMan's guarded cleanup. Below macOS 26 it returns the rules-only text.
public enum ModelPolish {
    static func tone(for level: CleanupLevel) -> DictationTone {
        switch level {
        case .none: return .verbatim
        case .light, .medium: return .neutral
        case .high: return .professional
        }
    }

    public static func prepare(level: CleanupLevel) {
        guard level == .medium || level == .high else { return }
        DictationCleanup.prepare(tone: tone(for: level))
    }

    public static func polish(_ text: String, level: CleanupLevel, bundleID: String?) async -> String {
        guard level == .medium || level == .high else { return text }
        return await DictationCleanup.clean(text, tone: tone(for: level), targetBundleID: bundleID)
    }
}
