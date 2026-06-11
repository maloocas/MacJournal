import Foundation
import AppKit

// MARK: - Checklist Item Model

struct ChecklistItem: Identifiable, Equatable {
    enum Section: String, Equatable {
        case professional = "Professional"
        case personal = "Personal & Academic"
    }

    let id: UUID
    var section: Section
    var text: String
    var isChecked: Bool

    init(id: UUID = UUID(), section: Section, text: String, isChecked: Bool = false) {
        self.id = id
        self.section = section
        self.text = text
        self.isChecked = isChecked
    }
}

// MARK: - Parsed Checklist Result (kept for the Notes tab)

struct NotesChecklistResult {
    let proDone: Int
    let proTotal: Int
    let perDone: Int
    let perTotal: Int
    let rawText: String
    let errorMessage: String?
    let lastSync: Date

    var isEmpty: Bool { proTotal == 0 && perTotal == 0 }
    var proRatio: Double { proTotal > 0 ? Double(proDone) / Double(proTotal) : 0 }
    var perRatio: Double { perTotal > 0 ? Double(perDone) / Double(perTotal) : 0 }
}

// MARK: - Notes Checklist Sync Service

@MainActor
class NotesChecklistService: ObservableObject {
    static let shared = NotesChecklistService()

    @Published var lastResult: NotesChecklistResult?
    @Published var isSyncing = false
    @Published var items: [ChecklistItem] = []

    private let noteName = "TD List"
    private let folderName = "Notes"

    private init() {}

    // MARK: - Public API

    /// Syncs counts only (for the Notes tab / auto-apply).
    func sync() async -> NotesChecklistResult {
        isSyncing = true
        defer { isSyncing = false }

        let plaintext = await runReadScript()
        let result = parseChecklist(from: plaintext)
        lastResult = result
        return result
    }

    /// Fetches the full structured checklist (for the interactive TD List tab).
    func fetchItems() async -> [ChecklistItem] {
        isSyncing = true
        defer { isSyncing = false }

        let plaintext = await runReadScript()
        let parsed = parseItems(from: plaintext)
        items = parsed
        // Also update lastResult for the Notes tab
        lastResult = parseChecklist(from: plaintext)
        return parsed
    }

    /// Saves the full item list back to the Notes app, then updates DataStore.
    func saveItems(_ newItems: [ChecklistItem], store: DataStore) async {
        items = newItems
        await runWriteScript(with: newItems)

        // Update lastResult
        let counts = computeCounts(from: newItems)
        lastResult = counts

        // Update today's entry in DataStore
        updateTodayEntry(with: counts, store: store)
    }

    /// Toggles a single item: toggles in memory, writes to Notes, updates DataStore.
    func toggleItem(_ item: ChecklistItem, store: DataStore) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isChecked.toggle()

        await runWriteScript(with: items)

