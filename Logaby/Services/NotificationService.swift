import Foundation
import UserNotifications

/// Service for managing local push notifications
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Authorization
    
    /// Request notification permission
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorization() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule a daily notification for a reminder
    func scheduleReminder(_ reminder: Reminder) {
        guard reminder.isEnabled else {
            cancelReminder(reminder)
            return
        }
        
        let center = UNUserNotificationCenter.current()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminderBody(for: reminder)
        content.sound = .default
        content.categoryIdentifier = "REMINDER"
        
        // If no specific days, schedule for every day
        if reminder.repeatDays.isEmpty {
            scheduleDaily(reminder: reminder, content: content)
        } else {
            // Schedule for specific days
            for weekday in reminder.repeatDays {
                scheduleForWeekday(reminder: reminder, weekday: weekday, content: content)
            }
        }
    }
    
    private func scheduleDaily(reminder: Reminder, content: UNNotificationContent) {
        var dateComponents = DateComponents()
        dateComponents.hour = reminder.hour
        dateComponents.minute = reminder.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func scheduleForWeekday(reminder: Reminder, weekday: Int, content: UNNotificationContent) {
        var dateComponents = DateComponents()
        dateComponents.hour = reminder.hour
        dateComponents.minute = reminder.minute
        dateComponents.weekday = weekday + 1  // Calendar uses 1-7 (Sun=1)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "\(reminder.id.uuidString)-\(weekday)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func reminderBody(for reminder: Reminder) -> String {
        switch reminder.activityType {
        case .feeding:
            return "Time to feed baby 🍼"
        case .sleep:
            return "Time for baby's nap 😴"
        case .diaper:
            return "Time for a diaper check or bath 🛁"
        case .weight:
            return "Time to weigh baby ⚖️"
        case .pumping:
            return "Time to pump 🤱"
        }
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel notifications for a specific reminder
    func cancelReminder(_ reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        
        // Cancel main notification
        var identifiers = [reminder.id.uuidString]
        
        // Also cancel weekday-specific notifications
        for weekday in 0..<7 {
            identifiers.append("\(reminder.id.uuidString)-\(weekday)")
        }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Cancel all scheduled notifications
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Reschedule All
    
    /// Reschedule all enabled reminders (call after app becomes active)
    func rescheduleAll(_ reminders: [Reminder]) {
        // Cancel all first
        cancelAllReminders()
        
        // Reschedule enabled ones
        for reminder in reminders where reminder.isEnabled {
            scheduleReminder(reminder)
        }
    }
}
