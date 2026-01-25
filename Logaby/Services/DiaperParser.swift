import Foundation

/// Parses diaper-related voice commands
/// Supports: wet, dirty, mixed/both
struct DiaperParser {
    
    // MARK: - Keywords
    
    static let keywords = [
        // Direct diaper words
        "diaper", "diapers", "nappy", "nappies",
        
        // Change words
        "changed", "change", "changing",
        
        // Wet indicators
        "wet", "pee", "peed", "pees", "peeing",
        "urine", "urinated", "wee", "weed",
        
        // Dirty indicators
        "poop", "poopy", "pooped", "poops", "pooping",
        "dirty", "messy", "soiled",
        "bowel", "bm", "stool", "stools",
        "number two", "number 2",
        
        // Combined
        "both", "mixed", "combo",
        
        // Natural speech
        "changed her diaper", "changed his diaper", "changed the diaper",
        "changed baby", "diaper change",
        "she pooped", "he pooped", "baby pooped",
        "she peed", "he peed", "baby peed",
        "had a dirty diaper", "had a wet diaper",
        "needed a change", "needs a change"
    ]
    
    private static let wetKeywords = [
        "wet", "pee", "peed", "pees", "peeing",
        "urine", "urinated", "wee", "weed"
    ]
    
    private static let dirtyKeywords = [
        "poop", "poopy", "pooped", "poops", "pooping",
        "dirty", "messy", "soiled",
        "bowel", "bm", "stool", "stools",
        "number two", "number 2"
    ]
    
    private static let mixedKeywords = ["both", "mixed", "combo", "pee and poop", "poop and pee"]
    
    // MARK: - Public API
    
    /// Check if text contains diaper keywords
    static func matches(_ text: String) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    /// Parse diaper from text
    static func parse(_ text: String, timestamp: Date) -> Diaper? {
        // Determine diaper type
        let hasWet = wetKeywords.contains { text.contains($0) }
        let hasDirty = dirtyKeywords.contains { text.contains($0) }
        let hasMixed = mixedKeywords.contains { text.contains($0) }
        
        let type: DiaperType
        
        if hasMixed || (hasWet && hasDirty) {
            type = .mixed
        } else if hasDirty {
            type = .dirty
        } else if hasWet {
            type = .wet
        } else if text.contains("diaper") || text.contains("changed") {
            // Generic diaper mention - default to wet
            type = .wet
        } else {
            return nil
        }
        
        return Diaper(timestamp: timestamp, type: type)
    }
}
