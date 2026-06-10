import SwiftUI

// MARK: - Bottom-Right Theme Switcher

struct ThemeSwitcher: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    if isExpanded {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    themeManager.theme = theme
                                    isExpanded = false
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text(theme.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                        .textCase(.uppercase)
                                        .tracking(1.5)
                                        .foregroundColor(themeManager.theme == theme
                                            ? themeManager.colors.accent
                                            : themeManager.colors.textSecondary)
                                    Circle()
                                        .fill(themePreviewColor(theme))
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(
                                            themeManager.theme == theme
                                                ? themeManager.colors.accent
                                                : themeManager.colors.borderFaint,
                                            lineWidth: themeManager.theme == theme ? 1.5 : 0.5
                                        ))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    themeManager.theme == theme
                                        ? themeManager.colors.accent.opacity(0.1)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Toggle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: themeManager.theme.icon)
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.colors.textSecondary)
                            Text(themeManager.theme.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .textCase(.uppercase)
                                .tracking(1.5)
                                .foregroundColor(themeManager.colors.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(themeManager.colors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(themeManager.colors.borderFaint)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 12)
                .padding(.trailing, 16)
            }
        }
    }

    private func themePreviewColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .dark: return Color.black
        case .blue: return Color(red: 0.36, green: 0.61, blue: 0.84)
        case .light: return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }
}
