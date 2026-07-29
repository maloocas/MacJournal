import SwiftUI
import Charts

// MARK: - Glass Line Chart (Reusable, per-chart color)

struct GlassLineChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    let data: [TrendPoint]
    let title: String
    let subtitle: String
    let lineColor: Color
    let yAxisDomain: ClosedRange<Double>?

    init(
        data: [TrendPoint],
        title: String,
        subtitle: String = "",
        lineColor: Color,
        yAxisDomain: ClosedRange<Double>? = nil
    ) {
        self.data = data
        self.title = title
        self.subtitle = subtitle
        self.lineColor = lineColor
        self.yAxisDomain = yAxisDomain
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.colors.textPrimary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                }
                Spacer()
                // Latest value badge
                if let latest = data.last {
                    Text(formattedValue(latest.value))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(lineColor)
                }
            }
            .padding(.horizontal, 4)

            // Chart
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            lineColor.opacity(0.18),
                            lineColor.opacity(0.04),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(lineColor)
                .symbolSize(data.count > 30 ? 0 : 4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, data.count / 5))) {
                    AxisGridLine()
                        .foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine()
                        .foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .modifier(DomainModifier(domain: yAxisDomain))
            .chartPlotStyle {
                $0.background(.clear)
            }
            .frame(height: 150)
            .drawingGroup()
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.colors.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(themeManager.colors.border, lineWidth: 1)
        }
    }
    private func formattedValue(_ v: Double) -> String {
        if v == floor(v) { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}

// MARK: - Glass Step Chart (for boolean / binary data)

struct GlassStepChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    let data: [TrendPoint]
    let title: String
    let subtitle: String
    let lineColor: Color

    init(
        data: [TrendPoint],
        title: String,
        subtitle: String = "",
        lineColor: Color
    ) {
        self.data = data
        self.title = title
        self.subtitle = subtitle
        self.lineColor = lineColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.colors.textPrimary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                }
                Spacer()
                if let latest = data.last {
                    Text(latest.value >= 1 ? "YES" : "NO")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(latest.value >= 1 ? lineColor : themeManager.colors.textMuted)
                }
            }
            .padding(.horizontal, 4)

            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Meditated", point.value)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.stepStart)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Meditated", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            lineColor.opacity(0.15),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.stepStart)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, data.count / 5))) {
                    AxisGridLine()
                        .foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 1]) { v in
                    AxisGridLine()
                        .foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel {
                        Text(v.as(Int.self) == 1 ? "YES" : "NO")
                            .font(.system(size: 9))
                            .foregroundStyle(themeManager.colors.textMuted)
                    }
                }
            }
            .chartYScale(domain: -0.1...1.1)
            .chartPlotStyle { $0.background(.clear) }
            .frame(height: 150)
            .drawingGroup()
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.colors.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(themeManager.colors.border, lineWidth: 1)
        }
    }
}

// MARK: - Data Model

struct TrendPoint: Identifiable {
    var id: Double { date.timeIntervalSince1970 }
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

// MARK: - Metric Color Palette

struct MetricColors {
    let efficiency  = Color(red: 0.55, green: 0.75, blue: 0.55)  // sage green
    let tdi         = Color(red: 0.45, green: 0.70, blue: 0.50)  // deeper sage
    let reading     = Color(red: 0.95, green: 0.72, blue: 0.42)  // warm amber
    let sleep       = Color(red: 0.60, green: 0.50, blue: 0.85)  // soft purple
    let social      = Color(red: 0.92, green: 0.45, blue: 0.42)  // coral red
    let meditation  = Color(red: 0.42, green: 0.78, blue: 0.82)  // teal
    let tasks       = Color(red: 0.55, green: 0.75, blue: 0.55)  // sage (matches efficiency)
}

// MARK: - Domain Modifier (applies y-axis scale only when domain is set)

struct DomainModifier: ViewModifier {
    let domain: ClosedRange<Double>?

    func body(content: Content) -> some View {
        if let domain = domain {
            content.chartYScale(domain: domain)
        } else {
            content
        }
    }
}
