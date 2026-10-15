import AppKit
import CoreText
import FlowCore
import SwiftUI

/// Design tokens. Colors follow docs/WISPRFLOW_SPEC.md §10; the font is
/// DM Sans (OFL), bundled.
enum Theme {
    static let cream = Color(hex: 0xFFFFEB)
    static let creamDark = Color(hex: 0xE4E4D0)
    static let card = Color(hex: 0xFFFDF9)
    static let paper = Color(hex: 0xF5F4F0)
    static let ink = Color(hex: 0x1A1A1A)
    static let muted = Color(hex: 0x71716E)
    static let lavender = Color(hex: 0xF0D7FF)
    static let pink = Color(hex: 0xFFBCF2)
    static let orange = Color(hex: 0xFF6C4C)
    static let amber = Color(hex: 0xFFA946)
    static let forest = Color(hex: 0x034F46)
    static let errorBG = Color(hex: 0xF8E4E4)
    static let errorInk = Color(hex: 0x7F1C34)
    static let successBG = Color(hex: 0xCEF5CA)
    static let successInk = Color(hex: 0x114E0B)
    static let warningBG = Color(hex: 0xFCF8D8)
    static let focus = Color(hex: 0x2D62FF)
    static let border = Color(hex: 0x1A1A1A).opacity(0.3)
    static let hairline = Color(hex: 0x1A1A1A).opacity(0.08)

    static let cardRadius: CGFloat = 12
    static let buttonRadius: CGFloat = 8

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom("DM Sans", size: size).weight(weight)
    }

    static func registerFonts() {
        for name in ["DMSans-Variable", "DMSans-Italic-Variable"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else { continue }
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
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                .stroke(prominent ? Color.clear : Theme.border, lineWidth: 1))
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
