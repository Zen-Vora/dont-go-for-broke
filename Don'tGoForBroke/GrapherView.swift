//
//  GrapherView.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/14/26.
//

import SwiftUI
import Charts
import SwiftData

fileprivate func parseAmount(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return nil }

    // Try currency-aware parsing first
    let currencyFormatter = NumberFormatter()
    currencyFormatter.numberStyle = .currency
    currencyFormatter.locale = Locale.current
    if let number = currencyFormatter.number(from: trimmed) {
        return number.decimalValue
    }

    // Try decimal parsing
    let decimalFormatter = NumberFormatter()
    decimalFormatter.numberStyle = .decimal
    decimalFormatter.locale = Locale.current
    if let number = decimalFormatter.number(from: trimmed) {
        return number.decimalValue
    }

    // Fallback: strip currency symbols and grouping separators
    let currencySymbol = currencyFormatter.currencySymbol ?? "$"
    let symbols = CharacterSet(charactersIn: currencySymbol).union(.whitespacesAndNewlines)
    var cleaned = trimmed.components(separatedBy: symbols).joined()

    let grouping = currencyFormatter.groupingSeparator ?? ","
    cleaned = cleaned.replacingOccurrences(of: grouping, with: "")

    let decimalSep = currencyFormatter.decimalSeparator ?? "."
    if decimalSep != "." {
        cleaned = cleaned.replacingOccurrences(of: decimalSep, with: ".")
    }

    // Keep digits, a single decimal point, and leading sign
    let validSet = CharacterSet(charactersIn: "0123456789.-")
    cleaned = cleaned.unicodeScalars.filter { validSet.contains($0) }.map(String.init).joined()

    return Decimal(string: cleaned)
}

fileprivate struct DailyPoint: Identifiable {
    let date: Date
    let total: Double
    var id: Date { date }

    init(date: Date, total: Double) {
        self.date = date
        self.total = total
    }
}

