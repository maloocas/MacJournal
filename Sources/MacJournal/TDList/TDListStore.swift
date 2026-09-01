import Foundation

// MARK: - [TDList] DataStore extension
//
// All TD List feature mutations live here so the feature is removable
// by deleting the TDList/ folder. See TDListFeature.swift for the
// full removal checklist.

extension DataStore {

    // MARK: - TD Checkoff Tracking

    func recordCheckoffEvent(itemText: String, section: String, action: TDCheckoffEvent.Action) {
        guard config.tdCheckoffTracking else { return }
        let event = TDCheckoffEvent(
            itemText: itemText,
            section: section,
            action: action,
            timestamp: Date()
        )
        tdCheckoffEvents.append(event)
        save()
    }

    // MARK: - Checklist Items (Local)

    func toggleChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].isChecked.toggle()
        updateTodayFromChecklist()
        let newChecked = checklistItems[index].isChecked
        let action: TDCheckoffEvent.Action = newChecked ? .checked : .unchecked
        recordCheckoffEvent(itemText: item.text, section: item.section.rawValue, action: action)
        save()
    }

    func addChecklistItem(section: ChecklistItem.Section, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newItem = ChecklistItem(section: section, text: trimmed, isChecked: false)
        checklistItems.append(newItem)
        updateTodayFromChecklist()
        save()
    }

    func deleteChecklistItem(_ item: ChecklistItem) {
        checklistItems.removeAll { $0.id == item.id }
        updateTodayFromChecklist()
        save()
    }

    func updateChecklistItemText(_ item: ChecklistItem, newText: String) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        checklistItems[index].text = trimmed
        save()
    }

    /// Removes every checklist item. Today's entry stays in sync (counts drop to zero).
    func clearAllChecklistItems() {
        checklistItems.removeAll()
        updateTodayFromChecklist()
        save()
    }

    private func updateTodayFromChecklist() {
        let proItems = checklistItems.filter { $0.section == .professional }
        let perItems = checklistItems.filter { $0.section == .personal }
        let proDone = proItems.filter { $0.isChecked }.count
        let proTotal = proItems.count
        let perDone = perItems.filter { $0.isChecked }.count
        let perTotal = perItems.count

        let today = Date()
        if var existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existing.proTotal = proTotal
            existing.proDone = proDone
            existing.perTotal = perTotal
            existing.perDone = perDone
            addOrUpdate(entry: &existing)
        } else if !checklistItems.isEmpty {
            var newEntry = Entry(
                date: today,
                sleepHours: 7.0,
                socialMins: 0,
                breakfast: .standard,
                lunch: .standard,
                dinner: .standard,
                proTotal: proTotal,
                proDone: proDone,
                perTotal: perTotal,
                perDone: perDone,
                readingPages: 0,
                meditated: false
            )
            addOrUpdate(entry: &newEntry)
        }
    }

    // MARK: - Daily Goals (embedded in TD List views)

    var todayDailyGoals: [DailyGoal] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        return dailyGoals.filter { cal.startOfDay(for: $0.date) == todayStart }
    }

    func addDailyGoal(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard todayDailyGoals.count < DailyGoal.maxPerDay else { return }
        let goal = DailyGoal(text: trimmed)
        dailyGoals.append(goal)
        save()
    }

    func toggleDailyGoal(id: UUID) {
        guard let index = dailyGoals.firstIndex(where: { $0.id == id }) else { return }
        dailyGoals[index].isChecked.toggle()
        save()
    }

    func deleteDailyGoal(id: UUID) {
        dailyGoals.removeAll { $0.id == id }
        save()
    }

    func updateDailyGoalText(id: UUID, text: String) {
        guard let index = dailyGoals.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        dailyGoals[index].text = trimmed
        save()
    }
}
