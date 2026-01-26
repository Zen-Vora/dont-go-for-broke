//
//  GrapherView.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/14/26.
//

import SwiftUI
import Charts
import SwiftData

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
                Section("Add Expense") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amountText)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Category", text: $category)
                    Toggle("Recurring", isOn: $isRecurring)

                    // Insert action: parse amount and save to SwiftData
                    Button("Add Expense") {
                        guard let amount = Decimal(string: amountText), !title.isEmpty else { return }
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
                    .disabled(title.isEmpty || Decimal(string: amountText) == nil)
                }

                Section("Recent Expenses") {
                    if expenses.isEmpty {
                        Text("No expenses yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(expenses) { expense in
                            HStack {
                                Text(expense.title)
                                Spacer()
                                Text(expense.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                            }
                            .contentShape(Rectangle())
                            .background((selectedExpense === expense) ? Color.accentColor.opacity(0.15) : Color.clear)
                            .onTapGesture {
                                selectedExpense = expense
                            }
                            .swipeActions {
                                Button {
                                    // Preload edit fields and present sheet
                                    editTitle = expense.title
                                    editAmountText = expense.amount.description
                                    editDate = expense.date
                                    editCategory = expense.category
                                    editIsRecurring = expense.isRecurring
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
                                    // Preload edit fields and present sheet
                                    editTitle = expense.title
                                    editAmountText = expense.amount.description
                                    editDate = expense.date
                                    editCategory = expense.category
                                    editIsRecurring = expense.isRecurring
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
                    }
                }
            }

            ExpenseChartView(points: dailyTotals)
                .frame(height: 240)
                .padding(.top, 8)
        }
        .padding()
        .navigationTitle("Expense Grapher")
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                Form {
                    Section("Edit Expense") {
                        TextField("Title", text: $editTitle)
                        TextField("Amount", text: $editAmountText)
                        DatePicker("Date", selection: $editDate, displayedComponents: .date)
                        TextField("Category", text: $editCategory)
                        Toggle("Recurring", isOn: $editIsRecurring)
                    }
                }
                .navigationTitle("Edit")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            editingExpense = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let amount = Decimal(string: editAmountText) {
                                expense.title = editTitle
                                expense.amount = amount
                                expense.date = editDate
                                expense.category = editCategory
                                expense.isRecurring = editIsRecurring
                                try? modelContext.save()
                                editingExpense = nil
                            }
                        }
                        .disabled(Decimal(string: editAmountText) == nil || editTitle.isEmpty)
                    }
                }
            }
        }
        .confirmationDialog("Actions", isPresented: Binding(get: { selectedExpense != nil }, set: { if !$0 { selectedExpense = nil } }), presenting: selectedExpense) { expense in
            Button("Edit") {
                // Preload edit fields and present sheet
                editTitle = expense.title
                editAmountText = expense.amount.description
                editDate = expense.date
                editCategory = expense.category
                editIsRecurring = expense.isRecurring
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
}

fileprivate struct ExpenseChartView: View {
    let points: [DailyPoint]

    var body: some View {
        Chart {
            ForEach(points) { (point: DailyPoint) in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(Color.accentColor.opacity(0.25))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(.init(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .symbol(.circle)
                .symbolSize(40)
                .foregroundStyle(Color.accentColor)
                .annotation(position: .top, alignment: .center) {
                    Text(point.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .chartXScale(range: .plotDimension(padding: 12))
        .chartYScale(range: .plotDimension(padding: 12))
        .chartPlotStyle { plotArea in
            plotArea
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6))
        }
        .chartXAxisLabel {
            Text("Date")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYAxisLabel(position: .leading) {
            Text("Total Spent")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    GrapherView()
}

