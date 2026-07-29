import SwiftUI

// MARK: - Stats Tab (Glass Charts with KPI Summary)

struct StatsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showCharts = false

    private let colors = MetricColors()

    @State private var recentEntries: [Entry] = []
    @State private var chartData: [ChartDataItem] = []
    @State private var tdCheckoffEvents: [TDCheckoffEvent] = []

    struct ChartDataItem: Identifiable {
        let id: String
        let data: [TrendPoint]
        let title: String
        let subtitle: String
        let lineColor: Color
        let yAxisDomain: ClosedRange<Double>?
        let isStep: Bool
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(title: "Temporal Trends")

                if store.chronoEntries.isEmpty {
                    emptyState
                } else {
                    kpiSummaryRow
                        .padding(.horizontal)
                        .opacity(showCharts ? 1 : 0)

                    chartGrid
                        .padding(.horizontal)
                        .opacity(showCharts ? 1 : 0)
                }
            }
            .padding(.vertical, 16)
            .onAppear {
                refreshChartData()
                withAnimation(.easeIn(duration: 0.3)) {
                    showCharts = true
                }
            }
        }
        .background(themeManager.colors.background)
        .onReceive(store.$entries) { _ in refreshChartData() }
        .onReceive(store.$tdCheckoffEvents) { _ in refreshChartData() }
    }

    private func refreshChartData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -store.config.statsWindowDays, to: Date())!
        let entries = store.chronoEntries.filter { $0.date >= cutoff }
        recentEntries = entries

        let items: [ChartDataItem] = [
            ChartDataItem(id: "efficiency", data: entries.map { TrendPoint(date: $0.date, value: $0.kpis?.efficiency ?? 0) }, title: "Overall Efficiency", subtitle: "Daily score, 0–100", lineColor: colors.efficiency, yAxisDomain: 0...100, isStep: false),
            ChartDataItem(id: "tdi", data: entries.map { TrendPoint(date: $0.date, value: $0.kpis?.tdi ?? 0) }, title: "Tasks Done Index", subtitle: "Weighted completion score", lineColor: colors.tdi, yAxisDomain: 0...100, isStep: false),
            ChartDataItem(id: "reading", data: entries.map { TrendPoint(date: $0.date, value: $0.readingPages) }, title: "Reading Volume", subtitle: "Pages per day", lineColor: colors.reading, yAxisDomain: nil, isStep: false),
            ChartDataItem(id: "sleep", data: entries.map { TrendPoint(date: $0.date, value: $0.sleepHours) }, title: "Sleep Duration", subtitle: "Hours per night", lineColor: colors.sleep, yAxisDomain: nil, isStep: false),
            ChartDataItem(id: "social", data: entries.map { TrendPoint(date: $0.date, value: Double($0.socialMins)) }, title: "Social Media", subtitle: "Minutes per day", lineColor: colors.social, yAxisDomain: nil, isStep: false),
            ChartDataItem(id: "meditated", data: entries.map { TrendPoint(date: $0.date, value: $0.meditated ? 1 : 0) }, title: "Meditated", subtitle: "Previous night", lineColor: colors.meditation, yAxisDomain: nil, isStep: true),
            ChartDataItem(id: "tasks", data: entries.map { TrendPoint(date: $0.date, value: Double($0.proDone + $0.perDone)) }, title: "Tasks Completed", subtitle: "Total done per day", lineColor: colors.tasks, yAxisDomain: nil, isStep: false),
        ]

        if store.config.tdCheckoffTracking {
            let eventsCutoff = Calendar.current.date(byAdding: .day, value: -store.config.statsWindowDays, to: Date())!
            tdCheckoffEvents = store.tdCheckoffEvents.filter { $0.timestamp >= eventsCutoff }
        }

        chartData = items
    }

    private var dateRangeText: String {
        guard let first = recentEntries.first?.date,
              let last = recentEntries.last?.date else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return "\(df.string(from: first)) – \(df.string(from: last)) · \(recentEntries.count) days"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            EmptyTrendBox(title: "Overall Efficiency")
            EmptyTrendBox(title: "Tasks Done Index")
            EmptyTrendBox(title: "Reading Volume")
            EmptyTrendBox(title: "Sleep Duration")
            EmptyTrendBox(title: "Social Media Time")
            EmptyTrendBox(title: "Meditated")
            EmptyTrendBox(title: "Tasks Completed")
        }
        .padding(.horizontal)
    }

    // MARK: - KPI Summary Row

    private var kpiSummaryRow: some View {
        let entries = recentEntries
        let avgEff = average(entries.map { Double($0.kpis?.efficiency ?? 0) })
        let avgTDI = average(entries.map { Double($0.kpis?.tdi ?? 0) })
        let totalRead = entries.reduce(0) { $0 + $1.readingPages }
        let avgSleep = average(entries.map { $0.sleepHours })
        let avgSocial = average(entries.map { Double($0.socialMins) })

        return HStack(spacing: 14) {
            KpiStatCard(label: "Avg Efficiency", value: String(format: "%.0f", avgEff), unit: "%", color: colors.efficiency)
            KpiStatCard(label: "Avg TDI", value: String(format: "%.1f", avgTDI), unit: "", color: colors.tdi)
            KpiStatCard(label: "Total Reading", value: "\(totalRead)", unit: "pg", color: colors.reading)
            KpiStatCard(label: "Avg Sleep", value: String(format: "%.1f", avgSleep), unit: "hrs", color: colors.sleep)
            KpiStatCard(label: "Avg Social", value: String(format: "%.0f", avgSocial), unit: "min", color: colors.social)
        }
    }

    // MARK: - Chart Grid (2 columns)

    private var chartGrid: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !dateRangeText.isEmpty {
                Text(dateRangeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .padding(.leading, 4)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                ForEach(chartData) { item in
                    if item.isStep {
                        GlassStepChart(data: item.data, title: item.title, subtitle: item.subtitle, lineColor: item.lineColor)
                    } else {
                        GlassLineChart(data: item.data, title: item.title, subtitle: item.subtitle, lineColor: item.lineColor, yAxisDomain: item.yAxisDomain)
                    }
                }

                if !tdCheckoffEvents.isEmpty {
                    HourlyCheckoffChart(events: tdCheckoffEvents)
                }
            }
        }
    }

    // MARK: - Helpers

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - KPI Stat Card (glass, compact)

struct KpiStatCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(themeManager.colors.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Empty Trend Box

struct EmptyTrendBox: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.colors.textPrimary)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.horizontal, 4)

            EmptyTrendSkeleton()
                .padding()
        }
        .frame(minHeight: 170)
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

// MARK: - Skeleton Line Chart

struct EmptyTrendSkeleton: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let gridColor = themeManager.colors.chartGrid
                let w = size.width
                let h = size.height

                for frac: CGFloat in [0.25, 0.5, 0.75] {
                    let y = h * (1 - frac)
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: w, y: y))
                    context.stroke(line, with: .color(gridColor), lineWidth: 0.5)
                }

                var dashedLine = Path()
                dashedLine.move(to: CGPoint(x: w * 0.15, y: h * 0.65))
                dashedLine.addCurve(
                    to: CGPoint(x: w * 0.85, y: h * 0.35),
                    control1: CGPoint(x: w * 0.40, y: h * 0.25),
                    control2: CGPoint(x: w * 0.60, y: h * 0.70)
                )
                context.stroke(dashedLine, with: .color(gridColor),
                               style: StrokeStyle(lineWidth: 1, dash: [6, 4]))

                context.draw(
                    Text("No Data")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted),
                    at: CGPoint(x: w / 2, y: h / 2)
                )
            }
        }
    }
}
