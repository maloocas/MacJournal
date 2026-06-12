import SwiftUI

// MARK: - Dashboard Tab (3-Column Layout)

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notesService = NotesChecklistService.shared

    var body: some View {
        GeometryReader { geo in
            let avail = geo.size.width - 40 // HStack spacing
            HStack(alignment: .top, spacing: 20) {
                leftColumn
                    .frame(width: avail * 0.15)

                middleColumn
                    .frame(width: avail * 0.48)

                rightColumn
                    .frame(width: avail * 0.37)
            }
        }
        .padding(20)
        .background(themeManager.colors.background)
        .onAppear {
            Task { await notesService.fetchItems() }
        }
    }

    // MARK: - Left Column (KPI Values)

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "KPIs")

            if let latest = store.latestEntry, let kpis = latest.kpis {
                KpiCard(label: "Tasks Done Index", value: "\(kpis.tdi)%")
                KpiCard(label: "Efficiency", value: "\(kpis.efficiency)/100")
                KpiCard(label: "Focus Ratio", value: String(format: "%.1f", kpis.focusRatio))
                KpiCard(label: "Sleep Logged", value: "\(String(format: "%.1f", latest.sleepHours))h")
            } else {
                EmptyKpiCard(label: "Tasks Done Index")
                EmptyKpiCard(label: "Efficiency")
                EmptyKpiCard(label: "Focus Ratio")
                EmptyKpiCard(label: "Sleep Logged")
            }
        }
        .slideUpAppear()
    }

    // MARK: - Middle Column (TD List)

    private var middleColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "TD List")

            if notesService.items.isEmpty {
                emptyChecklistPlaceholder
            } else {
                checklistContent
            }
        }
        .slideUpAppear()
    }

    private var emptyChecklistPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 28))
                .foregroundColor(themeManager.colors.textMuted)
            Text("No checklist items.\nAdd some in the TD List tab.")
                .font(.system(size: 11))
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
    }

    private var checklistContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                let proItems = notesService.items.filter { $0.section == .professional }
                let perItems = notesService.items.filter { $0.section == .personal }

                if !proItems.isEmpty {
                    SectionBox(title: "Professional (\(proItems.count))") {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(proItems.enumerated()), id: \.element.id) { idx, item in
                                ChecklistItemRow(
                                    item: item,
                                    onToggle: { toggleItem(item) },
                                    onDelete: { deleteItem(item) },
                                    onEdit: nil
                                )
                                if idx < proItems.count - 1 {
                                    Divider().overlay(themeManager.colors.borderFaint)
                                }
                            }
                        }
                    }
                }

                if !perItems.isEmpty {
                    SectionBox(title: "Personal & Academic (\(perItems.count))") {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(perItems.enumerated()), id: \.element.id) { idx, item in
                                ChecklistItemRow(
                                    item: item,
                                    onToggle: { toggleItem(item) },
                                    onDelete: { deleteItem(item) },
                                    onEdit: nil
                                )
                                if idx < perItems.count - 1 {
                                    Divider().overlay(themeManager.colors.borderFaint)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Right Column (Charts)

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Charts")

            if let latest = store.latestEntry, let kpis = latest.kpis {
                chartContent(latest: latest, kpis: kpis)
            } else {
                emptyChartContent
            }
        }
        .slideUpAppear()
    }

    private func chartContent(latest: Entry, kpis: KPIs) -> some View {
        ScrollView {
            VStack(spacing: 20) {
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
                    .padding()
                }

                ChartBox(title: "Task Completion") {
                    BarChartView(
                        proDone: latest.proDone,
                        proTotal: latest.proTotal,
                        perDone: latest.perDone,
                        perTotal: latest.perTotal
                    )
                    .padding()
                }

                ChartBox(title: "Dietary Distribution") {
                    let dietValues = dietDistribution(for: latest)
                    DonutChartView(values: dietValues)
                        .padding()
                }
            }
        }
    }

    private var emptyChartContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                EmptyChartBox(title: "Efficiency Radar")
                EmptyChartBox(title: "Task Completion")
                EmptyChartBox(title: "Dietary Distribution")
            }
        }
    }

    // MARK: - Checklist Actions

    private func toggleItem(_ item: ChecklistItem) {
        Task {
            await notesService.toggleItem(item, store: store)
        }
    }

    private func deleteItem(_ item: ChecklistItem) {
        Task {
            await notesService.deleteItem(item, store: store)
        }
    }

    // MARK: - Helpers

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
