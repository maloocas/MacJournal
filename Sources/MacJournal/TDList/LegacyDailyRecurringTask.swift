import Foundation

struct LegacyDailyRecurringTask: Codable {
    let id: UUID
    var text: String
    var lastCompletedDate: Date?

    func migratedChecklistItem(on date: Date, calendar: Calendar = .current) -> ChecklistItem {
        let wasCheckedToday = lastCompletedDate.map {
            calendar.isDate($0, inSameDayAs: date)
        } ?? false
        return ChecklistItem(id: id, priority: .p4, text: text, isChecked: wasCheckedToday)
    }
}
