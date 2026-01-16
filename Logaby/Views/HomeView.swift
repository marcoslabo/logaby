import SwiftUI
import SwiftData

/// Home screen - Dashboard showing today's summary and recent activity
struct HomeView: View {
    @ObservedObject var repository: ActivityRepository
    @State private var summary: DailySummary = .empty
    @State private var recentActivities: [Activity] = []
    @State private var showVoiceInput = false
    @State private var showTutorial = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection
                    
                    // Stats grid
                    statsGrid
                    
                    // Recent activity
                    recentActivitySection
                    
                    // Bottom padding for FAB
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, Spacing.screenPadding)
            }
            .background(AppColors.background)
            .refreshable {
                loadData()
            }
            
            // Floating mic button
            MicButton {
                showVoiceInput = true
            }
            .padding(.bottom, Spacing.lg)
        }
        .onAppear {
            // Sync any activities logged via Siri while app was closed
            let synced = SiriSyncService.syncPendingActivities(repository: repository)
            if synced > 0 {
                print("Synced \(synced) activities from Siri")
            }
            loadData()
        }
        .sheet(isPresented: $showVoiceInput) {
            VoiceInputSheet(repository: repository) {
                loadData()
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView(hasSeenTutorial: $hasSeenTutorial)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi there 👋")
                    .font(AppFonts.bodyLarge())
                    .foregroundColor(AppColors.textSoft)
                
                Text("Today's Summary")
                    .font(AppFonts.headlineLarge())
                    .foregroundColor(AppColors.textDark)
            }
            
            Spacer()
            
            // Help button - minimal and unobtrusive
            Button {
                showTutorial = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textLight)
            }
            .padding(.trailing, Spacing.xs)
            
            // Active sleep indicator
            if summary.activeSleep != nil {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                    Text("Sleeping")
                        .font(AppFonts.labelLarge())
                }
                .foregroundColor(AppColors.sage)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(AppColors.sage.opacity(0.2))
                .cornerRadius(20)
            }
        }
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
    
    private var statsGrid: some View {
        VStack(spacing: Spacing.md) {
            // First row - Feeding and Pumping (mother's activities)
            HStack(spacing: Spacing.md) {
                StatCard(
                    title: "Feedings",
                    value: String(format: "%.0f", summary.totalOz),
                    subtitle: "oz",
                    accentColor: AppColors.feedingAccent,
                    icon: "drop.fill"
                )
                .frame(height: 100)
                
                StatCard(
                    title: "Pumped",
                    value: String(format: "%.0f", summary.totalPumpedOz),
                    subtitle: "oz",
                    accentColor: AppColors.pumpingAccent,
                    icon: "heart.fill"
                )
                .frame(height: 100)
            }
            
            // Second row - Sleep and Diapers
            HStack(spacing: Spacing.md) {
                StatCard(
                    title: "Sleep",
                    value: String(format: "%.1f", summary.totalSleepHours),
                    subtitle: "hrs",
                    accentColor: AppColors.sleepAccent,
                    icon: "moon.fill"
                )
                .frame(height: 100)
                
                StatCard(
                    title: "Diapers",
                    value: "\(summary.diaperCount)",
                    subtitle: "changes",
                    accentColor: AppColors.diaperAccent,
                    icon: "sparkles"
                )
                .frame(height: 100)
            }
            
            // Third row - Weight only (full width optional)
            if summary.latestWeight != nil {
                StatCard(
                    title: "Weight",
                    value: summary.latestWeight.map { String(format: "%.1f", $0) } ?? "--",
                    subtitle: "lbs",
                    accentColor: AppColors.weightAccent,
                    icon: "scalemass.fill"
                )
                .frame(height: 80)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Activity")
                .font(AppFonts.headlineMedium())
                .foregroundColor(AppColors.textDark)
                .padding(.top, Spacing.xl)
            
            if recentActivities.isEmpty {
                emptyState
            } else {
                ForEach(recentActivities) { activity in
                    ActivityRow(activity: activity) {
                        repository.deleteActivity(activity)
                        loadData()
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "plus.circle")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textLight)
            
            Text("No activity yet")
                .font(AppFonts.headlineSmall())
                .foregroundColor(AppColors.textLight)
            
            Text("Tap the mic button to log")
                .font(AppFonts.bodyMedium())
                .foregroundColor(AppColors.textLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        summary = repository.getTodaySummary()
        recentActivities = repository.getRecentActivities(limit: 7)
    }
}

#Preview {
    HomeView(repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self, Diaper.self, Sleep.self, Weight.self).mainContext))
}
