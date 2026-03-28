import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @Query(sort: \MoneyEntry.date, order: .reverse) private var moneyEntries: [MoneyEntry]
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @AppStorage("settings.weeklyIncome") private var weeklyIncome: Double = 0
    @AppStorage("settings.savingsRate") private var savingsRate: Double = 0.2

    @State private var showingAddGoal = false
    @State private var editingGoal: Goal?
    @State private var moneyAmountText: String = ""
    @State private var moneyDate: Date = .now
    @State private var selectedGoalID: PersistentIdentifier?
    @State private var allocationSelections: [PersistentIdentifier: PersistentIdentifier?] = [:]
    @AppStorage("settings.lastGoalAllocationTitle") private var lastGoalAllocationTitle: String = ""
    @FocusState private var isMoneyAmountFocused: Bool
    @State private var moneyAmountTouched: Bool = false

    private var theme: ThemePalette { ThemePalette(accentChoice: accentChoice) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                addMoneySection
                unallocatedSection

                if goals.isEmpty {
                    ContentUnavailableView(
                        "No goals yet",
                        systemImage: "target",
                        description: Text("Save a goal from Want vs Need to get started.")
                    )
                } else {
                    ForEach(goals) { goal in
                        goalCard(goal)
                    }
                }
            }
            .padding()
        }
        .background(backgroundGradient)
        .navigationTitle("Goals")
        .tint(theme.primary)
        .sheet(isPresented: $showingAddGoal) {
            GoalEditorView(onSave: { newGoal in
                modelContext.insert(newGoal)
                try? modelContext.save()
            })
        }
        .sheet(item: $editingGoal) { goal in
            GoalEditorView(
                prefillTitle: goal.title,
                prefillAmount: goal.targetAmount,
                prefillDate: goal.targetDate,
                onSave: { updated in
                    goal.title = updated.title
                    goal.targetAmount = updated.targetAmount
                    goal.targetDate = updated.targetDate
                    try? modelContext.save()
                }
            )
        }
        .onAppear {
            if selectedGoalID == nil, !lastGoalAllocationTitle.isEmpty {
                selectedGoalID = goals.first { $0.title == lastGoalAllocationTitle }?.persistentModelID
            }
        }
    }

    private var selectedGoal: Goal? {
        goals.first { $0.persistentModelID == selectedGoalID }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Goals")
                    .font(.title2)
                    .bold()
                Text("Plan your savings for the things you want.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showingAddGoal = true
            } label: {
                Label("Add Goal", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addMoneySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Add Money")
                    .font(.headline)
                    .foregroundStyle(theme.primary)
                Spacer()
            }

            TextField("Amount", text: $moneyAmountText)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isMoneyAmountFocused)
                .onChange(of: moneyAmountText) { _, _ in
                    moneyAmountTouched = true
                }

            if moneyAmountTouched && !moneyAmountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parseAmount(moneyAmountText) == nil {
                Text("Enter a valid amount.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            DatePicker("Date", selection: $moneyDate, displayedComponents: .date)

            if goals.isEmpty {
                Text("Create a goal to allocate savings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Allocate to goal", selection: $selectedGoalID) {
                    Text("No goal").tag(Optional<PersistentIdentifier>.none)
                    ForEach(goals) { goal in
                        Text(goal.title).tag(Optional(goal.persistentModelID))
                    }
                }
                .onChange(of: selectedGoalID) { _, newValue in
                    if let newValue, let goal = goals.first(where: { $0.persistentModelID == newValue }) {
                        lastGoalAllocationTitle = goal.title
                    } else if newValue == nil {
                        lastGoalAllocationTitle = ""
                    }
                }
            }

            Button("Add Money") {
                guard let amount = parseAmount(moneyAmountText) else { return }
                let entry = MoneyEntry(amount: amount, date: moneyDate, goal: selectedGoal)
                modelContext.insert(entry)
                try? modelContext.save()

                moneyAmountText = ""
                moneyDate = .now
                selectedGoalID = nil
                moneyAmountTouched = false
            }
            .buttonStyle(.glassProminent)
            .tint(theme.primary)
            .disabled(parseAmount(moneyAmountText) == nil)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(theme.tertiary.opacity(0.22)), in: .rect(cornerRadius: 16))
    }

    private var unallocatedSection: some View {
        let unallocated = moneyEntries.filter { $0.goal == nil }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Unallocated Money")
                    .font(.headline)
                    .foregroundStyle(theme.primary)
                Spacer()
            }

            if unallocated.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("All money entries are allocated.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if goals.isEmpty {
                        Text("Add a goal to start allocating.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Add money") {
                            isMoneyAmountFocused = true
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                ForEach(unallocated) { entry in
                    let binding = allocationBinding(for: entry)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                                .foregroundStyle(theme.primary)
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Picker("Allocate", selection: binding) {
                            Text("No goal").tag(Optional<PersistentIdentifier>.none)
                            ForEach(goals) { goal in
                                Text(goal.title).tag(Optional(goal.persistentModelID))
                            }
                        }
                        .onChange(of: binding.wrappedValue) { _, newValue in
                            if let newValue {
                                entry.goal = goals.first { $0.persistentModelID == newValue }
                            } else {
                                entry.goal = nil
                            }
                            try? modelContext.save()
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.tertiary.opacity(0.12))
                    )
                    .animation(.easeInOut(duration: 0.2), value: entry.goal?.persistentModelID)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(theme.secondary.opacity(0.20)), in: .rect(cornerRadius: 16))
    }

    private func goalCard(_ goal: Goal) -> some View {
        let targetAmount = (goal.targetAmount as NSDecimalNumber).doubleValue
        let savedAmount = savedAmount(for: goal)
        let weeklySavings = max(0, weeklyIncome * savingsRate)
        let weeksNeeded = weeklySavings > 0 ? (targetAmount / weeklySavings) : nil

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                Spacer()
                Text(goal.targetAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                Menu {
                    Button("Edit") {
                        editingGoal = goal
                    }
                    Button("Delete", role: .destructive) {
                        modelContext.delete(goal)
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(theme.primary)
                }
            }

            if let date = goal.targetDate {
                Text("Target date: \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let weeksNeeded {
                Text("Estimated time: \(Int(ceil(weeksNeeded))) weeks")
                    .font(.subheadline)
                    .foregroundStyle(theme.primary)
            } else {
                Text("Add weekly income + savings rate to see a plan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let planText = goalPlanSummary(for: goal, weeklySavings: weeklySavings) {
                Text(planText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if targetAmount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: min(savedAmount, targetAmount), total: targetAmount)
                        .tint(theme.primary)
                    Text("Saved \(formatCurrency(savedAmount)) of \(formatCurrency(targetAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if savedAmount >= targetAmount {
                        Text("Goal reached!")
                            .font(.caption)
                            .foregroundStyle(theme.primary)
                    } else {
                        Text("Remaining: \(formatCurrency(max(0, targetAmount - savedAmount)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Set a target amount to track progress.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            GoalPlannerView()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(theme.secondary.opacity(0.24)), in: .rect(cornerRadius: 16))
        .contextMenu {
            Button("Edit") {
                editingGoal = goal
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(goal)
                try? modelContext.save()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [theme.primary.opacity(0.20), theme.secondary.opacity(0.16), theme.tertiary.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func goalPlanSummary(for goal: Goal, weeklySavings: Double) -> String? {
        let amount = (goal.targetAmount as NSDecimalNumber).doubleValue
        let remaining = max(0, amount - savedAmount(for: goal))
        guard remaining > 0 else { return "Goal is fully funded." }
        if let targetDate = goal.targetDate {
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: .now)
            let endDate = calendar.startOfDay(for: targetDate)
            let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            guard dayCount > 0 else { return "Target date is in the past." }
            let weeks = max(1, Int(ceil(Double(dayCount) / 7.0)))
            let requiredWeekly = remaining / Double(weeks)
            if weeklySavings > 0 {
                let extraWeekly = max(0, requiredWeekly - weeklySavings)
                if extraWeekly > 0 {
                    return "Need \(formatCurrency(extraWeekly)) more per week to hit the date."
                }
                return "On track to hit the date at current savings."
            }
            return "Need \(formatCurrency(requiredWeekly)) per week to hit the date."
        }
        guard weeklySavings > 0 else { return nil }
        let weeks = max(1, Int(ceil(remaining / weeklySavings)))
        return "At \(formatCurrency(weeklySavings))/week, you’ll reach it in \(weeks) weeks."
    }

    private func savedAmount(for goal: Goal) -> Double {
        moneyEntries
            .filter { $0.goal?.persistentModelID == goal.persistentModelID }
            .reduce(0) { $0 + ($1.amount as NSDecimalNumber).doubleValue }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func parseAmount(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        if let number = currencyFormatter.number(from: trimmed) {
            return number.decimalValue
        }

        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.locale = Locale.current
        if let number = decimalFormatter.number(from: trimmed) {
            return number.decimalValue
        }

        let currencySymbol = currencyFormatter.currencySymbol ?? "$"
        let symbols = CharacterSet(charactersIn: currencySymbol).union(.whitespacesAndNewlines)
        var cleaned = trimmed.components(separatedBy: symbols).joined()

        let grouping = currencyFormatter.groupingSeparator ?? ","
        cleaned = cleaned.replacingOccurrences(of: grouping, with: "")

        let decimalSep = currencyFormatter.decimalSeparator ?? "."
        if decimalSep != "." {
            cleaned = cleaned.replacingOccurrences(of: decimalSep, with: ".")
        }

        let validSet = CharacterSet(charactersIn: "0123456789.-")
        cleaned = cleaned.unicodeScalars.filter { validSet.contains($0) }.map(String.init).joined()

        return Decimal(string: cleaned)
    }

    private func allocationBinding(for entry: MoneyEntry) -> Binding<PersistentIdentifier?> {
        let key = entry.persistentModelID
        if allocationSelections[key] == nil {
            allocationSelections[key] = entry.goal?.persistentModelID
        }
        return Binding(
            get: { allocationSelections[key] ?? entry.goal?.persistentModelID },
            set: { allocationSelections[key] = $0 }
        )
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}

private struct GoalPlannerView: View {
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @AppStorage("settings.weeklyIncome") private var weeklyIncome: Double = 0
    @AppStorage("settings.savingsRate") private var savingsRate: Double = 0.2

    @State private var weeklyIncomeText: String = ""
    @State private var localSavingsRate: Double = 0.2
    @State private var weeklyIncomeTouched: Bool = false

    private var theme: ThemePalette { ThemePalette(accentChoice: accentChoice) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Planner")
                .font(.subheadline)
                .foregroundStyle(theme.primary)

            TextField("Weekly income", text: $weeklyIncomeText)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: weeklyIncomeText) { _, newValue in
                    weeklyIncomeTouched = true
                    if let value = parsedIncome(from: newValue) {
                        weeklyIncome = value
                    } else if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        weeklyIncome = 0
                    }
                }
                .onSubmit {
                    weeklyIncomeTouched = true
                    if let value = parsedIncome(from: weeklyIncomeText) {
                        weeklyIncome = value
                    } else if weeklyIncomeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        weeklyIncome = 0
                    }
                }
            if weeklyIncomeTouched && isWeeklyIncomeInvalid {
                Text("Enter a valid income amount.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Text("Savings rate")
                    .font(.caption)
                Slider(value: $localSavingsRate, in: 0...1.0, step: 0.05)
                    .onChange(of: localSavingsRate) { _, newValue in
                        savingsRate = newValue
                    }
                Text("\(Int(localSavingsRate * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
        .onAppear {
            weeklyIncomeText = weeklyIncome == 0 ? "" : String(format: "%.2f", weeklyIncome)
            localSavingsRate = savingsRate
            weeklyIncomeTouched = false
        }
        .onDisappear {
            if let value = parsedIncome(from: weeklyIncomeText) {
                weeklyIncome = value
            } else if weeklyIncomeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                weeklyIncome = 0
            }
            savingsRate = localSavingsRate
        }
    }

    private func parsedIncome(from text: String) -> Double? {
        let sanitized = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "₩", with: "")
            .replacingOccurrences(of: "₽", with: "")
            .replacingOccurrences(of: "₺", with: "")
            .replacingOccurrences(of: "₫", with: "")
            .replacingOccurrences(of: "₴", with: "")
            .replacingOccurrences(of: "R$", with: "")
        return Double(sanitized)
    }

    private var isWeeklyIncomeInvalid: Bool {
        let trimmed = weeklyIncomeText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && parsedIncome(from: weeklyIncomeText) == nil
    }
}

#Preview {
    GoalsView()
}
