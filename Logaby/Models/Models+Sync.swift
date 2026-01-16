import Foundation
import SwiftData

// MARK: - Model Extensions for Sync

extension Feeding {
    func toSyncActivity(familyId: UUID, userId: UUID) -> SyncActivity {
        var data: [String: AnyJSON] = [:]
        
        switch type {
        case .bottle:
            data["subtype"] = .string("bottle")
            if let amount = amountOz { data["amount"] = .number(amount) }
        case .nursing:
            data["subtype"] = .string("nursing")
            if let dur = durationMinutes { data["duration"] = .number(Double(dur)) }
            if let s = side { data["side"] = .string(s.rawValue) }
        }
        
        return SyncActivity(
            id: id,
            family_id: familyId,
            type: "feeding",
            timestamp: timestamp,
            data: data,
            created_by: userId
        )
    }
}

extension Diaper {
    func toSyncActivity(familyId: UUID, userId: UUID) -> SyncActivity {
        var data: [String: AnyJSON] = [:]
        data["status"] = .string(type.rawValue)
        
        return SyncActivity(
            id: id,
            family_id: familyId,
            type: "diaper",
            timestamp: timestamp,
            data: data,
            created_by: userId
        )
    }
}

extension Sleep {
    func toSyncActivity(familyId: UUID, userId: UUID) -> SyncActivity {
        var data: [String: AnyJSON] = [:]
        if let end = endTime {
            data["endTime"] = .number(end.timeIntervalSince1970)
        }
        
        return SyncActivity(
            id: id,
            family_id: familyId,
            type: "sleep",
            timestamp: startTime,
            data: data,
            created_by: userId
        )
    }
}

extension Weight {
    func toSyncActivity(familyId: UUID, userId: UUID) -> SyncActivity {
        return SyncActivity(
            id: id,
            family_id: familyId,
            type: "weight",
            timestamp: timestamp,
            data: ["pounds": .number(weightLbs)],
            created_by: userId
        )
    }
}

extension Pumping {
    func toSyncActivity(familyId: UUID, userId: UUID) -> SyncActivity {
        var data: [String: AnyJSON] = [:]
        data["amount"] = .number(amountOz)
        if let dur = durationMinutes { data["duration"] = .number(Double(dur)) }
        data["side"] = .string(side.rawValue)
        
        return SyncActivity(
            id: id,
            family_id: familyId,
            type: "pumping",
            timestamp: timestamp,
            data: data,
            created_by: userId
        )
    }
}

// MARK: - Import Logic

extension Feeding {
    static func fromSyncActivity(_ activity: SyncActivity) -> Feeding? {
        guard activity.type == "feeding" else { return nil }
        
        let subtype = activity.data["subtype"]?.stringValue
        
        if subtype == "bottle", let amt = activity.data["amount"]?.doubleValue {
            return Feeding.bottle(amountOz: amt, timestamp: activity.timestamp).applyId(activity.id)
        } else if subtype == "nursing", let dur = activity.data["duration"]?.intValue {
            let sideRaw = activity.data["side"]?.stringValue ?? "both"
            let side = NursingSide(rawValue: sideRaw) ?? .both
            return Feeding.nursing(durationMinutes: dur, side: side, timestamp: activity.timestamp).applyId(activity.id)
        }
        return nil
    }
}

extension Diaper {
    static func fromSyncActivity(_ activity: SyncActivity) -> Diaper? {
        guard activity.type == "diaper",
              let statusRaw = activity.data["status"]?.stringValue,
              let type = DiaperType(rawValue: statusRaw) else { return nil }
        
        return Diaper(id: activity.id, timestamp: activity.timestamp, type: type)
    }
}

extension Sleep {
    static func fromSyncActivity(_ activity: SyncActivity) -> Sleep? {
        guard activity.type == "sleep" else { return nil }
        
        let s = Sleep(startTime: activity.timestamp)
        s.id = activity.id
        
        if let endTs = activity.data["endTime"]?.doubleValue {
            s.endTime = Date(timeIntervalSince1970: endTs)
        }
        return s
    }
}

extension Weight {
    static func fromSyncActivity(_ activity: SyncActivity) -> Weight? {
        guard activity.type == "weight",
              let lbs = activity.data["pounds"]?.doubleValue else { return nil }
        
        return Weight(id: activity.id, timestamp: activity.timestamp, weightLbs: lbs)
    }
}

extension Pumping {
    static func fromSyncActivity(_ activity: SyncActivity) -> Pumping? {
        guard activity.type == "pumping",
              let amt = activity.data["amount"]?.doubleValue else { return nil }
        
        let sideRaw = activity.data["side"]?.stringValue ?? "left"
        let side = PumpingSide(rawValue: sideRaw) ?? .left
        
        let p = Pumping(
            id: activity.id,
            timestamp: activity.timestamp,
            amountOz: amt,
            durationMinutes: activity.data["duration"]?.intValue,
            side: side
        )
        return p
    }
}

// Helper to set ID
extension Feeding { func applyId(_ id: UUID) -> Feeding { self.id = id; return self } }
