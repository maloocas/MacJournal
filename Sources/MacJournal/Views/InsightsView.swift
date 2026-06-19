import SwiftUI

// MARK: - Insights Tab

struct InsightsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var engine = InsightsEngine()
    @State private var report: InsightsReport?
    @State private var showCards = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(title: "Insights")

                if let report, !report.isEmpty {
                    // Group cards by category
                    let grouped = Dictionary(grouping: report.cards) { $0.category }

                    ForEach(InsightCard.Category.allCases, id: \.self) { category in
                        if let cards = grouped[category], !cards.isEmpty {
                            categorySection(category: category, cards: cards)
                        }
                    }

                    // Timestamp footer
                    HStack {
                        Spacer()
                        Text("Generated \(report.generatedAt, style: .relative) ago")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.colors.textMuted)
                        Text("No Insights Yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.colors.textSecondary)
                        Text("Log a few days of data to unlock patterns, trends, and goal tracking.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
        .onAppear {
            refresh()
        }
        .onChange(of: store.entries.count) { _ in
            refresh()
        }
    }

    // MARK: - Refresh

    private func refresh() {
        let newReport = engine.generate(from: store.entries, config: store.config)
        withAnimation(.easeInOut(duration: 0.3)) {
            report = newReport
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { showCards = true }
        }
    }

    // MARK: - Category Section

    private func categorySection(category: InsightCard.Category, cards: [InsightCard]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category label
            HStack(spacing: 8) {
                Rectangle()
                    .fill(severityColor(for: category))
                    .frame(width: 3, height: 14)
                Text(category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            .padding(.horizontal)

            // Cards
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                InsightCardView(card: card, severityColor: severityColor(for: card.category))
                    .padding(.horizontal)
                    .opacity(showCards ? 1 : 0)
                    .offset(y: showCards ? 0 : 8)
                    .animation(
                        .easeOut(duration: 0.2).delay(Double(index) * 0.04),
                        value: showCards
                    )
            }
        }
    }

    private func severityColor(for category: InsightCard.Category) -> Color {
        switch category {
        case .trend: return themeManager.colors.accent
        case .goal: return Color.green.opacity(0.7)
        case .pattern: return Color.purple.opacity(0.7)
        case .anomaly: return Color.orange.opacity(0.8)
        case .comparison: return themeManager.colors.accentDim
        }
    }
}

// MARK: - Insight Card

struct InsightCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let card: InsightCard
    let severityColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(severityColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: card.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(severityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Title + severity dot
                HStack(spacing: 6) {
                    Circle()
                        .fill(severityDotColor)
                        .frame(width: 6, height: 6)
                    Text(card.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.colors.textPrimary)
                }

                // Body
                Text(card.body)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(themeManager.colors.card)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(themeManager.colors.borderFaint, lineWidth: 1)
        )
    }

    private var severityDotColor: Color {
        switch card.severity {
        case .positive: return Color.green
        case .negative: return Color.red
        case .warning: return Color.orange
        case .neutral: return themeManager.colors.textMuted
        }
    }
}
