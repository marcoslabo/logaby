import Foundation

/// Family group for syncing data
struct Family: Codable, Identifiable {
    let id: UUID
    let name: String
    let inviteCode: String?
    let createdBy: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

/// Member of a family
struct FamilyMember: Codable, Identifiable {
    let id: UUID
    let familyId: UUID
    let userId: UUID
    let role: String
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}
