import Foundation

// MARK: - TD Checkoff Tracking Event

/// Records a single check-off or uncheck event from the TD List.
/// Persisted alongside entries so checkoff timestamps survive across sessions.
struct TDCheckoffEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let itemText: String
    let section: String          // "Professional" or "Personal & Academic"
    let action: Action           // checked or unchecked
    let timestamp: Date

    enum Action: String, Codable {
        case checked
        case unchecked
    }

    init(id: UUID = UUID(),
         itemText: String,
         section: String,
         action: Action,
         timestamp: Date = Date()) {
        self.id = id
        self.itemText = itemText
        self.section = section
        self.action = action
        self.timestamp = timestamp
    }
}
