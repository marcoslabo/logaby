import Foundation

/// AI-powered voice parser using Supabase Edge Function
/// Calls the parse-voice function which proxies to Claude Haiku
actor ClaudeParserService {
    
    // MARK: - Singleton
    static let shared = ClaudeParserService()
    
    // MARK: - Configuration
    // Edge Function endpoint - uses your Supabase project
    private let edgeFunctionURL = "https://vgnvloytauupdwxdkmlu.supabase.co/functions/v1/parse-voice"
    
    // MARK: - Service Availability
    
    /// AI parsing is always available (no API key needed from users)
    static func isAvailable() -> Bool {
        return true
    }
    
    // Legacy methods for compatibility (no longer needed)
    static func hasAPIKey() -> Bool { return true }
    static func setAPIKey(_ key: String) { }
    static func clearAPIKey() { }
    
    // MARK: - Parsing
    
    /// Parse voice input using AI (via Edge Function)
    /// Returns structured activity data or nil if parsing fails
    func parse(_ input: String) async throws -> ParsedActivity? {
        guard let url = URL(string: edgeFunctionURL) else {
            throw ClaudeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // 15 second timeout
        
        let body: [String: Any] = ["voice_input": input]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("Edge Function error: \(httpResponse.statusCode)")
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse Edge Function response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let parsed = json["parsed"] as? [String: Any],
              let type = parsed["type"] as? String else {
            throw ClaudeError.parseError
        }
        
        // Debug: Log fields from AI response
        print("🤖 AI Response - type: \(type), amount_oz: \(parsed["amount_oz"] ?? "nil"), amount_ml: \(parsed["amount_ml"] ?? "nil")")
        print("🤖 AI Response - at_hour: \(parsed["at_hour"] ?? "nil"), at_minute: \(parsed["at_minute"] ?? "nil")")
        
        return ParsedActivity(
            type: type,
            amountOz: parsed["amount_oz"] as? Double,
            amountMl: parsed["amount_ml"] as? Double,  // NEW: handle ml
            durationMinutes: parsed["duration_minutes"] as? Int,
            side: parsed["side"] as? String,
            content: parsed["content"] as? String,
            diaperType: parsed["diaper_type"] as? String,
            weightLbs: parsed["weight_lbs"] as? Double,
            startHour: parsed["start_hour"] as? Int,
            startMinute: parsed["start_minute"] as? Int,
            endHour: parsed["end_hour"] as? Int,
            endMinute: parsed["end_minute"] as? Int,
            hoursAgo: parsed["hours_ago"] as? Int,
            minutesAgo: parsed["minutes_ago"] as? Int,
            atHour: parsed["at_hour"] as? Int,
            atMinute: parsed["at_minute"] as? Int,
            isPM: parsed["is_pm"] as? Bool
        )
    }
}

// MARK: - Parsed Activity Model

struct ParsedActivity {
    let type: String
    let amountOz: Double?
    let amountMl: Double?  // NEW: handle ml separately
    let durationMinutes: Int?
    let side: String?
    let content: String?
    let diaperType: String?
    let weightLbs: Double?
    let startHour: Int?
    let startMinute: Int?
    let endHour: Int?
    let endMinute: Int?
    let hoursAgo: Int?
    let minutesAgo: Int?
    let atHour: Int?
    let atMinute: Int?
    let isPM: Bool?
    
    /// Convert parsed activity to ParseResult
    func toParseResult() -> ParseResult? {
        let timestamp = calculateTimestamp()
        
        switch type {
        case "feeding":
            // Convert ml to oz if needed (30ml = 1oz)
            var oz: Double
            if let mlAmount = amountMl {
                oz = mlAmount / 30.0  // Convert ml to oz
            } else if let ozAmount = amountOz {
                oz = ozAmount
            } else {
                return nil
            }
            var bottleContent: BottleContent? = nil
            if content == "formula" { bottleContent = .formula }
            else if content == "breastmilk" { bottleContent = .breastmilk }
            return .feeding(Feeding.bottle(amountOz: oz, content: bottleContent, timestamp: timestamp))
            
        case "nursing":
            let duration = calculateDuration() ?? durationMinutes ?? 10
            let nursingSide = parseSide()
            return .feeding(Feeding.nursing(durationMinutes: duration, side: nursingSide, timestamp: timestamp))
            
        case "diaper":
            let type = parseDiaperType()
            return .diaper(Diaper(timestamp: timestamp, type: type))
            
        case "sleep_start":
            return .sleepStart(Sleep(startTime: timestamp))
            
        case "sleep_end":
            return .sleepEnd
            
        case "sleep_completed":
            guard let start = calculateStartTime(), let end = calculateEndTime() else {
                let duration = durationMinutes ?? 60
                let startTime = Calendar.current.date(byAdding: .minute, value: -duration, to: Date()) ?? Date()
                return .sleepCompleted(Sleep(startTime: startTime, endTime: Date()))
            }
            return .sleepCompleted(Sleep(startTime: start, endTime: end))
            
        case "weight":
            guard let lbs = weightLbs else { return nil }
            return .weight(Weight(timestamp: timestamp, weightLbs: lbs))
            
        case "pumping":
            // Convert ml to oz if needed (30ml = 1oz)
            var oz: Double
            if let mlAmount = amountMl {
                oz = mlAmount / 30.0  // Convert ml to oz
            } else if let ozAmount = amountOz {
                oz = ozAmount
            } else {
                oz = 0
            }
            let pumpingSide = parsePumpingSide()
            return .pumping(Pumping(
                timestamp: timestamp,
                amountOz: oz,
                durationMinutes: durationMinutes,
                side: pumpingSide
            ))
            
        default:
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func calculateTimestamp() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        if let hoursAgo = hoursAgo {
            return calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
        }
        
        if let minutesAgo = minutesAgo {
            return calendar.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
        }
        
        if let hour = atHour {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = atMinute ?? 0
            return calendar.date(from: components) ?? now
        }
        
        if let endHour = endHour {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = endHour
            components.minute = endMinute ?? 0
            return calendar.date(from: components) ?? now
        }
        
        return now
    }
    
    private func calculateDuration() -> Int? {
        guard let startHour = startHour, let endHour = endHour else { return nil }
        let startMinutes = startHour * 60 + (startMinute ?? 0)
        let endMinutes = endHour * 60 + (endMinute ?? 0)
        return endMinutes - startMinutes
    }
    
    private func calculateStartTime() -> Date? {
        guard let hour = startHour else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = startMinute ?? 0
        return Calendar.current.date(from: components)
    }
    
    private func calculateEndTime() -> Date? {
        guard let hour = endHour else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = endMinute ?? 0
        return Calendar.current.date(from: components)
    }
    
    private func parseSide() -> NursingSide {
        switch side?.lowercased() {
        case "left": return .left
        case "right": return .right
        default: return .both
        }
    }
    
    private func parsePumpingSide() -> PumpingSide {
        switch side?.lowercased() {
        case "left": return .left
        case "right": return .right
        default: return .both
        }
    }
    
    private func parseDiaperType() -> DiaperType {
        switch diaperType?.lowercased() {
        case "dirty": return .dirty
        case "mixed": return .mixed
        default: return .wet
        }
    }
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid response from API"
        case .apiError(let code): return "API error: \(code)"
        case .parseError: return "Failed to parse response"
        }
    }
}
