import Foundation

// MARK: - Goal Model

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var dueDate: Date?
    var createdAt: Date = Date()

    init(id: UUID = UUID(), text: String, dueDate: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}
