import SwiftUI
import SwiftData

/// Main Logaby app entry point
@main
struct LogabyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // Create container once
    let container: ModelContainer
    
    // Create repository once
    @StateObject private var repository: ActivityRepository
    
    init() {
        let schema = Schema([
            Feeding.self,
            Diaper.self,
            Sleep.self,
            Weight.self,
            Pumping.self,
            Reminder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.container = container
            self._repository = StateObject(wrappedValue: ActivityRepository(modelContext: container.mainContext))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository, hasSeenOnboarding: $hasSeenOnboarding)
                .modelContainer(container)
        }
    }
}

/// Root content view handling navigation
struct ContentView: View {
    @ObservedObject var repository: ActivityRepository
    @ObservedObject var auth = SupabaseService.shared
    @Binding var hasSeenOnboarding: Bool
    @State private var selectedTab = 0
    
    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
                // After onboarding, we might need auth
            }
        } else if auth.currentUser == nil {
            // Explicit Auth/Loading state
            AuthView()
        } else {
            // Main App
            TabView(selection: $selectedTab) {
                HomeView(repository: repository)
                    .tabItem {
                        Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                
                HistoryView(repository: repository)
                    .tabItem {
                        Label("History", systemImage: selectedTab == 1 ? "clock.fill" : "clock")
                    }
                    .tag(1)
                
                ReportsView(repository: repository)
                    .tabItem {
                        Label("Reports", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    }
                    .tag(2)
                
                SettingsView(repository: repository)
                    .tabItem {
                        Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    }
                    .tag(3)
            }
            .tint(AppColors.primary)
            .onAppear {
                repository.startSync() // Start sync now that we have a user
            }
        }
    }
}

#Preview {
    ContentView(
        repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self, Diaper.self, Sleep.self, Weight.self).mainContext),
        hasSeenOnboarding: .constant(true)
    )
}

/// Authentication landing screen
struct AuthView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Logo / Branding
            VStack(spacing: Spacing.md) {
                Image(systemName: "heart.text.square.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(AppColors.primary)
                
                Text("Logaby")
                    .font(AppFonts.headlineLarge())
                    .foregroundColor(AppColors.textDark)
                
                Text("Track your baby's day\nwith just your voice")
                    .font(AppFonts.bodyLarge())
                    .foregroundColor(AppColors.textSoft)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView("Setting up...")
                    .controlSize(.large)
            } else {
                VStack(spacing: Spacing.md) {
                    Button {
                        startAsGuest()
                    } label: {
                        Text("Get Started")
                            .font(AppFonts.titleLarge())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.primary)
                            .cornerRadius(16)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(AppFonts.bodySmall())
                            .foregroundColor(AppColors.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(AppColors.background)
    }
    
    private func startAsGuest() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await SupabaseService.shared.signInAnonymously()
                // Success is handled by the auth listener in ContentView
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Could not sign in: \(error.localizedDescription)"
                }
            }
        }
    }
}
