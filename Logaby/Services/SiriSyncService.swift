import Foundation
import SwiftData

/// Service to sync activities logged via Siri when app was closed
@MainActor
struct SiriSyncService {
    
    /// Sync any pending activities from Siri to the repository
    /// Returns the number of activities synced
    static func syncPendingActivities(repository: ActivityRepository) -> Int {
        guard let defaults = UserDefaults(suiteName: "group.com.babble.shared") else {
            print("[SiriSync] Could not access shared UserDefaults")
            return 0
        }
        
        guard let pending = defaults.array(forKey: "pendingActivities") as? [[String: Any]], !pending.isEmpty else {
            print("[SiriSync] No pending activities")
            return 0
        }
        
        var syncedCount = 0
        
        for item in pending {
            if processActivity(item, repository: repository) {
                syncedCount += 1
            }
        }
        
        // Clear pending activities after processing
        defaults.removeObject(forKey: "pendingActivities")
        defaults.synchronize()
        
        print("[SiriSync] Synced \(syncedCount) activities from Siri")
        return syncedCount
    }
    
    private static func processActivity(_ item: [String: Any], repository: ActivityRepository) -> Bool {
        guard let type = item["type"] as? String else { return false }
        
        // Parse timestamp if available
        var timestamp = Date()
        if let timestampString = item["timestamp"] as? String,
           let parsed = ISO8601DateFormatter().date(from: timestampString) {
            timestamp = parsed
        }
        
        switch type {
        case "feeding":
            return processFeedingActivity(item, repository: repository, timestamp: timestamp)
            
        case "diaper":
            return processDiaperActivity(item, repository: repository, timestamp: timestamp)
            
        case "sleepStart":
            let sleep = Sleep(startTime: timestamp)
            repository.startSleep(sleep)
            return true
            
        case "sleepEnd":
            if let activeSleep = repository.getActiveSleep() {
                repository.endSleep(id: activeSleep.id)
                return true
            }
            return false
            
        case "weight":
            if let lbs = item["weightLbs"] as? Double {
                let weight = Weight(timestamp: timestamp, weightLbs: lbs)
                repository.addWeight(weight)
                return true
            }
            return false
            
        default:
            print("[SiriSync] Unknown activity type: \(type)")
            return false
        }
    }
    
    private static func processFeedingActivity(_ item: [String: Any], repository: ActivityRepository, timestamp: Date) -> Bool {
        guard let feedingType = item["feedingType"] as? String else { return false }
        
        if feedingType == "bottle" {
            if let amountOz = item["amountOz"] as? Double {
                let feeding = Feeding(timestamp: timestamp, type: .bottle, amountOz: amountOz)
                repository.addFeeding(feeding)
                return true
            }
        } else if feedingType == "nursing" {
            let duration = item["durationMinutes"] as? Int ?? 10
            let sideString = item["side"] as? String ?? "both"
            let side: NursingSide = sideString == "left" ? .left : (sideString == "right" ? .right : .both)
            
            let feeding = Feeding(timestamp: timestamp, type: .nursing, durationMinutes: duration, side: side)
            repository.addFeeding(feeding)
            return true
        }
        
        return false
    }
    
    private static func processDiaperActivity(_ item: [String: Any], repository: ActivityRepository, timestamp: Date) -> Bool {
        let diaperTypeString = item["diaperType"] as? String ?? "wet"
        
        let type: DiaperType
        switch diaperTypeString {
        case "dirty": type = .dirty
        case "mixed": type = .mixed
        default: type = .wet
        }
        
        let diaper = Diaper(timestamp: timestamp, type: type)
        repository.addDiaper(diaper)
        return true
    }
}
