//
//  ContentView.swift
//  Don'tGoForBroke
//
//  Created by Zen Vora on 1/9/26.
//

import SwiftUI
import SwiftData

#if os(macOS)
private enum Destination: Hashable {
    case wantNeed
    case grapher
    case settings
}
#endif // os(macOS)

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
#if os(iOS)
    @State private var selectedTab = 0
#endif
#if os(macOS)
    @State private var selection: Destination? = .wantNeed
    @State private var showingSettings = false
#endif
    
    var body: some View {
#if os(macOS)
        NavigationSplitView {
            List(selection: $selection) {
                Section("Tools") {
                    NavigationLink(value: Destination.wantNeed) {
                        Label("Want vs Need", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(value: Destination.grapher) {
                        Label("Expense Grapher", systemImage: "chart.xyaxis.line")
                    }
                    NavigationLink(value: Destination.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Don'tGoForBroke")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            switch selection {
            case .wantNeed:
                WantVNeedView()
                    .navigationTitle("Want vs Need")
            case .grapher:
                GrapherView()
                    .navigationTitle("Expense Grapher")
            case .settings:
                SettingsView()
                    .navigationTitle("Settings")
            case .none:
                ContentUnavailableView(
                    "Welcome",
                    systemImage: "chart.pie.fill",
                    description: Text("Choose a section from the sidebar to get started.")
                )
            }
        }
#elseif os(iOS)
        TabView(selection: $selectedTab) {
            WantVNeedView()
                .tabItem {
                    Label("Want vs Need", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            GrapherView()
                .tabItem {
                    Label("Expense Grapher", systemImage: "chart.xyaxis.line")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
#endif
    }
}

#Preview {
    ContentView()
}
