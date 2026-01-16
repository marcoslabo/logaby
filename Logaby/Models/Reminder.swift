import Foundation
import SwiftData

/// A scheduled reminder for baby activities
@Model
final class Reminder {
    var id: UUID
    var title: String
    var activityTypeRaw: String  // Store as raw string for SwiftData compatibility
    var hour: Int       // 0-23
    var minute: Int     // 0-59
    var isEnabled: Bool
    var repeatDays: [Int]  // 0=Sunday to 6=Saturday, empty=every day
    
    /// Activity type computed from raw value
    var activityType: ActivityType {
        get { ActivityType(rawValue: activityTypeRaw) ?? .feeding }
        set { activityTypeRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        activityType: ActivityType,
        hour: Int,
        minute: Int,
        isEnabled: Bool = true,
        repeatDays: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.activityTypeRaw = activityType.rawValue
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
    }
    
    /// Formatted time string (e.g., "7:00 AM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }
    
    /// Days string (e.g., "Mon, Wed, Fri" or "Every day")
    var daysString: String {
        if repeatDays.isEmpty {
            return "Every day"
        }
        
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let selectedDays = repeatDays.sorted().compactMap { dayNames[safe: $0] }
        return selectedDays.joined(separator: ", ")
    }
    
    /// Icon for this reminder type
    var icon: String {
        activityType.icon
    }
}

// MARK: - Array Safe Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Schedule Templates

struct ScheduleTemplate {
    let name: String
    let description: String
    let reminders: [(title: String, type: ActivityType, hour: Int, minute: Int)]
    
    /// Moms on Call 8+ week schedule
    static let momsOnCall = ScheduleTemplate(
        name: "Moms on Call",
        description: "8+ week schedule",
        reminders: [
            ("Morning Feed", .feeding, 7, 0),
            ("Morning Nap", .sleep, 9, 0),
            ("Mid-Morning Feed", .feeding, 10, 30),
            ("Afternoon Nap", .sleep, 12, 30),
            ("Afternoon Feed", .feeding, 14, 0),
            ("Late Nap", .sleep, 16, 0),
            ("Evening Feed", .feeding, 17, 30),
            ("Bath Time", .diaper, 18, 30),  // Using diaper for bath (closest)
            ("Bedtime Feed", .feeding, 19, 0)
        ]
    )
    
    /// Create Reminder objects from this template
    func createReminders() -> [Reminder] {
        reminders.map { item in
            Reminder(
                title: item.title,
                activityType: item.type,
                hour: item.hour,
                minute: item.minute
            )
        }
    }
}
