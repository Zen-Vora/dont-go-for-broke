import Foundation
import SwiftData

@Model
final class MoneyEntry {
    var amount: Decimal
    var date: Date
    var goal: Goal?
    var note: String?

    init(amount: Decimal,
         date: Date = .now,
         goal: Goal? = nil,
         note: String? = nil) {
        self.amount = amount
        self.date = date
        self.goal = goal
        self.note = note
    }
}
