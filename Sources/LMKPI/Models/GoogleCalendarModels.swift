import Foundation

// MARK: - Google Calendar Event

struct GoogleCalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let description: String?
    let colorHex: String?
    let calendarName: String?

    /// The hour part for listing (e.g. "14:00" or "All Day")
    var timeDisplay: String {
        if isAllDay { return "All Day" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: startDate)
    }
}

// MARK: - API Response Types (raw JSON decoding)

/// JSON shape from GET /calendar/v3/calendars/primary/events
struct GoogleEventsResponse: Codable {
    let items: [GoogleEventItem]
}

struct GoogleEventItem: Codable {
    let id: String
    let summary: String?
    let start: GoogleEventTime?
    let end: GoogleEventTime?
    let location: String?
    let description: String?
    let colorId: String?

    struct GoogleEventTime: Codable {
        let date: String?       // yyyy-MM-dd (all-day)
        let dateTime: String?   // RFC 3339 (timed)
    }
}

// MARK: - Calendar List

struct GoogleCalendarListResponse: Codable {
    let items: [GoogleCalendarEntry]
}

struct GoogleCalendarEntry: Codable {
    let id: String
    let summary: String?
    let backgroundColor: String?
    let primary: Bool?
}

// MARK: - Conversion

extension GoogleEventItem {
    func toCalendarEvent(using parser: ISO8601DateFormatter) -> GoogleCalendarEvent? {
        guard let summaryText = summary, !summaryText.isEmpty else { return nil }

        let isAllDay: Bool
        let startDate: Date
        let endDate: Date

        if let dateStr = start?.date {
            // All-day event — dateStr is "yyyy-MM-dd"
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            guard let s = df.date(from: dateStr) else { return nil }
            startDate = s
            isAllDay = true
            if let endStr = end?.date, let e = df.date(from: endStr) {
                endDate = e
            } else {
                endDate = s
            }
        } else if let dateTimeStr = start?.dateTime {
            guard let s = parser.date(from: dateTimeStr) else { return nil }
            startDate = s
            isAllDay = false
            if let endStr = end?.dateTime, let e = parser.date(from: endStr) {
                endDate = e
            } else {
                endDate = s.addingTimeInterval(3600)
            }
        } else {
            return nil
        }

        return GoogleCalendarEvent(
            id: id,
            title: summaryText,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            description: description,
            colorHex: nil,  // colorId mapping can be added later
            calendarName: nil
        )
    }
}
