import Foundation

struct TrapShootingSet: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var totalScore: Int
    var notes: String
    var weather: WeatherCondition
    var windSpeed: Int?
    var temperature: Double?
    var timeOfDay: String
    var totalShooters: Int
    var gunUsed: String?
    var ammoUsed: String?
    var isCompetition: Bool
    var location: String?

    var hitRate: Double {
        Double(totalScore) / 25.0 * 100.0
    }

    init(
        date: Date = Date(),
        totalScore: Int = 0,
        notes: String = "",
        weather: WeatherCondition = .sunny,
        windSpeed: Int? = nil,
        temperature: Double? = nil,
        timeOfDay: String = "",
        totalShooters: Int = 1,
        gunUsed: String? = nil,
        ammoUsed: String? = nil,
        isCompetition: Bool = false,
        location: String? = nil
    ) {
        self.date = date
        self.totalScore = min(25, max(0, totalScore))
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.weather = weather
        self.windSpeed = windSpeed
        self.temperature = temperature
        self.timeOfDay = timeOfDay
        self.totalShooters = min(6, max(1, totalShooters))
        self.gunUsed = gunUsed?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.ammoUsed = ammoUsed?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isCompetition = isCompetition
        self.location = location?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum WeatherCondition: String, Codable, CaseIterable {
        case sunny
        case partlyCloudy
        case cloudy
        case overcast
        case rainy
        case windy
        case foggy
        case indoor

        var label: String {
            switch self {
            case .sunny: return "Sunny"
            case .partlyCloudy: return "Partly Cloudy"
            case .cloudy: return "Cloudy"
            case .overcast: return "Overcast"
            case .rainy: return "Rainy"
            case .windy: return "Windy"
            case .foggy: return "Foggy"
            case .indoor: return "Indoor"
            }
        }

        var icon: String {
            switch self {
            case .sunny: return "sun.max.fill"
            case .partlyCloudy: return "cloud.sun.fill"
            case .cloudy: return "cloud.fill"
            case .overcast: return "smoke.fill"
            case .rainy: return "cloud.rain.fill"
            case .windy: return "wind"
            case .foggy: return "cloud.fog.fill"
            case .indoor: return "house.fill"
            }
        }
    }
}

struct TrapAnalysis: Codable, Equatable {
    var suggestions: [String]
    var guidance: String
    var generatedAt: Date
    var modelUsed: String
}
