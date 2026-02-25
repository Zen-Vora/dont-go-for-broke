import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss

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

            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let targetAmount = Decimal(string: targetAmountText.replacingOccurrences(of: ",", with: "")) ?? 0
                        let goal = Goal(
                            title: title,
                            targetAmount: targetAmount,
                            targetDate: targetDateEnabled ? targetDate : nil
                        )
                        onSave(goal)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || Decimal(string: targetAmountText.replacingOccurrences(of: ",", with: "")) == nil)
                }
            }
        }
    }
}

#Preview {
    GoalEditorView(onSave: { _ in })
}
