import Foundation

// MARK: - Application Configuration

struct AppConfig: Codable {
    var readingTarget: Int = 50
    var socialWeight: Double = 0.25
    var sleepMin: Double = 7.0
    var sleepMax: Double = 9.0
    var sleepPenaltyThreshold: Double = 6.0
}

// MARK: - Persisted Data Container

struct AppData: Codable {
    var entries: [Entry]
    var config: AppConfig
    var journalEntries: [JournalEntry]?

    init(entries: [Entry], config: AppConfig, journalEntries: [JournalEntry]? = nil) {
        self.entries = entries
        self.config = config
        self.journalEntries = journalEntries
    }
}
