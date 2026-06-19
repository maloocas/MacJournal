import Foundation

// MARK: - Insight Card Model

struct InsightCard: Identifiable {
    let id = UUID()

    enum Category: String, CaseIterable {
        case trend = "Trend"
        case goal = "Goal Attainment"
        case pattern = "Pattern"
        case anomaly = "Anomaly"
        case comparison = "Week-over-Week"
    }

    enum Severity {
        case positive   // green / accent — good news
        case negative   // red / warning — needs attention
        case neutral    // gray — informational
        case warning    // amber — something to watch
    }

    let category: Category
    let title: String
    let body: String
    let icon: String         // SF Symbol name
    let severity: Severity
}

// MARK: - Insights Report

struct InsightsReport {
    let generatedAt: Date
    let periodStart: Date
    let periodEnd: Date
    let cards: [InsightCard]

    var isEmpty: Bool { cards.isEmpty }
}

// MARK: - Helper: Week-over-Week Delta

struct MetricDelta {
    let metric: String
    let currentAvg: Double
    let previousAvg: Double
    let percentChange: Double   // e.g. +12.5 or -8.3
}
