import Foundation
import SwiftData

/// Repository for managing all activity data
@MainActor
final class ActivityRepository: ObservableObject {
    private let modelContext: ModelContext
    
    /// Track deleted activity IDs to prevent re-import from sync
    private var deletedActivityIds: Set<UUID> = []
    
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
                
                // Bi-directional sync: upload first, then download
                if FamilyService.shared.currentFamily != nil {
                    await syncUp()   // Upload local activities
                    await syncDown() // Download remote activities
                }
                
                // Set up realtime subscription if we have a family
                if let family = FamilyService.shared.currentFamily {
                    await setupRealtimeSync(familyId: family.id)
                }
            }
        }
    }
    
    /// Upload all local activities to cloud (ensures nothing is lost)
    func syncUp() async {
        guard let family = FamilyService.shared.currentFamily,
              let userId = SupabaseService.shared.currentUserId else { return }
        
        // Get all local activities and upload them
        let feedings = getFeedings()
        let diapers = getDiapers()
        let sleeps = getSleeps()
        let weights = getWeights()
        let pumpings = getPumpings()
        
        for feeding in feedings {
            let syncItem = feeding.toSyncActivity(familyId: family.id, userId: userId)
            try? await SyncService.shared.uploadActivity(syncItem)
        }
        
        for diaper in diapers {
            let syncItem = diaper.toSyncActivity(familyId: family.id, userId: userId)
            try? await SyncService.shared.uploadActivity(syncItem)
        }
        
        for sleep in sleeps {
            let syncItem = sleep.toSyncActivity(familyId: family.id, userId: userId)
            try? await SyncService.shared.uploadActivity(syncItem)
        }
        
        for weight in weights {
            let syncItem = weight.toSyncActivity(familyId: family.id, userId: userId)
            try? await SyncService.shared.uploadActivity(syncItem)
        }
        
        for pumping in pumpings {
            let syncItem = pumping.toSyncActivity(familyId: family.id, userId: userId)
            try? await SyncService.shared.uploadActivity(syncItem)
        }
        
        print("📤 Uploaded all local activities to cloud")
    }
    
    /// Set up realtime sync for a family
    func setupRealtimeSync(familyId: UUID) async {
        // Set up callback to import activities received in realtime
        SyncService.shared.onActivityReceived = { [weak self] activity in
            Task { @MainActor in
                self?.importActivity(activity)
                try? self?.modelContext.save()
                
                // Notify observers that data changed
                self?.objectWillChange.send()
            }
        }
        
        // Subscribe to realtime updates
        await SyncService.shared.subscribeToFamily(familyId)
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
        // Skip if this activity was deleted locally
        if deletedActivityIds.contains(activity.id) {
            return
        }
        
        // Import or update activity from sync data
        
        if activity.type == "feeding" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Feeding>(predicate: #Predicate { $0.id == activity.id })).first {
                // UPDATE existing feeding with new values from sync
                if let updated = Feeding.fromSyncActivity(activity) {
                    existing.timestamp = updated.timestamp
                    existing.type = updated.type
                    existing.amountOz = updated.amountOz
                    existing.durationMinutes = updated.durationMinutes
                    existing.side = updated.side
                    existing.bottleContent = updated.bottleContent
                }
            } else if let new = Feeding.fromSyncActivity(activity) {
                modelContext.insert(new)
            }
        } else if activity.type == "diaper" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Diaper>(predicate: #Predicate { $0.id == activity.id })).first {
                // UPDATE existing diaper
                if let updated = Diaper.fromSyncActivity(activity) {
                    existing.timestamp = updated.timestamp
                    existing.type = updated.type
                }
            } else if let new = Diaper.fromSyncActivity(activity) {
                modelContext.insert(new)
            }
        } else if activity.type == "sleep" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Sleep>(predicate: #Predicate { $0.id == activity.id })).first {
                // UPDATE existing sleep with new start/end times
                if let updated = Sleep.fromSyncActivity(activity) {
                    existing.startTime = updated.startTime
                    existing.endTime = updated.endTime
                }
            } else if let new = Sleep.fromSyncActivity(activity) {
                modelContext.insert(new)
            }
        } else if activity.type == "weight" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Weight>(predicate: #Predicate { $0.id == activity.id })).first {
                // UPDATE existing weight
                if let updated = Weight.fromSyncActivity(activity) {
                    existing.timestamp = updated.timestamp
                    existing.weightLbs = updated.weightLbs
                }
            } else if let new = Weight.fromSyncActivity(activity) {
                modelContext.insert(new)
            }
        } else if activity.type == "pumping" {
            if let existing = try? modelContext.fetch(FetchDescriptor<Pumping>(predicate: #Predicate { $0.id == activity.id })).first {
                // UPDATE existing pumping
                if let updated = Pumping.fromSyncActivity(activity) {
                    existing.timestamp = updated.timestamp
                    existing.amountOz = updated.amountOz
                    existing.durationMinutes = updated.durationMinutes
                    existing.side = updated.side
                }
            } else if let new = Pumping.fromSyncActivity(activity) {
                modelContext.insert(new)
            }
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
    
    func updateFeeding(_ feeding: Feeding) {
        try? modelContext.save()
        upload(feeding)
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
    
    func updateDiaper(_ diaper: Diaper) {
        try? modelContext.save()
        upload(diaper)
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
    
    func updateSleep(_ sleep: Sleep) {
        try? modelContext.save()
        upload(sleep)
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
    
    func updateWeight(_ weight: Weight) {
        try? modelContext.save()
        upload(weight)
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
    
    func updatePumping(_ pumping: Pumping) {
        try? modelContext.save()
        upload(pumping)
    }
    
    // MARK: - Summary
    
    func getTodaySummary() -> DailySummary {
        let today = Date()
        
        let feedings = getFeedings(for: today)
        let totalOz = feedings.reduce(0.0) { $0 + $1.summaryValue }
        let totalNursingMinutes = feedings.reduce(0) { $0 + $1.nursingMinutes }
        
        let pumpings = getPumpings(for: today)
        let totalPumpedOz = pumpings.reduce(0.0) { $0 + $1.amountOz }
        
        let sleeps = getSleeps(for: today)
        let completedSleeps = sleeps.filter { !$0.isActive }
        let totalSleepHours = completedSleeps.reduce(0.0) { $0 + $1.durationHours }
        let daySleepHours = completedSleeps.filter { !$0.isNightSleep }.reduce(0.0) { $0 + $1.durationHours }
        let nightSleepHours = completedSleeps.filter { $0.isNightSleep }.reduce(0.0) { $0 + $1.durationHours }
        
        let diapers = getDiapers(for: today)
        let wetCount = diapers.filter { $0.type == .wet }.count
        let dirtyCount = diapers.filter { $0.type == .dirty }.count
        let mixedCount = diapers.filter { $0.type == .mixed }.count
        
        let latestWeightRecord = getLatestWeight()
        let latestWeight = latestWeightRecord?.weightLbs
        let lastWeightDate = latestWeightRecord?.timestamp
        
        let activeSleep = getActiveSleep()
        
        return DailySummary(
            totalOz: totalOz,
            totalPumpedOz: totalPumpedOz,
            totalNursingMinutes: totalNursingMinutes,
            totalSleepHours: totalSleepHours,
            daySleepHours: daySleepHours,
            nightSleepHours: nightSleepHours,
            diaperCount: diapers.count,
            wetDiaperCount: wetCount,
            dirtyDiaperCount: dirtyCount,
            mixedDiaperCount: mixedCount,
            latestWeight: latestWeight,
            lastWeightDate: lastWeightDate,
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
        // Track as deleted to prevent re-import from sync
        deletedActivityIds.insert(activity.id)
        
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
        
        // Notify views that data changed
        objectWillChange.send()
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

