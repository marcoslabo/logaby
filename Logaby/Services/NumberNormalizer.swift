import Foundation

/// Converts word numbers to digits and normalizes text for parsing
struct NumberNormalizer {
    
    // MARK: - Word to Number Mappings
    
    private static let wordNumbers: [String: String] = [
        // Basic numbers
        "zero": "0", "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
        "six": "6", "seven": "7", "eight": "8", "nine": "9", "ten": "10",
        "eleven": "11", "twelve": "12", "thirteen": "13", "fourteen": "14", "fifteen": "15",
        "sixteen": "16", "seventeen": "17", "eighteen": "18", "nineteen": "19", "twenty": "20",
        "thirty": "30", "forty": "40", "fifty": "50", "sixty": "60",
        
        // Compound numbers (common for minutes/oz)
        "twenty-one": "21", "twenty-two": "22", "twenty-three": "23", "twenty-four": "24", "twenty-five": "25",
        "twenty-six": "26", "twenty-seven": "27", "twenty-eight": "28", "twenty-nine": "29",
        "thirty-five": "35", "forty-five": "45", "fifty-five": "55",
        
        // Articles that imply 1
        "an": "1"
        // NOTE: Removed "a": "1" - it breaks "a nap", "a bottle", etc.
    ]
    
    // MARK: - Public API
    
    /// Normalize text by converting word numbers to digits
    static func normalize(_ text: String) -> String {
        var result = text.lowercased()
        
        // Convert hour expressions to minutes (before other processing)
        result = result.replacingOccurrences(of: "an hour and a half", with: "90 minutes")
        result = result.replacingOccurrences(of: "1.5 hours", with: "90 minutes")
        result = result.replacingOccurrences(of: "an hour", with: "60 minutes")
        result = result.replacingOccurrences(of: "1 hour", with: "60 minutes")
        result = result.replacingOccurrences(of: "half hour", with: "30 minutes")
        result = result.replacingOccurrences(of: "half an hour", with: "30 minutes")
        
        // Handle fractions (before word replacement)
        result = result.replacingOccurrences(of: "and a half", with: ".5")
        result = result.replacingOccurrences(of: "and half", with: ".5")
        result = result.replacingOccurrences(of: "a half", with: "0.5")
        result = result.replacingOccurrences(of: "half an", with: "0.5")
        
        // Protect weight patterns like "8 lbs and 6 oz" from being split
        let weightPattern = #"(\d+)\s*(lbs?|pounds?)\s+and\s+(\d+)\s*(oz|ounces?)"#
        if let regex = try? NSRegularExpression(pattern: weightPattern, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1 $2 PLUS $3 $4"
            )
        }
        
        // Replace word numbers with digits (using word boundaries)
        for (word, number) in wordNumbers {
            result = result.replacingOccurrences(
                of: "\\b\(word)\\b",
                with: number,
                options: .regularExpression
            )
        }
        
        // Restore protected patterns
        result = result.replacingOccurrences(of: "PLUS", with: "and")
        
        return result
    }
    
    /// Extract a numeric value from text
    static func extractNumber(from text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Double(text[range])
    }
    
    /// Extract an integer from text
    static func extractInt(from text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[range])
    }
}
