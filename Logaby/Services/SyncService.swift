import Foundation
import Supabase
import SwiftData

/// DTO for syncing activities
struct SyncActivity: Codable {
    let id: UUID
    let family_id: UUID
    let type: String
    let timestamp: Date
    let data: [String: AnyJSON]
    let created_by: UUID?
    
    // Memberwise init
    init(id: UUID, family_id: UUID, type: String, timestamp: Date, data: [String: AnyJSON], created_by: UUID?) {
        self.id = id
        self.family_id = family_id
        self.type = type
        self.timestamp = timestamp
        self.data = data
        self.created_by = created_by
    }
    
    // Helper to decode JSONB
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        family_id = try container.decode(UUID.self, forKey: .family_id)
        type = try container.decode(String.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        data = try container.decode([String: AnyJSON].self, forKey: .data)
        created_by = try container.decodeIfPresent(UUID.self, forKey: .created_by)
    }
    
    // Helper to encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(family_id, forKey: .family_id)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(data, forKey: .data)
        try container.encodeIfPresent(created_by, forKey: .created_by)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, family_id, type, timestamp, data, created_by
    }
}

/// JSON Value wrapper for Any decoding
enum AnyJSON: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) { self = .string(x); return }
        if let x = try? container.decode(Double.self) { self = .number(x); return }
        if let x = try? container.decode(Bool.self) { self = .bool(x); return }
        if container.decodeNil() { self = .null; return }
        throw DecodingError.typeMismatch(AnyJSON.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for AnyJSON"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x): try container.encode(x)
        case .number(let x): try container.encode(x)
        case .bool(let x): try container.encode(x)
        case .null: try container.encodeNil()
        }
    }
    
    var stringValue: String? { if case .string(let s) = self { return s } else { return nil } }
    var doubleValue: Double? { if case .number(let n) = self { return n } else { return nil } }
    var intValue: Int? { if case .number(let n) = self { return Int(n) } else { return nil } }
}

/// Service for syncing activities with real-time support
class SyncService: ObservableObject {
    static let shared = SyncService()
    private let client = SupabaseService.shared.client
    
    /// Callback for when new activities arrive via realtime or polling
    var onActivityReceived: ((SyncActivity) -> Void)?
    
    /// Current realtime channel subscription
    private var realtimeChannel: RealtimeChannelV2?
    private var subscribedFamilyId: UUID?
    
    /// Polling timer for fallback sync
    private var pollingTimer: Timer?
    private var lastSyncTime: Date = Date()
    
    /// Track known activity IDs to avoid duplicates
    private var knownActivityIds: Set<UUID> = []
    
    private init() {}
    
    /// Sync a single activity to cloud
    func uploadActivity(_ activity: SyncActivity) async throws {
        _ = try await client.database
            .from("activities")
            .upsert(activity) // Use upsert to handle updates
            .execute()
        
        // Track this as known to avoid re-importing via polling
        knownActivityIds.insert(activity.id)
    }
    
    /// Fetch recent activities for family
    func fetchActivities(familyId: UUID, since: Date? = nil) async throws -> [SyncActivity] {
        var query = client.database
            .from("activities")
            .select()
            .eq("family_id", value: familyId)
        
        if let since = since {
            // Fetch only newer activities
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            query = query.gt("timestamp", value: formatter.string(from: since))
        }
        
        let activities: [SyncActivity] = try await query
            .order("timestamp", ascending: false)
            .limit(100)
            .execute()
            .value
        
        return activities
    }
    
    // MARK: - Realtime Subscription
    
    /// Subscribe to realtime updates for a family
    func subscribeToFamily(_ familyId: UUID) async {
        // Don't resubscribe to same family
        if subscribedFamilyId == familyId { return }
        
        // Unsubscribe from previous if any
        await unsubscribe()
        
        subscribedFamilyId = familyId
        
        print("📡 Subscribing to realtime for family: \(familyId)")
        
        // Create channel for this family's activities
        let channel = client.realtimeV2.channel("family-\(familyId.uuidString)")
        
        // Listen for new inserts on activities table for this family
        let changes = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "activities",
            filter: "family_id=eq.\(familyId.uuidString)"
        )
        
        // Store channel reference
        realtimeChannel = channel
        
        // Subscribe to the channel
        await channel.subscribe()
        
        // Listen for inserts
        Task {
            for await insert in changes {
                do {
                    // Configure decoder for ISO8601 dates
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    // Decode the new activity
                    let activity = try insert.decodeRecord(as: SyncActivity.self, decoder: decoder)
                    
                    // Skip if already known
                    if knownActivityIds.contains(activity.id) {
                        continue
                    }
                    knownActivityIds.insert(activity.id)
                    
                    // Skip if this was created by current user (we already have it locally)
                    if activity.created_by == SupabaseService.shared.currentUserId {
                        print("📡 Skipping own activity")
                        continue
                    }
                    
                    print("📡 Received new activity from family member: \(activity.type)")
                    
                    // Notify listener (ActivityRepository)
                    await MainActor.run {
                        self.onActivityReceived?(activity)
                    }
                } catch {
                    print("📡 Error decoding realtime activity: \(error)")
                }
            }
        }
        
        print("📡 Realtime subscription active")
        
        // Start polling as fallback (every 15 seconds)
        await MainActor.run {
            startPolling(familyId: familyId)
        }
    }
    
    /// Unsubscribe from realtime updates
    func unsubscribe() async {
        await MainActor.run {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
        
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
            subscribedFamilyId = nil
            print("📡 Unsubscribed from realtime")
        }
    }
    
    // MARK: - Polling Fallback
    
    /// Start polling for new activities (fallback if realtime doesn't work)
    @MainActor
    private func startPolling(familyId: UUID) {
        pollingTimer?.invalidate()
        lastSyncTime = Date()
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task {
                await self?.pollForNewActivities(familyId: familyId)
            }
        }
        
        print("📡 Polling fallback started (every 15s)")
    }
    
    /// Poll for new activities since last sync
    private func pollForNewActivities(familyId: UUID) async {
        do {
            // Fetch recent activities (last 24 hours worth) to catch any updates
            let activities = try await fetchActivities(familyId: familyId)
            
            for activity in activities {
                // Track as known (but don't skip - let importActivity handle update logic)
                knownActivityIds.insert(activity.id)
                
                // Pass to import handler - it will insert OR update as needed
                await MainActor.run {
                    self.onActivityReceived?(activity)
                }
            }
            
            print("📡 [Polling] Processed \(activities.count) activities")
        } catch {
            print("📡 Polling error: \(error)")
        }
    }
}
