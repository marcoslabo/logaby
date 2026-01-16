import Foundation
import SwiftData

/// Repository for managing all activity data
@MainActor
final class ActivityRepository: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func startSync() {
        Task {
            // Check/Ensure we have a session
            var session = try? await SupabaseService.shared.client.auth.session
            
            if session == nil {
                try? await SupabaseService.shared.signInAnonymously()
                // Re-check after sign in attempt
                session = try? await SupabaseService.shared.client.auth.session
            }
            
            if session != nil {
                await FamilyService.shared.fetchCurrentFamily()
                await syncDown()
            }
        }
    }
    
    // MARK: - Sync Helpers
    
    private func upload<T>(_ item: T) {
        Task {
            guard let family = FamilyService.shared.currentFamily,
                  let userId = SupabaseService.shared.currentUserId else { return }
            
            var syncItem: SyncActivity?
            
            if let feeding = item as? Feeding {
                syncItem = feeding.toSyncActivity(familyId: family.id, userId: userId)
            } else if let diaper = item as? Diaper {
                syncItem = diaper.toSyncActivity(familyId: family.id, userId: userId)
            } else if let sleep = item as? Sleep {
                syncItem = sleep.toSyncActivity(familyId: family.id, userId: userId)
            } else if let weight = item as? Weight {
                syncItem = weight.toSyncActivity(familyId: family.id, userId: userId)
            } else if let pumping = item as? Pumping {
                syncItem = pumping.toSyncActivity(familyId: family.id, userId: userId)
            }
            
            if let syncItem {
                try? await SyncService.shared.uploadActivity(syncItem)
            }
        }
    }
    
    func syncDown() async {
        guard let family = FamilyService.shared.currentFamily else { return }
        
        do {
            let activities = try await SyncService.shared.fetchActivities(familyId: family.id)
            
            guard !activities.isEmpty else { return }
            
            await MainActor.run {
                for activity in activities {
                    importActivity(activity)
                }
                // Save ONCE after batch import
                try? modelContext.save()
            }
        } catch {
            print("Sync down error: \(error)")
        }
    }
    
    private func importActivity(_ activity: SyncActivity) {
        // Check if exists
        // This is simplified: assuming separate tables for local models
        // Ideally we check by ID. ActivityRepository manage models separately so we'd need to check each.
        // For beta: just try to fetch by ID across models? No, ID is UUID.
        // We can just try to fetch existing item by ID.
        // But SwiftData query by ID requires Type.
        
        if activity.type == "feeding" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Feeding>(predicate: #Predicate { $0.id == activity.id })).first {
                // Update?
                return 
            }
            if let new = Feeding.fromSyncActivity(activity) { modelContext.insert(new) }
        } else if activity.type == "diaper" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Diaper>(predicate: #Predicate { $0.id == activity.id })).first { return }
            if let new = Diaper.fromSyncActivity(activity) { modelContext.insert(new) }
        } else if activity.type == "sleep" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Sleep>(predicate: #Predicate { $0.id == activity.id })).first { return }
            if let new = Sleep.fromSyncActivity(activity) { modelContext.insert(new) }
        } else if activity.type == "weight" {
             if let existing = try? modelContext.fetch(FetchDescriptor<Weight>(predicate: #Predicate { $0.id == activity.id })).first { return }
            if let new = Weight.fromSyncActivity(activity) { modelContext.insert(new) }
        } else if activity.type == "pumping" {
             if let existing = try? modelContext.fetch(FetchDescriptor<Pumping>(predicate: #Predicate { $0.id == activity.id })).first { return }
             if let new = Pumping.fromSyncActivity(activity) { modelContext.insert(new) }
        }
    }
    
    // MARK: - Feeding
    
    func addFeeding(_ feeding: Feeding) {
        modelContext.insert(feeding)
        try? modelContext.save()
        upload(feeding)
    }
    
    func getFeedings(for date: Date? = nil) -> [Feeding] {
        var descriptor = FetchDescriptor<Feeding>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        if let date = date {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            descriptor.predicate = #Predicate { $0.timestamp >= start && $0.timestamp < end }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteFeeding(id: UUID) {
        let descriptor = FetchDescriptor<Feeding>(predicate: #Predicate { $0.id == id })
        if let feeding = try? modelContext.fetch(descriptor).first {
            modelContext.delete(feeding)
            try? modelContext.save()
        }
    }
    
    // MARK: - Diaper
    
    func addDiaper(_ diaper: Diaper) {
        modelContext.insert(diaper)
        try? modelContext.save()
        upload(diaper)
    }
    
    func getDiapers(for date: Date? = nil) -> [Diaper] {
        var descriptor = FetchDescriptor<Diaper>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        if let date = date {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            descriptor.predicate = #Predicate { $0.timestamp >= start && $0.timestamp < end }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteDiaper(id: UUID) {
        let descriptor = FetchDescriptor<Diaper>(predicate: #Predicate { $0.id == id })
        if let diaper = try? modelContext.fetch(descriptor).first {
            modelContext.delete(diaper)
            try? modelContext.save()
        }
    }
    
    // MARK: - Sleep
    
    func startSleep(_ sleep: Sleep) {
        modelContext.insert(sleep)
        try? modelContext.save()
        upload(sleep)
    }
    
    func endSleep(id: UUID) {
        let descriptor = FetchDescriptor<Sleep>(predicate: #Predicate { $0.id == id })
        if let sleep = try? modelContext.fetch(descriptor).first {
            sleep.wake()
            try? modelContext.save()
        }
    }
    
    func getActiveSleep() -> Sleep? {
        let descriptor = FetchDescriptor<Sleep>(predicate: #Predicate { $0.endTime == nil })
        return try? modelContext.fetch(descriptor).first
    }
    
    func getSleeps(for date: Date? = nil) -> [Sleep] {
        var descriptor = FetchDescriptor<Sleep>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        
        if let date = date {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            descriptor.predicate = #Predicate { $0.startTime >= start && $0.startTime < end }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteSleep(id: UUID) {
        let descriptor = FetchDescriptor<Sleep>(predicate: #Predicate { $0.id == id })
        if let sleep = try? modelContext.fetch(descriptor).first {
            modelContext.delete(sleep)
            try? modelContext.save()
        }
    }
    
    // MARK: - Weight
    
    func addWeight(_ weight: Weight) {
        modelContext.insert(weight)
        try? modelContext.save()
        upload(weight)
    }
    
    func getWeights() -> [Weight] {
        let descriptor = FetchDescriptor<Weight>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getLatestWeight() -> Weight? {
        var descriptor = FetchDescriptor<Weight>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    func deleteWeight(id: UUID) {
        let descriptor = FetchDescriptor<Weight>(predicate: #Predicate { $0.id == id })
        if let weight = try? modelContext.fetch(descriptor).first {
            modelContext.delete(weight)
            try? modelContext.save()
        }
    }
    
    // MARK: - Pumping
    
    func addPumping(_ pumping: Pumping) {
        modelContext.insert(pumping)
        try? modelContext.save()
        upload(pumping)
    }
    
    func getPumpings(for date: Date? = nil) -> [Pumping] {
        var descriptor = FetchDescriptor<Pumping>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        if let date = date {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            descriptor.predicate = #Predicate { $0.timestamp >= start && $0.timestamp < end }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deletePumping(id: UUID) {
        let descriptor = FetchDescriptor<Pumping>(predicate: #Predicate { $0.id == id })
        if let pumping = try? modelContext.fetch(descriptor).first {
            modelContext.delete(pumping)
            try? modelContext.save()
        }
    }
    
    // MARK: - Summary
    
    func getTodaySummary() -> DailySummary {
        let today = Date()
        
        let feedings = getFeedings(for: today)
        let totalOz = feedings.reduce(0.0) { $0 + $1.summaryValue }
        
        let pumpings = getPumpings(for: today)
        let totalPumpedOz = pumpings.reduce(0.0) { $0 + $1.amountOz }
        
        let sleeps = getSleeps(for: today)
        let totalSleepHours = sleeps.filter { !$0.isActive }.reduce(0.0) { $0 + $1.durationHours }
        
        let diapers = getDiapers(for: today)
        
        let latestWeight = getLatestWeight()?.weightLbs
        
        let activeSleep = getActiveSleep()
        
        return DailySummary(
            totalOz: totalOz,
            totalPumpedOz: totalPumpedOz,
            totalSleepHours: totalSleepHours,
            diaperCount: diapers.count,
            latestWeight: latestWeight,
            activeSleep: activeSleep
        )
    }
    
    // MARK: - Recent Activities
    
    func getRecentActivities(limit: Int = 10) -> [Activity] {
        var activities: [Activity] = []
        
        // Get all activity types
        let feedings = getFeedings().prefix(limit).map { Activity.from(feeding: $0) }
        let diapers = getDiapers().prefix(limit).map { Activity.from(diaper: $0) }
        let sleeps = getSleeps().prefix(limit).map { Activity.from(sleep: $0) }
        let weights = getWeights().prefix(limit).map { Activity.from(weight: $0) }
        let pumpings = getPumpings().prefix(limit).map { Activity.from(pumping: $0) }
        
        activities.append(contentsOf: feedings)
        activities.append(contentsOf: diapers)
        activities.append(contentsOf: sleeps)
        activities.append(contentsOf: weights)
        activities.append(contentsOf: pumpings)
        
        // Sort by timestamp and take limit
        return activities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - All Activities (for History)
    
    func getAllActivities(filter: ActivityType? = nil) -> [Activity] {
        var activities: [Activity] = []
        
        if filter == nil || filter == .feeding {
            activities.append(contentsOf: getFeedings().map { Activity.from(feeding: $0) })
        }
        if filter == nil || filter == .diaper {
            activities.append(contentsOf: getDiapers().map { Activity.from(diaper: $0) })
        }
        if filter == nil || filter == .sleep {
            activities.append(contentsOf: getSleeps().map { Activity.from(sleep: $0) })
        }
        if filter == nil || filter == .weight {
            activities.append(contentsOf: getWeights().map { Activity.from(weight: $0) })
        }
        if filter == nil || filter == .pumping {
            activities.append(contentsOf: getPumpings().map { Activity.from(pumping: $0) })
        }
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Delete Activity
    
    func deleteActivity(_ activity: Activity) {
        switch activity.type {
        case .feeding:
            deleteFeeding(id: activity.id)
        case .diaper:
            deleteDiaper(id: activity.id)
        case .sleep:
            deleteSleep(id: activity.id)
        case .weight:
            deleteWeight(id: activity.id)
        case .pumping:
            deletePumping(id: activity.id)
        }
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        try? modelContext.delete(model: Feeding.self)
        try? modelContext.delete(model: Diaper.self)
        try? modelContext.delete(model: Sleep.self)
        try? modelContext.delete(model: Weight.self)
        try? modelContext.delete(model: Pumping.self)
        try? modelContext.save()
    }
    
    // MARK: - Reports
    
    func generateReport(from startDate: Date, to endDate: Date) -> ReportSummary {
        // Fetch feedings in range
        let feedingDescriptor = FetchDescriptor<Feeding>(
            predicate: #Predicate { $0.timestamp >= startDate && $0.timestamp <= endDate },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let feedings = (try? modelContext.fetch(feedingDescriptor)) ?? []
        let totalFeedingOz = feedings.reduce(0.0) { $0 + $1.summaryValue }
        
        // Fetch sleeps in range
        let sleepDescriptor = FetchDescriptor<Sleep>(
            predicate: #Predicate { $0.startTime >= startDate && $0.startTime <= endDate },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        let sleeps = (try? modelContext.fetch(sleepDescriptor)) ?? []
        let completedSleeps = sleeps.filter { !$0.isActive }
        let totalSleepHours = completedSleeps.reduce(0.0) { $0 + $1.durationHours }
        
        // Fetch diapers in range
        let diaperDescriptor = FetchDescriptor<Diaper>(
            predicate: #Predicate { $0.timestamp >= startDate && $0.timestamp <= endDate },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let diapers = (try? modelContext.fetch(diaperDescriptor)) ?? []
        let wetCount = diapers.filter { $0.type == .wet }.count
        let dirtyCount = diapers.filter { $0.type == .dirty }.count
        let mixedCount = diapers.filter { $0.type == .mixed }.count
        
        // Fetch weights in range
        let weightDescriptor = FetchDescriptor<Weight>(
            predicate: #Predicate { $0.timestamp >= startDate && $0.timestamp <= endDate },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let weights = (try? modelContext.fetch(weightDescriptor)) ?? []
        let startWeight = weights.first?.weightLbs
        let endWeight = weights.last?.weightLbs
        
        return ReportSummary(
            startDate: startDate,
            endDate: endDate,
            totalFeedingOz: totalFeedingOz,
            feedingCount: feedings.count,
            totalSleepHours: totalSleepHours,
            sleepCount: completedSleeps.count,
            diaperCount: diapers.count,
            wetDiaperCount: wetCount + mixedCount, // mixed counts as both
            dirtyDiaperCount: dirtyCount + mixedCount,
            startWeight: startWeight,
            endWeight: endWeight
        )
    }
}

