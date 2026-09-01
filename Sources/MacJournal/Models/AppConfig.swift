import Foundation

// MARK: - Application Configuration

struct AppConfig: Codable {
    var readingTarget: Int = 50
    var socialWeight: Double = 0.25
    var sleepMin: Double = 7.0
    var sleepMax: Double = 9.0
    var sleepPenaltyThreshold: Double = 6.0
    var tdCheckoffTracking: Bool = false // [TDList]
    var statsWindowDays: Int = 30
    var accentColor: String = "blue"
    var llmConfig: LLMConfig = LLMConfig()

    init(readingTarget: Int = 50,
         socialWeight: Double = 0.25,
         sleepMin: Double = 7.0,
         sleepMax: Double = 9.0,
         sleepPenaltyThreshold: Double = 6.0,
         tdCheckoffTracking: Bool = false, // [TDList]
         statsWindowDays: Int = 30,
         accentColor: String = "blue",
         llmConfig: LLMConfig = LLMConfig()) {
        self.readingTarget = readingTarget
        self.socialWeight = socialWeight
        self.sleepMin = sleepMin
        self.sleepMax = sleepMax
        self.sleepPenaltyThreshold = sleepPenaltyThreshold
        self.tdCheckoffTracking = tdCheckoffTracking // [TDList]
        self.statsWindowDays = statsWindowDays
        self.accentColor = accentColor
        self.llmConfig = llmConfig
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        readingTarget = try container.decodeIfPresent(Int.self, forKey: .readingTarget) ?? 50
        socialWeight = try container.decodeIfPresent(Double.self, forKey: .socialWeight) ?? 0.25
        sleepMin = try container.decodeIfPresent(Double.self, forKey: .sleepMin) ?? 7.0
        sleepMax = try container.decodeIfPresent(Double.self, forKey: .sleepMax) ?? 9.0
        sleepPenaltyThreshold = try container.decodeIfPresent(Double.self, forKey: .sleepPenaltyThreshold) ?? 6.0
        tdCheckoffTracking = try container.decodeIfPresent(Bool.self, forKey: .tdCheckoffTracking) ?? false // [TDList]
        statsWindowDays = try container.decodeIfPresent(Int.self, forKey: .statsWindowDays) ?? 30
        accentColor = try container.decodeIfPresent(String.self, forKey: .accentColor) ?? "blue"
        llmConfig = try container.decodeIfPresent(LLMConfig.self, forKey: .llmConfig) ?? LLMConfig()
    }
}

// MARK: - Persisted Data Container

struct AppData: Codable {
    var entries: [Entry]
    var config: AppConfig
    var journalEntries: [JournalEntry]?
    var tdCheckoffEvents: [TDCheckoffEvent]? // [TDList]
    var checklistItems: [ChecklistItem]?     // [TDList]
    var morningBriefing: MorningBriefing?
    var goals: [Goal]?
    var subscriptions: [Subscription]?
    var trapShootingSets: [TrapShootingSet]?
    var trapAnalysis: TrapAnalysis?

    var dailyGoals: [DailyGoal]? // [TDList]

    init(entries: [Entry], config: AppConfig, journalEntries: [JournalEntry]? = nil, tdCheckoffEvents: [TDCheckoffEvent]? = nil, checklistItems: [ChecklistItem]? = nil, morningBriefing: MorningBriefing? = nil, goals: [Goal]? = nil, subscriptions: [Subscription]? = nil, trapShootingSets: [TrapShootingSet]? = nil, trapAnalysis: TrapAnalysis? = nil, dailyGoals: [DailyGoal]? = nil) { // [TDList]
        self.entries = entries
        self.config = config
        self.journalEntries = journalEntries
        self.tdCheckoffEvents = tdCheckoffEvents // [TDList]
        self.checklistItems = checklistItems     // [TDList]
        self.morningBriefing = morningBriefing
        self.goals = goals
        self.subscriptions = subscriptions
        self.trapShootingSets = trapShootingSets
        self.trapAnalysis = trapAnalysis
        self.dailyGoals = dailyGoals // [TDList]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decode([Entry].self, forKey: .entries)
        config = try container.decode(AppConfig.self, forKey: .config)
        journalEntries = try container.decodeIfPresent([JournalEntry].self, forKey: .journalEntries)
        // Silently drop corrupted checkoff events — never let them sink the entire load
        tdCheckoffEvents = (try? container.decodeIfPresent([TDCheckoffEvent].self, forKey: .tdCheckoffEvents)) ?? nil // [TDList]
        // Silently drop corrupted checklist items — never let them sink the entire load
        checklistItems = (try? container.decodeIfPresent([ChecklistItem].self, forKey: .checklistItems)) ?? nil // [TDList]
        // Silently drop corrupted briefing — never let it sink the entire load
        morningBriefing = (try? container.decodeIfPresent(MorningBriefing.self, forKey: .morningBriefing)) ?? nil
        // Silently drop corrupted goals — never let them sink the entire load
        goals = (try? container.decodeIfPresent([Goal].self, forKey: .goals)) ?? nil
        // Silently drop corrupted subscriptions — never let them sink the entire load
        subscriptions = (try? container.decodeIfPresent([Subscription].self, forKey: .subscriptions)) ?? nil
        trapShootingSets = (try? container.decodeIfPresent([TrapShootingSet].self, forKey: .trapShootingSets)) ?? nil
        trapAnalysis = (try? container.decodeIfPresent(TrapAnalysis.self, forKey: .trapAnalysis)) ?? nil
        // Silently drop corrupted daily goals — never let them sink the entire load
        dailyGoals = (try? container.decodeIfPresent([DailyGoal].self, forKey: .dailyGoals)) ?? nil // [TDList]
    }
}
