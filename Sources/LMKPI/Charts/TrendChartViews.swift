import SwiftUI
import Charts

// MARK: - Line Trend Chart (Reusable)

struct LineTrendView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let data: [TrendPoint]
    let title: String

    private var lineColor: Color { themeManager.colors.chartLine }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.colors.textPrimary)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.horizontal)

            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 1.5))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(LinearGradient(
                    colors: [lineColor.opacity(0.08), .clear],
                    startPoint: .top, endPoint: .bottom
                ))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(lineColor)
                .symbolSize(6)
            }
            .chartXAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel().foregroundStyle(themeManager.colors.textSecondary).font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel().foregroundStyle(themeManager.colors.textSecondary).font(.system(size: 9))
                }
            }
            .chartPlotStyle { $0.background(.clear) }
            .padding()
        }
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
    }
}

// MARK: - Step Trend Chart (Boolean - Meditated)

struct StepTrendView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let data: [TrendPoint]
    let title: String

    private var lineColor: Color { themeManager.colors.chartLine }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.colors.textPrimary)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.horizontal)

            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Meditated", point.value)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 1.5))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Meditated", point.value)
                )
                .foregroundStyle(LinearGradient(
                    colors: [lineColor.opacity(0.08), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
            }
            .chartXAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel().foregroundStyle(themeManager.colors.textSecondary).font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 1]) { v in
                    AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel {
                        Text(v.as(Int.self) == 1 ? "YES" : "NO")
                            .font(.system(size: 9))
                            .foregroundStyle(themeManager.colors.textSecondary)
                    }
                }
            }
            .chartYScale(domain: -0.1...1.1)
            .chartPlotStyle { $0.background(.clear) }
            .padding()
        }
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
    }
}

// MARK: - Data Model

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double

    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }

    init(date: Date, value: Int) {
        self.date = date
        self.value = Double(value)
    }
}
