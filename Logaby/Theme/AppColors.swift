import SwiftUI

/// Logaby Color Palette
/// Soft, warm, calming colors made for exhausted parents at 3am
struct AppColors {
    // Background colors
    static let background = Color(hex: "FFFBF7") // Cream
    static let cardBackground = Color.white
    
    // Primary action color
    static let primary = Color(hex: "FF8A6C") // Coral
    static let primaryLight = Color(hex: "FFB4A0")
    
    // Accent colors
    static let sage = Color(hex: "B8D4C8")
    static let peach = Color(hex: "FFE5D9")
    static let lavender = Color(hex: "E8E0F0")
    static let yellow = Color(hex: "FFF3CD")
    
    // Text colors
    static let textDark = Color(hex: "2D3436")
    static let textSoft = Color(hex: "636E72")
    static let textLight = Color(hex: "95A5A6")
    
    // Semantic colors for activity types
    static let feedingAccent = primary
    static let sleepAccent = sage
    static let diaperAccent = lavender
    static let weightAccent = yellow
    static let pumpingAccent = Color(hex: "E8A0D0") // Pink
    
    // UI colors
    static let divider = Color(hex: "EEEEEE")
    static let shadow = Color.black.opacity(0.1)
    static let error = Color(hex: "E74C3C")
    static let success = Color(hex: "27AE60")
}

// MARK: - Color Extension for Hex

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
            (a, r, g, b) = (255, 0, 0, 0)
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
