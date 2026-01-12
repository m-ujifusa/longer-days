import SwiftUI

enum Theme {
    // Background colors
    static let background = Color(hex: "0D0D0D")
    static let cardBackground = Color(hex: "1A1A1A")

    // Text colors
    static let primaryText = Color(hex: "F5F5F0")
    static let secondaryText = Color(hex: "A0978C")

    // Accent colors (positive/gains)
    static let accent = Color(hex: "FCBF49")        // Golden yellow
    static let accentSecondary = Color(hex: "F4A261") // Warm amber
    static let progressMarker = Color(hex: "FFD966")  // Bright gold

    // Negative/loss colors (summer)
    static let negative = Color(hex: "E07A5F")      // Muted coral

    // Arc gradient colors
    static let arcStart = Color(hex: "F4A261")      // Amber
    static let arcMiddle = Color(hex: "FCBF49")     // Gold
    static let arcEnd = Color(hex: "F4A261")        // Amber

    // Semantic colors
    static func gainColor(_ isGaining: Bool) -> Color {
        isGaining ? accent : negative
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