        let counts = computeCounts(from: items)
        lastResult = counts
        updateTodayEntry(with: counts, store: store)
    }

    /// Adds a new item to the given section, writes to Notes, updates DataStore.
    func addItem(section: ChecklistItem.Section, text: String, store: DataStore) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newItem = ChecklistItem(section: section, text: trimmed, isChecked: false)
        items.append(newItem)

        await runWriteScript(with: items)

        let counts = computeCounts(from: items)
        lastResult = counts
        updateTodayEntry(with: counts, store: store)
    }

    /// Removes an item, writes to Notes, updates DataStore.
    func deleteItem(_ item: ChecklistItem, store: DataStore) async {
        items.removeAll { $0.id == item.id }

        await runWriteScript(with: items)

        let counts = computeCounts(from: items)
        lastResult = counts
        updateTodayEntry(with: counts, store: store)
    }

    /// Updates the text of an existing item, writes to Notes, updates DataStore.
    func updateItemText(_ item: ChecklistItem, newText: String, store: DataStore) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items[index].text = trimmed

        await runWriteScript(with: items)

        let counts = computeCounts(from: items)
        lastResult = counts
        updateTodayEntry(with: counts, store: store)
    }

    // MARK: - AppleScript: Read

    private func runReadScript() async -> String {
        let script = """
        tell application "Notes"
            set folderNotes to notes of folder "\(folderName)"
            repeat with n in folderNotes
                if name of n is "\(noteName)" then
                    return plaintext of n
                end if
            end repeat
            return ""
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }

    // MARK: - AppleScript: Write

    /// Rebuilds the entire note body from the item list.
    private func runWriteScript(with items: [ChecklistItem]) async {
        // Build the HTML body
        var html = "<div><h1>TD List</h1></div><div><br></div>"

        // Professional section
        html += "<div><b>Professional Items</b></div><div><br></div>"
        for item in items where item.section == .professional {
            let marker = item.isChecked ? "[x]" : "[ ]"
            let escapedText = item.text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            html += "<div>\(marker) \(escapedText)</div>"
        }

        html += "<div><br></div>"

        // Personal section
        html += "<div><b>Academic &amp; Personal</b></div><div><br></div>"
        for item in items where item.section == .personal {
            let marker = item.isChecked ? "[x]" : "[ ]"
            let escapedText = item.text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            html += "<div>\(marker) \(escapedText)</div>"
        }

        html += "<div><br></div>"
        html += "<div>Get ready for bed at 10:45</div>"
        html += "<div>Be in bed and sleep at 11</div>"

        // Escape for AppleScript string
        let escapedHtml = html
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            set folderNotes to notes of folder "\(folderName)"
            repeat with n in folderNotes
                if name of n is "\(noteName)" then
                    set body of n to "\(escapedHtml)"
                end if
            end repeat
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to write to Notes: \(error)")
        }
    }

    // MARK: - Parsing

    /// Parses plaintext into a list of ChecklistItem objects.
    private func parseItems(from text: String) -> [ChecklistItem] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var result: [ChecklistItem] = []
        var currentSection: ChecklistItem.Section = .professional

        for line in lines {
            let lower = line.lowercased()

            // Section detection
            if lower.contains("professional") || lower.contains("pro items") || lower.contains("pro list") {
                currentSection = .professional
                continue
            }
            if lower.contains("personal") || lower.contains("academic") || lower == "academic & personal" || lower.contains("per list") {
                currentSection = .personal
                continue
            }

            // Parse checkbox
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let checked = parseCheckbox(trimmed) else { continue }

            // Extract the text after the [x] or [ ]
            let textStart = trimmed.index(trimmed.startIndex, offsetBy: 3)
            let textAfterBracket = trimmed[textStart...].trimmingCharacters(in: .whitespaces)
            guard !textAfterBracket.isEmpty else { continue }

            result.append(ChecklistItem(
                section: currentSection,
                text: textAfterBracket,
                isChecked: checked
            ))
        }

        return result
    }

    /// Parses plaintext into aggregate counts (for the Notes tab).
    private func parseChecklist(from text: String) -> NotesChecklistResult {
        guard !text.isEmpty else {
            return NotesChecklistResult(
                proDone: 0, proTotal: 0,
                perDone: 0, perTotal: 0,
                rawText: text,
                errorMessage: "Could not read TD List note from Apple Notes.",
                lastSync: Date()
            )
        }

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var proDone = 0, proTotal = 0
        var perDone = 0, perTotal = 0

        enum Section { case unknown, professional, personal }
        var currentSection: Section = .unknown

        for line in lines {
            let lower = line.lowercased()

            if lower.contains("professional") || lower.contains("pro items") || lower.contains("pro list") {
                currentSection = .professional
                continue
            }
            if lower.contains("personal") || lower.contains("academic") || lower == "academic & personal" || lower.contains("per list") {
                currentSection = .personal
                continue
            }

            guard let checked = parseCheckbox(line) else { continue }

            switch currentSection {
            case .professional:
                proTotal += 1
                if checked { proDone += 1 }
            case .personal:
                perTotal += 1
                if checked { perDone += 1 }
            case .unknown:
                break
            }
        }

        return NotesChecklistResult(
            proDone: proDone, proTotal: proTotal,
            perDone: perDone, perTotal: perTotal,
            rawText: text,
            errorMessage: nil,
            lastSync: Date()
        )
    }

    /// Returns nil if line isn't a checklist item, or true/false for checked/unchecked.
    private func parseCheckbox(_ line: String) -> Bool? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("[") else { return nil }

        guard trimmed.count >= 3 else { return nil }
        let secondChar = trimmed[trimmed.index(after: trimmed.startIndex)]

        switch secondChar {
        case "x", "X":
            return true
        case " ":
            return false
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func computeCounts(from items: [ChecklistItem]) -> NotesChecklistResult {
        var proDone = 0, proTotal = 0
        var perDone = 0, perTotal = 0

        for item in items {
            switch item.section {
            case .professional:
                proTotal += 1
                if item.isChecked { proDone += 1 }
            case .personal:
                perTotal += 1
                if item.isChecked { perDone += 1 }
            }
        }

        return NotesChecklistResult(
            proDone: proDone, proTotal: proTotal,
            perDone: perDone, perTotal: perTotal,
            rawText: "",
            errorMessage: nil,
            lastSync: Date()
        )
    }

    /// Updates today's entry in DataStore with the given counts.
    private func updateTodayEntry(with result: NotesChecklistResult, store: DataStore) {
        let today = Date()
        if var existing = store.entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existing.proTotal = result.proTotal
            existing.proDone = result.proDone
            existing.perTotal = result.perTotal
            existing.perDone = result.perDone
            store.addOrUpdate(entry: &existing)
        } else {
            var newEntry = Entry(
                date: today,
                sleepHours: 7.0,
                socialMins: 0,
                breakfast: .standard,
                lunch: .standard,
                dinner: .standard,
                proTotal: result.proTotal,
                proDone: result.proDone,
                perTotal: result.perTotal,
                perDone: result.perDone,
                readingPages: 0,
                meditated: false
            )
            store.addOrUpdate(entry: &newEntry)
        }
    }
}
