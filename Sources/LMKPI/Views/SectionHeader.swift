import SwiftUI

// MARK: - Reusable Section Header (used across all tabs)

struct SectionHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .textCase(.uppercase)
                .tracking(3)
                .foregroundColor(themeManager.colors.textPrimary)
            Spacer()
        }
        .padding(.horizontal)
         .padding(.top, 8)
        .overlay(alignment: .bottom) {
            themeManager.colors.sectionDivider.frame(height: 1)
        }
         .padding(.bottom, 10)
    }
}

// MARK: - Slide-Up Appearance Modifier

struct SlideUpAppear: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func slideUpAppear() -> some View {
        modifier(SlideUpAppear())
    }
}
