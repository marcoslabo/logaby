import Foundation

/// Result of parsing a voice command
enum ParseResult {
    case feeding(Feeding)
    case diaper(Diaper)
    case sleepStart(Sleep)
    case sleepEnd
    case sleepCompleted(Sleep)
    case weight(Weight)
    case pumping(Pumping)
    case error(String)
}

/// Voice command parser
/// Parses natural human language into structured activity data
/// Designed to be flexible and understand many ways people naturally speak
struct VoiceParser {
    
    // MARK: - Number Normalization
    
    private static let wordNumbers: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
        "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
        "an": 1, "a": 1, "half": 0 // "half" handled specially
    ]
    
    /// Convert word numbers to digits
    private static func normalizeNumbers(_ text: String) -> String {
        var result = text
        
        // Handle "X and a half" -> X.5
        result = result.replacingOccurrences(of: "and a half", with: ".5")
        result = result.replacingOccurrences(of: "and half", with: ".5")
        
        // Replace word numbers with digits
        for (word, number) in wordNumbers {
            result = result.replacingOccurrences(of: "\\b\(word)\\b", with: "\(number)", options: .regularExpression)
        }
        
        return result
    }
    
    // MARK: - Main Parser
    
    /// Parse a single activity from input
    static func parse(_ input: String) -> ParseResult {
        let rawText = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let text = normalizeNumbers(rawText)
        
        // Check for completed sleep first (most specific)
        if let sleep = parseCompletedSleep(text) {
            return .sleepCompleted(sleep)
        }
        
        // Check for sleep start
        if matchesSleepStart(text) {
            return .sleepStart(Sleep())
        }
        
        // Check for sleep end/wake
        if matchesSleepEnd(text) {
            return .sleepEnd
        }
        
        // Check for weight
        if let weight = parseWeight(text) {
            return .weight(weight)
        }
        
        // Check for pumping (before feeding - "pumped" is specific)
        if let pumping = parsePumping(text) {
            return .pumping(pumping)
        }
        
        // Check for diaper
        if let diaper = parseDiaper(text) {
            return .diaper(diaper)
        }
        
        // Check for feeding (bottle, breast, formula)
        if let feeding = parseFeeding(text) {
            return .feeding(feeding)
        }
        
        return .error("Couldn't understand: \"\(input)\"")
    }
    
    // MARK: - Multi-Activity Parser
    
    /// Keywords for each activity type
    private static let feedingKeywords = ["fed", "feed", "ate", "bottle", "nursed", "nursing", "breastfed", "formula", "oz", "ounce", "ml"]
    private static let diaperKeywords = ["diaper", "wet", "poop", "poopy", "dirty", "changed"]
    private static let sleepKeywords = ["sleep", "slept", "nap", "napped", "asleep", "woke", "wake"]
    private static let pumpingKeywords = ["pumped", "pump", "pumping", "expressed"]
    private static let weightKeywords = ["weigh", "weighs", "weight", "pounds", "lbs", "kg"]
    
    /// Parse multiple activities from a single voice command
    /// Returns array of successfully parsed results
    static func parseMultiple(_ input: String) -> [ParseResult] {
        let rawText = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First, count how many activity types are mentioned
        var activityTypesFound = 0
        if feedingKeywords.contains(where: { rawText.contains($0) }) { activityTypesFound += 1 }
        if diaperKeywords.contains(where: { rawText.contains($0) }) { activityTypesFound += 1 }
        if sleepKeywords.contains(where: { rawText.contains($0) }) { activityTypesFound += 1 }
        if pumpingKeywords.contains(where: { rawText.contains($0) }) { activityTypesFound += 1 }
        if weightKeywords.contains(where: { rawText.contains($0) }) { activityTypesFound += 1 }
        
        // If only one type or none, return single parse result
        if activityTypesFound <= 1 {
            return []
        }
        
        // Multiple activity types detected - split and parse each
        var segments = splitIntoSegments(rawText)
        
        if segments.isEmpty {
            segments = [rawText]
        }
        
        var results: [ParseResult] = []
        
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            let result = parse(trimmed)
            
            // Only include successful parses
            switch result {
            case .error:
                continue
            default:
                results.append(result)
            }
        }
        
        return results
    }
    
    /// Split input into segments by "and", "also", "then", commas
    private static func splitIntoSegments(_ text: String) -> [String] {
        // First, protect "and a half" patterns
        var protected = text
        protected = protected.replacingOccurrences(of: "and a half", with: "ANDHALF")
        protected = protected.replacingOccurrences(of: "and half", with: "ANDHALF")
        
        // Split by separators - order matters (more specific first)
        let separators = [
            " and also ",
            ", and ",
            " and then ",
            " i also ",
            " also ",
            " then ",
            ", ",
            " i ",  // Split on " i " to separate "I fed ... I pumped"
            " and "
        ]
        
        var segments: [String] = [protected]
        
        for separator in separators {
            var newSegments: [String] = []
            for segment in segments {
                let parts = segment.components(separatedBy: separator)
                newSegments.append(contentsOf: parts)
            }
            segments = newSegments
        }
        
        // Restore protected patterns
        segments = segments.map { $0.replacingOccurrences(of: "ANDHALF", with: "and a half") }
        
        // Filter out empty/tiny segments
        return segments.filter { 
            let trimmed = $0.trimmingCharacters(in: .whitespaces)
            return trimmed.count > 2
        }
    }
    
    // MARK: - Feeding Parser
    // Handles: "fed the baby 4oz", "gave her 150ml of formula", "nursed for 10 minutes", etc.
    
    private static func parseFeeding(_ text: String) -> Feeding? {
        // First check if this is nursing/breastfeeding with duration
        if let nursing = parseNursing(text) {
            return nursing
        }
        
        // Check for bottle feeding with amount (oz or ml)
        if let bottle = parseBottleFeeding(text) {
            return bottle
        }
        
        return nil
    }
    
    private static func parseNursing(_ text: String) -> Feeding? {
        // Nursing keywords
        let nursingKeywords = ["nursed", "nursing", "breastfed", "breastfeeding", "breast fed", 
                               "fed from breast", "from the breast", "latched"]
        
        guard nursingKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        // Try to extract duration
        let durationPatterns = [
            #"(\d+)\s*(?:minutes?|mins?|min|m)\b"#,
            #"for\s+(\d+)"#
        ]
        
        for pattern in durationPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let duration = Int(text[range]) {
                
                // Check for side
                var side: NursingSide = .both
                if text.contains("left") { side = .left }
                else if text.contains("right") { side = .right }
                
                return Feeding.nursing(durationMinutes: duration, side: side)
            }
        }
        
        // If no duration found but nursing keywords present, default to 10 min
        var side: NursingSide = .both
        if text.contains("left") { side = .left }
        else if text.contains("right") { side = .right }
        return Feeding.nursing(durationMinutes: 10, side: side)
    }
    
    private static func parseBottleFeeding(_ text: String) -> Feeding? {
        // Look for amount patterns - oz or ml
        let ozPattern = #"(\d+(?:\.\d+)?)\s*(?:oz|ounces?)\b"#
        let mlPattern = #"(\d+(?:\.\d+)?)\s*(?:ml|milliliters?|mls)\b"#
        
        // Check for oz
        if let regex = try? NSRegularExpression(pattern: ozPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let amount = Double(text[range]) {
            return Feeding.bottle(amountOz: amount)
        }
        
        // Check for ml (convert to oz: 1 oz ≈ 30ml)
        if let regex = try? NSRegularExpression(pattern: mlPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let ml = Double(text[range]) {
            let oz = ml / 30.0
            return Feeding.bottle(amountOz: oz)
        }
        
        // Check for feeding keywords without explicit amount
        let feedingKeywords = ["fed", "feed", "ate", "drank", "bottle", "formula", "milk"]
        if feedingKeywords.contains(where: { text.contains($0) }) {
            // Try to find any number that might be the amount
            let anyNumber = #"(\d+(?:\.\d+)?)"#
            if let regex = try? NSRegularExpression(pattern: anyNumber),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let amount = Double(text[range]), amount > 0 && amount < 20 {
                // Assume oz if small number, ml if large
                if amount > 10 {
                    return Feeding.bottle(amountOz: amount / 30.0) // Assume ml
                }
                return Feeding.bottle(amountOz: amount)
            }
        }
        
        return nil
    }
    
    // MARK: - Diaper Parser
    // Handles: "changed diaper", "wet diaper", "poopy diaper", "had a poo", etc.
    
    private static func parseDiaper(_ text: String) -> Diaper? {
        // Check for diaper-related keywords
        let diaperKeywords = ["diaper", "nappy", "changed", "change", "poop", "poo", "poopy", 
                              "dirty", "wet", "soiled", "messy"]
        
        guard diaperKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        // Determine type
        let isDirty = ["poop", "poo", "poopy", "dirty", "soiled", "messy", "number 2", "#2"].contains(where: { text.contains($0) })
        let isWet = ["wet", "pee", "peed", "number 1", "#1"].contains(where: { text.contains($0) })
        
        let type: DiaperType
        if isDirty && isWet {
            type = .mixed
        } else if isDirty {
            type = .dirty
        } else {
            type = .wet // Default to wet if just "diaper" or "changed"
        }
        
        return Diaper(type: type)
    }
    
    // MARK: - Sleep Parser
    // Handles: "baby asleep", "put her down", "woke up", "slept for 2 hours", etc.
    
    private static func parseCompletedSleep(_ text: String) -> Sleep? {
        // Look for past tense sleep with duration
        let sleepKeywords = ["slept", "napped", "sleep", "nap", "sleeping"]
        guard sleepKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        // Pattern for hours
        let hoursPattern = #"(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b"#
        if let regex = try? NSRegularExpression(pattern: hoursPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let hours = Double(text[range]) {
            
            let minutes = Int(hours * 60)
            let endTime = Date()
            let startTime = Calendar.current.date(byAdding: .minute, value: -minutes, to: endTime)!
            return Sleep(startTime: startTime, endTime: endTime)
        }
        
        // Pattern for minutes
        let minutesPattern = #"(\d+)\s*(?:minutes?|mins?|min|m)\b"#
        if let regex = try? NSRegularExpression(pattern: minutesPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let minutes = Int(text[range]) {
            
            let endTime = Date()
            let startTime = Calendar.current.date(byAdding: .minute, value: -minutes, to: endTime)!
            return Sleep(startTime: startTime, endTime: endTime)
        }
        
        return nil
    }
    
    private static func matchesSleepStart(_ text: String) -> Bool {
        let patterns = [
            // Direct statements
            "asleep", "fell asleep", "going to sleep", "went to sleep",
            "sleeping now", "start sleep", "started sleeping", "is sleeping",
            // Action phrases
            "put down", "putting down", "going down", "laid down", "laying down",
            "in the crib", "in bed", "to bed", "bedtime",
            // Time to sleep
            "nap time", "naptime", "time for a nap"
        ]
        return patterns.contains { text.contains($0) }
    }
    
    private static func matchesSleepEnd(_ text: String) -> Bool {
        let patterns = [
            "woke up", "woke", "awake", "is up", "got up", "getting up",
            "stop sleep", "end sleep", "done sleeping", "finished sleeping",
            "up from nap", "up from sleep"
        ]
        return patterns.contains { text.contains($0) }
    }
    
    // MARK: - Weight Parser
    // Handles: "weighs 12 pounds", "12 lbs 4 oz", "weight is 5.5 kg"
    
    private static func parseWeight(_ text: String) -> Weight? {
        // Must have weight-related keyword
        let weightKeywords = ["weigh", "weight", "pounds", "lbs", "kg", "kilos"]
        guard weightKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        // Pattern for lbs and oz
        let lbsOzPattern = #"(\d+(?:\.\d+)?)\s*(?:pounds?|lbs?)(?:\s+(\d+)\s*(?:ounces?|oz))?"#
        if let regex = try? NSRegularExpression(pattern: lbsOzPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let lbsRange = Range(match.range(at: 1), in: text) {
            
            var lbs = Double(text[lbsRange]) ?? 0
            
            // Add ounces if present
            if match.range(at: 2).location != NSNotFound,
               let ozRange = Range(match.range(at: 2), in: text),
               let oz = Int(text[ozRange]) {
                lbs += Double(oz) / 16.0
            }
            
            return Weight(weightLbs: lbs)
        }
        
        // Pattern for kg (convert to lbs: 1 kg ≈ 2.2 lbs)
        let kgPattern = #"(\d+(?:\.\d+)?)\s*(?:kg|kilos?|kilograms?)"#
        if let regex = try? NSRegularExpression(pattern: kgPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let kg = Double(text[range]) {
            return Weight(weightLbs: kg * 2.205)
        }
        
        return nil
    }
    
    // MARK: - Pumping Parser
    // Handles: "pumped 4oz", "pumped 120ml", "expressed 5oz"
    
    private static func parsePumping(_ text: String) -> Pumping? {
        // Check for pumping keywords
        let pumpingKeywords = ["pumped", "pumping", "pump", "expressed", "expression"]
        guard pumpingKeywords.contains(where: { text.contains($0) }) else { return nil }
        
        // Pattern for oz
        let ozPattern = #"(\d+(?:\.\d+)?)\s*(?:oz|ounces?)\b"#
        if let regex = try? NSRegularExpression(pattern: ozPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let amount = Double(text[range]) {
            
            var side: PumpingSide = .both
            if text.contains("left") { side = .left }
            else if text.contains("right") { side = .right }
            
            return Pumping(amountOz: amount, side: side)
        }
        
        // Pattern for ml (convert to oz)
        let mlPattern = #"(\d+(?:\.\d+)?)\s*(?:ml|milliliters?|mls)\b"#
        if let regex = try? NSRegularExpression(pattern: mlPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let ml = Double(text[range]) {
            
            let oz = ml / 30.0
            var side: PumpingSide = .both
            if text.contains("left") { side = .left }
            else if text.contains("right") { side = .right }
            
            return Pumping(amountOz: oz, side: side)
        }
        
        return nil
    }
}

