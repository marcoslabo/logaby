import Foundation

/// Parses weight-related voice commands
/// Supports: lbs + oz, decimal lbs, kg
struct WeightParser {
    
    // MARK: - Keywords
    
    /// Weight action verbs - must have one of these to be a weight command
    static let weightVerbs = [
        "weigh", "weighs", "weighed", "weighing",
        "weight", "weighted",
        "measured", "measuring",
        "baby weighs", "she weighs", "he weighs",
        "came in at", "weighs in at",
        "weight check", "weight is"
    ]
    
    /// Unit keywords (used for parsing, but not for matching)
    static let keywords = [
        "pounds", "pound", "lbs", "lb",
        "ounces", "ounce", "oz",
        "kilograms", "kilogram", "kg", "kilos", "kilo",
        "grams", "gram", "g"
    ]
    
    // MARK: - Public API
    
    /// Check if text is a weight command (requires weight verb, not just units)
    static func matches(_ text: String) -> Bool {
        // Must contain a weight-specific verb to be considered a weight command
        // This prevents "2 oz bottle" from being matched as weight
        return weightVerbs.contains { text.contains($0) }
    }
    
    /// Parse weight from text
    static func parse(_ text: String, timestamp: Date) -> Weight? {
        var totalLbs: Double? = nil
        
        // Pattern 1: "X lbs Y oz" or "X pounds Y ounces" or "X lbs and Y oz"
        let lbsOzPattern = #"(\d+)\s*(?:lbs?|pounds?)\s*(?:and\s*)?(\d+)\s*(?:oz|ounces?)"#
        if let regex = try? NSRegularExpression(pattern: lbsOzPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let lbsRange = Range(match.range(at: 1), in: text),
           let ozRange = Range(match.range(at: 2), in: text),
           let lbs = Double(text[lbsRange]),
           let oz = Double(text[ozRange]) {
            totalLbs = lbs + (oz / 16.0)
        }
        
        // Pattern 2: "X.Y lbs" (decimal)
        if totalLbs == nil {
            let decimalPattern = #"(\d+(?:\.\d+)?)\s*(?:lbs?|pounds?)"#
            if let lbs = NumberNormalizer.extractNumber(from: text, pattern: decimalPattern) {
                totalLbs = lbs
            }
        }
        
        // Pattern 3: "X oz" only (convert to lbs)
        if totalLbs == nil {
            let ozOnlyPattern = #"(\d+)\s*(?:oz|ounces?)"#
            if let oz = NumberNormalizer.extractNumber(from: text, pattern: ozOnlyPattern) {
                totalLbs = oz / 16.0
            }
        }
        
        // Pattern 4: "X kg" (convert to lbs)
        if totalLbs == nil {
            let kgPattern = #"(\d+(?:\.\d+)?)\s*(?:kg|kilograms?)"#
            if let kg = NumberNormalizer.extractNumber(from: text, pattern: kgPattern) {
                totalLbs = kg * 2.20462
            }
        }
        
        guard let lbs = totalLbs else { return nil }
        
        return Weight(timestamp: timestamp, weightLbs: lbs)
    }
}
