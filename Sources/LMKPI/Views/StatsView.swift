import SwiftUI

// MARK: - Stats Tab

struct StatsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notesService = NotesChecklistService.shared
    @State private var showCharts = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(title: "Today's Progress")

                // ── Progress Overview Card ──
                progressOverviewCard

                SectionHeader(title: "Temporal Trends")

                if store.chronoEntries.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.flexible())],
                        spacing: 20
                    ) {
                        EmptyTrendBox(title: "Overall Efficiency")
                        EmptyTrendBox(title: "Tasks Done Index (TDI)")
                        EmptyTrendBox(title: "Reading Volume")
                        EmptyTrendBox(title: "Sleep Duration")
                        EmptyTrendBox(title: "Social Media Time")
                        EmptyTrendBox(title: "Meditated Prev. Night")
                        EmptyTrendBox(title: "Total Completed Tasks")
                    }
                    .padding(.horizontal)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible())],
                        spacing: 20
                    ) {
                        LineTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: $0.kpis?.efficiency ?? 0) },
                            title: "Overall Efficiency"
                        )
                        .frame(minHeight: 220)

                        LineTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: $0.kpis?.tdi ?? 0) },
                            title: "Tasks Done Index (TDI)"
                        )
                        .frame(minHeight: 220)

                        LineTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: $0.readingPages) },
                            title: "Reading Volume"
                        )
                        .frame(minHeight: 220)

                        LineTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: $0.sleepHours) },
                            title: "Sleep Duration"
                        )
                        .frame(minHeight: 220)

                        LineTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: Double($0.socialMins)) },
                            title: "Social Media Time"
                        )
                        .frame(minHeight: 220)

                        StepTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: $0.meditated ? 1 : 0) },
                            title: "Meditated Prev. Night"
                        )
                        .frame(minHeight: 220)

                        LineTrendView(
                            data: store.chronoEntries.map { TrendPoint(date: $0.date, value: Double($0.proDone + $0.perDone)) },
                            title: "Total Completed Tasks"
                        )
                        .frame(minHeight: 220)
                    }
                    .padding(.horizontal)
                    .opacity(showCharts ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.3)) {
                            showCharts = true
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
        .onAppear {
            Task { await notesService.fetchItems() }
        }
    }

    // MARK: - Progress Overview Card

    private var progressOverviewCard: some View {
        let proDone = notesService.items.filter { $0.section == .professional && $0.isChecked }.count
        let proTotal = notesService.items.filter { $0.section == .professional }.count
        let perDone = notesService.items.filter { $0.section == .personal && $0.isChecked }.count
        let perTotal = notesService.items.filter { $0.section == .personal }.count

        return HStack(spacing: 18) {
            // Professional ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(proTotal > 0 ? Double(proDone) / Double(proTotal) : 0))
                        .stroke(themeManager.colors.accent, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(proDone)/\(proTotal)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Professional")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Personal ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(perTotal > 0 ? Double(perDone) / Double(perTotal) : 0))
                        .stroke(themeManager.colors.accentDim, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(perDone)/\(perTotal)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Personal")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Overall
            let totalDone = proDone + perDone
            let totalAll = proTotal + perTotal
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(themeManager.colors.borderFaint, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(totalAll > 0 ? Double(totalDone) / Double(totalAll) : 0))
                        .stroke(themeManager.colors.accent, lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(totalDone)/\(totalAll)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }
                Text("Total")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
        .padding(.horizontal)
    }
}

// MARK: - Empty Trend Box (skeleton placeholder)

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
                .padding(.horizontal)
                .padding(.top, 14)

            EmptyTrendSkeleton()
                .padding()
        }
        .frame(minHeight: 210)
        .background(themeManager.colors.card)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.borderFaint))
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

                // Grid lines
                for frac: CGFloat in [0.25, 0.5, 0.75] {
                    let y = h * (1 - frac)
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: w, y: y))
                    context.stroke(line, with: .color(gridColor), lineWidth: 0.5)
                }

                // Y-axis labels
                for (frac, label) in [(0.0, "100"), (0.25, "75"), (0.5, "50"), (0.75, "25"), (1.0, "0")] {
                    let y = h * (1 - frac)
                    context.draw(Text(label).font(.system(size: 9)).foregroundColor(gridColor),
                                 at: CGPoint(x: -4, y: y))
                }

                var dashedLine = Path()
                dashedLine.move(to: CGPoint(x: w * 0.2, y: h * 0.7))
                dashedLine.addLine(to: CGPoint(x: w * 0.4, y: h * 0.4))
                dashedLine.addLine(to: CGPoint(x: w * 0.6, y: h * 0.55))
                dashedLine.addLine(to: CGPoint(x: w * 0.8, y: h * 0.3))
                context.stroke(dashedLine, with: .color(themeManager.colors.chartGrid),
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
