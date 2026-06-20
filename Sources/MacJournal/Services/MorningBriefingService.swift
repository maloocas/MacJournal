import Foundation

// MARK: - Morning Briefing Service

/// Gathers data, constructs an LLM prompt, calls DeepSeek API, parses the response.
/// Designed for extensibility: add new providers by extending the switch in endpoint/headers.
@MainActor
class MorningBriefingService: ObservableObject {

    // MARK: - Public API

    /// Generate a morning briefing from the full dataset.
    /// - Parameters:
    ///   - entries: All daily tracking entries
    ///   - journalEntries: All journal reflections
    ///   - config: App configuration (targets, weights)
    ///   - llmConfig: LLM provider settings
    /// - Returns: A MorningBriefing with suggestions + guidance
    /// - Throws: MorningBriefingError on failure
    func generate(
        entries: [Entry],
        journalEntries: [JournalEntry],
        config: AppConfig,
        llmConfig: LLMConfig
    ) async throws -> MorningBriefing {
        // 1. Get API key
        let apiKey = llmConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw MorningBriefingError.missingAPIKey("API key not set — add your DeepSeek API key in Settings")
        }

        // 2. Build the prompt
        let prompt = buildPrompt(entries: entries, journalEntries: journalEntries, config: config)

        // 3. Call the LLM
        let rawResponse = try await callLLM(prompt: prompt, apiKey: apiKey, config: llmConfig)

