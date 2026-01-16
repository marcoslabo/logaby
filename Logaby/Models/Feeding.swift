import Foundation
import SwiftData

/// Type of feeding
enum FeedingType: String, Codable, CaseIterable {
    case bottle
    case nursing
}

/// Side for nursing
enum NursingSide: String, Codable, CaseIterable {
    case left
    case right
    case both
}

/// Feeding activity model
@Model
final class Feeding {
    var id: UUID
    var timestamp: Date
    var type: FeedingType
    var amountOz: Double?
    var durationMinutes: Int?
    var side: NursingSide?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: FeedingType,
        amountOz: Double? = nil,
        durationMinutes: Int? = nil,
        side: NursingSide? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.amountOz = amountOz
        self.durationMinutes = durationMinutes
        self.side = side
    }
    
    /// Create a bottle feeding
    static func bottle(amountOz: Double, timestamp: Date = Date()) -> Feeding {
        Feeding(timestamp: timestamp, type: .bottle, amountOz: amountOz)
    }
    
    /// Create a nursing feeding
    static func nursing(durationMinutes: Int, side: NursingSide = .both, timestamp: Date = Date()) -> Feeding {
        Feeding(timestamp: timestamp, type: .nursing, durationMinutes: durationMinutes, side: side)
    }
    
    /// Get a display string for the feeding
    var displayText: String {
        if type == .bottle {
            return "\(Int(amountOz ?? 0))oz bottle"
        } else {
            let sideText = side == .both ? "" : " \(side?.rawValue ?? "")"
            return "\(durationMinutes ?? 0)min nursing\(sideText)"
        }
    }
    
    /// Get amount for summary (oz for bottle only)
    var summaryValue: Double {
        type == .bottle ? (amountOz ?? 0) : 0
    }
}
