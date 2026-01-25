import Foundation

/// Parses feeding-related voice commands
/// Supports: bottle, nursing, breastfeeding, formula, breastmilk
struct FeedingParser {
    
    // MARK: - Keywords
    
    /// Keywords that indicate a feeding activity
    static let keywords = [
        // Direct feeding words
        "fed", "feed", "feeding", "ate", "eaten", "eating",
        "drank", "drinking", "drink", "had", "finished",
        "gave", "give", "giving",
        
        // Container keywords
        "bottle", "bottles",
        
        // Amount keywords
        "oz", "ounce", "ounces",
        "ml", "milliliter", "milliliters",
        
        // Nursing keywords
        "nursed", "nursing", "nurse",
        "breastfed", "breastfeeding", "breastfeed",
        "breast-fed", "breast-feeding", "breast-feed",
        "breast fed", "breast feeding", "breast feed",
        "latched", "latch", "latching",
        "suckled", "suckling",
        
        // Content keywords
        "formula", "breastmilk", "breast milk",
        "expressed", "pumped milk",
        
        // Natural speech variations
        "she ate", "he ate", "baby ate",
        "she drank", "he drank", "baby drank",
        "she had", "he had", "baby had",
        "took a bottle", "took the bottle",
        "finished bottle", "finished her bottle", "finished his bottle"
    ]
    
    /// Keywords specifically for nursing (not bottle)
    private static let nursingKeywords = [
        // Direct nursing words
        "nursed", "nursing", "nurse",
        "breastfed", "breastfeeding", "breastfeed",
        "breast-fed", "breast-feeding", "breast-feed",
        "breast fed", "breast feeding", "breast feed",
        "latched", "latch", "latching",
        "suckled", "suckling",
        "on the breast", "at the breast",
        
        // Breastmilk implies nursing when used with duration (not oz)
        "breastmilk", "breast milk",
        
        // Natural speech variations
        "i breastfed", "i nursed", "she nursed", "he nursed",
        "baby nursed", "baby breastfed"
    ]
    
    /// Keywords for formula content
    private static let formulaKeywords = ["formula", "similac", "enfamil", "gerber"]
    
    /// Keywords for breastmilk content (for bottle - "4oz breastmilk")
    private static let breastmilkKeywords = [
        "breastmilk", "breast milk", "pumped milk", "expressed milk",
        "pumped", "expressed", "my milk"
    ]
    
    // MARK: - Public API
    
    /// Check if text contains feeding keywords
    static func matches(_ text: String) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    /// Parse feeding from text
    static func parse(_ text: String, timestamp: Date) -> Feeding? {
        // Check for nursing first (more specific)
        if let nursing = parseNursing(text, timestamp: timestamp) {
            return nursing
        }
        
        // Check for bottle feeding
        if let bottle = parseBottle(text, timestamp: timestamp) {
            return bottle
        }
        
        return nil
    }
    
    // MARK: - Nursing Parser
    
    private static func parseNursing(_ text: String, timestamp: Date) -> Feeding? {
        // Must contain nursing keyword
        guard nursingKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        // Don't match if bottle amount is present (e.g., "4oz breastmilk" is bottle, not nursing)
        let ozPattern = #"\d+(?:\.\d+)?\s*(?:oz|ounce|ml)"#
        if let regex = try? NSRegularExpression(pattern: ozPattern),
           regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return nil
        }
        
        // Extract side
        let side = extractSide(from: text)
        
        // Try time range first: "from 2 to 3:30 PM" -> calculate duration
        if let (duration, actualTimestamp) = parseTimeRange(text) {
            return Feeding.nursing(durationMinutes: duration, side: side, timestamp: actualTimestamp)
        }
        
        // Try duration: "for 20 minutes"
        let duration = extractDuration(from: text) ?? 10 // Default 10 min
        
