import Foundation
import SwiftData

/// Pumping side options
enum PumpingSide: String, Codable {
    case left
    case right
    case both
    
    var displayText: String {
        switch self {
        case .left: return "left"
        case .right: return "right"
        case .both: return "both sides"
        }
    }
}

/// Pumping session - tracks milk pumped by mother
@Model
final class Pumping {
    var id: UUID
    var timestamp: Date
    var amountOz: Double
    var durationMinutes: Int?
    var sideRaw: String
    
    var side: PumpingSide {
        get { PumpingSide(rawValue: sideRaw) ?? .both }
        set { sideRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        amountOz: Double,
        durationMinutes: Int? = nil,
        side: PumpingSide = .both
    ) {
        self.id = id
        self.timestamp = timestamp
        self.amountOz = amountOz
        self.durationMinutes = durationMinutes
        self.sideRaw = side.rawValue
    }
    
    /// Display text for lists
    var displayText: String {
        let oz = String(format: "%.1f", amountOz)
        if let mins = durationMinutes {
            return "\(oz)oz pumped (\(mins) min)"
        }
        return "\(oz)oz pumped"
    }
    
    /// For summary calculations
    var summaryValue: Double { amountOz }
}
