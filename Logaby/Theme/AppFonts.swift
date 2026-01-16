import SwiftUI

/// Typography system for Logaby
struct AppFonts {
    // Headlines
    static func headlineLarge() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    static func headlineMedium() -> Font {
        .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    static func headlineSmall() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }
    
    // Body
    static func bodyLarge() -> Font {
        .system(size: 17, weight: .regular)
    }
    
    static func bodyMedium() -> Font {
        .system(size: 15, weight: .regular)
    }
    
    static func bodySmall() -> Font {
        .system(size: 13, weight: .regular)
    }
    
    // Labels
    static func labelLarge() -> Font {
        .system(size: 14, weight: .semibold)
    }
    
    static func titleLarge() -> Font {
        .system(size: 16, weight: .semibold)
    }
}

// MARK: - Spacing Constants

struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let screenPadding: CGFloat = 20
}
