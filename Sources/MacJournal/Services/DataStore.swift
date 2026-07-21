import Foundation
import AppKit

// MARK: - Data Store (JSON-based persistence)

@MainActor
class DataStore: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var config: AppConfig = AppConfig()
    @Published var tdCheckoffEvents: [TDCheckoffEvent] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var morningBriefing: MorningBriefing? = nil
    @Published var isGeneratingBriefing = false
    @Published var briefingError: String? = nil
    @Published var goals: [Goal] = []
    @Published var subscriptions: [Subscription] = []
    @Published var trapShootingSets: [TrapShootingSet] = []
    @Published var trapAnalysis: TrapAnalysis? = nil
    @Published var isGeneratingTrapAnalysis = false
    @Published var trapAnalysisError: String? = nil

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let maxBackups = 20

    static let shared = DataStore()

    private var dataURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = supportDir.appendingPathComponent("MacJournal", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("data.json")
    }

    private var backupsDir: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = supportDir.appendingPathComponent("MacJournal/Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        load()
    }

    // MARK: - Persistence

    func load() {
        guard let data = try? Data(contentsOf: dataURL),
              let appData = try? decoder.decode(AppData.self, from: data)
        else { return }
        entries = appData.entries
        journalEntries = appData.journalEntries ?? []
        config = appData.config
        tdCheckoffEvents = appData.tdCheckoffEvents ?? []
        checklistItems = appData.checklistItems ?? []
        morningBriefing = appData.morningBriefing
        goals = appData.goals ?? []
        subscriptions = appData.subscriptions ?? []
        sortEntries()
        sortJournal()
        trapShootingSets = appData.trapShootingSets ?? []
        trapAnalysis = appData.trapAnalysis
        sortTrapShootingSets()
        recalculateAllKPIs()
        ThemeManager.shared.applyAccent(config.accentColor)
    }

    func save() {
        sortEntries()
        recalculateAllKPIs()
        // Safety: never overwrite non-empty data with empty data
        let isFirstSave = !FileManager.default.fileExists(atPath: dataURL.path)
        if !isFirstSave {
            // Don't save if we somehow lost all entries — data is safe on disk
            if entries.isEmpty && journalEntries.isEmpty {
                return
            }
        }
        let appData = AppData(entries: entries, config: config, journalEntries: journalEntries, tdCheckoffEvents: tdCheckoffEvents, checklistItems: checklistItems, morningBriefing: morningBriefing, goals: goals, subscriptions: subscriptions, trapShootingSets: trapShootingSets, trapAnalysis: trapAnalysis)
        guard let data = try? encoder.encode(appData) else { return }
        // Atomic write: write to temp, then rename
        let tempURL = dataURL.deletingLastPathComponent().appendingPathComponent("data.json.tmp")
        try? data.write(to: tempURL, options: .atomic)
        _ = try? FileManager.default.replaceItemAt(dataURL, withItemAt: tempURL)

        // Auto-backup: timestamped copy in Backups/
        writeBackup(data: data)
    }

    // MARK: - Automatic Backups

    private func writeBackup(data: Data) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        let stamp = df.string(from: Date())
        let backupURL = backupsDir.appendingPathComponent("macjournal_backup_\(stamp).json")
        try? data.write(to: backupURL, options: .atomic)
        pruneBackups()
    }

    private func pruneBackups() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let sorted = files
            .filter { $0.lastPathComponent.hasPrefix("macjournal_backup_") && $0.pathExtension == "json" }
            .sorted { a, b -> Bool in
                let da = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return da > db
            }

        if sorted.count > maxBackups {
            for file in sorted[maxBackups...] {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // MARK: - Entry Operations

    func addOrUpdate(entry: inout Entry) {
        entry.computeKPIs(config: config)
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        save()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func updateConfig(_ newConfig: AppConfig) {
        config = newConfig
        recalculateAllKPIs()
        save()
    }

    // MARK: - TD Checkoff Tracking

    func recordCheckoffEvent(itemText: String, section: String, action: TDCheckoffEvent.Action) {
        guard config.tdCheckoffTracking else { return }
        let event = TDCheckoffEvent(
            itemText: itemText,
            section: section,
            action: action,
            timestamp: Date()
        )
        tdCheckoffEvents.append(event)
        save()
    }

    // MARK: - Checklist Items (Local)

    func toggleChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].isChecked.toggle()
        updateTodayFromChecklist()
        let newChecked = checklistItems[index].isChecked
        let action: TDCheckoffEvent.Action = newChecked ? .checked : .unchecked
        recordCheckoffEvent(itemText: item.text, section: item.section.rawValue, action: action)
        save()
    }

    func addChecklistItem(section: ChecklistItem.Section, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newItem = ChecklistItem(section: section, text: trimmed, isChecked: false)
        checklistItems.append(newItem)
        updateTodayFromChecklist()
        save()
    }

    func deleteChecklistItem(_ item: ChecklistItem) {
        checklistItems.removeAll { $0.id == item.id }
        updateTodayFromChecklist()
        save()
    }

    func updateChecklistItemText(_ item: ChecklistItem, newText: String) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        checklistItems[index].text = trimmed
        save()
    }

    private func updateTodayFromChecklist() {
        let proItems = checklistItems.filter { $0.section == .professional }
        let perItems = checklistItems.filter { $0.section == .personal }
        let proDone = proItems.filter { $0.isChecked }.count
        let proTotal = proItems.count
        let perDone = perItems.filter { $0.isChecked }.count
        let perTotal = perItems.count

        let today = Date()
        if var existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existing.proTotal = proTotal
            existing.proDone = proDone
            existing.perTotal = perTotal
            existing.perDone = perDone
            addOrUpdate(entry: &existing)
        } else if !checklistItems.isEmpty {
            var newEntry = Entry(
                date: today,
                sleepHours: 7.0,
                socialMins: 0,
                breakfast: .standard,
                lunch: .standard,
                dinner: .standard,
                proTotal: proTotal,
                proDone: proDone,
                perTotal: perTotal,
                perDone: perDone,
                readingPages: 0,
                meditated: false
            )
            addOrUpdate(entry: &newEntry)
        }
    }

    // MARK: - Goals

    func addGoal(text: String, dueDate: Date? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let goal = Goal(text: trimmed, dueDate: dueDate)
        goals.append(goal)
        save()
    }

    func updateGoal(id: UUID, text: String, dueDate: Date? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[idx].text = trimmed
        goals[idx].dueDate = dueDate
        save()
    }

    func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        save()
    }

    // MARK: - Subscriptions

    func addSubscription(name: String, amount: Double, billingCycle: BillingCycle, nextPaymentDate: Date, notes: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, amount > 0 else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let sub = Subscription(name: trimmedName, amount: amount, billingCycle: billingCycle, nextPaymentDate: nextPaymentDate, notes: trimmedNotes)
        subscriptions.append(sub)
        save()
    }

    func updateSubscription(id: UUID, name: String, amount: Double, billingCycle: BillingCycle, nextPaymentDate: Date, notes: String) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, amount > 0 else { return }
        subscriptions[idx].name = trimmedName
        subscriptions[idx].amount = amount
        subscriptions[idx].billingCycle = billingCycle
        subscriptions[idx].nextPaymentDate = nextPaymentDate
        subscriptions[idx].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deleteSubscription(id: UUID) {
        subscriptions.removeAll { $0.id == id }
        save()
    }

    // MARK: - Morning Briefing

    func generateBriefing() {
        guard config.llmConfig.morningBriefingEnabled else {
            briefingError = "Morning briefing is disabled in Settings"
            return
        }
        isGeneratingBriefing = true
        briefingError = nil
        Task {
            let service = MorningBriefingService()
            do {
                let briefing = try await service.generate(
                    entries: entries,
                    journalEntries: journalEntries,
                    config: config,
                    llmConfig: config.llmConfig
                )
                morningBriefing = briefing
                save()
            } catch {
                briefingError = error.localizedDescription
            }
            isGeneratingBriefing = false
        }
    }

    func clearBriefingError() {
        briefingError = nil
    }

    // MARK: - Journal Operations

    func addJournalEntry(date: Date, text: String) {
        // Trim and ensure non-empty
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Replace any existing entry for the same date
        journalEntries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        var entry = JournalEntry(date: date, text: trimmed)
        // Limit to ~200 words
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count > 200 {
            entry.text = words.prefix(200).joined(separator: " ")
        }
        journalEntries.append(entry)
        sortJournal()
        save()
    }

    func deleteJournalEntry(id: UUID) {
        journalEntries.removeAll { $0.id == id }
        save()
    }

    func journalEntry(for date: Date) -> JournalEntry? {
        journalEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func sortJournal() {
        journalEntries.sort { $0.date > $1.date }
    }

    // MARK: - Derived Data

    var latestEntry: Entry? {
        entries.first
    }

    var chronoEntries: [Entry] {
        entries.reversed()
    }

    // MARK: - Helpers

    private func sortEntries() {
        entries.sort { $0.date > $1.date }
    }

    private func recalculateAllKPIs() {
        for i in entries.indices {
            entries[i].computeKPIs(config: config)
        }
    }

    // MARK: - Import / Export

    func importJSON(url: URL) throws -> (imported: Int, skipped: Int) {
        let data = try Data(contentsOf: url)
        let container = try decoder.decode(AppData.self, from: data)

        var imported = 0
        var skipped = 0
        for entry in container.entries {
            let alreadyHas = entries.contains { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
            if alreadyHas {
                skipped += 1
            } else {
                var e = entry
                e.id = UUID()
                e.computeKPIs(config: config)
                entries.append(e)
                imported += 1
            }
        }
        save()
        return (imported, skipped)
    }

    func exportJSON(savePanel: Bool = true) -> URL? {
        let appData = AppData(entries: entries, config: config, journalEntries: journalEntries)
        guard let data = try? encoder.encode(appData) else { return nil }

        if savePanel {
            let panel = NSSavePanel()
            panel.title = "Export MacJournal Data"
            panel.nameFieldStringValue = "MacJournal_export.json"
            panel.allowedContentTypes = [.json]
            guard panel.runModal() == .OK, let url = panel.url else { return nil }
            try? data.write(to: url, options: .atomic)
            return url
        }
        return nil
    }

    func exportCSV(savePanel: Bool = true) -> URL? {
        var csvString = "Date,Sleep Hours,Social Mins,Breakfast,Lunch,Dinner,Professional Tasks Total,Professional Tasks Done,Personal Tasks Total,Personal Tasks Done,Reading Pages,Meditated,TDI,Efficiency,Focus Ratio,Sleep Metric,Reading Score,Professional Exec,Personal Exec\n"
        
        for entry in entries {
            // Escape values if needed, though most fields don't contain commas.
            let row = [
                entry.dateString,
                String(entry.sleepHours),
                String(entry.socialMins),
                entry.breakfast.rawValue.replacingOccurrences(of: ",", with: " "),
                entry.lunch.rawValue.replacingOccurrences(of: ",", with: " "),
                entry.dinner.rawValue.replacingOccurrences(of: ",", with: " "),
                String(entry.proTotal),
                String(entry.proDone),
                String(entry.perTotal),
                String(entry.perDone),
                String(entry.readingPages),
                String(entry.meditated),
                String(entry.kpis?.tdi ?? 0),
                String(entry.kpis?.efficiency ?? 0),
                String(format: "%.2f", entry.kpis?.focusRatio ?? 0.0),
                String(format: "%.2f", entry.kpis?.sleepMetric ?? 0.0),
                String(entry.kpis?.readingScore ?? 0),
                String(format: "%.2f", entry.kpis?.proExec ?? 0.0),
                String(format: "%.2f", entry.kpis?.perExec ?? 0.0)
            ].joined(separator: ",")
            csvString.append(row + "\n")
        }
        
        guard let data = csvString.data(using: .utf8) else { return nil }
        
        if savePanel {
            let panel = NSSavePanel()
            panel.title = "Export MacJournal Data as CSV"
            panel.nameFieldStringValue = "MacJournal_export.csv"
            panel.allowedContentTypes = [.commaSeparatedText]
            guard panel.runModal() == .OK, let url = panel.url else { return nil }
            try? data.write(to: url, options: .atomic)
            return url
        }
        return nil
    }

    /// Imports entries from a legacy JSON export (web app format).
    /// The web app stores entries as raw JSON with fields: id, date, sleepHours, socialMins,
    /// diet (array of strings), proTotal, proDone, perTotal, perDone, readingPages, meditated.
    func importLegacyJSON(url: URL) throws -> Int {
        let rawData = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: rawData) as? [[String: Any]] else {
            throw MigrationError.invalidFormat
        }

        var imported = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for raw in json {
            guard let dateStr = raw["date"] as? String,
                  let date = dateFormatter.date(from: dateStr)
            else { continue }

            // Skip if we already have this date
            if entries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                continue
            }

            let dietStrings = raw["diet"] as? [String] ?? ["Quick/Standard", "Quick/Standard", "Quick/Standard"]

            var entry = Entry(
                date: date,
                sleepHours: raw["sleepHours"] as? Double ?? 0,
                socialMins: raw["socialMins"] as? Int ?? 0,
                breakfast: DietCategory(rawValue: dietStrings.indices.contains(0) ? dietStrings[0] : "Quick/Standard") ?? .standard,
                lunch: DietCategory(rawValue: dietStrings.indices.contains(1) ? dietStrings[1] : "Quick/Standard") ?? .standard,
                dinner: DietCategory(rawValue: dietStrings.indices.contains(2) ? dietStrings[2] : "Quick/Standard") ?? .standard,
                proTotal: raw["proTotal"] as? Int ?? 0,
                proDone: raw["proDone"] as? Int ?? 0,
                perTotal: raw["perTotal"] as? Int ?? 0,
                perDone: raw["perDone"] as? Int ?? 0,
                readingPages: raw["readingPages"] as? Int ?? 0,
                meditated: raw["meditated"] as? Bool ?? false
            )
            entry.computeKPIs(config: config)
            entries.append(entry)
            imported += 1
        }
        save()
        return imported
    }

    enum MigrationError: Error, LocalizedError {
        case invalidFormat
        case invalidDate

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Invalid JSON format. Expected an array of entry objects."
            case .invalidDate: return "Invalid date format. Expected yyyy-MM-dd."
            }
        }
    }

    // MARK: - Trap Shooting

    func addTrapShootingSet(_ set: TrapShootingSet) {
        trapShootingSets.append(set)
        sortTrapShootingSets()
        save()
    }

    func updateTrapShootingSet(_ set: TrapShootingSet) {
        guard let idx = trapShootingSets.firstIndex(where: { $0.id == set.id }) else { return }
        trapShootingSets[idx] = set
        sortTrapShootingSets()
        save()
    }

    func deleteTrapShootingSet(_ set: TrapShootingSet) {
        trapShootingSets.removeAll { $0.id == set.id }
        save()
    }

    func deleteTrapShootingSet(id: UUID) {
        trapShootingSets.removeAll { $0.id == id }
        save()
    }

    private func sortTrapShootingSets() {
        trapShootingSets.sort { $0.date > $1.date }
    }

    // MARK: - Trap Shooting Analysis

    func generateTrapAnalysis() {
        guard config.llmConfig.morningBriefingEnabled else {
            trapAnalysisError = "LLM integration is disabled in Settings"
            return
        }
        isGeneratingTrapAnalysis = true
        trapAnalysisError = nil
        Task {
            let service = TrapAnalysisService()
            do {
                let analysis = try await service.generate(
                    sets: trapShootingSets,
                    llmConfig: config.llmConfig
                )
                trapAnalysis = analysis
                save()
            } catch {
                trapAnalysisError = error.localizedDescription
            }
            isGeneratingTrapAnalysis = false
        }
    }

    func clearTrapAnalysisError() {
        trapAnalysisError = nil
    }
}
