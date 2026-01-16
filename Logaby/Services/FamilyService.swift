import Foundation
import Supabase

/// Service for managing families
class FamilyService: ObservableObject {
    static let shared = FamilyService()
    
    private let client = SupabaseService.shared.client
    
    @Published var currentFamily: Family?
    @Published var members: [FamilyMember] = []
    
    private init() {}
    
    /// Create a new family
    func createFamily(name: String) async throws -> Family {
        guard let userId = SupabaseService.shared.currentUser?.id else {
            throw NSError(domain: "FamilyService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        
        // Generate a random invite code (6 uppercase letters/numbers)
        let inviteCode = generateInviteCode()
        
        struct CreateParams: Encodable {
            let name: String
            let created_by: UUID
            let invite_code: String
        }
        
        let family: Family = try await client.database
            .from("families")
            .insert(CreateParams(name: name, created_by: userId, invite_code: inviteCode))
            .select()
            .single()
            .execute()
            .value
        
        // Add self as member
        try await joinFamily(id: family.id)
        
        await MainActor.run {
            self.currentFamily = family
        }
        
        return family
    }
    
    /// Generate a random 6-character invite code
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluded I, O, 0, 1 to avoid confusion
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    /// Join a family by ID
    private func joinFamily(id: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUser?.id else { return }
        
        struct JoinParams: Encodable {
            let family_id: UUID
            let user_id: UUID
            let role: String
        }
        
        _ = try await client.database
            .from("family_members")
            .insert(JoinParams(family_id: id, user_id: userId, role: "admin"))
            .execute()
    }
    
    /// Join family by invite code
    func joinByCode(_ code: String) async throws -> Family {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !trimmedCode.isEmpty else {
            throw NSError(domain: "FamilyService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter an invite code"])
        }
        
        print("DEBUG: Searching for family with invite_code = '\(trimmedCode)'")
        
        // Find family by code
        let family: Family
        do {
            family = try await client.database
                .from("families")
                .select()
                .eq("invite_code", value: trimmedCode)
                .single()
                .execute()
                .value
            print("DEBUG: Found family: \(family.name) with id \(family.id)")
        } catch let error {
            print("DEBUG: Failed to find family. Error: \(error)")
            // PGRST116 means no matching row found
            throw NSError(domain: "FamilyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No family found with code '\(trimmedCode)'. Please check the code and try again."])
        }
        
        // Join it
        if let userId = SupabaseService.shared.currentUser?.id {
            struct JoinParams: Encodable {
                let family_id: UUID
                let user_id: UUID
                let role: String
            }
            
            do {
                _ = try await client.database
                    .from("family_members")
                    .insert(JoinParams(family_id: family.id, user_id: userId, role: "member"))
                    .execute()
            } catch {
                // User might already be a member
                throw NSError(domain: "FamilyService", code: 409, userInfo: [NSLocalizedDescriptionKey: "You may already be a member of this family."])
            }
        }
        
        await MainActor.run {
            self.currentFamily = family
        }
        
        return family
    }
    
    /// Fetch current user's family
    func fetchCurrentFamily() async {
        guard let userId = SupabaseService.shared.currentUser?.id else { return }
        
        do {
            // Get membership
            let member: FamilyMember = try await client.database
                .from("family_members")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            // Get family details
            let family: Family = try await client.database
                .from("families")
                .select()
                .eq("id", value: member.familyId)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentFamily = family
            }
        } catch {
            // It's normal for new users to not have a family yet
            // print("Debug: User has no family yet or error fetching: \(error)")
        }
    }
}
