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
    
    @State private var editingExpense: Expense?
    @State private var editTitle: String = ""
    @State private var editAmountText: String = ""
    @State private var editDate: Date = .now
    @State private var editCategory: String = "General"
    @State private var editIsRecurring: Bool = false
    @State private var selectedExpense: Expense?
    
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

            // Placeholder for a future chart
            // Chart(...) { ... }
            //     .frame(height: 240)
            //     .padding(.top, 8)
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

#Preview {
    GrapherView()
}
