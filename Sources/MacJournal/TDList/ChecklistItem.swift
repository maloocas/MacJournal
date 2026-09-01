import Foundation

// MARK: - Checklist Item Model

struct ChecklistItem: Identifiable, Equatable, Codable {
    enum Section: String, Equatable, Codable {
        case professional = "Professional"
        case personal = "Personal & Academic"
    }

    let id: UUID
    var section: Section
    var text: String
    var isChecked: Bool

    init(id: UUID = UUID(), section: Section, text: String, isChecked: Bool = false) {
        self.id = id
        self.section = section
        self.text = text
        self.isChecked = isChecked
    }
}

// MARK: - Parsed Checklist Result (aggregate counts)

struct NotesChecklistResult: Codable {
    let proDone: Int
    let proTotal: Int
    let perDone: Int
    let perTotal: Int
    let rawText: String
    let errorMessage: String?
    let lastSync: Date

    var isEmpty: Bool { proTotal == 0 && perTotal == 0 }
    var proRatio: Double { proTotal > 0 ? Double(proDone) / Double(proTotal) : 0 }
    var perRatio: Double { perTotal > 0 ? Double(perDone) / Double(perTotal) : 0 }

    init(proDone: Int, proTotal: Int, perDone: Int, perTotal: Int, rawText: String, errorMessage: String?, lastSync: Date) {
        self.proDone = proDone
        self.proTotal = proTotal
        self.perDone = perDone
        self.perTotal = perTotal
        self.rawText = rawText
        self.errorMessage = errorMessage
        self.lastSync = lastSync
    }
}
