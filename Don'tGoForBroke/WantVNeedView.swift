//
//  WantVNeedView.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/14/26.
//

import SwiftUI
<<<<<<< Updated upstream
import SwiftData
#if os(iOS)
import AVFoundation
#endif
=======
import Foundation

fileprivate enum ThemeColors {
    static let green = Color(red: 0.10, green: 0.55, blue: 0.35)
    static let gold = Color(red: 0.95, green: 0.80, blue: 0.40)
    static let beige = Color(red: 0.97, green: 0.90, blue: 0.72)
}
>>>>>>> Stashed changes

struct WantNeedHistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let itemName: String
    let needPct: Int
    let wantPct: Int
    let date: Date
}

struct WantVNeedView: View {
    struct Question {
        let text: String
        let type: QuestionType
        let choices: [String]?
        let score: (Any) -> Int

        enum QuestionType {
            case yesNo, number, choices
        }
    }
<<<<<<< Updated upstream
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @State private var itemName: String = ""
    @State private var currentQuestion: Int = -1 // -1 means entering item name
    @State private var answers: [Any] = []
    @State private var showingGoalEditor = false
    
=======

    @State private var itemName: String = ""
    @State private var currentQuestion: Int = -1 // -1 means entering item name
    @State private var answers: [Any] = []
    @AppStorage("wantNeedHistory") private var historyData: String = ""
    @State private var history: [WantNeedHistoryEntry] = []
    @State private var editingEntry: WantNeedHistoryEntry?
    @State private var editingName: String = ""

>>>>>>> Stashed changes
    // Questions and logic for scoring answers as 'needness'
    let questions: [Question] = [
        .init(text: "Is this item essential for your daily life?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 10 : 0 }),
        .init(text: "Will not having it negatively impact your health or safety?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 10 : 0 }),
        .init(text: "What is the price of this item? (in your currency)", type: .number, choices: nil, score: { guard let n = $0 as? Double else { return 0 }; return n < 50 ? 6 : n < 200 ? 3 : 0 }),
        .init(text: "Can you afford it right now without debt or sacrificing essentials?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 8 : 0 }),
        .init(text: "How long will you realistically use it?", type: .choices, choices: ["<1 month", "1-6 months", ">6 months"], score: { ($0 as? Int) == 2 ? 8 : ($0 as? Int) == 1 ? 4 : 0 }),
        .init(text: "Is there a cheaper or better alternative?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 5 }),
        .init(text: "Do you already have this or a similar item?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 5 }),
        .init(text: "Would you buy this if it cost twice as much?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 5 : 0 }),
        .init(text: "Does it help you achieve an important goal?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 9 : 0 }),
        .init(text: "Will it lose most of its value quickly?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 5 }),
        .init(text: "Is this an impulse purchase?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 4 })
    ]
<<<<<<< Updated upstream
    
    private var theme: ThemePalette { ThemePalette(accentChoice: accentChoice) }
=======
>>>>>>> Stashed changes

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [theme.primary.opacity(0.35), theme.secondary.opacity(0.28), theme.tertiary.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var body: some View { // Start page
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                if currentQuestion >= 0 && currentQuestion < questions.count {
                    progressHeader
                }
                if currentQuestion == -1 {
                    VStack(spacing: 12) {
                        Text("What do you want to buy?")
                            .font(.title)
                            .bold()
                        TextField("Enter item name: ", text: $itemName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ThemeColors.gold.opacity(0.22))
                            )
                            .padding()
                        Button("Start") {
                            answers = []
                            currentQuestion = 0
                        }
                        .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.glassProminent)
                    }
                    if !history.isEmpty {
                        historySection
                    }
                } else if currentQuestion < questions.count {
                    questionView(for: questions[currentQuestion])
                } else {
                    resultView
                }
                Spacer()
            }
            .animation(.default, value: currentQuestion)
            .padding()
            .background(backgroundGradient)
            .tint(ThemeColors.green)
            .navigationTitle("Want vs Need")
            .onAppear {
                if history.isEmpty {
                    history = loadHistory()
                }
            }
#if os(iOS)
            .sheet(item: $editingEntry) { entry in
                VStack(spacing: 16) {
                    Text("Edit History Item")
                        .font(.headline)
                    TextField("Item name", text: $editingName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
<<<<<<< Updated upstream
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.secondary.opacity(0.22))
                        )
                        .padding()
                    Button("Start") {
                        answers = []
                        currentQuestion = 0
=======
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            editingEntry = nil
                        }
                        .buttonStyle(.bordered)
                        Button("Save") {
                            updateHistoryEntry(entry: entry, newName: editingName)
                            editingEntry = nil
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
>>>>>>> Stashed changes
                    }
                }
                .padding()
                .onAppear {
                    editingName = entry.itemName
                }
            }
<<<<<<< Updated upstream
            Spacer()
        }
        .animation(.default, value: currentQuestion)
        .padding()
        .background(backgroundGradient)
        .tint(theme.primary)
        .navigationTitle("Want vs Need")
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView(
                prefillTitle: itemName,
                prefillAmount: estimatedGoalAmount,
                onSave: { newGoal in
                    modelContext.insert(newGoal)
                    try? modelContext.save()
                }
            )
        }
=======
#endif
>>>>>>> Stashed changes
#if os(macOS)
            .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
#elseif os(iOS)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
#endif
        }
    }

    @ViewBuilder
    func questionView(for question: Question) -> some View { // structure for answering questions
        VStack(spacing: 16) {
            Text(question.text.replacingOccurrences(of: "this item", with: itemName))
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            switch question.type {
            case .yesNo:
                HStack(spacing: 32) {
                    Button("Yes") {
                        answers.append(true)
                        FeedbackManager.tap()
                        currentQuestion += 1
                    }
                    .buttonStyle(.glassProminent)
                    Button("No") {
                        answers.append(false)
                        FeedbackManager.tap()
                        currentQuestion += 1
                    }
                    .buttonStyle(.bordered)
                }
            case .number:
                NumberInputView(theme: theme) { number in
                    FeedbackManager.tap()
                    onNumberEntered(number: number)
                }
            case .choices:
                if let options = question.choices {
                    ChoicesQuestionView(theme: theme, options: options, initialSelection: answers.count > currentQuestion ? answers[currentQuestion] as? Int ?? 0 : 0) { selectedIndex in
                        if answers.count > currentQuestion {
                            answers[currentQuestion] = selectedIndex
                        } else {
                            answers.append(selectedIndex)
                        }
                        currentQuestion += 1
                    }
                }
            }
        }
        .padding()
        .glassEffect(.regular.tint(theme.secondary.opacity(0.30)), in: .rect(cornerRadius: 16))
    }
    
    private func onNumberEntered(number: Double) {
        answers.append(number)
        currentQuestion += 1
    }

    private var estimatedGoalAmount: Decimal? {
        guard let price = answers.compactMap({ $0 as? Double }).first else { return nil }
        return Decimal(price)
    }

    var resultView: some View {
        let totalScore = zip(questions, answers).map { q, a in q.score(a) }.reduce(0, +)
        // Calculate max score assuming best answers: yes for yesNo, 0.0 (lowest) for number (adjusted below), last index for choices
        let maxScore = questions.enumerated().map { (idx, q) in
            switch q.type {
            case .yesNo:
                return q.score(true)
            case .number:
                // For number, assume lowest price (0.0) gets max score
                return q.score(0.0)
            case .choices:
                // For choices, assume last index (best)
                return q.score((q.choices?.count ?? 1) - 1)
            }
        }.reduce(0, +)
        let pct = maxScore > 0 ? Double(totalScore) / Double(maxScore) : 0
        let needPct = Int((pct * 100).rounded())
        let wantPct = 100 - needPct
        return VStack(spacing: 16) {
            Text("Your Result:")
                .font(.headline)
            Text("Need: \(needPct)% | Want: \(wantPct)%")
                .font(.title)
                .bold()
                .foregroundColor(needPct > 60 ? .green : (needPct > 40 ? .yellow : .orange))
            Text(summaryText(needPct: needPct))
                .font(.title3)
                .multilineTextAlignment(.center)
            Button("Save as Goal") {
                FeedbackManager.tap()
                showingGoalEditor = true
            }
            .buttonStyle(.bordered)

            Button("Start Over") {
                FeedbackManager.warning()
                itemName = ""
                answers = []
                currentQuestion = -1
            }
            .padding(.top, 16)
            .buttonStyle(.glassProminent)

        }
        .padding()
<<<<<<< Updated upstream
        .glassEffect(.regular.tint(theme.secondary.opacity(0.30)), in: .rect(cornerRadius: 16))
=======
        .glassEffect(.regular.tint(ThemeColors.gold.opacity(0.30)), in: .rect(cornerRadius: 16))
        .onAppear {
            saveToHistoryIfNeeded(needPct: needPct, wantPct: wantPct)
        }
>>>>>>> Stashed changes
    }

    func summaryText(needPct: Int) -> String {
        if needPct > 70 {
            return "\(itemName) is quite likely a NEED. This purchase seems justified."
        } else if needPct > 40 {
            return "\(itemName) is somewhere between a want and a need. Consider carefully."
        } else {
            return "\(itemName) is more of a WANT. Think twice before buying."
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 12) {
            Text("Question \(currentQuestion + 1) of \(questions.count)")
                .font(.subheadline)
                .foregroundStyle(theme.primary.opacity(0.9))
            ProgressView(value: Double(currentQuestion), total: Double(questions.count))
                .progressViewStyle(.linear)
        }
        .padding(.horizontal)
        .padding(10)
        .background(
            Capsule()
                .fill(theme.secondary.opacity(0.18))
        )
        .glassEffect(.regular.tint(theme.secondary.opacity(0.25)), in: .capsule)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
            ForEach(history) { entry in
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.itemName)
                            .font(.subheadline)
                            .bold()
                        Text("Need \(entry.needPct)% • \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Edit") {
                        editingName = entry.itemName
                        editingEntry = entry
                    }
                    .buttonStyle(.bordered)
                    Button("Delete") {
                        deleteHistoryEntry(entry)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ThemeColors.gold.opacity(0.18))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(ThemeColors.gold.opacity(0.22)), in: .rect(cornerRadius: 16))
    }

    private func loadHistory() -> [WantNeedHistoryEntry] {
        guard let data = historyData.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([WantNeedHistoryEntry].self, from: data)) ?? []
    }

    private func persistHistory() {
        guard let data = try? JSONEncoder().encode(history),
              let string = String(data: data, encoding: .utf8) else { return }
        historyData = string
    }

    private func deleteHistoryEntry(_ entry: WantNeedHistoryEntry) {
        history.removeAll { $0.id == entry.id }
        persistHistory()
    }

    private func updateHistoryEntry(entry: WantNeedHistoryEntry, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        if let index = history.firstIndex(where: { $0.id == entry.id }) {
            history[index] = WantNeedHistoryEntry(
                id: entry.id,
                itemName: trimmedName,
                needPct: entry.needPct,
                wantPct: entry.wantPct,
                date: entry.date
            )
            persistHistory()
        }
    }

    private func saveToHistoryIfNeeded(needPct: Int, wantPct: Int) {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        if let latest = history.first, latest.itemName == trimmedName, latest.needPct == needPct {
            return
        }
        let entry = WantNeedHistoryEntry(
            id: UUID(),
            itemName: trimmedName,
            needPct: needPct,
            wantPct: wantPct,
            date: Date()
        )
        history.insert(entry, at: 0)
        if history.count > 20 {
            history = Array(history.prefix(20))
        }
        persistHistory()
    }
}
// Helper for number input (price)
struct NumberInputView: View {
    let theme: ThemePalette
    @State private var valueString = ""
    var onDone: (Double) -> Void
    var body: some View {
        VStack {
            TextField("Enter number ", text: $valueString)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.secondary.opacity(0.22))
                )
                .padding()
            Button("Next") {
                // Allow currency symbols and formatting; strip everything except digits, decimal separators, and minus
                let sanitized = valueString
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: " ", with: "")
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
                    .replacingOccurrences(of: "$", with: "")
                let val = Double(sanitized) ?? 0
                onDone(val)
            }
            .disabled({
                let sanitized = valueString
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: " ", with: "")
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
                    .replacingOccurrences(of: "$", with: "")
                return Double(sanitized) == nil
            }())
            .buttonStyle(.glassProminent)
        }
    }
}

// Separate view for choices question to maintain @State for selection
struct ChoicesQuestionView: View {
    let theme: ThemePalette
    let options: [String]
    @State private var selection: Int
    var onNext: (Int) -> Void
<<<<<<< Updated upstream
    
    init(theme: ThemePalette, options: [String], initialSelection: Int, onNext: @escaping (Int) -> Void) {
        self.theme = theme
=======

    init(options: [String], initialSelection: Int, onNext: @escaping (Int) -> Void) {
>>>>>>> Stashed changes
        self.options = options
        self._selection = State(initialValue: initialSelection)
        self.onNext = onNext
    }

    var body: some View {
        VStack {
            Picker("", selection: $selection) {
                ForEach(options.indices, id: \.self) { i in
                    Text(options[i])
                }
            }
            .pickerStyle(.segmented)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondary.opacity(0.18))
            )
            .padding(.vertical)
            Button("Next") {
                onNext(selection)
            }
            .buttonStyle(.glassProminent)
        }
    }
}
