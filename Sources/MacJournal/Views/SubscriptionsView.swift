import SwiftUI

// MARK: - Subscriptions Tab

struct SubscriptionsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var newName = ""
    @State private var newAmount = 9.99
    @State private var newCycle: BillingCycle = .monthly
    @State private var newNextPaymentDate = Date()
    @State private var newNotes = ""

    @State private var editingID: UUID? = nil
    @State private var editingName = ""
    @State private var editingAmount = 9.99
    @State private var editingCycle: BillingCycle = .monthly
    @State private var editingNextPaymentDate = Date()
    @State private var editingNotes = ""

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    private var monthlyTotal: Double {
        store.subscriptions.filter(\.isActive).reduce(0) { $0 + $1.monthlyCost }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Subscriptions")

                // ── Monthly Total ──
                monthlyTotalBar

                // ── Add Subscription Bar ──
                addSubscriptionBar

                // ── Subscriptions List ──
                if store.subscriptions.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(store.subscriptions) { sub in
                            subscriptionCard(sub)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(themeManager.colors.background)
    }

    // MARK: - Monthly Total Bar

    private var monthlyTotalBar: some View {
        let total = monthlyTotal
        return HStack {
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.colors.accent)
                Text("Monthly Equivalent")
                    .font(.system(size: 12, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: total)) ?? "$0.00")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.colors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Add Subscription Bar

    private var addSubscriptionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                TextField("Subscription name", text: $newName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.colors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(themeManager.colors.background)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onSubmit { submitSubscription() }

                TextField("Amount", value: $newAmount, format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.colors.textPrimary)
                    .frame(width: 90)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(themeManager.colors.background)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 10) {
                Picker("Cycle", selection: $newCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).tag(cycle)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                DatePicker("Next Payment", selection: $newNextPaymentDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .font(.system(size: 12))
                    .labelsHidden()

                Spacer()

                Button(action: submitSubscription) {
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            newNameIsValid ? themeManager.colors.accent : themeManager.colors.surface
                        )
                        .foregroundColor(
                            newNameIsValid ? themeManager.colors.background : themeManager.colors.textMuted
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!newNameIsValid)
            }

            HStack(spacing: 10) {
                TextField("Notes (optional)", text: $newNotes)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(themeManager.colors.background)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(14)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var newNameIsValid: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && newAmount > 0
    }

    // MARK: - Subscription Card

    private func subscriptionCard(_ sub: Subscription) -> some View {
        let isEditing = editingID == sub.id

        return VStack(spacing: 0) {
            if isEditing {
                // ── Editing mode ──
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Name", text: $editingName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.colors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(themeManager.colors.background)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))

                    HStack(spacing: 10) {
                        TextField("Amount", value: $editingAmount, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.textPrimary)
                            .frame(width: 90)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(themeManager.colors.background)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))

                        Picker("Cycle", selection: $editingCycle) {
                            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                Text(cycle.rawValue).tag(cycle)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    DatePicker("Next Payment", selection: $editingNextPaymentDate, displayedComponents: .date)
                        .datePickerStyle(.field)
                        .font(.system(size: 12))
                        .labelsHidden()

                    TextField("Notes", text: $editingNotes)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(themeManager.colors.background)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.accent, lineWidth: 1))

                    HStack(spacing: 10) {
                        Spacer()

                        Button(action: { cancelEdit() }) {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.colors.textMuted)
                        }
                        .buttonStyle(.plain)

                        Button(action: { confirmEdit(sub: sub) }) {
                            Text("Save")
                                .font(.system(size: 11, weight: .semibold))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundColor(themeManager.colors.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editingAmount <= 0)
                    }
                }
                .padding(14)
            } else {
                // ── Display mode ──
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(sub.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.colors.textPrimary)
                                .lineLimit(1)

                            Text(sub.billingCycle.shortLabel)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.colors.accent.opacity(0.15))
                                .foregroundColor(themeManager.colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }

                        Text(currencyFormatter.string(from: NSNumber(value: sub.amount)) ?? "$0.00")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(themeManager.colors.textPrimary)
                            + Text(sub.billingCycle.shortLabel)
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.textSecondary)

                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text("Renews \(dateFormatter.string(from: sub.nextPaymentDate))")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(themeManager.colors.textSecondary)

                        if !sub.notes.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 10))
                                Text(sub.notes)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(themeManager.colors.textMuted)
                            .lineLimit(2)
                        }
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Button(action: { startEdit(sub: sub) }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.colors.textMuted)
                                .padding(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: { store.deleteSubscription(id: sub.id) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.colors.textMuted)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
        }
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 32))
                .foregroundColor(themeManager.colors.textMuted)
            Text("No subscriptions yet.\nAdd one above to start tracking.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(themeManager.colors.surface)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Actions

    private func submitSubscription() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, newAmount > 0 else { return }
        store.addSubscription(name: trimmed, amount: newAmount, billingCycle: newCycle, nextPaymentDate: newNextPaymentDate, notes: newNotes)
        newName = ""
        newAmount = 9.99
        newCycle = .monthly
        newNextPaymentDate = Date()
        newNotes = ""
    }

    private func startEdit(sub: Subscription) {
        editingID = sub.id
        editingName = sub.name
        editingAmount = sub.amount
        editingCycle = sub.billingCycle
        editingNextPaymentDate = sub.nextPaymentDate
        editingNotes = sub.notes
    }

    private func confirmEdit(sub: Subscription) {
        store.updateSubscription(id: sub.id, name: editingName, amount: editingAmount, billingCycle: editingCycle, nextPaymentDate: editingNextPaymentDate, notes: editingNotes)
        cancelEdit()
    }

    private func cancelEdit() {
        editingID = nil
        editingName = ""
        editingNotes = ""
    }
}
