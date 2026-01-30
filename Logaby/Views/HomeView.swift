import SwiftUI
import SwiftData

/// Home screen - Dashboard showing today's summary and recent activity
struct HomeView: View {
    @ObservedObject var repository: ActivityRepository
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var summary: DailySummary = .empty
    @State private var recentActivities: [Activity] = []
    @State private var showVoiceInput = false
    @State private var showPaywall = false
    @State private var showWalkthrough = false
    @AppStorage("hasSeenWalkthrough") private var hasSeenWalkthrough = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection
                    
                    // Trial banner (if in trial and not subscribed)
                    if subscriptionManager.isTrialActive && !subscriptionManager.hasActiveSubscription {
                        trialBanner
                    }
                    
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
                // Check if user can access voice logging
                if subscriptionManager.canAccessPremiumFeatures {
                    showVoiceInput = true
                } else {
                    showPaywall = true
                }
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
            
            // Show walkthrough on first launch (after onboarding)
            if !hasSeenWalkthrough {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showWalkthrough = true
                    hasSeenWalkthrough = true
                }
            }
        }
        .onReceive(repository.objectWillChange) { _ in
            // Refresh data when repository changes (e.g., from family sync)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadData()
            }
        }
        .sheet(isPresented: $showVoiceInput) {
            VoiceInputSheet(repository: repository) {
                loadData()
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .overlay {
            if showWalkthrough {
                WalkthroughOverlay(isShowing: $showWalkthrough)
            }
        }
    }
    
    // MARK: - Sections
    
    private var trialBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Trial")
                        .font(AppFonts.labelLarge())
                        .foregroundColor(AppColors.textDark)
                    Text("\(subscriptionManager.trialDaysRemaining) days left")
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.textSoft)
                }
                
                Spacer()
                
                Text("Upgrade")
                    .font(AppFonts.labelLarge())
                    .foregroundColor(AppColors.primary)
            }
            .padding(Spacing.md)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.bottom, Spacing.md)
    }
    
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
            
            // Help button - shows walkthrough
            Button {
                showWalkthrough = true
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
                let feedingMl = Int(summary.totalOz * 30)
                let nursingText = summary.totalNursingMinutes > 0 ? " + \(summary.totalNursingMinutes)min" : ""
                StatCard(
                    title: "Feedings",
                    value: String(format: "%.0f", summary.totalOz),
                    subtitle: "oz (\(feedingMl)ml)\(nursingText)",
                    accentColor: AppColors.feedingAccent,
                    icon: "drop.fill"
                )
                .frame(height: 100)
                
                let pumpedMl = Int(summary.totalPumpedOz * 30)
                StatCard(
                    title: "Pumped",
                    value: String(format: "%.0f", summary.totalPumpedOz),
                    subtitle: "oz (\(pumpedMl)ml)",
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
                    subtitle: "☀️\(String(format: "%.1f", summary.daySleepHours))h 🌙\(String(format: "%.1f", summary.nightSleepHours))h",
                    accentColor: AppColors.sleepAccent,
                    icon: "moon.fill"
                )
                .frame(height: 100)
                
                StatCard(
                    title: "Diapers",
                    value: "\(summary.diaperCount)",
                    subtitle: summary.diaperBreakdown,
                    accentColor: AppColors.diaperAccent,
                    icon: "sparkles"
                )
                .frame(height: 100)
            }
            
            // Third row - Weight with prompt if stale
            weightCard
        }
    }
    
    @ViewBuilder
    private var weightCard: some View {
        let daysSinceWeight = summary.lastWeightDate.map { 
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 
        } ?? 999
        
        if let weightLbs = summary.latestWeight {
            // Convert decimal lbs to lb + oz format (always show oz)
            let wholeLbs = Int(weightLbs)
            let ozPart = Int((weightLbs - Double(wholeLbs)) * 16)
            let weightDisplay = "\(wholeLbs)lb \(ozPart)oz"
            
            StatCard(
                title: daysSinceWeight > 7 ? "Weight (update soon!)" : "Weight",
                value: weightDisplay,
                subtitle: "",
                accentColor: daysSinceWeight > 7 ? .orange : AppColors.weightAccent,
                icon: "scalemass.fill"
            )
            .frame(height: 80)
        } else {
            // No weight logged yet - prompt
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(.orange)
                Text("Tap mic to log baby's weight")
                    .font(AppFonts.bodyMedium())
                    .foregroundColor(AppColors.textSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
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
                    ActivityRow(activity: activity)
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
