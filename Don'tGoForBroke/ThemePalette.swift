import SwiftUI

struct ThemePalette {
    let accentChoice: String

    var primary: Color {
        switch accentChoice {
        case "green":
            return Self.green
        case "gold":
            return Self.gold
        case "beige":
            return Self.beige
        case "blue":
            return .blue
        case "pink":
            return .pink
        default:
            return Self.green
        }
    }

    var secondary: Color {
        switch accentChoice {
        case "gold":
            return Self.green
        default:
            return Self.gold
        }
    }

    var tertiary: Color {
        switch accentChoice {
        case "beige":
            return Self.green
        default:
            return Self.beige
        }
    }

    private static let green = Color(red: 0.10, green: 0.55, blue: 0.35)
    private static let gold = Color(red: 0.95, green: 0.80, blue: 0.40)
    private static let beige = Color(red: 0.97, green: 0.90, blue: 0.72)
}