        return Feeding.nursing(durationMinutes: duration, side: side, timestamp: timestamp)
    }
    
    /// Parse time range like "from 2 to 3:30 PM" and return (durationMinutes, endTimestamp)
    private static func parseTimeRange(_ text: String) -> (Int, Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        // Pattern: "from 2 to 3:30 PM", "from two to 3:30 PM"
        let pattern = #"from\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:to|until|-)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        // Parse start time
        var startHour = extractMatchInt(from: text, match: match, group: 1) ?? 0
        let startMin = extractMatchInt(from: text, match: match, group: 2) ?? 0
        
        // Parse end time
        var endHour = extractMatchInt(from: text, match: match, group: 4) ?? 0
        let endMin = extractMatchInt(from: text, match: match, group: 5) ?? 0
        
        // Handle AM/PM for end (and apply to start if not specified)
        var endAMPM: String? = nil
        if match.range(at: 6).location != NSNotFound,
           let range = Range(match.range(at: 6), in: text) {
            endAMPM = String(text[range]).lowercased()
        }
        
        // Handle AM/PM for start
        if match.range(at: 3).location != NSNotFound,
           let range = Range(match.range(at: 3), in: text) {
            let startAMPM = String(text[range]).lowercased()
            if startAMPM == "pm" && startHour < 12 { startHour += 12 }
            else if startAMPM == "am" && startHour == 12 { startHour = 0 }
        } else if let endAMPM = endAMPM {
            // Apply end's AM/PM to start if start doesn't have one
            if endAMPM == "pm" && startHour < 12 && startHour <= endHour { startHour += 12 }
            else if endAMPM == "am" && startHour == 12 { startHour = 0 }
        }
        
        // Apply AM/PM to end
        if let endAMPM = endAMPM {
            if endAMPM == "pm" && endHour < 12 { endHour += 12 }
            else if endAMPM == "am" && endHour == 12 { endHour = 0 }
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
        
        // Calculate duration in minutes
        let durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        
        // Sanity check - duration should be positive and reasonable (< 180 min)
        guard durationMinutes > 0 && durationMinutes < 180 else {
            return nil
        }
        
        return (durationMinutes, endTime)
    }
    
    private static func extractMatchInt(from text: String, match: NSTextCheckingResult, group: Int) -> Int? {
        guard match.range(at: group).location != NSNotFound,
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }
        return Int(text[range])
    }
    
    // MARK: - Bottle Parser
    
    private static func parseBottle(_ text: String, timestamp: Date) -> Feeding? {
        // Try to extract amount in oz
        var amountOz: Double? = nil
        
        // Pattern: "X oz", "X ounce", "X ounces"
        let ozPatterns = [
            #"(\d+(?:\.\d+)?)\s*(?:oz|ounces?)\b"#,
            #"fed\s+(\d+(?:\.\d+)?)"#,
            #"gave\s+(\d+(?:\.\d+)?)"#,
            #"drank\s+(\d+(?:\.\d+)?)"#
        ]
        
        for pattern in ozPatterns {
            if let oz = NumberNormalizer.extractNumber(from: text, pattern: pattern) {
                amountOz = oz
                break
            }
        }
        
        // Pattern: "X ml" - convert to oz
        let mlPattern = #"(\d+(?:\.\d+)?)\s*(?:ml|milliliters?)\b"#
        if amountOz == nil, let ml = NumberNormalizer.extractNumber(from: text, pattern: mlPattern) {
            amountOz = ml / 30.0 // Approximate conversion
        }
        
        guard let oz = amountOz else { return nil }
        
        // Detect bottle content (formula or breastmilk)
        var bottleContent: BottleContent? = nil
        if formulaKeywords.contains(where: { text.contains($0) }) {
            bottleContent = .formula
        } else if breastmilkKeywords.contains(where: { text.contains($0) }) {
            bottleContent = .breastmilk
        }
        
        return Feeding.bottle(amountOz: oz, content: bottleContent, timestamp: timestamp)
    }
    
    // MARK: - Helpers
    
    private static func extractDuration(from text: String) -> Int? {
        let patterns = [
            #"(\d+)\s*(?:minutes?|mins?|min|m)\b"#,
            #"for\s+(\d+)"#,
            #"(\d+)\s+(?:minutes?|mins?)"#
        ]
        
        for pattern in patterns {
            if let duration = NumberNormalizer.extractInt(from: text, pattern: pattern) {
                return duration
            }
        }
        return nil
    }
    
    private static func extractSide(from text: String) -> NursingSide {
        // Check for both sides first (most specific)
        let hasLeft = text.contains("left")
        let hasRight = text.contains("right")
        
        if hasLeft && hasRight { return .both }
        if text.contains("both") { return .both }
        if hasLeft { return .left }
        if hasRight { return .right }
        return .both  // Default to both if not specified
    }
}
