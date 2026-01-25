import Foundation

/// Unified activity type for displaying in lists
enum ActivityType: String, CaseIterable, Identifiable {
    case feeding
    case diaper
    case sleep
    case weight
    case pumping
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .feeding: return "drop.fill"
        case .diaper: return "sparkles"
        case .sleep: return "moon.fill"
        case .weight: return "scalemass.fill"
        case .pumping: return "heart.fill"
        }
    }
}

/// Wrapper struct for displaying any activity type in a unified way
struct Activity: Identifiable {
    let type: ActivityType
    let id: UUID
    let timestamp: Date
    let displayText: String
    let detailText: String  // New: shows time/duration details
    let endTime: Date?      // New: for sleep time ranges
    let source: AnyObject   // Reference to original model for editing
    
    /// Format time as "8:30 PM"
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    static func from(feeding: Feeding) -> Activity {
        var detail = "at \(formatTime(feeding.timestamp))"
        if feeding.type == .nursing, let duration = feeding.durationMinutes {
            detail += " • \(duration) min"
        }
        
        return Activity(
            type: .feeding,
            id: feeding.id,
            timestamp: feeding.timestamp,
            displayText: feeding.displayText,
            detailText: detail,
            endTime: nil,
            source: feeding
        )
    }
    
    static func from(diaper: Diaper) -> Activity {
        Activity(
            type: .diaper,
            id: diaper.id,
            timestamp: diaper.timestamp,
            displayText: diaper.displayText,
            detailText: "at \(formatTime(diaper.timestamp))",
            endTime: nil,
            source: diaper
        )
    }
    
    static func from(sleep: Sleep) -> Activity {
        let detail: String
        if let endTime = sleep.endTime {
            detail = "\(formatTime(sleep.startTime)) - \(formatTime(endTime))"
        } else {
            detail = "Started \(formatTime(sleep.startTime))"
        }
        
        return Activity(
            type: .sleep,
            id: sleep.id,
            timestamp: sleep.startTime,
            displayText: sleep.displayText,
            detailText: detail,
            endTime: sleep.endTime,
            source: sleep
        )
    }
    
    static func from(weight: Weight) -> Activity {
        Activity(
            type: .weight,
            id: weight.id,
            timestamp: weight.timestamp,
            displayText: weight.displayText,
            detailText: "at \(formatTime(weight.timestamp))",
            endTime: nil,
            source: weight
        )
    }
    
    static func from(pumping: Pumping) -> Activity {
        Activity(
            type: .pumping,
            id: pumping.id,
            timestamp: pumping.timestamp,
            displayText: pumping.displayText,
            detailText: "at \(formatTime(pumping.timestamp))",
            endTime: nil,
            source: pumping
        )
    }
}

/// Daily summary for the dashboard
struct DailySummary {
    let totalOz: Double
    let totalPumpedOz: Double
    let totalNursingMinutes: Int  // NEW: total nursing time
    let totalSleepHours: Double
    let daySleepHours: Double
    let nightSleepHours: Double
    let diaperCount: Int
    let wetDiaperCount: Int
    let dirtyDiaperCount: Int
    let mixedDiaperCount: Int
    let latestWeight: Double?
    let lastWeightDate: Date?
    let activeSleep: Sleep?
    
    /// Formatted diaper breakdown string (e.g., "3💧 2💩")
    var diaperBreakdown: String {
        var parts: [String] = []
        let wetTotal = wetDiaperCount + mixedDiaperCount
        let dirtyTotal = dirtyDiaperCount + mixedDiaperCount
        if wetTotal > 0 { parts.append("\(wetTotal)💧") }
        if dirtyTotal > 0 { parts.append("\(dirtyTotal)💩") }
        return parts.isEmpty ? "0" : parts.joined(separator: " ")
    }
    
    static var empty: DailySummary {
        DailySummary(
            totalOz: 0,
            totalPumpedOz: 0,
            totalNursingMinutes: 0,
            totalSleepHours: 0,
            daySleepHours: 0,
            nightSleepHours: 0,
            diaperCount: 0,
            wetDiaperCount: 0,
            dirtyDiaperCount: 0,
            mixedDiaperCount: 0,
            latestWeight: nil,
            lastWeightDate: nil,
            activeSleep: nil
        )
    }
}

/// Report summary for a date range
struct ReportSummary {
    let startDate: Date
    let endDate: Date
    let totalFeedingOz: Double
    let feedingCount: Int
    let totalSleepHours: Double
    let sleepCount: Int
    let diaperCount: Int
    let wetDiaperCount: Int
    let dirtyDiaperCount: Int
    let startWeight: Double?
    let endWeight: Double?
    
    var weightChange: Double? {
        guard let start = startWeight, let end = endWeight else { return nil }
        return end - start
    }
    
    var avgFeedingOzPerDay: Double {
        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        return totalFeedingOz / Double(days)
    }
    
    var avgSleepHoursPerDay: Double {
        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        return totalSleepHours / Double(days)
    }
}
