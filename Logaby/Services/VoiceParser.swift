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

/// Voice command parser - orchestrates modular parsers
/// Parses natural human language into structured activity data
struct VoiceParser {
    
    // MARK: - AI Parsing (Claude Haiku)
    
    /// Parse using AI with local fallback
    /// Always tries AI first, falls back to local parser if offline/error
    static func parseWithAI(_ input: String) async -> ParseResult {
        // Always try AI parsing first
        print("🤖 AI Parser: Attempting to parse '\(input)'")
        do {
            if let parsed = try await ClaudeParserService.shared.parse(input) {
                print("🤖 AI Parser: Got response - type: \(parsed.type)")
                if let result = parsed.toParseResult() {
                    print("🤖 AI Parser: SUCCESS - converted to ParseResult")
                    return result
                } else {
                    print("🤖 AI Parser: toParseResult() returned nil, falling back")
                }
            } else {
                print("🤖 AI Parser: parse() returned nil")
            }
        } catch {
            print("🤖 AI Parser: FAILED - \(error.localizedDescription), falling back to local parser")
        }
        
        // Fallback to local parser
        print("📍 Local Parser: Used for '\(input)'")
        return parse(input)
    }
    
    // MARK: - Local Parser
    static func parse(_ input: String) -> ParseResult {
        let rawText = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = NumberNormalizer.normalize(rawText)
        
        // 1. Check for completed sleep with time range FIRST
        if let sleep = SleepParser.parseCompleted(normalizedText) {
            return .sleepCompleted(sleep)
        }
        
        // 2. Check for weight EARLY (before feeding - "oz" conflicts)
        //    "8 lbs 6 oz" should be weight, not feeding
        if WeightParser.matches(normalizedText) {
            let (timestamp, cleanedText) = TimeExtractor.extract(from: normalizedText)
            if let weight = WeightParser.parse(cleanedText, timestamp: timestamp) {
                return .weight(weight)
            }
        }
        
        // 3. Check for pumping EARLY (before feeding - "breast" conflicts)
        //    "pumped from left breast 2oz" should be pumping, not nursing
        if PumpingParser.matches(normalizedText) {
            let (timestamp, cleanedText) = TimeExtractor.extract(from: normalizedText)
            if let pumping = PumpingParser.parse(cleanedText, timestamp: timestamp) {
                return .pumping(pumping)
            }
        }
        
        // 4. Check for feeding - extract time first for "nurse at 2:20 PM" type inputs
        //    Note: Time ranges like "from 2 to 3:30 PM" are handled internally by FeedingParser
        if FeedingParser.matches(normalizedText) {
            // Extract time (e.g., "at 2:20 PM" -> timestamp, "nurse" -> remaining text)
            let (timestamp, cleanedText) = TimeExtractor.extract(from: normalizedText)
            if let feeding = FeedingParser.parse(cleanedText, timestamp: timestamp) {
                return .feeding(feeding)
            }
        }
        
        // 5. Extract time reference (e.g., "at 2pm", "30 minutes ago")
        let (timestamp, text) = TimeExtractor.extract(from: normalizedText)
        
        // 6. Check for sleep start/end
        if SleepParser.matchesStart(text) {
            return .sleepStart(Sleep(startTime: timestamp))
        }
        if SleepParser.matchesEnd(text) {
            return .sleepEnd
        }
        
        // 7. Check for diaper
        if DiaperParser.matches(text),
           let diaper = DiaperParser.parse(text, timestamp: timestamp) {
            return .diaper(diaper)
        }
        
        return .error("Couldn't understand: \"\(input)\"")
    }
    
    // MARK: - Multi-Activity Parser
    
    /// Parse multiple activities from a single voice command
    /// Returns array of successfully parsed results
    static func parseMultiple(_ input: String) -> [ParseResult] {
        let rawText = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Count how many activity types are mentioned
        var activityTypesFound = 0
        if FeedingParser.matches(rawText) { activityTypesFound += 1 }
        if DiaperParser.matches(rawText) { activityTypesFound += 1 }
        if SleepParser.matches(rawText) { activityTypesFound += 1 }
        if PumpingParser.matches(rawText) { activityTypesFound += 1 }
        if WeightParser.matches(rawText) { activityTypesFound += 1 }
        
        // If only one type or none, return empty (use parse() instead)
        if activityTypesFound <= 1 {
            return []
        }
        
        // Multiple activity types - split and parse each
        let segments = splitIntoSegments(rawText)
        
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
    
    // MARK: - Segment Splitter
    
    /// Split input into segments by "and", "also", "then", commas
    private static func splitIntoSegments(_ text: String) -> [String] {
        var protected = text
        
        // Protect patterns that shouldn't be split
        protected = protected.replacingOccurrences(of: "and a half", with: "ANDHALF")
        protected = protected.replacingOccurrences(of: "and half", with: "ANDHALF")
        
        // Protect "left and right" for nursing
        protected = protected.replacingOccurrences(of: "left and right", with: "LEFTANDRIGHT")
        protected = protected.replacingOccurrences(of: "right and left", with: "RIGHTANDLEFT")
        
        // Protect weight patterns like "8 lbs and 6 oz"
        let weightPattern = #"(\d+)\s*(lbs?|pounds?)\s+and\s+(\d+)\s*(oz|ounces?)"#
        if let regex = try? NSRegularExpression(pattern: weightPattern, options: .caseInsensitive) {
            protected = regex.stringByReplacingMatches(
                in: protected,
                range: NSRange(protected.startIndex..., in: protected),
                withTemplate: "$1 $2 WEIGHTAND $3 $4"
            )
        }
        
        // Split by separators
        let separators = [
            " and also ", ", and ", " and then ", ", then ",
            " also ", " then ", " and ", ","
        ]
        
        var segments = [protected]
        for separator in separators {
            segments = segments.flatMap { $0.components(separatedBy: separator) }
        }
        
        // Restore protected patterns
        segments = segments.map { segment in
            segment
                .replacingOccurrences(of: "ANDHALF", with: "and a half")
                .replacingOccurrences(of: "WEIGHTAND", with: "and")
                .replacingOccurrences(of: "LEFTANDRIGHT", with: "left and right")
                .replacingOccurrences(of: "RIGHTANDLEFT", with: "right and left")
        }
        
        return segments.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
