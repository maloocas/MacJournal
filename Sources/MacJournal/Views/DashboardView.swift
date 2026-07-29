import SwiftUI

// MARK: - Dashboard Tab (3-Column Layout)

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var dashboardDailyGoalText = ""

    @State private var weekEntries: [Entry] = []
    @State private var avgTDI: Double = 0
    @State private var avgEfficiency: Double = 0
    @State private var avgFocusRatio: Double = 0
    @State private var avgSleep: Double = 0
    @State private var avgReading: Double = 0
    @State private var avgSocial: Double = 0
    @State private var meditationStreak: Int = 0
    @State private var readingStreak: Int = 0
    @State private var pastWeekEntries: [Entry] = []

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            leftColumn
                .frame(minWidth: 0, maxWidth: .infinity)
            middleColumn
                .frame(minWidth: 0, maxWidth: .infinity)
            rightColumn
                .frame(minWidth: 0, maxWidth: .infinity)
        }

        .padding(20)
        .background(themeManager.colors.background)
        .onAppear(perform: recomputeMetrics)
        .onReceive(store.$entries) { _ in recomputeMetrics() }
    }

    // MARK: - Left Column (KPI Wall)

    private var leftColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "KPIs")

                if let latest = store.latestEntry, let kpis = latest.kpis {
                    KpiSectionLabel("Performance")

                    CompactKpiCard(
                        label: "TDI",
                        value: "\(kpis.tdi)",
                        unit: "%",
                        delta: deltaString(today: Double(kpis.tdi), avg: avgTDI),
                        accent: MetricColors().tdi
                    )

                    CompactKpiCard(
                        label: "Efficiency",
                        value: "\(kpis.efficiency)",
                        unit: "/100",
                        delta: deltaString(today: Double(kpis.efficiency), avg: avgEfficiency),
                        accent: MetricColors().efficiency
                    )

                    CompactKpiCard(
                        label: "Focus Ratio",
                        value: String(format: "%.2f", kpis.focusRatio),
                        unit: "",
                        delta: deltaString(today: kpis.focusRatio, avg: avgFocusRatio),
                        accent: Color(red: 0.95, green: 0.70, blue: 0.40)
                    )

                    KpiSectionLabel("Health & Habits")
                        .padding(.top, 6)

                    CompactKpiCard(
                        label: "Sleep",
                        value: String(format: "%.1f", latest.sleepHours),
                        unit: "h",
                        statusBadge: sleepInRange ? "checkmark.circle.fill" : nil,
                        statusColor: MetricColors().sleep,
                        delta: deltaString(today: latest.sleepHours, avg: avgSleep),
                        accent: MetricColors().sleep
                    )

                    CompactKpiCard(
                        label: "Reading",
                        value: "\(latest.readingPages)",
                        unit: "/\(store.config.readingTarget) pg",
                        progress: min(1.0, Double(latest.readingPages) / Double(max(1, store.config.readingTarget))),
                        statusBadge: readingTargetMet ? "checkmark.circle.fill" : nil,
                        statusColor: MetricColors().reading,
                        delta: deltaString(today: Double(latest.readingPages), avg: avgReading),
                        accent: MetricColors().reading
                    )

                    CompactKpiCard(
                        label: "Social Media",
                        value: "\(latest.socialMins)",
                        unit: "min",
                        delta: deltaString(today: Double(latest.socialMins), avg: avgSocial, inverted: true),
                        accent: MetricColors().social
                    )

                    CompactKpiCard(
                        label: "Diet Score",
                        value: dietScoreText,
                        unit: "",
                        accent: dietColor
                    )

                    KpiSectionLabel("Execution")
                        .padding(.top, 6)

                    CompactKpiCard(
                        label: "Professional",
                        value: "\(latest.proDone)",
                        unit: "/\(latest.proTotal)",
                        progress: latest.proTotal > 0 ? Double(latest.proDone) / Double(latest.proTotal) : 0,
                        accent: themeManager.colors.accent
                    )

                    CompactKpiCard(
                        label: "Personal",
                        value: "\(latest.perDone)",
                        unit: "/\(latest.perTotal)",
                        progress: latest.perTotal > 0 ? Double(latest.perDone) / Double(latest.perTotal) : 0,
                        accent: themeManager.colors.accent
                    )

                    KpiSectionLabel("Streaks")
                        .padding(.top, 6)

                    if meditationStreak > 0 {
                        StreakCard(icon: "sparkles", label: "Meditation", count: meditationStreak)
                    }

                    if readingStreak > 0 {
                        StreakCard(icon: "book.fill", label: "Reading Target", count: readingStreak)
                    }

                    if meditationStreak == 0 && readingStreak == 0 {
                        Text("Start a streak — log today.")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }

                    KpiSectionLabel("Quick Check")
                        .padding(.top, 6)

                    CompactKpiCard(
                        label: "Meditated",
                        value: latest.meditated ? "YES" : "NO",
                        unit: "",
                        statusBadge: latest.meditated ? "checkmark.circle.fill" : "xmark.circle.fill",
                        statusColor: latest.meditated ? MetricColors().meditation : themeManager.colors.textMuted,
                        accent: latest.meditated ? MetricColors().meditation : themeManager.colors.textMuted
                    )
                } else {
                    ForEach(0..<8, id: \.self) { _ in
                        EmptyCompactKpiCard()
                    }
                }

                Spacer().frame(height: 8)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Metric Recompute

    private func recomputeMetrics() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return }
        let entries = store.entries.filter { entry in
            let day = calendar.startOfDay(for: entry.date)
            return day >= sevenDaysAgo && day < today
        }
        weekEntries = entries
        pastWeekEntries = entries

        let tdiVals = entries.compactMap { $0.kpis?.tdi }.map(Double.init)
        avgTDI = tdiVals.isEmpty ? 0 : tdiVals.reduce(0, +) / Double(tdiVals.count)

        let effVals = entries.compactMap { $0.kpis?.efficiency }.map(Double.init)
        avgEfficiency = effVals.isEmpty ? 0 : effVals.reduce(0, +) / Double(effVals.count)

        let focusVals = entries.compactMap { $0.kpis?.focusRatio }
        avgFocusRatio = focusVals.isEmpty ? 0 : focusVals.reduce(0, +) / Double(focusVals.count)

        let sleepVals = entries.map { $0.sleepHours }
        avgSleep = sleepVals.isEmpty ? 0 : sleepVals.reduce(0, +) / Double(sleepVals.count)

        let readVals = entries.map { Double($0.readingPages) }
        avgReading = readVals.isEmpty ? 0 : readVals.reduce(0, +) / Double(readVals.count)

        let socialVals = entries.map { Double($0.socialMins) }
        avgSocial = socialVals.isEmpty ? 0 : socialVals.reduce(0, +) / Double(socialVals.count)

        meditationStreak = computeStreak { $0.meditated }
        readingStreak = computeStreak { $0.readingPages >= store.config.readingTarget }
    }

    private func deltaString(today: Double, avg: Double, inverted: Bool = false) -> String? {
        guard avg > 0 else { return nil }
        let diff = today - avg
        if abs(diff) < 0.01 { return "\u{2014}" }
        let arrow = (inverted ? (diff > 0 ? "\u{2191}" : "\u{2193}") : (diff > 0 ? "\u{2191}" : "\u{2193}"))
        return "\(arrow) \(String(format: "%.1f", abs(diff)))"
    }

    private var sleepInRange: Bool {
        guard let latest = store.latestEntry else { return false }
        return latest.sleepHours >= store.config.sleepMin && latest.sleepHours <= store.config.sleepMax
    }

    private var readingTargetMet: Bool {
        guard let latest = store.latestEntry else { return false }
        return latest.readingPages >= store.config.readingTarget
    }

    private var dietScoreText: String {
        guard let latest = store.latestEntry else { return "--" }
        var score = 0
        for meal in [latest.breakfast, latest.lunch, latest.dinner] {
            if meal == .healthy { score += 5 }
            else if meal == .junk || meal == .skipped { score -= 5 }
        }
        return score > 0 ? "+\(score)" : "\(score)"
    }

    private var dietColor: Color {
        guard let latest = store.latestEntry else { return themeManager.colors.textMuted }
        var score = 0
        for meal in [latest.breakfast, latest.lunch, latest.dinner] {
            if meal == .healthy { score += 5 }
            else if meal == .junk || meal == .skipped { score -= 5 }
        }
        if score >= 10 { return Color(red: 0.55, green: 0.80, blue: 0.55) }
        if score >= 0 { return MetricColors().tdi }
        if score >= -5 { return MetricColors().reading }
        return MetricColors().social
    }

    // MARK: - Streaks

    private func computeStreak(matches: (Entry) -> Bool) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sorted = store.entries
            .filter { calendar.startOfDay(for: $0.date) <= today }
            .sorted { $0.date > $1.date }

        guard let todayEntry = sorted.first,
              calendar.startOfDay(for: todayEntry.date) == today,
              matches(todayEntry)
        else { return 0 }

        var count = 1
        var currentDate = today

        for entry in sorted.dropFirst() {
            let entryDay = calendar.startOfDay(for: entry.date)
            let expectedDay = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            if entryDay == expectedDay && matches(entry) {
                count += 1
                currentDate = entryDay
            } else if entryDay < expectedDay {
                break
            }
        }
        return count
    }

    // MARK: - Middle Column (TD List)

    private var middleColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topTrailing) {
                SectionHeader(title: "TD List")
                Button(action: { PopOutWindowManager.shared.toggle() }) {
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Pop out TD List")
                .padding(.trailing, 12)
                .padding(.top, 12)
            }

            dailyGoalsDashboardSection

            if store.checklistItems.isEmpty {
                emptyChecklistPlaceholder
            } else {
                checklistContent
            }
        }
    }

    private var emptyChecklistPlaceholder: some View {
        SectionBox(title: "TD List") {
            VStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.colors.textMuted)
                Text("No checklist items.\nAdd some in the TD List tab.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        }
    }

    private var checklistContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                let proItems = store.checklistItems.filter { $0.section == .professional }
                let perItems = store.checklistItems.filter { $0.section == .personal }

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

    private var dailyGoalsDashboardSection: some View {
        let todayGoals = store.todayDailyGoals
        return SectionBox(title: "Daily Goals (\(todayGoals.count)/\(DailyGoal.maxPerDay))") {
            VStack(spacing: 0) {
                ForEach(Array(todayGoals.enumerated()), id: \.element.id) { idx, goal in
                    DailyGoalRow(
                        goal: goal,
                        onToggle: { store.toggleDailyGoal(id: goal.id) },
                        onDelete: { store.deleteDailyGoal(id: goal.id) },
                        onEdit: nil
                    )
                    if idx < todayGoals.count - 1 {
                        Divider().overlay(themeManager.colors.borderFaint)
                    }
                }

                if todayGoals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.colors.textMuted)
                        Text("No daily goals yet.\nAdd 1-5 goals for today.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }

                if todayGoals.count < DailyGoal.maxPerDay {
                    if !todayGoals.isEmpty {
                        Divider().overlay(themeManager.colors.borderFaint)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.accent.opacity(0.6))

                        TextField("Add daily goal...", text: $dashboardDailyGoalText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .onSubmit {
                                let trimmed = dashboardDailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                store.addDailyGoal(text: trimmed)
                                dashboardDailyGoalText = ""
                            }

                        Button(action: {
                            let trimmed = dashboardDailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            store.addDailyGoal(text: trimmed)
                            dashboardDailyGoalText = ""
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(
                                    dashboardDailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? themeManager.colors.textMuted
                                        : themeManager.colors.accent
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(dashboardDailyGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
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
                    let weekEntries = pastWeekEntries
                    if weekEntries.isEmpty {
                        EmptyChartSkeleton()
                            .padding()
                    } else {
                        let dietValues = dietDistribution(from: weekEntries)
                        DonutChartView(values: dietValues)
                            .padding()
                    }
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
        store.toggleChecklistItem(item)
    }

    private func deleteItem(_ item: ChecklistItem) {
        store.deleteChecklistItem(item)
    }

    // MARK: - Diet Helpers

    private func dietDistribution(from entries: [Entry]) -> [(label: String, value: Double, color: Color)] {
        var counts: [String: Double] = [:]
        for entry in entries {
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

// MARK: - Compact KPI Card

struct CompactKpiCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String
    let unit: String
    var progress: Double? = nil
    var statusBadge: String? = nil
    var statusColor: Color = .green
    var delta: String? = nil
    var accent: Color = .white

    var body: some View {
        let c = themeManager.colors

        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(c.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(accent)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(c.textMuted)
                }

                Spacer()

                if let badge = statusBadge {
                    Image(systemName: badge)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                }

                if let delta = delta {
                    let isUp = delta.contains("\u{2191}")
                    let isNeutral = delta == "\u{2014}"
                    Text(delta)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isNeutral ? c.textMuted : (isUp ? Color(red: 0.55, green: 0.80, blue: 0.55) : MetricColors().social))
                }
            }

            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(c.borderFaint)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accent)
                            .frame(width: max(3, geo.size.width * progress), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(c.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(c.border, lineWidth: 1)
        }
    }
}

// MARK: - Empty Compact KPI Card

struct EmptyCompactKpiCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let c = themeManager.colors
        VStack(alignment: .leading, spacing: 4) {
            Text("No Data")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(c.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)

            Text("--")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(c.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(c.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(c.border, lineWidth: 1)
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let label: String
    let count: Int

    var body: some View {
        let c = themeManager.colors

        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(c.accent)

            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(c.textPrimary)

            Text(label.lowercased())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(c.textSecondary)

            Spacer()

            Text(count == 1 ? "day" : "days")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(c.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(c.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(c.border, lineWidth: 1)
        }
    }
}

// MARK: - KPI Section Label

struct KpiSectionLabel: View {
    @EnvironmentObject var themeManager: ThemeManager
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(themeManager.colors.textMuted)
            .textCase(.uppercase)
            .tracking(1.5)
            .padding(.leading, 4)
    }
}

// MARK: - Chart Box

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

// MARK: - Chart Box (empty)

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

// MARK: - Empty Chart Skeleton

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


