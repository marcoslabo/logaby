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

/// Service for syncing activities
class SyncService {
    static let shared = SyncService()
    private let client = SupabaseService.shared.client
    
    private init() {}
    
    /// Sync a single activity to cloud
    func uploadActivity(_ activity: SyncActivity) async throws {
        _ = try await client.database
            .from("activities")
            .upsert(activity) // Use upsert to handle updates
            .execute()
    }
    
    /// Fetch recent activities for family
    func fetchActivities(familyId: UUID, since: Date? = nil) async throws -> [SyncActivity] {
        // Simplified query: fetch recent 100
        let activities: [SyncActivity] = try await client.database
            .from("activities")
            .select()
            .eq("family_id", value: familyId)
            .order("timestamp", ascending: false)
            .limit(100)
            .execute()
            .value
        
        return activities
    }
}
