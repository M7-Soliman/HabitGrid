import SwiftUI
import UIKit

// Design tokens adapted from the Belora UI spec: calm, near-monochrome, dark-first, with
// shape defined by borders (not shadows) and semantic accent colors. Every token is
// adaptive — the dark value is Belora's; the light value is a tasteful equivalent.
extension Color {
    // Surfaces
    static let appBg       = dyn(dark: 0x0D0E13, light: 0xF5F6F8)   // root background
    static let appCard     = dyn(dark: 0x0D0E13, light: 0xFFFFFF)   // card = root in dark; white in light
    static let appElevated = dyn(dark: 0x141518, light: 0xFFFFFF)   // hover / raised

    // Borders define card shape (white-alpha on dark, black-alpha on light)
    static let cardBorder  = dynAlpha(dark: 0.08, light: 0.08)
    static let line1       = dyn(dark: 0x26262B, light: 0xE6E6EB)   // subtle divider
    static let line2       = dyn(dark: 0x34343A, light: 0xD3D3D9)   // standard border

    // Foreground (text) scale
    static let fg1 = dyn(dark: 0xFAFAFA, light: 0x16171B)   // primary
    static let fg2 = dyn(dark: 0xC2C2C2, light: 0x3A3A40)   // secondary
    static let fg3 = dyn(dark: 0x8A8A8E, light: 0x6A6A70)   // tertiary
    static let fg4 = dyn(dark: 0x5A5A5E, light: 0x9A9AA0)   // muted labels
    static let fg5 = dyn(dark: 0x3A3A3E, light: 0xC4C4CA)   // ghost

    // Semantic accents (slightly stronger blue in light for contrast)
    static let brand = dyn(dark: 0xA8C5F5, light: 0x4F7FE0)
    static let win   = dyn(dark: 0xFDCA40, light: 0xE0A400)

    // Empty grid cell
    static let gridEmpty = dyn(dark: 0x1A1A1F, light: 0xEAEAEF)

    // A slip on a "quit" habit (the one place we use red).
    static let slip = dyn(dark: 0xF2555A, light: 0xE5484D)
}

// MARK: - Adaptive color helpers

// Builds a Color that resolves to one of two hex values based on light/dark mode.
private func dyn(dark: Int, light: Int) -> Color {
    Color(uiColor: UIColor { traits in
        UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
    })
}

// Builds an adaptive translucent border: white-alpha on dark, black-alpha on light.
private func dynAlpha(dark: Double, light: Double) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: dark)
            : UIColor(white: 0, alpha: light)
    })
}

private extension UIColor {
    convenience init(rgb: Int) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Haptics

// Small wrapper so taps feel responsive (used when logging a habit).
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}
