import AppKit
import CoreText
import FlowCore
import IsDeadDesign
import SwiftUI

/// Design tokens come from the shared IsDead design system
/// (`IsDeadTheme.wisprflow`). Fonts match the original's families: Figtree
/// for text and EB Garamond for display, both OFL and bundled.
enum Theme {
    static let t = IsDeadTheme.wisprflow
    static let cream = t.bg
    static let creamDark = Color(hex: 0xE4E4D0)   // --ids-color-divider
    static let card = t.surface
    static let paper = t.surfaceAlt
    static let ink = t.text
    static let muted = t.textMuted
    static let lavender = t.accentSoft
    static let pink = t.heroTo
    static let orange = Color(hex: 0xFF6C4C)      // --ids-color-flare
    static let amber = Color(hex: 0xFFA946)       // --ids-color-glow
    static let forest = t.accent
    static let errorBG = Color(hex: 0xF8E4E4)
    static let errorInk = t.danger
    static let successBG = Color(hex: 0xCEF5CA)
    static let successInk = t.success
    static let warningBG = Color(hex: 0xFCF8D8)
    static let focus = t.focus
    static let border = t.border
    static let hairline = t.text.opacity(0.08)

    static let cardRadius: CGFloat = t.radiusLg
    static let buttonRadius: CGFloat = t.radiusSm

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom(t.fontSans, size: size).weight(weight)
    }

    /// Serif display face for page titles and the hero line.
    static func display(_ size: CGFloat) -> Font {
        Font.custom(t.fontDisplay, size: size)
    }

    static func registerFonts() {
        for name in ["Figtree-Variable", "EBGaramond-Variable"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.module.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

struct PillButtonStyle: ButtonStyle {
    var prominent = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(13, .semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(prominent ? Theme.ink : Theme.card)
            .foregroundStyle(prominent ? Theme.cream : Theme.ink)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(prominent ? Color.clear : Theme.border, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1))
    }
}

struct KeyCap: View {
    var text: String
    var body: some View {
        Text(text)
            .font(Theme.font(12, .semibold))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Theme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct ShortcutLabel: View {
    var shortcut: Shortcut
    var body: some View {
        HStack(spacing: 4) {
            ForEach(shortcut.display.split(separator: " ").map(String.init), id: \.self) { KeyCap(text: $0) }
        }
    }
}
