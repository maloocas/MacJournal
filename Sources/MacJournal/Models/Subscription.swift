import Foundation

enum BillingCycle: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case annual = "Annual"

    var multiplier: Double {
        switch self {
        case .weekly: return 4.33
        case .monthly: return 1.0
        case .annual: return 1.0 / 12.0
        }
    }

    var shortLabel: String {
        switch self {
        case .weekly: return "/wk"
        case .monthly: return "/mo"
        case .annual: return "/yr"
        }
    }
}

struct Subscription: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var billingCycle: BillingCycle
    var nextPaymentDate: Date
    var notes: String
    var isActive: Bool
    var createdAt: Date = Date()

    var monthlyCost: Double {
        amount * billingCycle.multiplier
    }

    init(id: UUID = UUID(), name: String, amount: Double, billingCycle: BillingCycle, nextPaymentDate: Date, notes: String = "", isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.nextPaymentDate = nextPaymentDate
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
