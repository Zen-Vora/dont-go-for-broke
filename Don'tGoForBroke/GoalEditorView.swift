import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("settings.weeklyIncome") private var weeklyIncome: Double = 0
    @AppStorage("settings.savingsRate") private var savingsRate: Double = 0.2

    @State private var title: String
    @State private var targetAmountText: String
    @State private var targetDateEnabled: Bool
    @State private var targetDate: Date

    var onSave: (Goal) -> Void

    init(prefillTitle: String = "",
         prefillAmount: Decimal? = nil,
         prefillDate: Date? = nil,
         onSave: @escaping (Goal) -> Void) {
        self.onSave = onSave
        self._title = State(initialValue: prefillTitle)
        self._targetAmountText = State(initialValue: prefillAmount.map { $0.description } ?? "")
        self._targetDateEnabled = State(initialValue: prefillDate != nil)
        self._targetDate = State(initialValue: prefillDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Title", text: $title)
                    TextField("Target amount", text: $targetAmountText)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                    Toggle("Set target date", isOn: $targetDateEnabled)
                    if targetDateEnabled {
                        DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                    }
                }
                Section("Plan") {
                    if let amount = parsedTargetAmount, amount > 0 {
                        planSection(for: amount)
                    } else {
                        Text("Enter a target amount to generate a savings plan.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let targetAmount = Decimal(string: sanitizedAmountText(targetAmountText)) ?? 0
                        let goal = Goal(
                            title: title,
                            targetAmount: targetAmount,
                            targetDate: targetDateEnabled ? targetDate : nil
                        )
                        onSave(goal)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || Decimal(string: sanitizedAmountText(targetAmountText)) == nil)
                }
            }
        }
    }

    private var parsedTargetAmount: Decimal? {
        Decimal(string: sanitizedAmountText(targetAmountText))
    }

    @ViewBuilder
    private func planSection(for amount: Decimal) -> some View {
        if targetDateEnabled {
            if let plan = planDetails(for: amount) {
                Text("Save \(plan.requiredWeekly, format: .currency(code: currencyCode)) per week")
                    .font(.subheadline)
                Text("or \(plan.requiredMonthly, format: .currency(code: currencyCode)) per month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Based on \(plan.weeks) weeks until your target date.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if currentWeeklySavings > 0 {
                    if plan.extraWeekly > 0 {
                        Text("You currently save \(currentWeeklySavings, format: .currency(code: currencyCode))/week. Add \(plan.extraWeekly, format: .currency(code: currencyCode)) more per week to hit the date.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You’re on track at \(currentWeeklySavings, format: .currency(code: currencyCode)) per week.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Set weekly income and savings rate to compare your plan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Choose a future target date to generate a savings plan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            if let noDatePlan = noDatePlanDetails(for: amount) {
                Text("At \(currentWeeklySavings, format: .currency(code: currencyCode)) per week, you’ll reach it in \(noDatePlan.weeks) weeks.")
                    .font(.subheadline)
                Text("Estimated date: \(noDatePlan.estimatedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Set weekly income and savings rate to estimate when you’ll reach this goal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentWeeklySavings: Double {
        max(0, weeklyIncome * savingsRate)
    }

    private func planDetails(for amount: Decimal) -> (weeks: Int, requiredWeekly: Double, requiredMonthly: Double, extraWeekly: Double)? {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: .now)
        let endDate = calendar.startOfDay(for: targetDate)
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        guard dayCount > 0 else { return nil }
        let weeks = max(1, Int(ceil(Double(dayCount) / 7.0)))
        let months = max(1, Int(ceil(Double(dayCount) / 30.0)))
        let amountValue = (amount as NSDecimalNumber).doubleValue
        let requiredWeekly = amountValue / Double(weeks)
        let requiredMonthly = amountValue / Double(months)
        let extraWeekly = max(0, requiredWeekly - currentWeeklySavings)
        return (weeks: weeks,
                requiredWeekly: requiredWeekly,
                requiredMonthly: requiredMonthly,
                extraWeekly: extraWeekly)
    }

    private func noDatePlanDetails(for amount: Decimal) -> (weeks: Int, estimatedDate: Date)? {
        guard currentWeeklySavings > 0 else { return nil }
        let amountValue = (amount as NSDecimalNumber).doubleValue
        let weeks = max(1, Int(ceil(amountValue / currentWeeklySavings)))
        let estimatedDate = Calendar.current.date(byAdding: .day, value: weeks * 7, to: .now) ?? .now
        return (weeks: weeks, estimatedDate: estimatedDate)
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private func sanitizedAmountText(_ text: String) -> String {
        text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "$", with: "")
    }
}

#Preview {
    GoalEditorView(onSave: { _ in })
}
