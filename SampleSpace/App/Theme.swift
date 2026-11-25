import SwiftUI

/// Shared colours and type for the space look.
enum Theme {
    static let spaceTop = Color(red: 0.03, green: 0.04, blue: 0.11)
    static let spaceBottom = Color(red: 0.07, green: 0.03, blue: 0.14)
    static let nebulaViolet = Color(red: 0.45, green: 0.22, blue: 0.75)
    static let nebulaTeal = Color(red: 0.10, green: 0.55, blue: 0.65)
    static let accent = Color(red: 0.42, green: 0.85, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.80, blue: 0.35)
    static let route = Color.white.opacity(0.55)

    static let hudFont = Font.system(.callout, design: .rounded).weight(.semibold)
    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
}

extension Color {
    /// A planet colour from a hue (0–1), tuned to look good on the dark background.
    static func planet(hue: Double, brightness: Double = 0.9) -> Color {
        Color(hue: hue, saturation: 0.65, brightness: brightness)
    }
}
