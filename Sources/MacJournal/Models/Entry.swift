import Foundation

// MARK: - Diet Categories

enum DietCategory: String, Codable, CaseIterable {
    case healthy = "Healthy Meal"
    case fancy = "Fancy Meal"
    case standard = "Quick/Standard"
    case junk = "Junk Food"
    case skipped = "Skipped"
}

// MARK: - KPI Results

struct KPIs: Codable {
    var tdi: Int           // Tasks Done Index (0-100)
    var efficiency: Int    // Efficiency Score (0-100)
    var focusRatio: Double // Productivity / (socialMins + 1)
    var sleepMetric: Double
    var readingScore: Int
    var taskExecution: Double

    private enum CodingKeys: String, CodingKey {
        case tdi
        case efficiency
        case focusRatio
        case sleepMetric
        case readingScore
        case taskExecution
    }

    init(tdi: Int, efficiency: Int, focusRatio: Double, sleepMetric: Double, readingScore: Int, taskExecution: Double) {
        self.tdi = tdi
        self.efficiency = efficiency
        self.focusRatio = focusRatio
        self.sleepMetric = sleepMetric
        self.readingScore = readingScore
        self.taskExecution = taskExecution
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tdi = try container.decode(Int.self, forKey: .tdi)
        efficiency = try container.decode(Int.self, forKey: .efficiency)
        focusRatio = try container.decode(Double.self, forKey: .focusRatio)
        sleepMetric = try container.decode(Double.self, forKey: .sleepMetric)
        readingScore = try container.decode(Int.self, forKey: .readingScore)
        if let taskExecution = try container.decodeIfPresent(Double.self, forKey: .taskExecution) {
            self.taskExecution = taskExecution
        } else {
            self.taskExecution = Double(tdi)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tdi, forKey: .tdi)
        try container.encode(efficiency, forKey: .efficiency)
        try container.encode(focusRatio, forKey: .focusRatio)
        try container.encode(sleepMetric, forKey: .sleepMetric)
        try container.encode(readingScore, forKey: .readingScore)
        try container.encode(taskExecution, forKey: .taskExecution)
    }
}

// MARK: - Daily Entry

struct Entry: Identifiable, Codable {
    var id: UUID
    var date: Date
    var sleepHours: Double
    var socialMins: Int
    var breakfast: DietCategory
    var lunch: DietCategory
    var dinner: DietCategory
    var totalItems: Int
    var completedItems: Int
    var readingPages: Int
    var meditated: Bool
    var kpis: KPIs?

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case sleepHours
        case socialMins
        case breakfast
        case lunch
        case dinner
        case totalItems
        case completedItems
        case proTotal
        case proDone
        case perTotal
        case perDone
        case readingPages
        case meditated
        case kpis
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var diet: [String] {
        [breakfast.rawValue, lunch.rawValue, dinner.rawValue]
    }

    init(id: UUID = UUID(), date: Date, sleepHours: Double, socialMins: Int,
         breakfast: DietCategory, lunch: DietCategory, dinner: DietCategory,
         totalItems: Int, completedItems: Int,
         readingPages: Int, meditated: Bool) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.socialMins = socialMins
        self.breakfast = breakfast
        self.lunch = lunch
        self.dinner = dinner
        self.totalItems = totalItems
        self.completedItems = completedItems
        self.readingPages = readingPages
        self.meditated = meditated
        self.kpis = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        sleepHours = try container.decode(Double.self, forKey: .sleepHours)
        socialMins = try container.decode(Int.self, forKey: .socialMins)
        breakfast = try container.decode(DietCategory.self, forKey: .breakfast)
        lunch = try container.decode(DietCategory.self, forKey: .lunch)
        dinner = try container.decode(DietCategory.self, forKey: .dinner)
        let legacyProTotal = try container.decodeIfPresent(Int.self, forKey: .proTotal) ?? 0
        let legacyProDone = try container.decodeIfPresent(Int.self, forKey: .proDone) ?? 0
        let legacyPerTotal = try container.decodeIfPresent(Int.self, forKey: .perTotal) ?? 0
        let legacyPerDone = try container.decodeIfPresent(Int.self, forKey: .perDone) ?? 0
        totalItems = try container.decodeIfPresent(Int.self, forKey: .totalItems) ?? legacyProTotal + legacyPerTotal
        completedItems = try container.decodeIfPresent(Int.self, forKey: .completedItems) ?? legacyProDone + legacyPerDone
        readingPages = try container.decode(Int.self, forKey: .readingPages)
        meditated = try container.decode(Bool.self, forKey: .meditated)
        kpis = try container.decodeIfPresent(KPIs.self, forKey: .kpis)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(sleepHours, forKey: .sleepHours)
        try container.encode(socialMins, forKey: .socialMins)
        try container.encode(breakfast, forKey: .breakfast)
        try container.encode(lunch, forKey: .lunch)
        try container.encode(dinner, forKey: .dinner)
        try container.encode(totalItems, forKey: .totalItems)
        try container.encode(completedItems, forKey: .completedItems)
        try container.encode(readingPages, forKey: .readingPages)
        try container.encode(meditated, forKey: .meditated)
        try container.encodeIfPresent(kpis, forKey: .kpis)
    }

    mutating func computeKPIs(config: AppConfig) {
        let tdi = totalItems > 0 ? (Double(completedItems) / Double(totalItems)) * 100.0 : 0.0

        var dietScore = 0.0
        for meal in [breakfast, lunch, dinner] {
            if meal == .healthy { dietScore += 5 }
            if meal == .junk || meal == .skipped { dietScore -= 5 }
        }

        var sleepScore = 0.0
        if sleepHours >= config.sleepMin && sleepHours <= config.sleepMax {
            sleepScore = 10.0
        } else if sleepHours < config.sleepPenaltyThreshold {
            sleepScore = -10.0
        }

        let readingContribution = min(Double(readingPages), Double(config.readingTarget)) * (20.0 / Double(config.readingTarget))
        var efficiency = 50.0 + (tdi * 0.3) + readingContribution + dietScore + sleepScore - (Double(socialMins) * config.socialWeight)
        efficiency = max(0, min(100, efficiency))

        let productiveOutput = Double(completedItems * 10) + Double(readingPages)
        let focusRatio = productiveOutput / (Double(socialMins) + 1.0)

        let sleepMetric = sleepHours >= config.sleepMin ? 100.0 : (sleepHours / config.sleepMin) * 100.0
        let readingScore = min(100.0, (Double(readingPages) / Double(config.readingTarget)) * 100.0)
        let taskExecution = totalItems > 0 ? (Double(completedItems) / Double(totalItems)) * 100.0 : 0.0

        self.kpis = KPIs(
            tdi: Int(round(tdi)),
            efficiency: Int(round(efficiency)),
            focusRatio: focusRatio,
            sleepMetric: sleepMetric,
            readingScore: Int(round(readingScore)),
            taskExecution: taskExecution
        )
    }
}
