import Foundation

struct DailyPoint: Identifiable {
    let date: Date
    let total: Double
    var id: Date { date }
}

struct ExpenseOccurrence: Identifiable {
    let date: Date
    let amount: Double
    let category: String
    let title: String
    let isRecurring: Bool
    let id = UUID()
}

struct InsightsSummary {
    let totalAllTime: Double
    let last30Total: Double
    let averageDailyLast30: Double
    let topCategory: String?
    let topCategoryTotal: Double
    let biggestDay: DailyPoint?
    let last7Total: Double
    let previous7Total: Double
    let trendPercent: Double?
}

enum ExpenseAnalytics {
    static func occurrences(from expenses: [Expense], through endDate: Date, calendar: Calendar = .current) -> [ExpenseOccurrence] {
        var results: [ExpenseOccurrence] = []
        results.reserveCapacity(expenses.count)

        for expense in expenses {
            let amountDouble = (expense.amount as NSDecimalNumber).doubleValue
            if expense.isRecurring {
                var currentDate = expense.date
                while currentDate <= endDate {
                    results.append(
                        ExpenseOccurrence(
                            date: currentDate,
                            amount: amountDouble,
                            category: expense.category,
                            title: expense.title,
                            isRecurring: true
                        )
                    )
                    guard let next = nextMonthlyDate(from: currentDate, calendar: calendar) else { break }
                    currentDate = next
                }
            } else {
                results.append(
                    ExpenseOccurrence(
                        date: expense.date,
                        amount: amountDouble,
                        category: expense.category,
                        title: expense.title,
                        isRecurring: false
                    )
                )
            }
        }

        return results
    }

    static func dailyTotals(from occurrences: [ExpenseOccurrence], calendar: Calendar = .current) -> [DailyPoint] {
        var grouped: [Date: Double] = [:]
        for occurrence in occurrences {
            let day = calendar.startOfDay(for: occurrence.date)
            grouped[day, default: 0] += occurrence.amount
        }

        let sortedDays = grouped.keys.sorted()
        return sortedDays.map { day in
            DailyPoint(date: day, total: grouped[day] ?? 0)
        }
    }

    static func endDate(for expenses: [Expense], now: Date = .now) -> Date {
        return max(now, expenses.map(\.date).max() ?? now)
    }

    static func summary(for occurrences: [ExpenseOccurrence], now: Date = .now, calendar: Calendar = .current) -> InsightsSummary {
        let totalAllTime = occurrences.reduce(0) { $0 + $1.amount }

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) ?? now
        let last30 = occurrences.filter { $0.date >= thirtyDaysAgo && $0.date <= now }
        let last30Total = last30.reduce(0) { $0 + $1.amount }
        let averageDailyLast30 = last30Total / 30.0

        var categoryTotals: [String: Double] = [:]
        for occurrence in last30 {
            categoryTotals[occurrence.category, default: 0] += occurrence.amount
        }
        let topCategory = categoryTotals.max(by: { $0.value < $1.value })

        let dailyTotals = dailyTotals(from: occurrences, calendar: calendar)
        let biggestDay = dailyTotals.max(by: { $0.total < $1.total })

        let last7Start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let prev7Start = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: now)) ?? now
        let prev7End = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) ?? now

        let last7Total = occurrences
            .filter { $0.date >= last7Start && $0.date <= now }
            .reduce(0) { $0 + $1.amount }

        let previous7Total = occurrences
            .filter { $0.date >= prev7Start && $0.date < prev7End }
            .reduce(0) { $0 + $1.amount }

        let trendPercent: Double?
        if previous7Total > 0 {
            trendPercent = ((last7Total - previous7Total) / previous7Total) * 100.0
        } else {
            trendPercent = nil
        }

        return InsightsSummary(
            totalAllTime: totalAllTime,
            last30Total: last30Total,
            averageDailyLast30: averageDailyLast30,
            topCategory: topCategory?.key,
            topCategoryTotal: topCategory?.value ?? 0,
            biggestDay: biggestDay,
            last7Total: last7Total,
            previous7Total: previous7Total,
            trendPercent: trendPercent
        )
    }

    private static func nextMonthlyDate(from date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }

        var nextYear = year
        var nextMonth = month + 1
        if nextMonth > 12 {
            nextMonth = 1
            nextYear += 1
        }

        var monthComponents = DateComponents(year: nextYear, month: nextMonth)
        guard let monthDate = calendar.date(from: monthComponents) else { return nil }
        let dayRange = calendar.range(of: .day, in: .month, for: monthDate) ?? 1..<29

        monthComponents.day = min(day, dayRange.count)
        monthComponents.hour = components.hour
        monthComponents.minute = components.minute
        monthComponents.second = components.second

        return calendar.date(from: monthComponents)
    }
}
