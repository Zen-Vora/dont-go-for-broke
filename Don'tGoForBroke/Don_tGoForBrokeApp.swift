//
//  Don_tGoForBrokeApp.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/9/26.
//

import SwiftUI
import SwiftData

@main
struct Don_tGoForBrokeApp: App {
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"

    var sharedModelContainer: ModelContainer = {
        // Initialize an empty SwiftData schema since no default Item model is used.
        // Add your @Model types to this array when you create them, e.g. [Expense.self, Category.self]
        let schema = Schema([Expense.self, Goal.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(accentColor)
        }
        .modelContainer(sharedModelContainer)
    }

    private var accentColor: Color {
        switch accentChoice {
        case "green":
            return Color(red: 0.10, green: 0.55, blue: 0.35)
        case "gold":
            return Color(red: 0.95, green: 0.80, blue: 0.40)
        case "beige":
            return Color(red: 0.97, green: 0.90, blue: 0.72)
        case "blue":
            return .blue
        case "pink":
            return .pink
        default:
            return .green
        }
    }
}
