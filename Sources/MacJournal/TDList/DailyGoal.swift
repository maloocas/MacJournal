import Foundation

struct DailyGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isChecked: Bool
    var date: Date

    static let maxPerDay = 5

    init(id: UUID = UUID(), text: String, isChecked: Bool = false, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
        self.date = date
    }
}
