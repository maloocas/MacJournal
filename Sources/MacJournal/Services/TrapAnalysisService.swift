import Foundation

@MainActor
class TrapAnalysisService: ObservableObject {

    func generate(
        sets: [TrapShootingSet],
        llmConfig: LLMConfig
    ) async throws -> TrapAnalysis {
        let apiKey = llmConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw MorningBriefingError.missingAPIKey("API key not set — add your DeepSeek API key in Settings")
        }

        let prompt = buildPrompt(sets: sets)
        let rawResponse = try await callLLM(prompt: prompt, apiKey: apiKey, config: llmConfig)
        return parseResponse(rawResponse, model: llmConfig.model)
    }

    private func buildPrompt(sets: [TrapShootingSet]) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = dayOfWeekString(from: today)

        let cutoff30 = calendar.date(byAdding: .day, value: -30, to: today)!
        let recentSets = sets
            .filter { calendar.startOfDay(for: $0.date) >= cutoff30 && calendar.startOfDay(for: $0.date) <= today }
            .sorted { $0.date > $1.date }

        let cutoff90 = calendar.date(byAdding: .day, value: -90, to: today)!
        let last90Sets = sets
            .filter { calendar.startOfDay(for: $0.date) >= cutoff90 && calendar.startOfDay(for: $0.date) <= today }

        guard !recentSets.isEmpty else {
            return "You are a trap shooting coach. The shooter has no recent data to analyze. Tell them to log some rounds first."
        }

        var prompt = "You are an expert trap shooting coach analyzing a shooter's performance data. "
        prompt += "Be direct, specific, and encouraging. Reference actual scores from the data. "
        prompt += "Focus on actionable improvement advice. Today is \(dayOfWeek).\n\n"

        let df = DateFormatter()
        df.dateFormat = "EEE M/d"

        prompt += "RECENT ROUNDS (last 30 days, newest first):\n"
        for set in recentSets {
            prompt += "\(df.string(from: set.date)): \(set.totalScore)/25 "
            prompt += "(\(String(format: "%.0f", set.hitRate))% hit rate) "
            prompt += "- Weather: \(set.weather.label)"
            if let wind = set.windSpeed { prompt += ", Wind: \(wind) mph" }
            if let temp = set.temperature { prompt += ", \(Int(temp))°F" }
            if !set.timeOfDay.isEmpty { prompt += ", \(set.timeOfDay)" }
            prompt += ", Squad: \(set.totalShooters)/6"
            if set.isCompetition { prompt += ", COMPETITION" }
            if !set.notes.isEmpty { prompt += "\n  Notes: \"\(set.notes)\"" }
            prompt += "\n"
        }

        if !last90Sets.isEmpty {
            let avg30 = Double(recentSets.map(\.totalScore).reduce(0, +)) / max(1, Double(recentSets.count))
            let avg90 = Double(last90Sets.map(\.totalScore).reduce(0, +)) / max(1, Double(last90Sets.count))
            let best30 = recentSets.map(\.totalScore).max() ?? 0

            prompt += "\n30-DAY SUMMARY:\n"
            prompt += "  Rounds shot: \(recentSets.count)\n"
            prompt += "  Average: \(String(format: "%.1f", avg30))/25 (\(String(format: "%.0f", avg30 / 25.0 * 100))%)\n"
            prompt += "  Best: \(best30)/25\n"
            if last90Sets.count > recentSets.count {
                prompt += "  90-day average: \(String(format: "%.1f", avg90))/25\n"
            }

            let weatherGroups = Dictionary(grouping: recentSets) { $0.weather }
            prompt += "\n  Weather breakdown:\n"
            for (weather, groupSet) in weatherGroups.sorted(by: { $0.key.label < $1.key.label }) {
                let avg = Double(groupSet.map(\.totalScore).reduce(0, +)) / Double(groupSet.count)
                prompt += "    \(weather.label): \(String(format: "%.1f", avg))/25 (\(groupSet.count) rounds)\n"
            }

            if let bestStreak = computeBestStreak(sets: recentSets) {
                prompt += "\n  Best 20+ streak: \(bestStreak) consecutive rounds\n"
            }
        }

        prompt += "\nBased on all of the above, provide your coaching analysis in two sections.\n\n"
        prompt += "SECTION 1 — SUGGESTIONS: 3-5 specific, actionable recommendations for the shooter's next session. "
        prompt += "Each on its own line starting with \"• \". Reference actual data points and patterns in the scores.\n\n"
        prompt += "SECTION 2 — GUIDANCE: A 3-5 sentence motivational coaching paragraph. Be encouraging but direct. "
        prompt += "Identify what's working well and what needs focus.\n\n"
        prompt += "Format your ENTIRE response exactly like this (no other text):\n"
        prompt += "---SUGGESTIONS---\n"
        prompt += "• [suggestion 1]\n"
        prompt += "• [suggestion 2]\n"
        prompt += "---GUIDANCE---\n"
        prompt += "[guidance paragraph]"

        return prompt
    }

    private func computeBestStreak(sets: [TrapShootingSet]) -> Int? {
        let sorted = sets.sorted { $0.date < $1.date }
        var best = 0
        var current = 0
        for set in sorted {
            if set.totalScore >= 20 {
                current += 1
                best = max(best, current)
            } else { current = 0 }
        }
        return best > 0 ? best : nil
    }

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

        if httpResponse.statusCode == 401 { throw MorningBriefingError.invalidAPIKey }
        if httpResponse.statusCode == 429 { throw MorningBriefingError.rateLimited }
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MorningBriefingError.networkError("HTTP \(httpResponse.statusCode): \(body)")
        }

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

    private func parseResponse(_ raw: String, model: String) -> TrapAnalysis {
        var suggestions: [String] = []
        var guidance = ""

        if let suggStart = raw.range(of: "---SUGGESTIONS---"),
           let guidStart = raw.range(of: "---GUIDANCE---") {
            let suggBlock = String(raw[suggStart.upperBound..<guidStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guidance = String(raw[guidStart.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            for line in suggBlock.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                    let cleaned = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                    if !cleaned.isEmpty { suggestions.append(cleaned) }
                }
            }
        } else {
            guidance = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            for line in raw.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                    let cleaned = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                    if !cleaned.isEmpty { suggestions.append(cleaned) }
                }
            }
        }

        return TrapAnalysis(
            suggestions: suggestions,
            guidance: guidance,
            generatedAt: Date(),
            modelUsed: model
        )
    }

    private func providerDetails(for provider: LLMProvider, apiKey: String) -> (endpoint: String, headers: [String: String]) {
        switch provider {
        case .deepseek:
            return (
                endpoint: "https://api.deepseek.com/v1/chat/completions",
                headers: ["Authorization": "Bearer \(apiKey)"]
            )
        }
    }

    private func dayOfWeekString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: date)
    }
}
