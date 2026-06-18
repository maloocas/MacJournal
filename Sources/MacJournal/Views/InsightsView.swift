import SwiftUI

// MARK: - Insights Tab

struct InsightsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(title: "Insights")
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
    }
}
