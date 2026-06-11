import SwiftUI

// MARK: - Theme Enum

enum AppTheme: String, CaseIterable, Codable {
    case dark
    case blue
    case light

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .blue: return "Blue"
        case .light: return "Light"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .blue: return "drop.fill"
        case .light: return "sun.max.fill"
        }
    }
}

// MARK: - Theme Colors

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

    // ── Dark Mode (black monochrome) ──
    static let dark = ThemeColors(
        background: Color.black,
        surface: Color(white: 0.05),
        card: Color(white: 0.07),
        border: Color(white: 0.2),
        borderFaint: Color(white: 0.12),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.55),
        textMuted: Color(white: 0.35),
        accent: Color(red: 0.35, green: 0.55, blue: 0.82),
        accentDim: Color(red: 0.22, green: 0.38, blue: 0.62),
        chartLine: Color(red: 0.22, green: 0.38, blue: 0.62),
        chartFill: Color.white.opacity(0.05),
        chartGrid: Color(white: 0.2),
        sectionDivider: Color(white: 0.2),
        sidebarBg: Color(white: 0.05),
        dotFill: Color.black,
        dotStroke: Color(red: 0.22, green: 0.38, blue: 0.62)
    )

    // ── Blue Mode (navy blue base + light blue accent + white) ──
    static let blue = ThemeColors(
        background: Color(red: 0.04, green: 0.09, blue: 0.16),
        surface: Color(red: 0.07, green: 0.12, blue: 0.20),
        card: Color(red: 0.09, green: 0.15, blue: 0.24),
        border: Color(red: 0.25, green: 0.42, blue: 0.65),
        borderFaint: Color(red: 0.15, green: 0.28, blue: 0.48),
        textPrimary: Color(red: 0.86, green: 0.91, blue: 0.96),
        textSecondary: Color(red: 0.48, green: 0.61, blue: 0.78),
        textMuted: Color(red: 0.32, green: 0.44, blue: 0.60),
        accent: Color(red: 0.36, green: 0.61, blue: 0.84),
        accentDim: Color(red: 0.22, green: 0.38, blue: 0.58),
        chartLine: Color(red: 0.36, green: 0.61, blue: 0.84),
        chartFill: Color(red: 0.36, green: 0.61, blue: 0.84).opacity(0.08),
        chartGrid: Color(red: 0.15, green: 0.28, blue: 0.48),
        sectionDivider: Color(red: 0.15, green: 0.28, blue: 0.48),
        sidebarBg: Color(red: 0.05, green: 0.10, blue: 0.18),
        dotFill: Color(red: 0.04, green: 0.09, blue: 0.16),
        dotStroke: Color(red: 0.36, green: 0.61, blue: 0.84)
    )

    // ── Light Mode (reverse of dark — off-white base, comfortable on eyes) ──
    static let light = ThemeColors(
        background: Color(red: 0.95, green: 0.95, blue: 0.95),
        surface: Color(red: 0.91, green: 0.91, blue: 0.91),
        card: Color(red: 0.93, green: 0.93, blue: 0.93),
        border: Color(red: 0.75, green: 0.75, blue: 0.75),
        borderFaint: Color(red: 0.82, green: 0.82, blue: 0.82),
        textPrimary: Color(red: 0.10, green: 0.10, blue: 0.10),
        textSecondary: Color(red: 0.40, green: 0.40, blue: 0.40),
        textMuted: Color(red: 0.55, green: 0.55, blue: 0.55),
        accent: Color(red: 0.40, green: 0.65, blue: 0.40),
        accentDim: Color(white: 0.55),
        chartLine: Color(white: 0.55),
        chartFill: Color(white: 0.55).opacity(0.06),
        chartGrid: Color(red: 0.80, green: 0.80, blue: 0.80),
        sectionDivider: Color(red: 0.80, green: 0.80, blue: 0.80),
        sidebarBg: Color(red: 0.90, green: 0.90, blue: 0.90),
        dotFill: Color(red: 0.95, green: 0.95, blue: 0.95),
        dotStroke: Color(white: 0.55)
    )
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var theme: AppTheme = .dark {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        }
    }

    var colors: ThemeColors {
        switch theme {
        case .dark: return .dark
        case .blue: return .blue
        case .light: return .light
        }
    }

    var effectiveColorScheme: ColorScheme? {
        switch theme {
        case .dark: return .dark
        case .blue: return .dark
        case .light: return .light
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "app_theme"),
           let loaded = AppTheme(rawValue: saved) {
            self.theme = loaded
        }
    }
}
