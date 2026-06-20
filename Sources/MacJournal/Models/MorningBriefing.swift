import Foundation

// MARK: - Morning Briefing Result

/// The structured output from an LLM-generated morning briefing.
/// Persisted in AppData so it survives app restarts.
struct MorningBriefing: Codable, Identifiable, Equatable {
    var id: UUID
    var suggestions: [String]       // 3–5 bullet-point action items
    var guidance: String            // 3–5 sentence narrative paragraph
    var generatedAt: Date
    var modelUsed: String

    init(id: UUID = UUID(),
         suggestions: [String],
         guidance: String,
         generatedAt: Date = Date(),
         modelUsed: String = "") {
        self.id = id
        self.suggestions = suggestions
        self.guidance = guidance
        self.generatedAt = generatedAt
        self.modelUsed = modelUsed
    }

    // MARK: - Codable resilience

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        suggestions = try container.decodeIfPresent([String].self, forKey: .suggestions) ?? []
        guidance = try container.decodeIfPresent(String.self, forKey: .guidance) ?? ""
        generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
        modelUsed = try container.decodeIfPresent(String.self, forKey: .modelUsed) ?? ""
    }

    var isEmpty: Bool {
        suggestions.isEmpty && guidance.isEmpty
    }
}
