import SwiftUI
import SwiftData

/// Settings screen with subscription management, family sync, and support
struct SettingsView: View {
    @ObservedObject var repository: ActivityRepository
    @ObservedObject var familyService = FamilyService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var familyName = ""
    @State private var inviteCode = ""
    @State private var errorMessage: String?
    @State private var showRestoreSuccess = false
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                Section {
                    if subscriptionManager.hasActiveSubscription {
                        // Active subscription
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppColors.sage)
                                Text("First Months Pass")
                                    .font(AppFonts.titleLarge())
                                    .foregroundColor(AppColors.textDark)
                            }
                            Text("You have full access to all features")
                                .font(AppFonts.bodySmall())
                                .foregroundColor(AppColors.textSoft)
                        }
                        .padding(.vertical, Spacing.xs)
                    } else if subscriptionManager.isTrialActive {
                        // Trial active
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Free Trial")
                                    .font(AppFonts.titleLarge())
                                    .foregroundColor(AppColors.textDark)
                            }
                            Text("\(subscriptionManager.trialDaysRemaining) days remaining")
                                .font(AppFonts.bodySmall())
                                .foregroundColor(AppColors.textSoft)
                            
                            Button {
                                showPaywall = true
                            } label: {
                                Text("Upgrade to First Months Pass")
                                    .font(AppFonts.labelLarge())
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(.top, Spacing.xs)
                        }
                        .padding(.vertical, Spacing.xs)
                    } else {
                        // Trial expired
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Trial Expired")
                                .font(AppFonts.titleLarge())
                                .foregroundColor(AppColors.textDark)
                            Text("Subscribe to continue using voice logging")
                                .font(AppFonts.bodySmall())
                                .foregroundColor(AppColors.textSoft)
                            
                            Button {
                                showPaywall = true
                            } label: {
                                Text("Get the First Months Pass — $19.99")
                                    .font(AppFonts.labelLarge())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(AppColors.primary)
                                    .cornerRadius(12)
                            }
                            .padding(.top, Spacing.xs)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                    
                    // Restore Purchases (always show)
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                            if subscriptionManager.hasActiveSubscription {
                                showRestoreSuccess = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppColors.primary)
                            Text("Restore Purchases")
                                .foregroundColor(AppColors.primary)
                            Spacer()
                            if subscriptionManager.isLoading {
                                ProgressView()
                            }
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                // Sync Section
                Section {
                    if let family = familyService.currentFamily {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Family Group")
                                .font(AppFonts.labelLarge())
                                .foregroundColor(AppColors.textSoft)
                            Text(family.name)
                                .font(AppFonts.headlineMedium())
                                .foregroundColor(AppColors.textDark)
                            
                            Divider().padding(.vertical, Spacing.xs)
                            
                            if let code = family.inviteCode {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Invite Code")
                                            .font(AppFonts.labelLarge())
                                            .foregroundColor(AppColors.textSoft)
                                        Text(code)
                                            .font(AppFonts.titleLarge())
                                            .foregroundColor(AppColors.primary)
                                    }
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = code
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                            
                            Button("Sync Now") {
                                Task { await repository.syncDown() }
                            }
                            .font(AppFonts.labelLarge())
                            .foregroundColor(AppColors.primary)
                            .padding(.top, Spacing.sm)
                        }
                        .padding(.vertical, Spacing.xs)
                    } else {
                        SettingsTile(
                            icon: "person.3.fill",
                            iconColor: AppColors.primary,
                            title: "Create Family",
                            subtitle: "Start a new tracking group"
                        ) {
                            showCreateFamily = true
                        }
                        
                        SettingsTile(
                            icon: "arrow.right.circle.fill",
                            iconColor: AppColors.sage,
                            title: "Join Family",
                            subtitle: "Enter invite code"
                        ) {
                            showJoinFamily = true
                        }
                    }
                } header: {
                    Text("Family Sync")
                } footer: {
                    Text("Data stays on your device unless you choose to sync with family")
                }
                
                // Schedule section
                Section {
                    NavigationLink {
                        ScheduleView()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.sleepAccent.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(AppColors.sleepAccent)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Schedule & Reminders")
                                    .font(AppFonts.titleLarge())
                                    .foregroundColor(AppColors.textDark)
                                
                                Text("Set up daily notifications")
                                    .font(AppFonts.bodySmall())
                                    .foregroundColor(AppColors.textSoft)
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                } header: {
                    Text("Schedule")
                }
                
                // Data section
                Section {
                    SettingsTile(
                        icon: "square.and.arrow.up",
                        iconColor: AppColors.sage,
                        title: "Export Data",
                        subtitle: "Download as PDF"
                    ) {
                        // TODO: Implement export
                    }
                } header: {
                    Text("Data")
                }
                
                // About section
                Section {
                    Link(destination: URL(string: "https://logaby.com/privacy.html")!) {
                        HStack(spacing: Spacing.md) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.lavender.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "hand.raised")
                                        .foregroundColor(AppColors.lavender)
                                )
                            
                            Text("Privacy Policy")
                                .font(AppFonts.titleLarge())
                                .foregroundColor(AppColors.textDark)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textLight)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                    
                    Link(destination: URL(string: "https://logaby.com/support.html")!) {
                        HStack(spacing: Spacing.md) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primary.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(AppColors.primary)
                                )
                            
                            Text("Help & Support")
                                .font(AppFonts.titleLarge())
                                .foregroundColor(AppColors.textDark)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textLight)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                    
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        HStack(spacing: Spacing.md) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.textSoft.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "doc.text")
                                        .foregroundColor(AppColors.textSoft)
                                )
                            
                            Text("Terms of Use")
                                .font(AppFonts.titleLarge())
                                .foregroundColor(AppColors.textDark)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textLight)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                } header: {
                    Text("About")
                }
                
                // Version
                Section {
                    HStack {
                        Spacer()
                        Text("Logaby v1.0.0")
                            .font(AppFonts.bodySmall())
                            .foregroundColor(AppColors.textLight)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Create Family", isPresented: $showCreateFamily) {
            TextField("Family Name", text: $familyName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                Task {
                    do {
                        let family = try await familyService.createFamily(name: familyName)
                        await repository.syncDown()
                        await repository.setupRealtimeSync(familyId: family.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .alert("Join Family", isPresented: $showJoinFamily) {
            TextField("Invite Code", text: $inviteCode)
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                Task {
                    do {
                        let family = try await familyService.joinByCode(inviteCode)
                        await repository.syncDown()
                        await repository.setupRealtimeSync(familyId: family.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
            Button("OK") { }
        } message: {
            Text("Your First Months Pass has been restored.")
        }
    }
}

// MARK: - Settings Tile

struct SettingsTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(iconColor)
                    )
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.titleLarge())
                        .foregroundColor(AppColors.textDark)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodySmall())
                            .foregroundColor(AppColors.textSoft)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textLight)
            }
            .padding(.vertical, Spacing.xs)
        }
    }
}

#Preview {
    SettingsView(repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self, Diaper.self, Sleep.self, Weight.self).mainContext))
}
