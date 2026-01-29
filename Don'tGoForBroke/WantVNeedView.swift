//
//  WantVNeedView.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/14/26.
//

import SwiftUI

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
    
    @State private var itemName: String = ""
    @State private var currentQuestion: Int = -1 // -1 means entering item name
    @State private var answers: [Any] = []
    
    // Questions and logic for scoring answers as 'needness'
    let questions: [Question] = [
        .init(text: "Is this item essential for your daily life?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 10 : 0 }),
        .init(text: "Will not having it negatively impact your health or safety?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 10 : 0 }),
        .init(text: "What is the price of this item? (in your currency)", type: .number, choices: nil, score: { guard let n = $0 as? Double else { return 0 }; return n < 50 ? 6 : n < 200 ? 3 : 0 }),
        .init(text: "Can you afford it right now without debt or sacrificing essentials?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 8 : 0 }),
        .init(text: "How long will you realistically use it?", type: .choices, choices: ["<1 month", "1-6 months", ">6 months"], score: { ($0 as? Int) == 2 ? 8 : ($0 as? Int) == 1 ? 4 : 0 }),
        .init(text: "Is there a cheaper or better alternative?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 5 }),
        .init(text: "Would you buy this if it cost twice as much?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 5 : 0 }),
        .init(text: "Does it help you achieve an important goal?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 9 : 0 }),
        .init(text: "Will it lose most of its value quickly?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 5 }),
        .init(text: "Is this an impulse purchase?", type: .yesNo, choices: nil, score: { ($0 as? Bool) == true ? 0 : 4 })
    ]
    
    var body: some View { // Start page
        VStack(spacing: 28) {
            Spacer()
            if currentQuestion == -1 {
                VStack(spacing: 12) {
                    Text("What do you want to buy?")
                        .font(.title)
                        .bold()
                    TextField("Enter item name", text: $itemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Start") {
                        answers = []
                        currentQuestion = 0
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty)
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
                        currentQuestion += 1
                    }
                    .buttonStyle(.borderedProminent)
                    Button("No") {
                        answers.append(false)
                        currentQuestion += 1
                    }
                    .buttonStyle(.bordered)
                }
            case .number:
                NumberInputView { number in
                    answers.append(number)
                    currentQuestion += 1
                }
            case .choices:
                if let options = question.choices {
                    // We need a @State for the picker selection; since inside func, use a local @State via wrapper View
                    ChoicesQuestionView(options: options, initialSelection: answers.count > currentQuestion ? answers[currentQuestion] as? Int ?? 0 : 0) { selectedIndex in
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
            Button("Start Over") {
                itemName = ""
                answers = []
                currentQuestion = -1
            }
            .padding(.top, 24)
        }
        .padding()
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
}
// Helper for number input (price)
struct NumberInputView: View {
    @State private var valueString = ""
    var onDone: (Double) -> Void
    var body: some View {
        VStack {
            TextField("Enter number ", text: $valueString)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Next") {
                let val = Double(valueString) ?? 0
                onDone(val)
            }
            .disabled(Double(valueString) == nil)
            .buttonStyle(.borderedProminent)
        }
    }
}

// Separate view for choices question to maintain @State for selection
struct ChoicesQuestionView: View {
    let options: [String]
    @State private var selection: Int
    var onNext: (Int) -> Void
    
    init(options: [String], initialSelection: Int, onNext: @escaping (Int) -> Void) {
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
            .padding(.vertical)
            Button("Next") {
                onNext(selection)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

