import Foundation

/// Parses pumping-related voice commands
/// Supports: amount, side, duration
struct PumpingParser {
    
    // MARK: - Keywords
    
    static let keywords = [
        // Direct pumping words
        "pumped", "pump", "pumping", "pumps",
        "expressed", "express", "expressing",
        
        // Amount with pumping context
        "got", "collected", "produced",
        
        // Natural speech
        "i pumped", "just pumped", "finished pumping",
        "pumped out", "pumped from",
        "expressed milk", "got milk"
    ]
    
    // MARK: - Public API
    
    /// Check if text contains pumping keywords
    static func matches(_ text: String) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    /// Parse pumping from text
    static func parse(_ text: String, timestamp: Date) -> Pumping? {
        var amountOz: Double? = nil
        var durationMinutes: Int? = nil
        
        // Extract amount in oz
        let ozPatterns = [
            #"(\d+(?:\.\d+)?)\s*(?:oz|ounces?)\b"#,
            #"pumped\s+(\d+(?:\.\d+)?)"#,
            #"expressed\s+(\d+(?:\.\d+)?)"#
        ]
        
        for pattern in ozPatterns {
            if let oz = NumberNormalizer.extractNumber(from: text, pattern: pattern) {
                amountOz = oz
                break
            }
        }
        
        // Extract amount in ml (convert to oz)
        if amountOz == nil {
            let mlPattern = #"(\d+(?:\.\d+)?)\s*(?:ml|milliliters?)\b"#
            if let ml = NumberNormalizer.extractNumber(from: text, pattern: mlPattern) {
                amountOz = ml / 30.0
            }
        }
        
        // Extract duration
        let durationPattern = #"(\d+)\s*(?:minutes?|mins?|min)\b"#
        durationMinutes = NumberNormalizer.extractInt(from: text, pattern: durationPattern)
        
        // Extract side
        var side: PumpingSide = .both
        if text.contains("left") && !text.contains("right") {
            side = .left
        } else if text.contains("right") && !text.contains("left") {
            side = .right
        }
        
        // Need at least amount or duration
        guard amountOz != nil || durationMinutes != nil else {
            // If just "pumped" without details, default to 0 oz
            if keywords.contains(where: { text.contains($0) }) {
                return Pumping(timestamp: timestamp, amountOz: 0, durationMinutes: nil, side: side)
            }
            return nil
        }
        
        return Pumping(
            timestamp: timestamp,
            amountOz: amountOz ?? 0,
            durationMinutes: durationMinutes,
            side: side
        )
    }
}
