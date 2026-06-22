import SwiftUI
import Charts

// MARK: - Hourly Checkoff Distribution Chart

/// Bar chart showing the distribution of TD check-off events across hours of the day.
/// Only counts "checked" events (not unchecked), fills zero for hours with no activity.
struct HourlyCheckoffChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    let events: [TDCheckoffEvent]

    struct HourlyBucket: Identifiable {
        let id = UUID()
        let hour: Int
        let label: String
        let count: Int
    }

    private let hourLabels = ["12a","1a","2a","3a","4a","5a","6a","7a","8a","9a","10a","11a",
                               "12p","1p","2p","3p","4p","5p","6p","7p","8p","9p","10p","11p"]

    private var hourlyData: [HourlyBucket] {
        let calendar = Calendar.current
        var counts = [Int](repeating: 0, count: 24)

        for event in events where event.action == .checked {
            let hour = calendar.component(.hour, from: event.timestamp)
            counts[hour] += 1
        }

        return (0..<24).map { hour in
            HourlyBucket(hour: hour, label: hourLabels[hour], count: counts[hour])
        }
    }

    private var totalCheckoffs: Int {
        hourlyData.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title + total
            HStack {
                Text("Check-Off Hourly Distribution")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.colors.textPrimary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer()

                Text("\(totalCheckoffs) total")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
            }
            .padding(.horizontal)

            if totalCheckoffs == 0 {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.colors.textMuted)
                    Text("No check-off data yet.\nEnable tracking in Settings and check items on the TD List.")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart(hourlyData) { bucket in
                    BarMark(
                        x: .value("Hour", bucket.hour),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(
                        bucket.hour >= 6 && bucket.hour < 18
                            ? themeManager.colors.accent
                            : themeManager.colors.accentDim
                    )
                    .cornerRadius(2)
                }
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                        AxisValueLabel {
                            if let hour = value.as(Int.self), hour >= 0, hour < 24 {
                                Text(hourLabels[hour])
                                    .font(.system(size: 9))
                                    .foregroundStyle(themeManager.colors.textSecondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisGridLine().foregroundStyle(themeManager.colors.chartGrid)
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(themeManager.colors.textSecondary)
                    }
                }
                .chartPlotStyle { $0.background(.clear) }
                .frame(height: 200)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 14)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
