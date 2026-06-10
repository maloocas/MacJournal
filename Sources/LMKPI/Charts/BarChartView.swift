import SwiftUI
import Charts

// MARK: - Bar Chart (Completed vs Total)

struct BarChartView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let proDone: Int
    let proTotal: Int
    let perDone: Int
    let perTotal: Int

    struct BarItem: Identifiable {
        let id = UUID()
        let category: String
        let type: String
        let value: Int
    }

    var bars: [BarItem] {
        [
            BarItem(category: "Pro", type: "Completed", value: proDone),
            BarItem(category: "Pro", type: "Total", value: max(proTotal, proDone)),
            BarItem(category: "Per/Acad", type: "Completed", value: perDone),
            BarItem(category: "Per/Acad", type: "Total", value: max(perTotal, perDone)),
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
        .chartYAxis { AxisMarks { AxisValueLabel().foregroundStyle(themeManager.colors.textSecondary) } }
    }
}
