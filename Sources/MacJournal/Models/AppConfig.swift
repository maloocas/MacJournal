import Foundation

// MARK: - Application Configuration

struct AppConfig: Codable {
    var readingTarget: Int = 50
    var socialWeight: Double = 0.25
    var sleepMin: Double = 7.0
    var sleepMax: Double = 9.0
    var sleepPenaltyThreshold: Double = 6.0
    var tdCheckoffTracking: Bool = false
    var llmConfig: LLMConfig = LLMConfig()

    init(readingTarget: Int = 50,
         socialWeight: Double = 0.25,
         sleepMin: Double = 7.0,
         sleepMax: Double = 9.0,
         sleepPenaltyThreshold: Double = 6.0,
         tdCheckoffTracking: Bool = false,
         llmConfig: LLMConfig = LLMConfig()) {
        self.readingTarget = readingTarget
        self.socialWeight = socialWeight
        self.sleepMin = sleepMin
        self.sleepMax = sleepMax
        self.sleepPenaltyThreshold = sleepPenaltyThreshold
        self.tdCheckoffTracking = tdCheckoffTracking
        self.llmConfig = llmConfig
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        readingTarget = try container.decodeIfPresent(Int.self, forKey: .readingTarget) ?? 50
        socialWeight = try container.decodeIfPresent(Double.self, forKey: .socialWeight) ?? 0.25
        sleepMin = try container.decodeIfPresent(Double.self, forKey: .sleepMin) ?? 7.0
        sleepMax = try container.decodeIfPresent(Double.self, forKey: .sleepMax) ?? 9.0
        sleepPenaltyThreshold = try container.decodeIfPresent(Double.self, forKey: .sleepPenaltyThreshold) ?? 6.0
        tdCheckoffTracking = try container.decodeIfPresent(Bool.self, forKey: .tdCheckoffTracking) ?? false
        llmConfig = try container.decodeIfPresent(LLMConfig.self, forKey: .llmConfig) ?? LLMConfig()
    }
}

// MARK: - Persisted Data Container

struct AppData: Codable {
    var entries: [Entry]
    var config: AppConfig
    var journalEntries: [JournalEntry]?
    var tdCheckoffEvents: [TDCheckoffEvent]?
    var morningBriefing: MorningBriefing?

    init(entries: [Entry], config: AppConfig, journalEntries: [JournalEntry]? = nil, tdCheckoffEvents: [TDCheckoffEvent]? = nil, morningBriefing: MorningBriefing? = nil) {
        self.entries = entries
        self.config = config
        self.journalEntries = journalEntries
        self.tdCheckoffEvents = tdCheckoffEvents
        self.morningBriefing = morningBriefing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decode([Entry].self, forKey: .entries)
        config = try container.decode(AppConfig.self, forKey: .config)
        journalEntries = try container.decodeIfPresent([JournalEntry].self, forKey: .journalEntries)
        // Silently drop corrupted checkoff events — never let them sink the entire load
        tdCheckoffEvents = (try? container.decodeIfPresent([TDCheckoffEvent].self, forKey: .tdCheckoffEvents)) ?? nil
        // Silently drop corrupted briefing — never let it sink the entire load
        morningBriefing = (try? container.decodeIfPresent(MorningBriefing.self, forKey: .morningBriefing)) ?? nil
    }
}
