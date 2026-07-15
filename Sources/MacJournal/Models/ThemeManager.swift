import SwiftUI

// MARK: - Accent Color Palette

struct AccentOption: Identifiable, Equatable {
    let id: String       // storage key, matches AppConfig.accentColor
    let label: String    // display name
    let base: Color      // primary accent color

    var dim: Color { base.opacity(0.15) }
    var chartFill: Color { base.opacity(0.08) }

    static let all: [AccentOption] = [
        AccentOption(id: "blue",     label: "Sky Blue",  base: Color(red: 0.25, green: 0.55, blue: 0.85)),
        AccentOption(id: "sage",     label: "Sage",      base: Color(red: 0.55, green: 0.72, blue: 0.55)),
        AccentOption(id: "amber",    label: "Amber",     base: Color(red: 0.92, green: 0.72, blue: 0.28)),
        AccentOption(id: "rose",     label: "Rose",      base: Color(red: 0.88, green: 0.35, blue: 0.45)),
        AccentOption(id: "violet",   label: "Violet",    base: Color(red: 0.55, green: 0.40, blue: 0.85)),
        AccentOption(id: "teal",     label: "Teal",      base: Color(red: 0.25, green: 0.72, blue: 0.72)),
        AccentOption(id: "coral",    label: "Coral",     base: Color(red: 0.95, green: 0.45, blue: 0.35)),
        AccentOption(id: "lavender", label: "Lavender",  base: Color(red: 0.65, green: 0.55, blue: 0.90)),
    ]

    static func named(_ id: String) -> AccentOption {
        all.first { $0.id == id } ?? all[0]
    }
}

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

    static func dark(accent: Color) -> ThemeColors {
        ThemeColors(
            background: Color(white: 0.04),
            surface: Color(white: 0.07),
            card: Color(white: 0.10),
            border: Color(white: 0.18),
            borderFaint: Color(white: 0.10),
            textPrimary: Color.white.opacity(0.92),
            textSecondary: Color.white.opacity(0.50),
            textMuted: Color.white.opacity(0.30),
            accent: accent,
            accentDim: accent.opacity(0.15),
            chartLine: accent,
            chartFill: accent.opacity(0.08),
            chartGrid: Color.white.opacity(0.08),
            sectionDivider: Color.white.opacity(0.08),
            sidebarBg: Color(white: 0.06),
            dotFill: Color(white: 0.04),
            dotStroke: accent
        )
    }
}

// MARK: - Theme Manager (dark only, dynamic accent)

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var accentColorName: String = "blue" {
        didSet { rebuild() }
    }

    @Published private(set) var colors: ThemeColors

    private init() {
        colors = ThemeManager.buildColors(for: "blue")
    }

    func applyAccent(_ name: String) {
        guard AccentOption.named(name).id == name else { return }
        accentColorName = name
    }

    private func rebuild() {
        colors = ThemeManager.buildColors(for: accentColorName)
    }

    private static func buildColors(for name: String) -> ThemeColors {
        let option = AccentOption.named(name)
        return .dark(accent: option.base)
    }
}
