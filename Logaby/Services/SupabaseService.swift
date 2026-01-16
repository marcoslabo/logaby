import Foundation
import Supabase

/// Service for Supabase client and auth
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    // Replace with your project details
    private let projectUrl = URL(string: "https://vgnvloytauupdwxdkmlu.supabase.co")!
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnbnZsb3l0YXV1cGR3eGRrbWx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTYyNjUsImV4cCI6MjA4Mzk5MjI2NX0.rmy7K3e8Yl1a_f2GYj-t5RkNJsxOaF8btpsfKrMOUsc"
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var session: Session?
    
    private init() {
        let options = SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
        self.client = SupabaseClient(supabaseURL: projectUrl, supabaseKey: apiKey, options: options)
        
        // Listen for auth changes
        Task {
            for await event in client.auth.authStateChanges {
                await MainActor.run {
                    self.session = event.session
                    self.currentUser = event.session?.user
                }
            }
        }
    }
    
    /// Sign in anonymously (creates a new guest user)
    func signInAnonymously() async throws {
        _ = try await client.auth.signInAnonymously()
    }
    
    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    /// Get current user ID
    var currentUserId: UUID? {
        currentUser?.id
    }
}
