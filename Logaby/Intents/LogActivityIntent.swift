import AppIntents
import Foundation

/// Siri App Intent for logging baby activities via voice
/// Usage: "Hey Siri, tell Logaby 4oz bottle"
@available(iOS 16.0, *)
struct LogActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Baby Activity"
    static var description = IntentDescription("Log a feeding, diaper change, sleep, or weight for your baby")
    
    /// The voice input from Siri
    @Parameter(title: "Activity")
    var activity: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$activity)")
    }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = parseActivity(activity)
        
        // Save to UserDefaults for the app to pick up
        savePendingActivity(activity: activity, type: result.type, details: result.details)
        
        return .result(dialog: IntentDialog(stringLiteral: result.response))
    }
    
    private func parseActivity(_ input: String) -> (type: String, details: [String: Any], response: String) {
        let text = input.lowercased()
        
        // Bottle feeding: "4oz bottle", "4 ounces"
        if let range = text.range(of: #"(\d+(?:\.\d+)?)\s*(?:oz|ounces?)"#, options: .regularExpression) {
            let match = String(text[range])
            let numStr = match.replacingOccurrences(of: #"[^\d.]"#, with: "", options: .regularExpression)
            if let oz = Double(numStr) {
                return (
                    type: "feeding",
                    details: ["feedingType": "bottle", "amountOz": oz],
                    response: "Logged \(Int(oz))oz bottle 🍼"
                )
            }
        }
        
        // Nursing: "nursed 10 minutes"
        if text.contains("nursed") || text.contains("nursing") || text.contains("breastfed") {
            if let range = text.range(of: #"(\d+)\s*(?:minutes?|mins?)"#, options: .regularExpression) {
                let match = String(text[range])
                let numStr = match.replacingOccurrences(of: #"[^\d]"#, with: "", options: .regularExpression)
                if let mins = Int(numStr) {
                    var side = "both"
                    if text.contains("left") { side = "left" }
                    if text.contains("right") { side = "right" }
                    return (
                        type: "feeding",
                        details: ["feedingType": "nursing", "durationMinutes": mins, "side": side],
                        response: "Logged \(mins) min nursing 🤱"
                    )
                }
            }
        }
        
        // Diaper: "wet diaper", "dirty diaper"
        if text.contains("diaper") {
            var diaperType = "wet"
            if text.contains("dirty") || text.contains("poop") {
                diaperType = text.contains("wet") ? "mixed" : "dirty"
            }
            return (
                type: "diaper",
                details: ["diaperType": diaperType],
                response: "Logged \(diaperType) diaper 👶"
            )
        }
        
        // Sleep start
        if text.contains("asleep") || text.contains("sleeping") || text.contains("fell asleep") {
            return (
                type: "sleepStart",
                details: [:],
                response: "Started sleep timer 😴"
            )
        }
        
        // Sleep end
        if text.contains("woke up") || text.contains("awake") {
            return (
                type: "sleepEnd",
                details: [:],
                response: "Baby is awake! ☀️"
            )
        }
        
        // Weight
        if let range = text.range(of: #"(\d+(?:\.\d+)?)\s*(?:pounds?|lbs?)"#, options: .regularExpression) {
            let match = String(text[range])
            let numStr = match.replacingOccurrences(of: #"[^\d.]"#, with: "", options: .regularExpression)
            if var lbs = Double(numStr) {
                // Check for ounces
                if let ozRange = text.range(of: #"(\d+)\s*(?:oz|ounces?)"#, options: .regularExpression) {
                    let ozMatch = String(text[ozRange])
                    let ozStr = ozMatch.replacingOccurrences(of: #"[^\d]"#, with: "", options: .regularExpression)
                    if let oz = Int(ozStr) {
                        lbs += Double(oz) / 16.0
                    }
                }
                return (
                    type: "weight",
                    details: ["weightLbs": lbs],
                    response: "Logged weight: \(String(format: "%.1f", lbs)) lbs ⚖️"
                )
            }
        }
        
        return (
            type: "unknown",
            details: ["raw": text],
            response: "I didn't understand that. Try '4oz bottle' or 'wet diaper'"
        )
    }
    
    private func savePendingActivity(activity: String, type: String, details: [String: Any]) {
        let defaults = UserDefaults(suiteName: "group.com.babble.shared")
        
        var pending = defaults?.array(forKey: "pendingActivities") as? [[String: Any]] ?? []
        
        var entry: [String: Any] = [
            "raw": activity,
            "type": type,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        details.forEach { entry[$0.key] = $0.value }
        pending.append(entry)
        
        defaults?.set(pending, forKey: "pendingActivities")
    }
}

/// App Shortcuts provider - makes the intent discoverable
@available(iOS 16.0, *)
struct LogabyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogActivityIntent(),
            phrases: [
                "Log activity in \(.applicationName)",
                "Tell \(.applicationName) something"
            ],
            shortTitle: "Log Activity",
            systemImageName: "mic.fill"
        )
    }
}

