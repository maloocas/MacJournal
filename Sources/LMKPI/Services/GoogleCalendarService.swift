import Foundation

// MARK: - Google Calendar Service

/// Fetches events from the user's primary Google Calendar.
/// Conforms to GoogleService for registration with the services manager.
@MainActor
final class GoogleCalendarService: ObservableObject, GoogleService {
    // MARK: - GoogleService conformance

    let name = "calendar"
    let displayName = "Calendar"
    let icon = "calendar"
    let requiredScopes = [GoogleScope.calendarReadonly.rawValue]
    var isEnabled: Bool = false

    // MARK: - Published State

    @Published var events: [GoogleCalendarEvent] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    // MARK: - Internal

    private weak var authManager: GoogleAuthManager?
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // MARK: - Configuration

    func configure(with auth: GoogleAuthManager) async throws {
        self.authManager = auth
        // Pre-fetch the current month on configure; surface errors
        do {
            _ = try await fetchEventsForCurrentMonth()
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Fetch Events

    /// Fetches events for a date range.
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [GoogleCalendarEvent] {
        guard let auth = authManager else {
            throw CalendarServiceError.notConfigured
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let token = try await auth.ensureValidAccessToken()

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "timeMax", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "250")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw CalendarServiceError.apiError(httpResponse.statusCode, body)
        }

        let decoder = JSONDecoder()
        let eventsResponse = try decoder.decode(GoogleEventsResponse.self, from: data)

        let parsed = eventsResponse.items.compactMap { item in
            item.toCalendarEvent(using: self.isoFormatter)
        }
        events = parsed
        return parsed
    }

    /// Convenience: fetch events for the current calendar month.
    func fetchEventsForCurrentMonth() async throws {
        let now = Date()
        let cal = Calendar.current
        guard let startOfMonth = cal.dateInterval(of: .month, for: now)?.start,
              let nextMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth) else {
            throw CalendarServiceError.invalidDateRange
        }
        _ = try await fetchEvents(from: startOfMonth, to: nextMonth)
    }

    /// Fetch events for a specific month.
    func fetchEventsForMonth(containing date: Date) async throws {
        let cal = Calendar.current
        guard let startOfMonth = cal.dateInterval(of: .month, for: date)?.start,
              let nextMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth) else {
            throw CalendarServiceError.invalidDateRange
        }
        _ = try await fetchEvents(from: startOfMonth, to: nextMonth)
    }

    /// Fetch events for a specific week.
    func fetchEventsForWeek(containing date: Date) async throws {
        let cal = Calendar.current
        guard let startOfWeek = cal.dateInterval(of: .weekOfYear, for: date)?.start,
              let endOfWeek = cal.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) else {
            throw CalendarServiceError.invalidDateRange
        }
        _ = try await fetchEvents(from: startOfWeek, to: endOfWeek)
    }
}

// MARK: - Errors

enum CalendarServiceError: Error, LocalizedError {
    case notConfigured
    case invalidDateRange
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Calendar service not configured — sign in first"
        case .invalidDateRange:
            return "Invalid date range"
        case .apiError(let code, let body):
            return "Calendar API error (\(code)): \(body)"
        }
    }
}