        // 4. Parse response
        return parseResponse(rawResponse, model: llmConfig.model)
    }

    // MARK: - Prompt Construction

    private func buildPrompt(entries: [Entry], journalEntries: [JournalEntry], config: AppConfig) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = dayOfWeekString(from: today)

        // Last 7 days of entries (sorted chronologically)
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return ""
        }
        let recentEntries = entries
            .filter { calendar.startOfDay(for: $0.date) >= sevenDaysAgo && calendar.startOfDay(for: $0.date) < today }
            .sorted { $0.date < $1.date }

        // Last 7 days of journal entries
        let recentJournals = journalEntries
            .filter { calendar.startOfDay(for: $0.date) >= sevenDaysAgo && calendar.startOfDay(for: $0.date) < today }
            .sorted { $0.date < $1.date }

        // Build the prompt sections
        var prompt = "You are a personal performance coach analyzing a student's daily tracking data. "
        prompt += "Be direct, specific, and encouraging. Reference actual numbers from the data. "
        prompt += "Today is \(dayOfWeek).\n\n"

        // ── Journal Entries ──
        if !recentJournals.isEmpty {
            prompt += "RECENT JOURNAL ENTRIES:\n"
            let df = DateFormatter()
            df.dateFormat = "EEE M/d"
            for entry in recentJournals {
                prompt += "\(df.string(from: entry.date)): \"\(entry.text)\"\n"
            }
            prompt += "\n"
        }

        // ── Daily Tracking Data (yes/no emphasis) ──
        prompt += "WEEKLY TRACKING DATA (last 7 days):\n\n"
        let df = DateFormatter()
        df.dateFormat = "EEE M/d"

        for entry in recentEntries {
            let sleepInRange = entry.sleepHours >= config.sleepMin && entry.sleepHours <= config.sleepMax
            let sleepBelowThreshold = entry.sleepHours < config.sleepPenaltyThreshold
            let readingMet = entry.readingPages >= config.readingTarget
            let hadJunk = entry.breakfast == .junk || entry.lunch == .junk || entry.dinner == .junk
            let allClean = (entry.breakfast == .healthy || entry.breakfast == .standard) &&
                           (entry.lunch == .healthy || entry.lunch == .standard) &&
                           (entry.dinner == .healthy || entry.dinner == .standard)
            let hasTasks = entry.proTotal + entry.perTotal > 0
            let allTasksDone = hasTasks && entry.proDone == entry.proTotal && entry.perDone == entry.perTotal

            prompt += "\(df.string(from: entry.date)):\n"
            prompt += "  Sleep: \(String(format: "%.1f", entry.sleepHours))h — "
            if sleepBelowThreshold {
                prompt += "BELOW THRESHOLD (<\(String(format: "%.0f", config.sleepPenaltyThreshold))h) ⚠️\n"
            } else if sleepInRange {
                prompt += "in range ✓\n"
            } else {
                prompt += "out of range\n"
            }
            prompt += "  Social media: \(entry.socialMins) min\n"
            prompt += "  Diet: breakfast=\(dietLabel(entry.breakfast)), lunch=\(dietLabel(entry.lunch)), dinner=\(dietLabel(entry.dinner))"
            if hadJunk { prompt += " — JUNK FOOD DAY ⚠️" }
            if allClean { prompt += " — clean day ✓" }
            prompt += "\n"
            prompt += "  Tasks: pro \(entry.proDone)/\(entry.proTotal), per \(entry.perDone)/\(entry.perTotal)"
            if !hasTasks { prompt += " — NO TASKS SET ⚠️" }
            else if allTasksDone { prompt += " — all done ✓"}
            prompt += "\n"
            prompt += "  Reading: \(entry.readingPages) pgs"
            if readingMet { prompt += " — hit target ✓" } else if config.readingTarget > 0 { prompt += " — below \(config.readingTarget) target" }
            prompt += "\n"
            prompt += "  Meditated: \(entry.meditated ? "YES ✓" : "NO")\n"
            prompt += "  Efficiency: \(entry.kpis?.efficiency ?? 0)/100, TDI: \(entry.kpis?.tdi ?? 0)/100\n\n"
        }

        // ── Aggregate Statistics ──
        if !recentEntries.isEmpty {
            let count = recentEntries.count
            let avgSleep = recentEntries.map(\.sleepHours).reduce(0, +) / Double(count)
            let avgSocial = Double(recentEntries.map(\.socialMins).reduce(0, +)) / Double(count)
            let avgReading = Double(recentEntries.map(\.readingPages).reduce(0, +)) / Double(count)
            let avgEff = Double(recentEntries.compactMap { $0.kpis?.efficiency }.reduce(0, +)) / Double(count)
            let avgTDI = Double(recentEntries.compactMap { $0.kpis?.tdi }.reduce(0, +)) / Double(count)
            let medDays = recentEntries.filter(\.meditated).count
            let sleepOkDays = recentEntries.filter { $0.sleepHours >= config.sleepMin && $0.sleepHours <= config.sleepMax }.count
            let readingHitDays = recentEntries.filter { $0.readingPages >= config.readingTarget }.count
            let junkDays = recentEntries.filter { $0.breakfast == .junk || $0.lunch == .junk || $0.dinner == .junk }.count
            let zeroTaskDays = recentEntries.filter { $0.proTotal + $0.perTotal == 0 }.count
            let allDoneDays = recentEntries.filter {
                let has = $0.proTotal + $0.perTotal > 0
                return has && $0.proDone == $0.proTotal && $0.perDone == $0.perTotal
            }.count

            prompt += "7-DAY SUMMARY:\n"
            prompt += "  Avg sleep: \(String(format: "%.1f", avgSleep))h | In range: \(sleepOkDays)/\(count) days\n"
            prompt += "  Avg social media: \(String(format: "%.0f", avgSocial)) min/day\n"
            prompt += "  Meditation: \(medDays)/\(count) days\n"
            prompt += "  Reading target (\u{2265}\(config.readingTarget)pgs): \(readingHitDays)/\(count) days\n"
            prompt += "  Avg reading: \(String(format: "%.0f", avgReading)) pgs/day\n"
            prompt += "  Junk food days: \(junkDays)/\(count)\n"
            prompt += "  Days with zero tasks set: \(zeroTaskDays)/\(count)\n"
            prompt += "  Days all tasks completed: \(allDoneDays)/\(count)\n"
            prompt += "  Avg efficiency: \(String(format: "%.0f", avgEff))/100 | Avg TDI: \(String(format: "%.0f", avgTDI))/100\n"
            prompt += "\n"
        }

        // ── Patterns (from InsightsEngine, reused as structured context) ──
        let engine = InsightsEngine()
        let report = engine.generate(from: entries, config: config)
        if !report.cards.isEmpty {
            prompt += "DETECTED PATTERNS:\n"
            for card in report.cards {
                prompt += "  [\(card.category.rawValue)] \(card.title): \(card.body)\n"
            }
            prompt += "\n"
        }

        // ── Instructions ──
        prompt += "Based on all of the above, provide your analysis in two sections.\n\n"
        prompt += "SECTION 1 — SUGGESTIONS: 3-5 specific, actionable recommendations for today. "
        prompt += "Each on its own line starting with \"• \". Reference actual data points.\n\n"
        prompt += "SECTION 2 — GUIDANCE: A 3-5 sentence motivational paragraph that ties the data together "
        prompt += "into a focused direction for today. Be warm but direct.\n\n"
        prompt += "Format your ENTIRE response exactly like this (no other text):\n"
        prompt += "---SUGGESTIONS---\n"
        prompt += "• [suggestion 1]\n"
        prompt += "• [suggestion 2]\n"
        prompt += "---GUIDANCE---\n"
        prompt += "[guidance paragraph]"

        return prompt
    }

    // MARK: - LLM API Call

    private func callLLM(prompt: String, apiKey: String, config: LLMConfig) async throws -> String {
        let (endpoint, headers) = providerDetails(for: config.provider, apiKey: apiKey)

        guard let url = URL(string: endpoint) else {
            throw MorningBriefingError.invalidEndpoint
        }

        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MorningBriefingError.networkError("Invalid response")
        }

        if httpResponse.statusCode == 401 {
            throw MorningBriefingError.invalidAPIKey
        }
        if httpResponse.statusCode == 429 {
            throw MorningBriefingError.rateLimited
        }
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MorningBriefingError.networkError("HTTP \(httpResponse.statusCode): \(body)")
        }

        // Parse OpenAI-compatible response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw MorningBriefingError.parseError("Could not parse LLM response")
        }

        return content
    }

    // MARK: - Response Parsing

    private func parseResponse(_ raw: String, model: String) -> MorningBriefing {
        var suggestions: [String] = []
        var guidance = ""

        // Split on markers
        if let suggStart = raw.range(of: "---SUGGESTIONS---"),
           let guidStart = raw.range(of: "---GUIDANCE---") {

            let suggBlock = String(raw[suggStart.upperBound..<guidStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guidance = String(raw[guidStart.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Parse bullet suggestions
            for line in suggBlock.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                    let cleaned = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                    if !cleaned.isEmpty {
                        suggestions.append(cleaned)
                    }
                }
            }
        } else {
            // Fallback: if markers are missing, use the whole response as guidance
            guidance = raw.trimmingCharacters(in: .whitespacesAndNewlines)

            // Try to extract bullet points
            for line in raw.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                    let cleaned = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                    if !cleaned.isEmpty {
                        suggestions.append(cleaned)
                    }
                }
            }
        }

        return MorningBriefing(
            suggestions: suggestions,
            guidance: guidance,
            generatedAt: Date(),
            modelUsed: model
        )
    }

    // MARK: - Provider Configuration

    /// Maps a provider to its endpoint and headers. Extend this switch to add new providers.
    private func providerDetails(for provider: LLMProvider, apiKey: String) -> (endpoint: String, headers: [String: String]) {
        switch provider {
        case .deepseek:
            return (
                endpoint: "https://api.deepseek.com/v1/chat/completions",
                headers: [
                    "Authorization": "Bearer \(apiKey)"
                ]
            )
        // Future providers:
        // case .openai:
        //     return (endpoint: "https://api.openai.com/v1/chat/completions",
        //             headers: ["Authorization": "Bearer \(apiKey)"])
        // case .anthropic:
        //     return (endpoint: "https://api.anthropic.com/v1/messages",
        //             headers: ["x-api-key": apiKey, "anthropic-version": "2023-06-01"])
        // case .ollama:
        //     return (endpoint: "http://localhost:11434/v1/chat/completions",
        //             headers: [:])
        }
    }

    // MARK: - Helpers

    private func dayOfWeekString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: date)
    }

    private func dietLabel(_ category: DietCategory) -> String {
        switch category {
        case .healthy: return "healthy"
        case .fancy: return "fancy"
        case .standard: return "standard"
        case .junk: return "JUNK"
        case .skipped: return "SKIPPED"
        }
    }
}

// MARK: - Errors

enum MorningBriefingError: Error, LocalizedError {
    case missingAPIKey(String)
    case invalidEndpoint
    case networkError(String)
    case invalidAPIKey
    case rateLimited
    case parseError(String)
    case noInternet

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let msg): return msg
        case .invalidEndpoint: return "Invalid API endpoint"
        case .networkError(let detail): return "Network error: \(detail)"
        case .invalidAPIKey: return "Invalid API key — check your secrets.json"
        case .rateLimited: return "Rate limited — try again in a moment"
        case .parseError(let detail): return "Failed to parse response: \(detail)"
        case .noInternet: return "No internet connection"
        }
    }
}
