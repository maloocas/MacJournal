import Foundation

// MARK: - Journal Entry (100–200 word daily reflections)

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var text: String

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var displayDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }

    init(id: UUID = UUID(), date: Date, text: String) {
        self.id = id
        self.date = date
        self.text = text
    }
}
