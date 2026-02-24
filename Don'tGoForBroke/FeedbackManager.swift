import SwiftUI
#if os(iOS)
import AVFoundation
#endif
#if os(macOS)
import AppKit
#endif

enum FeedbackManager {
    @AppStorage("settings.soundEnabled") private static var soundEnabled: Bool = true
    @AppStorage("settings.hapticsEnabled") private static var hapticsEnabled: Bool = true

    static func success() { playSound(named: "Tock"); haptic(.success) }
    static func tap() { playSound(named: "Tock"); haptic(.generic) }
    static func warning() { playSound(named: "Tock"); haptic(.warning) }

    private static func playSound(named: String) {
        guard soundEnabled else { return }
#if os(iOS)
        AudioServicesPlaySystemSound(1104) // Tock-like
#elseif os(macOS)
        NSSound.beep()
#endif
    }

    private enum HType { case success, generic, warning }

    private static func haptic(_ type: HType) {
#if os(iOS)
        guard hapticsEnabled else { return }
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .generic:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
#elseif os(macOS)
        guard hapticsEnabled else { return }
        let performer = NSHapticFeedbackManager.defaultPerformer
        switch type {
        case .success:
            performer.perform(.levelChange, performanceTime: .now)
        case .warning, .generic:
            performer.perform(.alignment, performanceTime: .now)
        }
#endif
    }
}
