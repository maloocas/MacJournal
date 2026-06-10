import SwiftUI

// MARK: - Settings Tab

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var readingTarget: Int = 50
    @State private var socialWeight: Double = 0.25
    @State private var sleepMin: Double = 7.0
    @State private var sleepMax: Double = 9.0
    @State private var sleepPenalty: Double = 6.0

    @State private var showAlert = false
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "System Configuration")

                VStack(alignment: .leading, spacing: 24) {
                    // Targets
                    SectionBox(title: "Academic & Behavioral Targets") {
                        HStack(spacing: 18) {
                            FormField(label: "Reading Target (Pages)") {
                                TextField("50", value: $readingTarget, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(themeManager.colors.textPrimary)
                                    .font(.system(size: 14))
                            }
                            FormField(label: "Social Weight (Penalty)") {
                                TextField("0.25", value: $socialWeight, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                        }
                    }

                    // Sleep
                    SectionBox(title: "Sleep Optimization (Hours)") {
                        HStack(spacing: 18) {
                            FormField(label: "Target Minimum") {
                                TextField("7", value: $sleepMin, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(themeManager.colors.textPrimary)
                                    .font(.system(size: 14))
                            }
                            FormField(label: "Target Maximum") {
                                TextField("9", value: $sleepMax, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(themeManager.colors.textPrimary)
                                    .font(.system(size: 14))
                            }
                            FormField(label: "Penalty Threshold (<)") {
                                TextField("6", value: $sleepPenalty, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                        }
                    }

                    Button(action: saveConfig) {
                        Text("Update Configuration")
                            .font(.system(size: 13, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.colors.accent)
                            .foregroundColor(themeManager.colors.background)
                    }
                    .buttonStyle(.plain)
                    .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.accent, lineWidth: 1))
                }
                .padding(18)
                .background(themeManager.colors.card)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(themeManager.colors.border))
                .padding(.horizontal)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showContent = true
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
        .onAppear { loadConfig() }
        .alert("System Configuration Updated", isPresented: $showAlert) {
            Button("OK") {}
        }
    }

    private func loadConfig() {
        readingTarget = store.config.readingTarget
        socialWeight = store.config.socialWeight
        sleepMin = store.config.sleepMin
        sleepMax = store.config.sleepMax
        sleepPenalty = store.config.sleepPenaltyThreshold
    }

    private func saveConfig() {
        let newConfig = AppConfig(
            readingTarget: max(1, readingTarget),
            socialWeight: max(0, socialWeight),
            sleepMin: max(0, sleepMin),
            sleepMax: max(sleepMin, sleepMax),
            sleepPenaltyThreshold: max(0, min(sleepPenalty, sleepMin))
        )
        store.updateConfig(newConfig)
        showAlert = true
    }
}
