import SwiftUI
import Charts

struct TrapShootingView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showCharts = false
    @State private var analyticsRange: AnalyticsRange = .thirtyDays

    enum AnalyticsRange: String, CaseIterable {
        case thirtyDays = "30 Days"
        case ninetyDays = "90 Days"
        case all = "All Time"

        var days: Int? {
            switch self {
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            case .all: return nil
            }
        }
    }

    private var filteredSets: [TrapShootingSet] {
        let sets = store.trapShootingSets
        guard let days = analyticsRange.days else { return sets }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return sets.filter { $0.date >= cutoff }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(title: "Trap Shooting")

                newRoundForm
                    .padding(.horizontal)

                if store.trapShootingSets.isEmpty {
                    emptyState
                } else {
                    rangePicker
                        .padding(.horizontal)

                    statCards
                        .padding(.horizontal)
                        .opacity(showCharts ? 1 : 0)

                    chartGrid
                        .padding(.horizontal)
                        .opacity(showCharts ? 1 : 0)

                    historySection
                        .padding(.horizontal)

                    deepSeekAnalysisSection
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) { showCharts = true }
            }
        }
        .background(themeManager.colors.background)
    }

    // MARK: - New Round Form

    @State private var formScore: Double = 20
    @State private var formDate: Date = Date()
    @State private var formNotes: String = ""
    @State private var formWeather: TrapShootingSet.WeatherCondition = .sunny
    @State private var formWindSpeed: String = ""
    @State private var formTemperature: String = ""
    @State private var formTimeOfDay: String = ""
    @State private var formShooters: Double = 1
    @State private var formGun: String = "DT11"
    @State private var formAmmo: String = "Nobel Sport Trap & Skeet 7.5 1330 fps"
    @State private var formIsCompetition: Bool = false
    @State private var formLocation: String = "Renton Fish & Game Club"
    @State private var formExpanded: Bool = true
    @State private var editingSet: TrapShootingSet? = nil

    private var newRoundForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LOG A ROUND")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(themeManager.colors.textSecondary)
                Spacer()
                Button(action: { withAnimation(.snappy(duration: 0.25)) { formExpanded.toggle(); editingSet = nil; resetForm() } }) {
                    HStack(spacing: 4) {
                        Text(formExpanded ? "COLLAPSE" : "NEW ROUND")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                        Image(systemName: formExpanded ? "chevron.up" : "plus")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(themeManager.colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.colors.accent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(themeManager.colors.accent.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if formExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Score (0-25)").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            HStack {
                                Text("\(Int(formScore)) / 25")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(scoreColor(Int(formScore)))
                                    .frame(minWidth: 60, alignment: .leading)
                                Stepper("", value: $formScore, in: 0...25)
                                    .labelsHidden()
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            DatePicker("", selection: $formDate, displayedComponents: [.date])
                                .labelsHidden()
                                .datePickerStyle(.field)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Time").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            TextField("e.g. 10:30 AM", text: $formTimeOfDay)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(themeManager.colors.card)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                        }
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Weather").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            Picker("", selection: $formWeather) {
                                ForEach(TrapShootingSet.WeatherCondition.allCases, id: \.self) { w in
                                    HStack {
                                        Image(systemName: w.icon)
                                        Text(w.label)
                                    }.tag(w)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Wind (mph)").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            TextField("0", text: $formWindSpeed)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(themeManager.colors.card)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                                .frame(width: 90)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Temp (°F)").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            TextField("72", text: $formTemperature)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(themeManager.colors.card)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                                .frame(width: 90)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shooters (1-6)").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            HStack {
                                Text("\(Int(formShooters))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(themeManager.colors.textPrimary)
                                Stepper("", value: $formShooters, in: 1...6)
                                    .labelsHidden()
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Gun").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            TextField("DT11", text: $formGun)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(themeManager.colors.card)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ammo").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            TextField("Nobel Sport Trap & Skeet 7.5 1330 fps", text: $formAmmo)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(themeManager.colors.card)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                        }
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                            TextField("Renton Fish & Game Club", text: $formLocation)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(themeManager.colors.card)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                        }
                    }

                    HStack(spacing: 24) {
                        Toggle(isOn: $formIsCompetition) {
                            Text("Competition round").font(.system(size: 12, weight: .medium)).foregroundColor(themeManager.colors.textSecondary)
                        }
                        .toggleStyle(.switch)
                        .tint(themeManager.colors.accent)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes / Journal Entry").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                        TextEditor(text: $formNotes)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(themeManager.colors.card)
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                            .frame(height: 60)
                    }

                    HStack {
                        if editingSet != nil {
                            Button(action: { editingSet = nil; resetForm() }) {
                                Text("Cancel")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(themeManager.colors.textMuted)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        Button(action: saveRound) {
                            Text(editingSet != nil ? "UPDATE ROUND" : "SAVE ROUND")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundColor(themeManager.colors.background)
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(themeManager.colors.accent)
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func resetForm() {
        formScore = 20
        formDate = Date()
        formNotes = ""
        formWeather = .sunny
        formWindSpeed = ""
        formTemperature = ""
        formTimeOfDay = ""
        formShooters = 1
        formGun = "DT11"
        formAmmo = "Nobel Sport Trap & Skeet 7.5 1330 fps"
        formIsCompetition = false
        formLocation = "Renton Fish & Game Club"
    }

    private func saveRound() {
        let set = TrapShootingSet(
            date: formDate,
            totalScore: Int(formScore),
            notes: formNotes,
            weather: formWeather,
            windSpeed: Int(formWindSpeed).map { $0 },
            temperature: Double(formTemperature).map { $0 },
            timeOfDay: formTimeOfDay,
            totalShooters: Int(formShooters),
            gunUsed: formGun.isEmpty ? nil : formGun,
            ammoUsed: formAmmo.isEmpty ? nil : formAmmo,
            isCompetition: formIsCompetition,
            location: formLocation.isEmpty ? nil : formLocation
        )

        if let existing = editingSet {
            var updated = set
            updated.id = existing.id
            store.updateTrapShootingSet(updated)
        } else {
            store.addTrapShootingSet(set)
        }
        editingSet = nil
        resetForm()
    }

    // MARK: - Range Picker

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsRange.allCases, id: \.self) { range in
                Button(action: { withAnimation(.snappy(duration: 0.2)) { analyticsRange = range; showCharts = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.easeIn(duration: 0.3)) { showCharts = true } } } }) {
                    Text(range.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundColor(analyticsRange == range ? themeManager.colors.background : themeManager.colors.textSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(analyticsRange == range ? themeManager.colors.accent : themeManager.colors.surface)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        let sets = filteredSets
        let avg = sets.isEmpty ? 0 : Double(sets.map(\.totalScore).reduce(0, +)) / Double(sets.count)
        let best = sets.map(\.totalScore).max() ?? 0
        let hitRate = sets.isEmpty ? 0 : Double(sets.map(\.totalScore).reduce(0, +)) / Double(sets.count * 25) * 100
        let bestStreak = computeBestStreak(sets: sets)
        let count = sets.count

        return HStack(spacing: 12) {
            StatBox(label: "AVG SCORE", value: String(format: "%.1f", avg), unit: "/25", color: themeManager.colors.accent)
            StatBox(label: "BEST", value: "\(best)", unit: "/25", color: Color.green)
            StatBox(label: "HIT RATE", value: String(format: "%.0f", hitRate), unit: "%", color: Color.orange)
            StatBox(label: count == 1 ? "ROUND" : "ROUNDS", value: "\(count)", unit: "", color: themeManager.colors.accentDim)
            if let streak = bestStreak, streak > 1 {
                StatBox(label: "BEST STREAK 20+", value: "\(streak)", unit: "", color: Color.yellow.opacity(0.8))
            }
        }
    }

    // MARK: - Charts Grid

    private var chartGrid: some View {
        let sets = filteredSets.sorted { $0.date < $1.date }

        return VStack(alignment: .leading, spacing: 16) {
            if !sets.isEmpty {
                Text(dateRangeText(from: sets))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .padding(.leading, 4)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                scoreTrendChart(sets: sets)
                scoreDistributionChart(sets: sets)
                hitRateTrendChart(sets: sets)
                weatherImpactChart(sets: sets)
            }
        }
    }

    private func scoreTrendChart(sets: [TrapShootingSet]) -> some View {
        let data = sets.map { TrendPoint(date: $0.date, value: $0.totalScore) }
        return GlassLineChart(
            data: data,
            title: "Score Trend",
            subtitle: "Score per round over time",
            lineColor: themeManager.colors.accent,
            yAxisDomain: 0...25
        )
    }

    private func scoreDistributionChart(sets: [TrapShootingSet]) -> some View {
        let buckets = [(0...5, "0-5"), (6...10, "6-10"), (11...15, "11-15"), (16...20, "16-20"), (21...25, "21-25")]
        struct BucketItem: Identifiable {
            let id = UUID()
            let label: String
            let count: Int
        }
        let items = buckets.map { range, label in
            BucketItem(label: label, count: sets.filter { range.contains($0.totalScore) }.count)
        }

        return chartBox(title: "Score Distribution", subtitle: "Frequency of score ranges") {
            Chart(items) { item in
                BarMark(
                    x: .value("Range", item.label),
                    y: .value("Rounds", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [themeManager.colors.accent.opacity(0.8), themeManager.colors.accentDim.opacity(0.5)]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .chartPlotStyle { $0.background(.clear) }
            .frame(height: 150)
        }
    }

    private func hitRateTrendChart(sets: [TrapShootingSet]) -> some View {
        let window = 7
        let rolling: [TrendPoint] = sets.enumerated().compactMap { idx, set in
            let start = max(0, idx - window + 1)
            let slice = sets[start...idx]
            let avg = Double(slice.map(\.totalScore).reduce(0, +)) / Double(slice.count)
            return TrendPoint(date: set.date, value: avg)
        }

        return GlassLineChart(
            data: rolling,
            title: "Rolling Average",
            subtitle: "\(window)-round trailing average",
            lineColor: Color.orange,
            yAxisDomain: nil
        )
    }

    private func weatherImpactChart(sets: [TrapShootingSet]) -> some View {
        let grouped = Dictionary(grouping: sets) { $0.weather }
        struct WeatherStat: Identifiable {
            let id = UUID()
            let weather: TrapShootingSet.WeatherCondition
            let avgScore: Double
            let count: Int
        }
        let stats = grouped.compactMap { weather, groupSet -> WeatherStat? in
            guard !groupSet.isEmpty else { return nil }
            let avg = Double(groupSet.map(\.totalScore).reduce(0, +)) / Double(groupSet.count)
            return WeatherStat(weather: weather, avgScore: avg, count: groupSet.count)
        }.sorted { $0.avgScore > $1.avgScore }

        return chartBox(title: "Weather Impact", subtitle: "Average score by condition") {
            Chart(stats) { stat in
                BarMark(
                    x: .value("Weather", stat.weather.label),
                    y: .value("Avg Score", stat.avgScore)
                )
                .foregroundStyle(by: .value("Weather", stat.weather.label))
            }
            .chartForegroundStyleScale(range: barColors(for: stats.count))
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 8))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.colors.textMuted)
                }
            }
            .chartYScale(domain: 0...25)
            .chartPlotStyle { $0.background(.clear) }
            .frame(height: 150)
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ROUND HISTORY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(themeManager.colors.textSecondary)
                Spacer()
                Text("\(store.trapShootingSets.count) total")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
            }

            LazyVStack(spacing: 6) {
                ForEach(store.trapShootingSets) { set in
                    historyRow(set)
                }
            }
        }
    }

    private func historyRow(_ set: TrapShootingSet) -> some View {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(scoreColor(set.totalScore).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text("\(set.totalScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(scoreColor(set.totalScore))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(df.string(from: set.date))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.colors.textPrimary)
                        if set.isCompetition {
                            Text("COMP")
                                .font(.system(size: 8, weight: .bold))
                                .tracking(1)
                                .foregroundColor(Color.orange)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.orange.opacity(0.12))
                                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", set.hitRate))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.colors.textMuted)
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: set.weather.icon).font(.system(size: 10))
                            Text(set.weather.label).font(.system(size: 10))
                        }
                        .foregroundColor(themeManager.colors.textMuted)

                        if !set.timeOfDay.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "clock").font(.system(size: 10))
                                Text(set.timeOfDay).font(.system(size: 10))
                            }
                            .foregroundColor(themeManager.colors.textMuted)
                        }

                        Text("\(set.totalShooters)/6 shooters")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.colors.textMuted)

                        if let wind = set.windSpeed {
                            HStack(spacing: 2) {
                                Image(systemName: "wind").font(.system(size: 9))
                                Text("\(wind)mph").font(.system(size: 10))
                            }
                            .foregroundColor(themeManager.colors.textMuted)
                        }

                        if let temp = set.temperature {
                            Text("\(Int(temp))°F")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.colors.textMuted)
                        }
                    }

                    if !set.notes.isEmpty {
                        Text(set.notes)
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(2)
                    }

                    if set.gunUsed ?? set.ammoUsed ?? set.location != nil {
                        HStack(spacing: 4) {
                            if let gun = set.gunUsed { Text(gun).font(.system(size: 9)).foregroundColor(themeManager.colors.textMuted) }
                            if let ammo = set.ammoUsed { Text("· \(ammo)").font(.system(size: 9)).foregroundColor(themeManager.colors.textMuted) }
                            if let loc = set.location { Text("· \(loc)").font(.system(size: 9)).foregroundColor(themeManager.colors.textMuted) }
                        }
                    }
                }

                Spacer()

                VStack(spacing: 6) {
                    Button(action: { editSet(set) }) {
                        Image(systemName: "pencil").font(.system(size: 10)).foregroundColor(themeManager.colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    Button(action: { store.deleteTrapShootingSet(set) }) {
                        Image(systemName: "trash").font(.system(size: 10)).foregroundColor(Color.red.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(themeManager.colors.surface)
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func editSet(_ set: TrapShootingSet) {
        editingSet = set
        formScore = Double(set.totalScore)
        formDate = set.date
        formNotes = set.notes
        formWeather = set.weather
        formWindSpeed = set.windSpeed.map { String($0) } ?? ""
        formTemperature = set.temperature.map { String($0) } ?? ""
        formTimeOfDay = set.timeOfDay
        formShooters = Double(set.totalShooters)
        formGun = set.gunUsed ?? ""
        formAmmo = set.ammoUsed ?? ""
        formIsCompetition = set.isCompetition
        formLocation = set.location ?? ""
        formExpanded = true
    }

    // MARK: - DeepSeek Analysis

    private var deepSeekAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let analysis = store.trapAnalysis, !store.isGeneratingTrapAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "scope").font(.system(size: 13)).foregroundColor(themeManager.colors.accent)
                            Text("AI COACHING ANALYSIS").font(.system(size: 10, weight: .semibold)).tracking(2).foregroundColor(themeManager.colors.textSecondary)
                        }
                        Spacer()
                        Button(action: { store.generateTrapAnalysis() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 10))
                                Text("Refresh").font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(themeManager.colors.accent)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(themeManager.colors.accent.opacity(0.08))
                        }
                        .buttonStyle(.plain)
                    }

                    if !analysis.guidance.isEmpty {
                        Text(analysis.guidance)
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(themeManager.colors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                    }

                    if !analysis.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COACH TIPS").font(.system(size: 9, weight: .semibold)).tracking(2).foregroundColor(themeManager.colors.textMuted)
                            ForEach(Array(analysis.suggestions.enumerated()), id: \.offset) { idx, s in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle().fill(themeManager.colors.accentDim).frame(width: 5, height: 5).padding(.top, 4)
                                    Text(s).font(.system(size: 12, weight: .medium)).foregroundColor(themeManager.colors.textSecondary).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    HStack {
                        Text("Generated \(analysis.generatedAt, style: .relative) ago")
                            .font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                        if !analysis.modelUsed.isEmpty {
                            Text("· \(analysis.modelUsed)").font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                        }
                    }
                }
            } else if store.isGeneratingTrapAnalysis {
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(0.8).tint(themeManager.colors.accent)
                    Text("Generating coaching analysis...").font(.system(size: 12)).foregroundColor(themeManager.colors.textMuted)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 32)
            } else if let error = store.trapAnalysisError {
                VStack(spacing: 10) {
                    Text(error).font(.system(size: 12)).foregroundColor(themeManager.colors.textSecondary).multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        Button(action: { store.clearTrapAnalysisError(); store.generateTrapAnalysis() }) {
                            Text("Retry").font(.system(size: 11, weight: .semibold)).foregroundColor(themeManager.colors.accent)
                        }.buttonStyle(.plain)
                        Button(action: { store.clearTrapAnalysisError() }) {
                            Text("Dismiss").font(.system(size: 11)).foregroundColor(themeManager.colors.textMuted)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(16).frame(maxWidth: .infinity)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "scope").font(.system(size: 13)).foregroundColor(themeManager.colors.textMuted)
                        Text("AI COACHING").font(.system(size: 10, weight: .semibold)).tracking(2).foregroundColor(themeManager.colors.textSecondary)
                    }
                    Text("Get AI-powered analysis of your trap shooting data with personalized coaching tips.")
                        .font(.system(size: 12)).foregroundColor(themeManager.colors.textMuted).multilineTextAlignment(.center).frame(maxWidth: 280)
                    Button(action: { store.generateTrapAnalysis() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles").font(.system(size: 11))
                            Text("Generate Analysis").font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(themeManager.colors.background).padding(.horizontal, 20).padding(.vertical, 8).background(themeManager.colors.accent)
                    }.buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            }
        }
    }

    // MARK: - Helpers

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "scope").font(.system(size: 40)).foregroundColor(themeManager.colors.textMuted)
            Text("No Rounds Logged").font(.system(size: 16, weight: .semibold)).foregroundColor(themeManager.colors.textSecondary)
            Text("Log your first trap shooting round above to unlock score analytics and AI-powered coaching insights.").font(.system(size: 12)).foregroundColor(themeManager.colors.textMuted).multilineTextAlignment(.center).frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 80)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 22...25: return Color.green
        case 18...21: return Color.yellow
        case 12...17: return Color.orange
        default: return Color.red.opacity(0.8)
        }
    }

    private func computeBestStreak(sets: [TrapShootingSet]) -> Int? {
        let sorted = sets.sorted { $0.date < $1.date }
        var best = 0
        var current = 0
        for set in sorted {
            if set.totalScore >= 20 {
                current += 1
                best = max(best, current)
            } else { current = 0 }
        }
        return best > 0 ? best : nil
    }

    private func dateRangeText(from sets: [TrapShootingSet]) -> String {
        guard let first = sets.first?.date, let last = sets.last?.date else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return "\(df.string(from: first)) – \(df.string(from: last)) · \(sets.count) rounds"
    }

    private func chartBox<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(themeManager.colors.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 10)).foregroundColor(themeManager.colors.textMuted)
                }
            }
            .padding(.horizontal, 4)
            content()
        }
        .padding(18)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func barColors(for count: Int) -> [Color] {
        let base: [Color] = [
            Color.green, Color.blue, Color.orange, Color.purple,
            Color.teal, Color.yellow.opacity(0.8), Color.pink, Color.mint
        ]
        return Array(base.prefix(max(1, count)))
    }
}

struct StatBox: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundColor(themeManager.colors.textMuted).tracking(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 10, weight: .medium)).foregroundColor(themeManager.colors.textMuted)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
