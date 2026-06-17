import Foundation
import AppKit

// MARK: - Data Store (JSON-based persistence)

@MainActor
class DataStore: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var config: AppConfig = AppConfig()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let maxBackups = 20

    static let shared = DataStore()

    private var dataURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = supportDir.appendingPathComponent("LMKPI", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("data.json")
    }

    private var backupsDir: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = supportDir.appendingPathComponent("LMKPI/Backups", isDirectory: true)
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
        sortEntries()
        sortJournal()
        recalculateAllKPIs()
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
        let appData = AppData(entries: entries, config: config, journalEntries: journalEntries)
        guard let data = try? encoder.encode(appData) else { return }
        // Atomic write: write to temp, then rename
        let tempURL = dataURL.deletingLastPathComponent().appendingPathComponent("data.json.tmp")
        try? data.write(to: tempURL, options: .atomic)
        try? FileManager.default.replaceItemAt(dataURL, withItemAt: tempURL)

        // Auto-backup: timestamped copy in Backups/
        writeBackup(data: data)
    }

    // MARK: - Automatic Backups

    private func writeBackup(data: Data) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        let stamp = df.string(from: Date())
        let backupURL = backupsDir.appendingPathComponent("lmkpi_backup_\(stamp).json")
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
            .filter { $0.lastPathComponent.hasPrefix("lmkpi_backup_") && $0.pathExtension == "json" }
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
            panel.title = "Export LMKPI Data"
            panel.nameFieldStringValue = "LMKPI_export.json"
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
            panel.title = "Export LMKPI Data as CSV"
            panel.nameFieldStringValue = "LMKPI_export.csv"
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
}
