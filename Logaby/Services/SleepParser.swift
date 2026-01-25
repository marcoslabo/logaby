import Foundation

/// Parses sleep-related voice commands
/// Supports: time ranges, duration, start, end/wake
struct SleepParser {
    
    // MARK: - Keywords
    
    static let keywords = [
        // Sleep words
        "sleep", "slept", "sleeping", "sleeps",
        "nap", "napped", "napping", "naps",
        
        // State words
        "asleep", "down", "bed", "crib",
        "dozed", "dozing", "resting", "rest",
        
        // Wake words
        "woke", "wake", "waking", "awake",
        "up", "stirring", "stirred",
        
        // Natural speech
        "baby slept", "she slept", "he slept",
        "baby napped", "she napped", "he napped",
        "put down", "went down", "fell asleep",
        "is sleeping", "is asleep", "is napping"
    ]
    
    /// Keywords that indicate sleep START
    private static let startKeywords = [
        // Direct start
        "asleep", "down", "sleeping", "napping", "dozing",
        
        // Phrases
        "went to sleep", "fell asleep", "is asleep", "is sleeping",
        "put her down", "put him down", "put baby down", "put down",
        "went to bed", "in bed", "in crib", "in the crib",
        "started sleeping", "started napping", "taking a nap",
        "she's asleep", "he's asleep", "baby's asleep",
        "she's sleeping", "he's sleeping", "baby's sleeping",
        "just fell asleep", "just went down"
    ]
    
    /// Keywords that indicate sleep END
    private static let endKeywords = [
        "woke", "wake", "waking", "awake", "up",
        "woke up", "woken up", "is awake", "is up",
        "got up", "getting up",
        "she's up", "he's up", "baby's up",
        "she's awake", "he's awake", "baby's awake",
        "just woke", "just woke up", "stirring"
    ]
    
    /// Keywords that indicate COMPLETED sleep
    private static let completedKeywords = [
        "slept", "napped",
        "slept for", "napped for",
        "slept from", "napped from",
        "took a nap", "had a nap",
        "sleep was", "nap was"
    ]
    
    // MARK: - Public API
    
    /// Check if text contains sleep keywords
    static func matches(_ text: String) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    /// Parse completed sleep (with time range or duration)
    static func parseCompleted(_ text: String) -> Sleep? {
        // Must contain a completed keyword
        guard completedKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Try time range first: "from Xam to Ypm"
        if let sleep = parseTimeRange(text, calendar: calendar, now: now) {
            return sleep
        }
        
        // Try duration: "slept for 2 hours"
        if let sleep = parseDuration(text, calendar: calendar, now: now) {
            return sleep
        }
        
        return nil
    }
    
    /// Check if this is a sleep START
    static func matchesStart(_ text: String) -> Bool {
        // Should have start keywords but NOT end keywords
        let hasStartKeyword = startKeywords.contains { text.contains($0) }
        let hasEndKeyword = endKeywords.contains { text.contains($0) }
        
        return hasStartKeyword && !hasEndKeyword
    }
    
    /// Check if this is a sleep END
    static func matchesEnd(_ text: String) -> Bool {
        return endKeywords.contains { text.contains($0) }
    }
    
    // MARK: - Time Range Parser
    
    private static func parseTimeRange(_ text: String, calendar: Calendar, now: Date) -> Sleep? {
        // Pattern: "from 7am to 9:30am", "from 7 AM to 9:30 AM"
        let pattern = #"from\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:to|until|-)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        // Parse start time
        var startHour = extractInt(from: text, match: match, group: 1) ?? 0
        let startMin = extractInt(from: text, match: match, group: 2) ?? 0
        
        // Parse end time
        var endHour = extractInt(from: text, match: match, group: 4) ?? 0
        let endMin = extractInt(from: text, match: match, group: 5) ?? 0
        
        // Handle AM/PM for start
        if let ampm = extractString(from: text, match: match, group: 3) {
            if ampm.lowercased() == "pm" && startHour < 12 { startHour += 12 }
            else if ampm.lowercased() == "am" && startHour == 12 { startHour = 0 }
        }
        
        // Handle AM/PM for end
        if let ampm = extractString(from: text, match: match, group: 6) {
            if ampm.lowercased() == "pm" && endHour < 12 { endHour += 12 }
            else if ampm.lowercased() == "am" && endHour == 12 { endHour = 0 }
        } else {
            // No AM/PM for end - infer from context
            if endHour < startHour && endHour < 12 {
                endHour += 12
            }
        }
        
        // Create dates
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = startHour
        startComponents.minute = startMin
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = endHour
        endComponents.minute = endMin
        
        guard let startTime = calendar.date(from: startComponents),
              let endTime = calendar.date(from: endComponents) else {
            return nil
        }
        
        return Sleep(startTime: startTime, endTime: endTime)
    }
    
    // MARK: - Duration Parser
    
    private static func parseDuration(_ text: String, calendar: Calendar, now: Date) -> Sleep? {
        var totalMinutes: Int? = nil
        
        // Pattern: "X hours" or "X hours Y minutes"
        let hoursPattern = #"(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b"#
        let minsPattern = #"(\d+)\s*(?:minutes?|mins?|m)\b"#
        
        if let hours = NumberNormalizer.extractNumber(from: text, pattern: hoursPattern) {
            totalMinutes = Int(hours * 60)
            
            // Also check for additional minutes
            if let mins = NumberNormalizer.extractInt(from: text, pattern: minsPattern) {
                totalMinutes = (totalMinutes ?? 0) + mins
            }
        } else if let mins = NumberNormalizer.extractInt(from: text, pattern: minsPattern) {
            totalMinutes = mins
        }
        
        guard let minutes = totalMinutes else { return nil }
        
        // Calculate start time based on duration ago from now
        guard let startTime = calendar.date(byAdding: .minute, value: -minutes, to: now) else {
            return nil
        }
        
        return Sleep(startTime: startTime, endTime: now)
    }
    
    // MARK: - Helpers
    
    private static func extractInt(from text: String, match: NSTextCheckingResult, group: Int) -> Int? {
        guard match.range(at: group).location != NSNotFound,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }
        return Int(text[range])
    }
    
    private static func extractString(from text: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard match.range(at: group).location != NSNotFound,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }
        return String(text[range])
    }
}
