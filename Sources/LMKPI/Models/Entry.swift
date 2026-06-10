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
    var proExec: Double
    var perExec: Double
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
    var proTotal: Int
    var proDone: Int
    var perTotal: Int
    var perDone: Int
    var readingPages: Int
    var meditated: Bool
    var kpis: KPIs?

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
         proTotal: Int, proDone: Int, perTotal: Int, perDone: Int,
         readingPages: Int, meditated: Bool) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.socialMins = socialMins
        self.breakfast = breakfast
        self.lunch = lunch
        self.dinner = dinner
        self.proTotal = proTotal
        self.proDone = proDone
        self.perTotal = perTotal
        self.perDone = perDone
        self.readingPages = readingPages
        self.meditated = meditated
        self.kpis = nil
    }

    mutating func computeKPIs(config: AppConfig) {
        let totalTasks = proTotal + perTotal
        let completedTasks = proDone + perDone
        let tdi = totalTasks > 0 ? (Double(completedTasks) / Double(totalTasks)) * 100.0 : 0.0

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

        let productiveOutput = Double(completedTasks * 10) + Double(readingPages)
        let focusRatio = productiveOutput / (Double(socialMins) + 1.0)

        let sleepMetric = sleepHours >= config.sleepMin ? 100.0 : (sleepHours / config.sleepMin) * 100.0
        let readingScore = min(100.0, (Double(readingPages) / Double(config.readingTarget)) * 100.0)
        let proExec = proTotal > 0 ? (Double(proDone) / Double(proTotal)) * 100.0 : 0.0
        let perExec = perTotal > 0 ? (Double(perDone) / Double(perTotal)) * 100.0 : 0.0

        self.kpis = KPIs(
            tdi: Int(round(tdi)),
            efficiency: Int(round(efficiency)),
            focusRatio: focusRatio,
            sleepMetric: sleepMetric,
            readingScore: Int(round(readingScore)),
            proExec: proExec,
            perExec: perExec
        )
    }
}
