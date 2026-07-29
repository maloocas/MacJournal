import Foundation

// MARK: - Insights Engine

/// Processes historical entries and generates structured insight cards.
/// Pure Swift computation — no external APIs or dependencies.
/// Architecture leaves room for an optional LLM summary layer (future).

@MainActor
class InsightsEngine: ObservableObject {

    // MARK: - Public API

    nonisolated func generate(from entries: [Entry], config: AppConfig) -> InsightsReport {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // ── Time windows ──
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today),
              let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: today)
        else {
            return InsightsReport(generatedAt: Date(), periodStart: today, periodEnd: today, cards: [])
        }

        let thisWeek = entries.filter { entry in
            let day = calendar.startOfDay(for: entry.date)
            return day >= sevenDaysAgo && day < today
        }

        let lastWeek = entries.filter { entry in
            let day = calendar.startOfDay(for: entry.date)
            return day >= fourteenDaysAgo && day < sevenDaysAgo
        }

        let last14 = thisWeek + lastWeek

        guard !thisWeek.isEmpty else {
            return InsightsReport(
                generatedAt: Date(),
                periodStart: sevenDaysAgo,
                periodEnd: today,
                cards: [InsightCard(
                    category: .trend,
                    title: "Not Enough Data",
                    body: "Log at least a few days this week to see insights.",
                    icon: "chart.line.downtrend.xyaxis",
                    severity: .neutral
                )]
            )
        }

        var cards: [InsightCard] = []

        // ── 1. Trends (this week vs last week) ──
        cards.append(contentsOf: computeTrends(thisWeek: thisWeek, lastWeek: lastWeek))

        // ── 2. Goal attainment ──
        cards.append(contentsOf: computeGoals(thisWeek: thisWeek, config: config))

        // ── 3. Patterns ──
        cards.append(contentsOf: computePatterns(entries: last14))

        // ── 4. Anomalies ──
        cards.append(contentsOf: computeAnomalies(entries: last14))

        // ── 5. Comparisons (delta summary) ──
        if !lastWeek.isEmpty {
            cards.append(contentsOf: computeComparisons(thisWeek: thisWeek, lastWeek: lastWeek))
        }

        return InsightsReport(
            generatedAt: Date(),
            periodStart: sevenDaysAgo,
            periodEnd: today,
            cards: cards
        )
    }

    // MARK: - 1. Trends

    nonisolated private func computeTrends(thisWeek: [Entry], lastWeek: [Entry]) -> [InsightCard] {
        var cards: [InsightCard] = []

        let metrics: [(String, (Entry) -> Double, String, Bool)] = [
            ("Efficiency", { Double($0.kpis?.efficiency ?? 0) }, "gauge.with.needle", false),
            ("TDI", { Double($0.kpis?.tdi ?? 0) }, "checklist", false),
            ("Reading Pages", { Double($0.readingPages) }, "book", false),
            ("Sleep Hours", { $0.sleepHours }, "bed.double", true),
            ("Social Media (min)", { Double($0.socialMins) }, "iphone", true),
            ("Focus Ratio", { $0.kpis?.focusRatio ?? 0 }, "scope", false),
        ]

        for (name, extract, icon, inverted) in metrics {
            let cur = thisWeek.map(extract)
            let prev = lastWeek.map(extract)
            let curAvg = cur.reduce(0, +) / Double(max(cur.count, 1))
            let prevAvg = prev.reduce(0, +) / Double(max(prev.count, 1))

            guard prevAvg > 0 || curAvg > 0 else { continue }

            let change: Double
            if prevAvg > 0 {
                change = ((curAvg - prevAvg) / prevAvg) * 100.0
            } else {
                change = curAvg > 0 ? 100 : 0
            }

            // Only show meaningful changes (>5%)
            guard abs(change) >= 5 else { continue }

            let direction = change > 0 ? "up" : "down"
            let goodDirection = inverted ? change < 0 : change > 0
            let severity: InsightCard.Severity = goodDirection ? .positive : .negative
            let arrow = change > 0 ? "↑" : "↓"

            cards.append(InsightCard(
                category: .trend,
                title: "\(name) \(direction) \(arrow)",
                body: "\(String(format: "%.0f", curAvg))\(unit(for: name)) this week vs \(String(format: "%.0f", prevAvg))\(unit(for: name)) last week (\(String(format: "%+.0f", change))%)",
                icon: icon,
                severity: severity
            ))
        }

        return cards
    }

    // MARK: - 2. Goal Attainment

    nonisolated private func computeGoals(thisWeek: [Entry], config: AppConfig) -> [InsightCard] {
        var cards: [InsightCard] = []

        let readingDays = thisWeek.filter { $0.readingPages >= config.readingTarget }.count
        let meditatedDays = thisWeek.filter { $0.meditated }.count
        let goodSleepDays = thisWeek.filter {
            $0.sleepHours >= config.sleepMin && $0.sleepHours <= config.sleepMax
        }.count
        let total = thisWeek.count

        // Reading target
        if config.readingTarget > 0 {
            let pct = Double(readingDays) / Double(max(total, 1)) * 100
            cards.append(InsightCard(
                category: .goal,
                title: "Reading Target",
                body: "Hit \(config.readingTarget)+ pages on \(readingDays)/\(total) days (\(String(format: "%.0f", pct))%)",
                icon: "book",
                severity: pct >= 70 ? .positive : pct >= 40 ? .warning : .negative
            ))
        }

        // Meditation
        if total > 0 {
            let pct = Double(meditatedDays) / Double(total) * 100
            cards.append(InsightCard(
                category: .goal,
                title: "Meditation",
                body: "Meditated \(meditatedDays)/\(total) days (\(String(format: "%.0f", pct))%)",
                icon: "leaf",
                severity: meditatedDays >= 5 ? .positive : meditatedDays >= 3 ? .warning : .negative
            ))
        }

        // Sleep
        if total > 0 {
            let pct = Double(goodSleepDays) / Double(total) * 100
            cards.append(InsightCard(
                category: .goal,
                title: "Sleep in Range",
                body: "\(String(format: "%.1f", config.sleepMin))–\(String(format: "%.1f", config.sleepMax))h on \(goodSleepDays)/\(total) nights (\(String(format: "%.0f", pct))%)",
                icon: "bed.double",
                severity: pct >= 70 ? .positive : pct >= 40 ? .warning : .negative
            ))
        }

        return cards
    }

    // MARK: - 3. Pattern Detection

    nonisolated private func computePatterns(entries: [Entry]) -> [InsightCard] {
        var cards: [InsightCard] = []
        let calendar = Calendar.current

        // ── Meditation correlation ──
        let medDays = entries.filter { $0.meditated }
        let nonMedDays = entries.filter { !$0.meditated }
        if medDays.count >= 2 && nonMedDays.count >= 2 {
            let medEff = medDays.compactMap { $0.kpis?.efficiency }
            let nonEff = nonMedDays.compactMap { $0.kpis?.efficiency }
            if !medEff.isEmpty && !nonEff.isEmpty {
                let medAvg = Double(medEff.reduce(0, +)) / Double(medEff.count)
                let nonAvg = Double(nonEff.reduce(0, +)) / Double(nonEff.count)
                let diff = medAvg - nonAvg
                if abs(diff) >= 3 {
                    let direction = diff > 0 ? "higher" : "lower"
                    cards.append(InsightCard(
                        category: .pattern,
                        title: "Meditation Effect",
                        body: "On days you meditate, efficiency averages \(String(format: "%.0f", medAvg)) vs \(String(format: "%.0f", nonAvg)) without (\(direction) by \(String(format: "%.0f", abs(diff))) pts)",
                        icon: "leaf.arrow.circlepath",
                        severity: diff > 0 ? .positive : .neutral
                    ))
                }
            }
        }

        // ── Day-of-week patterns ──
        var weekdayEff: [Int: [Int]] = [:]  // 1=Sun...7=Sat
        for entry in entries {
            let wd = calendar.component(.weekday, from: entry.date)
            if let eff = entry.kpis?.efficiency {
                weekdayEff[wd, default: []].append(eff)
            }
        }
        let weekdayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let weekdayAvgs: [(String, Double)] = weekdayEff.compactMap { wd, values in
            guard values.count >= 2 else { return nil }
            let avg = Double(values.reduce(0, +)) / Double(values.count)
            return (weekdayNames[wd], avg)
        }.sorted { $0.1 > $1.1 }

        if let best = weekdayAvgs.first, let worst = weekdayAvgs.last, best.0 != worst.0 {
            let spread = best.1 - worst.1
            if spread >= 10 {
                cards.append(InsightCard(
                    category: .pattern,
                    title: "Best & Worst Days",
                    body: "\(best.0) is your strongest day (avg \(String(format: "%.0f", best.1)) efficiency). \(worst.0) is the weakest (avg \(String(format: "%.0f", worst.1))) — a \(String(format: "%.0f", spread))-point spread.",
                    icon: "calendar",
                    severity: .neutral
                ))
            }
        }

        // ── Diet patterns ──
        let junkDays = entries.filter { $0.breakfast == .junk || $0.lunch == .junk || $0.dinner == .junk }
        let healthyDays = entries.filter {
            ($0.breakfast == .healthy || $0.breakfast == .standard) &&
            ($0.lunch == .healthy || $0.lunch == .standard) &&
            ($0.dinner == .healthy || $0.dinner == .standard)
        }
        if junkDays.count >= 2 && healthyDays.count >= 2 {
            let junkTDI = junkDays.compactMap { $0.kpis?.tdi }
            let healthyTDI = healthyDays.compactMap { $0.kpis?.tdi }
            if !junkTDI.isEmpty && !healthyTDI.isEmpty {
                let junkAvg = Double(junkTDI.reduce(0, +)) / Double(junkTDI.count)
                let healthyAvg = Double(healthyTDI.reduce(0, +)) / Double(healthyTDI.count)
                if healthyAvg > junkAvg + 5 {
                    cards.append(InsightCard(
                        category: .pattern,
                        title: "Diet Impact",
                        body: "Clean-eating days average \(String(format: "%.0f", healthyAvg)) TDI vs \(String(format: "%.0f", junkAvg)) on junk-food days.",
                        icon: "fork.knife",
                        severity: .neutral
                    ))
                }
            }
        }

        return cards
    }

    // MARK: - 4. Anomaly Detection

    nonisolated private func computeAnomalies(entries: [Entry]) -> [InsightCard] {
        var cards: [InsightCard] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE M/d"

        // Check each metric for outlier days (>2 std dev from mean)
        let anomalyChecks: [(String, (Entry) -> Double?, String, String)] = [
            ("Efficiency", { $0.kpis.map { Double($0.efficiency) } }, "Low efficiency", "High efficiency"),
            ("Social Media", { Optional(Double($0.socialMins)) }, "Low social media", "Spike in social media"),
            ("Reading", { Optional(Double($0.readingPages)) }, "Low reading", "High reading volume"),
            ("Sleep", { Optional($0.sleepHours) }, "Short sleep", "Long sleep"),
        ]

        for (metric, extract, lowLabel, highLabel) in anomalyChecks {
            let pairs = entries.compactMap { entry -> (Entry, Double)? in
                guard let value = extract(entry), value > 0 else { return nil }
                return (entry, value)
            }
            guard pairs.count >= 4 else { continue }

            let values = pairs.map { $0.1 }
            let mean = values.reduce(0, +) / Double(values.count)
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
            let stdDev = sqrt(variance)
            guard stdDev > 0 else { continue }

            // Find most extreme outlier (highest z-score)
            var bestOutlier: (Entry, Double, Double)? = nil  // (entry, value, zScore)
            for (entry, value) in pairs {
                let z = abs(value - mean) / stdDev
                if z > 2.0 {
                    if bestOutlier == nil || z > bestOutlier!.2 {
                        bestOutlier = (entry, value, z)
                    }
                }
            }

            if let (entry, value, _) = bestOutlier {
                let label = value > mean ? highLabel : lowLabel
                let dateStr = formatter.string(from: entry.date)
                cards.append(InsightCard(
                    category: .anomaly,
                    title: "\(label) Anomaly",
                    body: "\(dateStr): \(metric) was \(String(format: "%.0f", value))\(unit(for: metric)) (avg: \(String(format: "%.0f", mean))\(unit(for: metric)))",
                    icon: "exclamationmark.triangle",
                    severity: value > mean
                        ? (metric == "Social Media" ? .warning : .positive)
                        : .warning
                ))
            }
        }

        return cards
    }

    // MARK: - 5. Week-over-Week Comparisons

    nonisolated private func computeComparisons(thisWeek: [Entry], lastWeek: [Entry]) -> [InsightCard] {
        var cards: [InsightCard] = []

        let metrics: [(String, (Entry) -> Double, String)] = [
            ("Efficiency", { Double($0.kpis?.efficiency ?? 0) }, "gauge.with.needle"),
            ("TDI", { Double($0.kpis?.tdi ?? 0) }, "checklist"),
            ("Reading", { Double($0.readingPages) }, "book"),
            ("Sleep", { $0.sleepHours }, "bed.double"),
            ("Social Media", { Double($0.socialMins) }, "iphone"),
        ]

        for (name, extract, icon) in metrics {
            let curVals = thisWeek.map(extract)
            let prevVals = lastWeek.map(extract)
            let curAvg = curVals.reduce(0, +) / Double(max(curVals.count, 1))
            let prevAvg = prevVals.reduce(0, +) / Double(max(prevVals.count, 1))
            guard prevAvg > 0 || curAvg > 0 else { continue }

            let curStr = String(format: "%.0f", curAvg) + unit(for: name)
            let prevStr = String(format: "%.0f", prevAvg) + unit(for: name)

            let change: Double
            let arrow: String
            if prevAvg > 0 {
                change = ((curAvg - prevAvg) / prevAvg) * 100.0
            } else {
                change = curAvg > 0 ? 100 : 0
            }
            arrow = change > 0 ? "▲" : change < 0 ? "▼" : "—"

            let isSocial = name == "Social Media"
            let goodDir = isSocial ? change < 0 : change > 0
            let severity: InsightCard.Severity = abs(change) < 3 ? .neutral : (goodDir ? .positive : .negative)

            cards.append(InsightCard(
                category: .comparison,
                title: name,
                body: "\(curStr) \(arrow) \(String(format: "%+.0f", change))% | Last week: \(prevStr)",
                icon: icon,
                severity: severity
            ))
        }

        return cards
    }

    // MARK: - Helpers

    nonisolated private func unit(for metric: String) -> String {
        switch metric {
        case "Sleep Hours", "Sleep": return "h"
        case "Social Media (min)", "Social Media": return "m"
        case "Reading Pages", "Reading": return "p"
        default: return "%"
        }
    }
}
