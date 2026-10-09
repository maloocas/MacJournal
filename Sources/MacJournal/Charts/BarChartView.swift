import SwiftUI
import Charts

// MARK: - Bar Chart (Completed vs Total)

struct BarChartView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let completedItems: Int
    let totalItems: Int

    struct BarItem: Identifiable {
        let id = UUID()
        let category: String
        let type: String
        let value: Int
    }

    var bars: [BarItem] {
        [
            BarItem(category: "Tasks", type: "Completed", value: completedItems),
            BarItem(category: "Tasks", type: "Total", value: max(totalItems, completedItems)),
        ]
    }

    var body: some View {
        Chart(bars) { item in
            BarMark(
                x: .value("Category", item.category),
                y: .value("Count", item.value)
            )
            .foregroundStyle(by: .value("Type", item.type))
            .position(by: .value("Type", item.type))
        }
        .chartForegroundStyleScale([
            "Completed": themeManager.colors.accent,
            "Total": themeManager.colors.accentDim
        ])
        .chartLegend(position: .bottom, spacing: 8)
        .chartXAxis { AxisMarks { AxisValueLabel().foregroundStyle(themeManager.colors.textSecondary) } }
        .drawingGroup()
    }
}
