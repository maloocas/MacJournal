import Foundation

// MARK: - LLM Provider Configuration

/// Defines supported LLM providers. Add new cases here to support more APIs.
/// Each provider's endpoint + auth header is handled in MorningBriefingService.
enum LLMProvider: String, Codable, CaseIterable {
    case deepseek
    // Future: case openai
    // Future: case anthropic
    // Future: case ollama

    var displayName: String {
        switch self {
        case .deepseek: return "DeepSeek"
        }
    }

    var defaultModel: String {
        switch self {
        case .deepseek: return "deepseek-v4-flash"
        }
    }

    var availableModels: [(id: String, label: String)] {
        switch self {
        case .deepseek:
            return [
                ("deepseek-v4-flash", "DeepSeek-V4 Flash"),
                ("deepseek-v4-pro", "DeepSeek-V4 Pro"),
            ]
        }
    }
}

// MARK: - LLM Settings (persisted in AppConfig)

struct LLMConfig: Codable, Equatable {
    var provider: LLMProvider = .deepseek
    var model: String = LLMProvider.deepseek.defaultModel
    var apiKey: String = ""
    var morningBriefingEnabled: Bool = false

    init(provider: LLMProvider = .deepseek,
         model: String = LLMProvider.deepseek.defaultModel,
         apiKey: String = "",
         morningBriefingEnabled: Bool = false) {
        self.provider = provider
        self.model = model
        self.apiKey = apiKey
        self.morningBriefingEnabled = morningBriefingEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provider = try container.decodeIfPresent(LLMProvider.self, forKey: .provider) ?? .deepseek
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? provider.defaultModel
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        morningBriefingEnabled = try container.decodeIfPresent(Bool.self, forKey: .morningBriefingEnabled) ?? false
    }
}
