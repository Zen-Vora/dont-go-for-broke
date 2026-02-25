import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @AppStorage("settings.weeklyIncome") private var weeklyIncome: Double = 0
    @AppStorage("settings.savingsRate") private var savingsRate: Double = 0.2

    @State private var showingAddGoal = false
    @State private var editingGoal: Goal?

    private var theme: ThemePalette { ThemePalette(accentChoice: accentChoice) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

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
    }

    private func goalCard(_ goal: Goal) -> some View {
        let targetAmount = (goal.targetAmount as NSDecimalNumber).doubleValue
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

            Divider()

            GoalPlannerView()
        }
        .padding()
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
}

private struct GoalPlannerView: View {
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @AppStorage("settings.weeklyIncome") private var weeklyIncome: Double = 0
    @AppStorage("settings.savingsRate") private var savingsRate: Double = 0.2

    @State private var weeklyIncomeText: String = ""
    @State private var localSavingsRate: Double = 0.2

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

            HStack {
                Text("Savings rate")
                    .font(.caption)
                Slider(value: $localSavingsRate, in: 0...0.8, step: 0.05)
                Text("\(Int(localSavingsRate * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Update Plan") {
                let parsed = Double(weeklyIncomeText.replacingOccurrences(of: ",", with: "")) ?? 0
                weeklyIncome = parsed
                savingsRate = localSavingsRate
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            weeklyIncomeText = weeklyIncome == 0 ? "" : String(format: "%.2f", weeklyIncome)
            localSavingsRate = savingsRate
        }
    }
}

#Preview {
    GoalsView()
}
