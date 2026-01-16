import Foundation
import SwiftData

/// Weight measurement model
@Model
final class Weight {
    var id: UUID
    var timestamp: Date
    var weightLbs: Double
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        weightLbs: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.weightLbs = weightLbs
    }
    
    /// Get a display string for the weight
    var displayText: String {
        let lbs = Int(weightLbs)
        let oz = Int((weightLbs - Double(lbs)) * 16)
        if oz > 0 {
            return "\(lbs)lb \(oz)oz"
        }
        return "\(lbs)lb"
    }
    
    /// Get simple pounds display
    var simplePounds: String {
        String(format: "%.1f lbs", weightLbs)
    }
}
