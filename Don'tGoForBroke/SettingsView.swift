import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.soundEnabled") private var soundEnabled: Bool = true
#if os(iOS)
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
#endif
    @AppStorage("settings.accentChoice") private var accentChoice: String = "green"
    @Environment(\.dismiss) private var dismiss

    private func confirmAndDismiss() {
        FeedbackManager.success()
        dismiss()
    }

    private let accentOptions: [(id: String, name: String, color: Color)] = [
        ("green", "Green", Color(red: 0.10, green: 0.55, blue: 0.35)),
        ("gold", "Gold", Color(red: 0.95, green: 0.80, blue: 0.40)),
        ("beige", "Beige", Color(red: 0.97, green: 0.90, blue: 0.72)),
        ("blue", "Blue", .blue),
        ("pink", "Pink", .pink)
    ]

    var body: some View {
        Form {
            Section(header: Text("Personalization")) {
                Picker("Accent color", selection: $accentChoice) {
                    ForEach(accentOptions, id: \.id) { option in
                        HStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 12, height: 12)
                            Text(option.name)
                        }.tag(option.id)
                    }
                }
            }

            Section(header: Text("Feedback")) {
                Toggle("Sound effects", isOn: $soundEnabled)
#if os(iOS)
                Toggle("Haptics", isOn: $hapticsEnabled)
#endif
            }

            Section(footer: Text("Settings are saved automatically and sync across launches.")) {
                EmptyView()
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
