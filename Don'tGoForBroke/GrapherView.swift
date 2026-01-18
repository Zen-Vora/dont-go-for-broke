//
//  GrapherView.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/14/26.
//

import SwiftUI
import Charts
import SwiftData

struct GrapherView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = .now
    @State private var category: String = "General"
    @State private var isRecurring: Bool = false
    
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
                        }
                    }
                }
            }

            // Placeholder for a future chart
            // Chart(...) { ... }
            //     .frame(height: 240)
            //     .padding(.top, 8)
        }
        .padding()
        .navigationTitle("Expense Grapher")
    }
}

#Preview {
    GrapherView()
}
