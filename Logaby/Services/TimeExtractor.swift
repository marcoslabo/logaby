import Foundation

/// Extracts time references from voice input
/// Supports: "at 2pm", "at 2:30pm", "X hours ago", "X minutes ago", "1am", "1 am"
struct TimeExtractor {
    
    // MARK: - Public API
    
    /// Extract a time reference from text
    /// Returns: (timestamp, textWithTimeRemoved)
    static func extract(from text: String) -> (Date, String) {
        let now = Date()
        let calendar = Calendar.current
        var cleanedText = text
        
        // Pattern 1: "X hours ago"
        if let result = extractHoursAgo(from: text, now: now, calendar: calendar) {
            return result
        }
        
        // Pattern 2: "X minutes ago"
        if let result = extractMinutesAgo(from: text, now: now, calendar: calendar) {
            return result
        }
        
        // Pattern 3: "at 2pm", "at 2:30pm", "at 2:30 pm"
        if let result = extractAtTime(from: text, now: now, calendar: calendar) {
            return result
        }
        
        // Pattern 4: "1am", "1 am", "2pm", "2:30pm" (without "at")
        if let result = extractDirectTime(from: text, now: now, calendar: calendar) {
            return result
        }
        
        // No time found - return current time
        return (now, text)
    }
    
    // MARK: - Private Extraction Methods
    
    private static func extractHoursAgo(from text: String, now: Date, calendar: Calendar) -> (Date, String)? {
        let pattern = #"(\d+)\s*hours?\s*ago"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text),
              let hours = Int(text[range]),
              let timestamp = calendar.date(byAdding: .hour, value: -hours, to: now),
              let fullRange = Range(match.range, in: text) else {
            return nil
        }
        
        let cleanedText = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
        return (timestamp, cleanedText)
    }
    
    private static func extractMinutesAgo(from text: String, now: Date, calendar: Calendar) -> (Date, String)? {
        let pattern = #"(\d+)\s*(?:minutes?|mins?)\s*ago"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text),
              let mins = Int(text[range]),
              let timestamp = calendar.date(byAdding: .minute, value: -mins, to: now),
              let fullRange = Range(match.range, in: text) else {
            return nil
        }
        
        let cleanedText = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
        return (timestamp, cleanedText)
    }
    
    private static func extractAtTime(from text: String, now: Date, calendar: Calendar) -> (Date, String)? {
        let pattern = #"at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              var hour = Int(text[hourRange]) else {
            return nil
        }
        
        var minute = 0
        if match.range(at: 2).location != NSNotFound,
           let minRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minRange]) ?? 0
        }
        
        // Handle AM/PM
        if match.range(at: 3).location != NSNotFound,
           let ampmRange = Range(match.range(at: 3), in: text) {
            let ampm = String(text[ampmRange]).lowercased()
            if ampm == "pm" && hour < 12 { hour += 12 }
            else if ampm == "am" && hour == 12 { hour = 0 }
        } else {
            // No AM/PM - smart default based on current time
            hour = smartHourDefault(hour: hour, calendar: calendar, now: now)
        }
        
        guard let timestamp = createDate(hour: hour, minute: minute, calendar: calendar, now: now),
              let fullRange = Range(match.range, in: text) else {
            return nil
        }
        
        let cleanedText = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
        return (timestamp, cleanedText)
    }
    
    private static func extractDirectTime(from text: String, now: Date, calendar: Calendar) -> (Date, String)? {
        // Match time with am/pm directly (no "at" prefix)
        let pattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              var hour = Int(text[hourRange]),
              let ampmRange = Range(match.range(at: 3), in: text) else {
            return nil
        }
        
        var minute = 0
        if match.range(at: 2).location != NSNotFound,
           let minRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minRange]) ?? 0
        }
        
        let ampm = String(text[ampmRange]).lowercased()
        if ampm == "pm" && hour < 12 { hour += 12 }
        else if ampm == "am" && hour == 12 { hour = 0 }
        
        guard let timestamp = createDate(hour: hour, minute: minute, calendar: calendar, now: now),
              let fullRange = Range(match.range, in: text) else {
            return nil
        }
        
        let cleanedText = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
        return (timestamp, cleanedText)
    }
    
    // MARK: - Helpers
    
    private static func smartHourDefault(hour: Int, calendar: Calendar, now: Date) -> Int {
        // If no AM/PM specified, make smart assumption
        if hour < 12 {
            let currentHour = calendar.component(.hour, from: now)
            // If current time is PM and hour is small, assume PM
            if currentHour >= 12 {
                return hour + 12
            }
        }
        return hour
    }
    
    private static func createDate(hour: Int, minute: Int, calendar: Calendar, now: Date) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }
}
