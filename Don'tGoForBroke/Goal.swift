import SwiftData
import Foundation

@Model
final class Goal {
    var title: String
    var targetAmount: Decimal
    var targetDate: Date?
    var createdAt: Date
    var weeklyIncome: Decimal
    var savingsRate: Double

    init(title: String,
         targetAmount: Decimal,
         targetDate: Date? = nil,
         createdAt: Date = .now,
         weeklyIncome: Decimal = 0,
         savingsRate: Double = 0.2) {
        self.title = title
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.weeklyIncome = weeklyIncome
        self.savingsRate = savingsRate
    }
}
