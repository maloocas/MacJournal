import Foundation

// MARK: - Screen Usage Session

struct ScreenUsageSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var start: Date
    var end: Date?

    var duration: TimeInterval {
        end?.timeIntervalSince(start) ?? Date().timeIntervalSince(start)
    }
}