struct GrapherView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    // Variables for an expense
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = .now
    @State private var category: String = "General"
    @State private var isRecurring: Bool = false
    
    @State private var editingExpense: Expense?
    @State private var editTitle: String = ""
    @State private var editAmountText: String = ""
    @State private var editDate: Date = .now
    @State private var editCategory: String = "General"
    @State private var editIsRecurring: Bool = false
    @State private var selectedExpense: Expense?
    
    private var theme: ThemePalette { ThemePalette(accentChoice: accentChoice) }

    private var dailyTotals: [DailyPoint] {
        let calendar = Calendar.current
        var grouped: [Date: Double] = [:]

        for expense in expenses {
            let day = calendar.startOfDay(for: expense.date)
            let amountDouble = (expense.amount as NSDecimalNumber).doubleValue
            grouped[day, default: 0] += amountDouble
        }

        let sortedDays = grouped.keys.sorted()

        var result: [DailyPoint] = []
        result.reserveCapacity(sortedDays.count)
        for day in sortedDays {
            let total = grouped[day] ?? 0
            result.append(DailyPoint(date: day, total: total))
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Form {
                addExpenseSection()
                expensesSection()
            }
            .scrollContentBackground(.hidden)
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
            .listRowBackground(theme.primary.opacity(0.06))
            .listRowSeparatorTint(theme.primary.opacity(0.2))

            ExpenseChartView(theme: theme, points: dailyTotals)
                .frame(height: 240)
                .padding(.top, 8)
        }
        .padding()
        .background(backgroundGradient)
        .navigationTitle("Expense Grapher")
        .tint(theme.primary)
        .sheet(item: $editingExpense) { expense in
            editSheetView(expense: expense)
        }
        .confirmationDialog("Actions", isPresented: isShowingActions, presenting: selectedExpense) { expense in
            Button("Edit") {
                preloadEditFields(from: expense)
                editingExpense = expense
                selectedExpense = nil
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(expense)
                try? modelContext.save()
                selectedExpense = nil
            }
        } message: { expense in
            Text(expense.title)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [theme.primary.opacity(0.12), theme.secondary.opacity(0.10), theme.tertiary.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var isShowingActions: Binding<Bool> {
        Binding(get: { selectedExpense != nil }, set: { if !$0 { selectedExpense = nil } })
    }

    private func preloadEditFields(from expense: Expense) {
        editTitle = expense.title
        editAmountText = expense.amount.description
        editDate = expense.date
        editCategory = expense.category
        editIsRecurring = expense.isRecurring
    }

    @ViewBuilder
    private func addExpenseSection() -> some View {
        Section {
            TextField("Title", text: $title)
                .listRowBackground(theme.tertiary.opacity(0.15))
            TextField("Amount", text: $amountText)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                .listRowBackground(theme.tertiary.opacity(0.15))
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .listRowBackground(theme.tertiary.opacity(0.15))
            TextField("Category", text: $category)
                .listRowBackground(theme.tertiary.opacity(0.15))
            Toggle("Recurring", isOn: $isRecurring)
                .listRowBackground(theme.tertiary.opacity(0.15))

            // Insert action: parse amount and save to SwiftData
            Button("Add Expense") {
                guard let amount = parseAmount(amountText), !title.isEmpty else { return }
                let newExpense = Expense(title: title,
                                         amount: amount,
                                         date: date,
                                         category: category,
                                         isRecurring: isRecurring)
                modelContext.insert(newExpense)
                try? modelContext.save()

                // Reset inputs
                title = ""
                amountText = ""
                date = .now
                category = "General"
                isRecurring = false
            }
            .disabled(title.isEmpty || parseAmount(amountText) == nil)
            .buttonStyle(.glassProminent)
            .tint(theme.primary)
        } header: {
            Text("Add Expense")
                .font(.headline)
                .foregroundStyle(theme.primary)
                .textCase(nil)
        }
    }

    @ViewBuilder
    private func expensesSection() -> some View {
        Section {
            if expenses.isEmpty {
                Text("No expenses yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(expenses) { expense in
                    expenseRow(expense)
                }
            }
        } header: {
            Text("Recent Expenses")
                .font(.headline)
                .foregroundStyle(theme.primary)
                .textCase(nil)
        }
    }

    @ViewBuilder
    private func expenseRow(_ expense: Expense) -> some View {
        HStack {
            Text(expense.title)
            Spacer()
            Text(expense.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                .foregroundStyle(theme.primary)
        }
        .contentShape(Rectangle())
        .background((selectedExpense === expense) ? theme.secondary.opacity(0.20) : Color.clear)
        .onTapGesture {
            selectedExpense = expense
        }
        .swipeActions {
            Button {
                preloadEditFields(from: expense)
                editingExpense = expense
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                modelContext.delete(expense)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                preloadEditFields(from: expense)
                editingExpense = expense
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                modelContext.delete(expense)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func editSheetView(expense: Expense) -> some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $editTitle)
                        .listRowBackground(theme.tertiary.opacity(0.15))
                    TextField("Amount", text: $editAmountText)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                        .listRowBackground(theme.tertiary.opacity(0.15))
                    DatePicker("Date", selection: $editDate, displayedComponents: .date)
                        .listRowBackground(theme.tertiary.opacity(0.15))
                    TextField("Category", text: $editCategory)
                        .listRowBackground(theme.tertiary.opacity(0.15))
                    Toggle("Recurring", isOn: $editIsRecurring)
                        .listRowBackground(theme.tertiary.opacity(0.15))
                } header: {
                    Text("Edit Expense")
                        .font(.headline)
                        .foregroundStyle(theme.primary)
                        .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
            .listRowBackground(theme.primary.opacity(0.06))
            .listRowSeparatorTint(theme.primary.opacity(0.2))
            .navigationTitle("Edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingExpense = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = parseAmount(editAmountText) {
                            expense.title = editTitle
                            expense.amount = amount
                            expense.date = editDate
                            expense.category = editCategory
                            expense.isRecurring = editIsRecurring
                            try? modelContext.save()
                            editingExpense = nil
                        }
                    }
                    .disabled(parseAmount(editAmountText) == nil || editTitle.isEmpty)
                }
            }
        }
    }
}

fileprivate struct ExpenseChartView: View {
    let theme: ThemePalette
    let points: [DailyPoint]

    var body: some View {
        Chart {
            ForEach(points) { (point: DailyPoint) in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary.opacity(0.45), theme.secondary.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.linear)

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(theme.primary)
                .lineStyle(.init(lineWidth: 2))
                .interpolationMethod(.linear)
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .symbol(.circle)
                .symbolSize(40)
                .foregroundStyle(theme.secondary)
                .annotation(position: .top, alignment: .center) {
                    Text(point.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.caption2)
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassEffect(.regular.tint(theme.tertiary.opacity(0.5)).interactive(), in: .capsule)
                }
            }
        }
        .chartXScale(range: .plotDimension(padding: 12))
        .chartYScale(range: .plotDimension(padding: 12))
        .chartPlotStyle { plotArea in
            plotArea
                .glassEffect(.regular.tint(theme.tertiary.opacity(0.35)), in: .rect(cornerRadius: 12))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6))
        }
        .chartXAxisLabel {
            Text("Date")
                .font(.caption)
                .foregroundStyle(theme.primary.opacity(0.7))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYAxisLabel(position: .leading) {
            Text("Total Spent")
                .font(.caption)
                .foregroundStyle(theme.primary.opacity(0.7))
        }
    }
}

#Preview {
    GrapherView()
}
