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

    @discardableResult
    func synchronizeTodayTaskCounts() -> Bool {
        let counts = TDListCounts(items: checklistItems)
        guard let index = entries.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) else {
            return false
        }
        guard entries[index].totalItems != counts.totalItems
                || entries[index].completedItems != counts.completedItems else {
            return false
        }
        entries[index].totalItems = counts.totalItems
        entries[index].completedItems = counts.completedItems
        return true
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].isChecked.toggle()
        if checklistItems[index].priority != .upcoming {
            synchronizeTodayTaskCounts()
        }
        let newChecked = checklistItems[index].isChecked
        let action: TDCheckoffEvent.Action = newChecked ? .checked : .unchecked
        recordCheckoffEvent(itemText: item.text, section: checklistItems[index].priority.rawValue, action: action)
        save()
    }

    func addChecklistItem(priority: ChecklistItem.Priority, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        checklistItems.append(ChecklistItem(priority: priority, text: trimmed))
        if priority != .upcoming {
            synchronizeTodayTaskCounts()
        }
        save()
    }

    @discardableResult
    func moveChecklistItem(id: UUID, to priority: ChecklistItem.Priority) -> Bool {
        guard let index = checklistItems.firstIndex(where: { $0.id == id }) else { return false }
        let oldPriority = checklistItems[index].priority
        guard oldPriority != priority else { return true }
        checklistItems[index].priority = priority
        if (oldPriority == .upcoming) != (priority == .upcoming) {
            synchronizeTodayTaskCounts()
        }
        save()
        return true
    }

    func deleteChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        let wasTracked = checklistItems[index].priority != .upcoming
        checklistItems.remove(at: index)
        if wasTracked {
            synchronizeTodayTaskCounts()
        }
        save()
    }

    func updateChecklistItemText(_ item: ChecklistItem, newText: String) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        checklistItems[index].text = trimmed
        save()
    }

    func clearChecklistItemsExceptDailyAndUpcoming() {
        let removedTrackedItems = checklistItems.contains { $0.priority != .p4 && $0.priority != .upcoming }
        checklistItems.removeAll { $0.priority != .p4 && $0.priority != .upcoming }
        if removedTrackedItems {
            synchronizeTodayTaskCounts()
        }
        save()
    }

    func uncheckAllChecklistItems() {
        let checkedItemIndices = checklistItems.indices.filter { checklistItems[$0].isChecked }
        guard !checkedItemIndices.isEmpty else { return }

        let hasTrackedCheckedItems = checkedItemIndices.contains { checklistItems[$0].priority != .upcoming }
        let timestamp = Date()
        for index in checkedItemIndices {
            let item = checklistItems[index]
            checklistItems[index].isChecked = false
            if config.tdCheckoffTracking {
                tdCheckoffEvents.append(TDCheckoffEvent(
                    itemText: item.text,
                    section: item.priority.rawValue,
                    action: .unchecked,
                    timestamp: timestamp
                ))
            }
        }
        if hasTrackedCheckedItems {
            synchronizeTodayTaskCounts()
        }
        save()
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
