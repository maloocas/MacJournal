import SwiftUI

// MARK: - Not Spyware View

struct NotSpywareView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var tickTimer: Timer?

    private static let formatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropLeading
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeader(title: "Session Stats")

                // status card
                VStack(spacing: 8) {
                    Image(systemName: store.isScreenCurrentlyOn ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(store.isScreenCurrentlyOn ? .green : themeManager.colors.textMuted)

                    Text(store.isScreenCurrentlyOn ? "Screen is ON" : "Screen is OFF")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(store.isScreenCurrentlyOn ? .green : themeManager.colors.textSecondary)

                    if store.isScreenCurrentlyOn {
                        Text("Current session: \(timeString(store.currentSessionDuration))")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)

                // stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCard(label: "TODAY", value: timeString(store.todayScreenTime))
                    statCard(label: "THIS WEEK", value: timeString(store.weekScreenTime))
                    statCard(label: "THIS MONTH", value: timeString(store.monthScreenTime))
                    statCard(label: "ALL TIME", value: timeString(store.allTimeScreenTime))
                }
                .padding(.horizontal)

                // session count
                Text("\(store.screenUsageSessions.filter { $0.end != nil }.count) completed sessions logged")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.colors.textMuted)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
        .onAppear {
            tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                // trigger UI refresh for live "current session" counter
                // by posting a dummy change to an @Published var
                store.objectWillChange.send()
            }
        }
        .onDisappear {
            tickTimer?.invalidate()
            tickTimer = nil
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        Self.formatter.string(from: interval) ?? "0s"
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.colors.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundColor(themeManager.colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
