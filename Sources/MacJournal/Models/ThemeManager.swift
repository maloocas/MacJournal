import SwiftUI

// MARK: - Theme Colors (dark only)

struct ThemeColors {
    let background: Color
    let surface: Color
    let card: Color
    let border: Color
    let borderFaint: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accent: Color
    let accentDim: Color
    let chartLine: Color
    let chartFill: Color
    let chartGrid: Color
    let sectionDivider: Color
    let sidebarBg: Color
    let dotFill: Color
    let dotStroke: Color

    static let dark = ThemeColors(
        background: Color(white: 0.04),
        surface: Color(white: 0.07),
        card: Color(white: 0.10),
        border: Color(white: 0.18),
        borderFaint: Color(white: 0.10),
        textPrimary: Color.white.opacity(0.92),
        textSecondary: Color.white.opacity(0.50),
        textMuted: Color.white.opacity(0.30),
        accent: Color(red: 0.25, green: 0.55, blue: 0.85),
        accentDim: Color(red: 0.25, green: 0.55, blue: 0.85).opacity(0.15),
        chartLine: Color(red: 0.25, green: 0.55, blue: 0.85),
        chartFill: Color(red: 0.25, green: 0.55, blue: 0.85).opacity(0.08),
        chartGrid: Color.white.opacity(0.08),
        sectionDivider: Color.white.opacity(0.08),
        sidebarBg: Color(white: 0.06),
        dotFill: Color(white: 0.04),
        dotStroke: Color(red: 0.25, green: 0.55, blue: 0.85)
    )
}

// MARK: - Theme Manager (dark only, always)

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    let colors: ThemeColors = .dark
    let effectiveColorScheme: ColorScheme? = .dark

    private init() {}
}
