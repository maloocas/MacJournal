import SwiftUI

// MARK: - Daily Log Tab

struct DailyLogView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var logDate = Date()
    @State private var sleepHours: Double = 7.0
    @State private var socialMins: Int = 0
    @State private var breakfast: DietCategory = .standard
    @State private var lunch: DietCategory = .standard
    @State private var dinner: DietCategory = .standard
    @State private var proTotal: Int = 0
    @State private var proDone: Int = 0
    @State private var perTotal: Int = 0
    @State private var perDone: Int = 0
    @State private var readingPages: Int = 0
    @State private var meditated: Bool = false

    @State private var journalText: String = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showForm = false
    @State private var showRecent = false
    @State private var editingExisting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Daily Metric Log")

                // ── Entry Form ──
                VStack(alignment: .leading, spacing: 24) {
                    if editingExisting {
                        HStack {
                            Text("Editing entry for \(formattedDate(logDate))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.5))
                            Spacer()
                            Button("Discard") { resetForm() }
                                .font(.system(size: 10, weight: .medium))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundColor(themeManager.colors.accentDim)
                                .buttonStyle(.plain)
                        }
                    }

                    // Row 1: Date, Social, Sleep
                    HStack(spacing: 18) {
                        FormField(label: "Date") {
                            DatePicker("", selection: $logDate, displayedComponents: .date)
                                .datePickerStyle(.field)
                                .labelsHidden()
                                .foregroundColor(themeManager.colors.textPrimary)
                                .onChange(of: logDate) { _ in loadEntryForDate() }
                        }
                        FormField(label: "Social (mins)") {
                            TextField("0", value: $socialMins, format: .number)
                                .textFieldStyle(.plain)
                                .foregroundColor(themeManager.colors.textPrimary)
                        }
                        FormField(label: "Sleep (hrs)") {
                            HStack(spacing: 8) {
                                Slider(value: $sleepHours, in: 0...12, step: 0.5)
                                    .tint(themeManager.colors.accent)
                                Text(String(format: "%.1f", sleepHours))
                                    .foregroundColor(themeManager.colors.textPrimary)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 40)
                            }
                        }
                    }

                    // Dietary Intake
                    SectionBox(title: "Dietary Intake") {
                        HStack(spacing: 18) {
                            DietPicker(label: "Breakfast", selection: $breakfast)
                            DietPicker(label: "Lunch", selection: $lunch)
                            DietPicker(label: "Dinner", selection: $dinner)
                        }
                    }

                    // Professional Ops
                    SectionBox(title: "Professional Operations") {
                        HStack(spacing: 18) {
                            FormField(label: "Total Items") {
                                TextField("0", value: $proTotal, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(themeManager.colors.textPrimary)
                            }
                            FormField(label: "Completed") {
                                TextField("0", value: $proDone, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // Personal & Academic
                    SectionBox(title: "Personal & Academic") {
                        HStack(spacing: 18) {
                            FormField(label: "Total Items") {
                                TextField("0", value: $perTotal, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(themeManager.colors.textPrimary)
                            }
                            FormField(label: "Completed") {
                                TextField("0", value: $perDone, format: .number)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // Behavioral
                    SectionBox(title: "Behavioral Variables") {
                        HStack {
                            Toggle(isOn: $meditated) {
                                Text("Meditated Previous Night")
                                    .foregroundColor(themeManager.colors.textPrimary)
                                    .font(.system(size: 13))
                            }
                            .toggleStyle(.switch)
                            .tint(themeManager.colors.accent)
                        }
                    }

                    // Reading
                    FormField(label: "Reading Volume (Target: \\(store.config.readingTarget)p)") {
                        TextField("0", value: $readingPages, format: .number)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }

                    // Journal Reflection
                    SectionBox(title: "Journal Reflection") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Write a 100-200 word reflection on your day. It will appear on the Journal tab.")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(themeManager.colors.textMuted)
                            ZStack(alignment: .topLeading) {
                                if journalText.isEmpty {
                                    Text("What happened today? What are you thinking about?")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.colors.textMuted.opacity(0.6))
                                        .padding(10)
                                }
                                TextEditor(text: $journalText)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(themeManager.colors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(minHeight: 100, maxHeight: 200)
                                    .padding(2)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                            .background(themeManager.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack {
                                let count = journalText
                                    .components(separatedBy: .whitespacesAndNewlines)
                                    .filter { !$0.isEmpty }
                                    .count
                                Text("\\(count)/200 words")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(count > 200 ? .red : themeManager.colors.textMuted)
                                Spacer()
                                if store.journalEntry(for: logDate) != nil {
                                    Text("Has entry for this date")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(themeManager.colors.accentDim)
                                }
                            }
                        }
                    }

                    // Submit
                    Button(action: submitEntry) {
                        Text(editingExisting ? "Update Entry" : "Commit Log")
                            .font(.system(size: 13, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.colors.accent)
                            .foregroundColor(themeManager.colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: editingExisting ? 2 : 1))
                }
                .padding(18)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .opacity(showForm ? 1 : 0)
                .offset(y: showForm ? 0 : 10)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) { showForm = true }
                }

                // ── Recent Entries ──
                if !store.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showRecent.toggle() } }) {
                            HStack {
                                Text("Recent Entries (\(store.entries.count))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .textCase(.uppercase)
                                    .tracking(2)
                                Spacer()
                                Image(systemName: showRecent ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if showRecent {
                            Divider().overlay(themeManager.colors.border)

                            let recent = Array(store.entries.prefix(15))
                            ForEach(Array(recent.enumerated()), id: \.element.id) { i, entry in
                                let kpis = entry.kpis
                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.dateString)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(themeManager.colors.textPrimary)
                                        Text("Eff: \(kpis?.efficiency ?? 0)  ·  TDI: \(kpis?.tdi ?? 0)%")
                                            .font(.system(size: 10))
                                            .foregroundColor(themeManager.colors.textSecondary)
                                    }

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Button("Edit") {
                                            loadEntryIntoForm(entry)
                                        }
                                        .font(.system(size: 10, weight: .medium))
                                        .textCase(.uppercase)
                                        .tracking(1)
                                        .foregroundColor(themeManager.colors.accentDim)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(themeManager.colors.borderFaint)
                                        .buttonStyle(.plain)

                                        Button("DEL") {
                                            store.deleteEntry(id: entry.id)
                                        }
                                        .font(.system(size: 10, weight: .medium))
                                        .textCase(.uppercase)
                                        .tracking(1)
                                        .foregroundColor(themeManager.colors.textMuted)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(themeManager.colors.surface)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .overlay(alignment: .bottom) {
                                    themeManager.colors.borderFaint.frame(height: 1)
                                }
                            }

                            if store.entries.count > 15 {
                                HStack {
                                    Spacer()
                                    Text("Showing 15 of \(store.entries.count) entries")
                                        .font(.system(size: 10))
                                        .foregroundColor(themeManager.colors.textMuted)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .background(themeManager.colors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
        .alert(editingExisting ? "Entry Updated" : "Data Log Committed", isPresented: $showAlert) {
            Button("OK") { resetForm() }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Date helpers

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Load existing entry for the selected date

    private func loadEntryForDate() {
        if let existing = store.entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: logDate) }) {
            loadEntryIntoForm(existing)
        }
        // Load journal text for this date
        if let journal = store.journalEntry(for: logDate) {
            journalText = journal.text
        } else {
            journalText = ""
        }
    }

    private func loadEntryIntoForm(_ entry: Entry) {
        logDate = entry.date
        sleepHours = entry.sleepHours
        socialMins = entry.socialMins
        breakfast = entry.breakfast
        lunch = entry.lunch
        dinner = entry.dinner
        proTotal = entry.proTotal
        proDone = entry.proDone
        perTotal = entry.perTotal
        perDone = entry.perDone
        readingPages = entry.readingPages
        meditated = entry.meditated
        editingExisting = true
        // Load journal text
        if let journal = store.journalEntry(for: entry.date) {
            journalText = journal.text
        } else {
            journalText = ""
        }
    }

    // MARK: - Submit

    private func submitEntry() {
        var entry = Entry(
            date: logDate,
            sleepHours: sleepHours,
            socialMins: socialMins,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            proTotal: proTotal,
            proDone: proDone,
            perTotal: perTotal,
            perDone: perDone,
            readingPages: readingPages,
            meditated: meditated
        )
        store.addOrUpdate(entry: &entry)

        // Submit journal reflection if non-empty
        let trimmed = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.addJournalEntry(date: logDate, text: trimmed)
        }

        if let kpis = entry.kpis {
            alertMessage = "Efficiency: \(kpis.efficiency)/100 | TDI: \(kpis.tdi)%"
        } else {
            alertMessage = "Entry saved for \(entry.dateString)."
        }
        showAlert = true
    }

    private func resetForm() {
        logDate = Date()
        sleepHours = 7.0
        socialMins = 0
        breakfast = .standard
        lunch = .standard
        dinner = .standard
        proTotal = 0
        proDone = 0
        perTotal = 0
        perDone = 0
        readingPages = 0
        meditated = false
        journalText = ""
        editingExisting = false
    }
}

// MARK: - Reusable Form Components

struct FormField<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            content
                .padding(10)
                .background(themeManager.colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct SectionLabel: View {
    @EnvironmentObject var themeManager: ThemeManager
    let text: String
    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(themeManager.colors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.5)
            .padding(.bottom, 4)
    }
}

struct SectionBox<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title)
            content
        }
        .padding(18)
        .background(themeManager.colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(themeManager.colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct DietPicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    @Binding var selection: DietCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            Picker("", selection: $selection) {
                ForEach(DietCategory.allCases, id: \.self) { cat in
                    Text(catDisplay(cat)).tag(cat)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    private func catDisplay(_ cat: DietCategory) -> String {
        switch cat {
        case .healthy: return "Healthy Meal"
        case .fancy: return "Fancy Meal"
        case .standard: return "Quick/Standard"
        case .junk: return "Junk Food"
        case .skipped: return "Skipped"
        }
    }
}
