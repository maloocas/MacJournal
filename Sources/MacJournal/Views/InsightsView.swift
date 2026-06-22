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

                // ── Morning Briefing Section ──
                if store.config.llmConfig.morningBriefingEnabled {
                    briefingSection
                }

                // ── Existing Insight Cards ──
                if let report, !report.isEmpty {
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
                } else if store.morningBriefing == nil && !store.config.llmConfig.morningBriefingEnabled {
                    // Empty state (only show if there's no briefing either)
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

    // MARK: - Morning Briefing Section

    @ViewBuilder
    private var briefingSection: some View {
        if let briefing = store.morningBriefing, !store.isGeneratingBriefing {
            // Show cached briefing
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.orange)
                        Text("MORNING BRIEFING")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(themeManager.colors.textSecondary)
                    }

                    Spacer()

                    // Regenerate button
                    Button(action: { store.generateBriefing() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Refresh")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(themeManager.colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(themeManager.colors.accent.opacity(0.08))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isGeneratingBriefing)
                }
                .padding(.horizontal)

                // Guidance paragraph
                if !briefing.guidance.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(briefing.guidance)
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeManager.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(themeManager.colors.border, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: 3, height: 14)
                            .offset(x: -1.5, y: 16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal)
                }

                // Suggestions
                if !briefing.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TODAY'S FOCUS")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(briefing.suggestions.enumerated()), id: \.offset) { index, suggestion in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(themeManager.colors.accentDim)
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 4)

                                    Text(suggestion)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(index % 2 == 0 ? Color.clear : themeManager.colors.card.opacity(0.3))

                                if index < briefing.suggestions.count - 1 {
                                    themeManager.colors.sectionDivider
                                        .frame(height: 1)
                                        .padding(.leading, 35)
                                }
                            }
                        }
                .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                    }
                }

                // Meta line: timestamp + model
                HStack {
                    Text("Generated \(briefing.generatedAt, style: .relative) ago")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted)
                    if !briefing.modelUsed.isEmpty {
                        Text("· \(briefing.modelUsed)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Divider before cards
                themeManager.colors.sectionDivider
                    .frame(height: 1)
                    .padding(.horizontal)
            }
        } else if store.isGeneratingBriefing {
            // Loading state
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(themeManager.colors.accent)
                Text("Generating your morning briefing...")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else if let error = store.briefingError {
            // Error state
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.orange)
                    Text("MORNING BRIEFING")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                .padding(.horizontal)

                VStack(spacing: 10) {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Button(action: {
                            store.clearBriefingError()
                            store.generateBriefing()
                        }) {
                            Text("Retry")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(themeManager.colors.accent)
                        }
                        .buttonStyle(.plain)

                        Button(action: { store.clearBriefingError() }) {
                            Text("Dismiss")
                                .font(.system(size: 11))
                                .foregroundColor(themeManager.colors.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
            }
        } else {
            // No briefing yet — generate button
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sun.horizon")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.textMuted)
                    Text("MORNING BRIEFING")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(themeManager.colors.textSecondary)
                }

                Text("Get an AI-powered summary of your week with personalized suggestions for today.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                Button(action: { store.generateBriefing() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                        Text("Generate Briefing")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(themeManager.colors.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(themeManager.colors.accent)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
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
.background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
