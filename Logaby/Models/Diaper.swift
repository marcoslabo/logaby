import Foundation
import SwiftData

/// Type of diaper
enum DiaperType: String, Codable, CaseIterable {
    case wet
    case dirty
    case mixed
}

/// Diaper change activity model
@Model
final class Diaper {
    var id: UUID
    var timestamp: Date
    var type: DiaperType
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: DiaperType
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
    }
    
    /// Get a display string for the diaper
    var displayText: String {
        switch type {
        case .wet:
            return "Wet diaper"
        case .dirty:
            return "Dirty diaper"
        case .mixed:
            return "Wet & dirty diaper"
        }
    }
}
