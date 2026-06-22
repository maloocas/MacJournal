import SwiftUI

// MARK: - Journal Tab (Wall of Daily Reflections)

struct JournalView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showDeleteConfirm: JournalEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Journal Wall")

                if store.journalEntries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 36))
                            .foregroundColor(themeManager.colors.textMuted)
                            .padding(.top, 60)
                        Text("No journal entries yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.colors.textSecondary)
                        Text("Write a reflection in the Daily Log tab to start your journal.")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                } else {
                    // Journal entry cards — newest first
                    ForEach(store.journalEntries) { entry in
                        JournalCard(
                            entry: entry,
                            onDelete: { showDeleteConfirm = entry }
                        )
                        .padding(.horizontal)
                        .slideUpAppear()
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(themeManager.colors.background)
        .alert("Delete Entry", isPresented: .init(
            get: { showDeleteConfirm != nil },
            set: { if !$0 { showDeleteConfirm = nil } }
        )) {
            Button("Cancel", role: .cancel) { showDeleteConfirm = nil }
            Button("Delete", role: .destructive) {
                if let id = showDeleteConfirm?.id {
                    store.deleteJournalEntry(id: id)
                }
                showDeleteConfirm = nil
            }
        } message: {
            if let entry = showDeleteConfirm {
                Text("Delete journal entry from \(entry.displayDate)?")
            }
        }
    }
}

// MARK: - Journal Card

struct JournalCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entry: JournalEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: date + delete
            HStack {
                Text(entry.displayDate)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundColor(themeManager.colors.accent)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.colors.textMuted)
                }
                .buttonStyle(.plain)
            }

            // Body text
            Text(entry.text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(themeManager.colors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Word count badge
            let wordCount = entry.text
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .count
            HStack(spacing: 4) {
                Spacer()
                Text("\u{00b7} \(wordCount) words")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(themeManager.colors.textMuted)
            }
        }
        .padding(18)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
