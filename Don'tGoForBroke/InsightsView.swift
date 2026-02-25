import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"

    private var theme: ThemePalette { ThemePalette(accentChoice: accentChoice) }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [theme.primary.opacity(0.20), theme.secondary.opacity(0.16), theme.tertiary.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var body: some View {
        let endDate = ExpenseAnalytics.endDate(for: expenses)
        let occurrences = ExpenseAnalytics.occurrences(from: expenses, through: endDate)
        let summary = ExpenseAnalytics.summary(for: occurrences)

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No expenses yet",
                        systemImage: "chart.pie.fill",
                        description: Text("Add an expense to unlock insights.")
                    )
                } else {
                    summaryCard(summary)
                    trendCard(summary)
                    categoryCard(summary)
                    biggestDayCard(summary)
                }
            }
            .padding()
        }
        .background(backgroundGradient)
        .navigationTitle("Insights")
        .tint(theme.primary)
    }

    private func summaryCard(_ summary: InsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(theme.primary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.totalAllTime, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3)
                        .bold()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last 30 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.last30Total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3)
                        .bold()
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg per day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.averageDailyLast30, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3)
                        .bold()
                }
                Spacer()
            }
        }
        .padding()
        .glassEffect(.regular.tint(theme.secondary.opacity(0.25)), in: .rect(cornerRadius: 16))
    }

    private func trendCard(_ summary: InsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-day trend")
                .font(.headline)
                .foregroundStyle(theme.primary)

            Text("Last 7 days: \(summary.last7Total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                .font(.subheadline)

            if let trend = summary.trendPercent {
                let sign = trend >= 0 ? "+" : ""
                Text("Change vs previous 7 days: \(sign)\(trend, specifier: "%.1f")%")
                    .font(.subheadline)
                    .foregroundStyle(trend >= 0 ? .red : .green)
            } else {
                Text("Change vs previous 7 days: N/A")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(.regular.tint(theme.tertiary.opacity(0.35)), in: .rect(cornerRadius: 16))
    }

    private func categoryCard(_ summary: InsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top category (30 days)")
                .font(.headline)
                .foregroundStyle(theme.primary)

            if let category = summary.topCategory {
                Text(category)
                    .font(.title3)
                    .bold()
                Text(summary.topCategoryTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No category data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(.regular.tint(theme.secondary.opacity(0.22)), in: .rect(cornerRadius: 16))
    }

    private func biggestDayCard(_ summary: InsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Biggest day")
                .font(.headline)
                .foregroundStyle(theme.primary)

            if let day = summary.biggestDay {
                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.title3)
                    .bold()
                Text(day.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No daily totals yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(.regular.tint(theme.tertiary.opacity(0.28)), in: .rect(cornerRadius: 16))
    }
}

#Preview {
    InsightsView()
}
