import Foundation
import SwiftData

/// Sleep activity model
@Model
final class Sleep {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
    }
    
    /// Check if baby is currently sleeping
    var isActive: Bool {
        endTime == nil
    }
    
    /// Get duration in minutes (or time since start if still sleeping)
    var durationMinutes: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime) / 60)
    }
    
    /// Get duration in hours (for summary)
    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }
    
    /// Get a display string for the sleep
    var displayText: String {
        if isActive {
            return "Sleeping (\(durationMinutes)min)"
        }
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        if hours > 0 {
            return "Slept \(hours)h \(mins)m"
        }
        return "Slept \(mins)min"
    }
    
    /// End the sleep session
    func wake() {
        endTime = Date()
    }
}
