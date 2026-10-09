import Foundation

// MARK: - Checklist Item Model

struct ChecklistItem: Identifiable, Equatable, Codable {
    enum Priority: String, CaseIterable, Codable, Hashable {
        case p0 = "P0"
        case p1 = "P1"
        case p2 = "P2"
        case p3 = "P3"
        case p4 = "P4"
        case upcoming = "Upcoming"

        static let progressCases: [Priority] = [.p0, .p1, .p2, .p3, .p4]

        var title: String {
            self == .p3 ? "Meetings" : (self == .p4 ? "Daily" : rawValue)
        }
    }

    let id: UUID
    var priority: Priority
    var text: String
    var isChecked: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case priority
        case text
        case isChecked
    }

    init(id: UUID = UUID(), priority: Priority = .p1, text: String, isChecked: Bool = false) {
        self.id = id
        self.priority = priority
        self.text = text
        self.isChecked = isChecked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .p1
        text = try container.decode(String.self, forKey: .text)
        isChecked = try container.decode(Bool.self, forKey: .isChecked)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(priority, forKey: .priority)
        try container.encode(text, forKey: .text)
        try container.encode(isChecked, forKey: .isChecked)
    }
}

struct TDListCounts: Equatable {
    let totalItems: Int
    let completedItems: Int

    init(items: [ChecklistItem]) {
        var totalItems = 0
        var completedItems = 0
        for item in items where item.priority != .upcoming {
            totalItems += 1
            if item.isChecked {
                completedItems += 1
            }
        }
        self.totalItems = totalItems
        self.completedItems = completedItems
    }
}
