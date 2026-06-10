import SwiftUI

// MARK: - Dashboard Tab

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                SectionHeader(title: "Analytics Engine")

                if let latest = store.latestEntry, let kpis = latest.kpis {
                    // KPI Cards — evenly fill the row
                    HStack(spacing: 18) {
                        KpiCard(label: "Tasks Done Index", value: "\(kpis.tdi)%")
                        KpiCard(label: "Efficiency Score", value: "\(kpis.efficiency)/100")
                        KpiCard(label: "Focus Ratio", value: String(format: "%.1f", kpis.focusRatio))
                        KpiCard(label: "Sleep Logged", value: "\(String(format: "%.1f", latest.sleepHours))h")
                    }
                    .padding(.horizontal)
                    .slideUpAppear()

                    // Charts
                    VStack(spacing: 24) {
                        HStack(spacing: 20) {
                            ChartBox(title: "Efficiency Radar") {
                                RadarChartView(
                                    values: [
                                        CGFloat(min(kpis.proExec, 100)),
                                        CGFloat(min(kpis.perExec, 100)),
                                        CGFloat(kpis.readingScore),
                                        CGFloat(min(100, max(0, 100 - Double(latest.socialMins) * store.config.socialWeight * 2))),
                                        CGFloat(min(kpis.sleepMetric, 100))
                                    ],
                                    labels: ["Pro Exec", "Personal Exec", "Reading", "Focus", "Rest"]
                                )
                                .frame(minHeight: 220)
                                .padding()
                            }

                            ChartBox(title: "Task Completion") {
                                BarChartView(
                                    proDone: latest.proDone,
                                    proTotal: latest.proTotal,
                                    perDone: latest.perDone,
                                    perTotal: latest.perTotal
                                )
                                .frame(minHeight: 220)
                                .padding()
                            }
                        }

                        ChartBox(title: "Dietary Distribution") {
                            let dietValues = dietDistribution(for: latest)
                            DonutChartView(values: dietValues)
                                .frame(minHeight: 220, maxHeight: 260)
                                .padding()
                        }
                        .frame(maxWidth: 480)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .slideUpAppear()
                } else {
                    // Empty state
                    HStack(spacing: 14) {
                        EmptyKpiCard(label: "Tasks Done Index")
                        EmptyKpiCard(label: "Efficiency Score")
                        EmptyKpiCard(label: "Focus Ratio")
                        EmptyKpiCard(label: "Sleep Logged")
                    }
                    .padding(.horizontal)

                    VStack(spacing: 24) {
                        HStack(spacing: 20) {
                            EmptyChartBox(title: "Efficiency Radar")
                            EmptyChartBox(title: "Task Completion")
                        }
                        EmptyChartBox(title: "Dietary Distribution")
                            .frame(maxWidth: 480)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
    }

    private func dietDistribution(for entry: Entry) -> [(label: String, value: Double, color: Color)] {
        var counts: [String: Double] = [:]
        for meal in [entry.breakfast, entry.lunch, entry.dinner] {
            let key: String
            switch meal {
            case .healthy: key = "Healthy"
            case .fancy: key = "Fancy"
            case .standard: key = "Standard"
            case .junk: key = "Junk"
            case .skipped: key = "Skipped"
            }
            counts[key, default: 0] += 1
        }
        let c = themeManager.colors
        let colors: [String: Color] = [
            "Healthy": c.accent,
            "Standard": c.textSecondary,
            "Fancy": c.accentDim,
            "Junk": c.textMuted,
            "Skipped": c.borderFaint
        ]
        return counts.map { (label: $0.key, value: $0.value, color: colors[$0.key, default: .gray]) }
            .sorted { $0.value > $1.value }
    }
}

// MARK: - KPI Card (filled)

struct KpiCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(themeManager.colors.textPrimary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
    }
}

// MARK: - KPI Card (empty)

struct EmptyKpiCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            Text("--")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(themeManager.colors.textMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
    }
}

// MARK: - Chart Box (filled)

struct ChartBox<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal)

            content
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
    }
}

// MARK: - Chart Box (empty skeleton)

struct EmptyChartBox: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal)

            EmptyChartSkeleton()
                .frame(minHeight: 220)
                .padding()
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
    }
}

// MARK: - Empty Chart Skeleton (Canvas)

struct EmptyChartSkeleton: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Canvas { context, size in
            let gridColor = themeManager.colors.chartGrid
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) * 0.45

            for ringFraction: CGFloat in [0.3, 0.5, 0.75, 1.0] {
                let rr = r * ringFraction
                let rect = CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2)
                let path = Path(ellipseIn: rect)
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            var hLine = Path()
            hLine.move(to: CGPoint(x: center.x - r, y: center.y))
            hLine.addLine(to: CGPoint(x: center.x + r, y: center.y))
            context.stroke(hLine, with: .color(gridColor), lineWidth: 0.5)

            var vLine = Path()
            vLine.move(to: CGPoint(x: center.x, y: center.y - r))
            vLine.addLine(to: CGPoint(x: center.x, y: center.y + r))
            context.stroke(vLine, with: .color(gridColor), lineWidth: 0.5)

            context.draw(
                Text("No Data")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted),
                at: center
            )
        }
    }
}
