import SwiftUI
import SwiftData

/// Settings screen with data management and Siri shortcut setup
struct SettingsView: View {
    @ObservedObject var repository: ActivityRepository
    @ObservedObject var familyService = FamilyService.shared
    @State private var showSiriInstructions = false
    @State private var showClearConfirmation = false
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var familyName = ""
    @State private var inviteCode = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
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
                    Text("Multi-Parent Sync")
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
                
                // Voice Shortcuts section
                Section {
                    SettingsTile(
                        icon: "mic.fill",
                        iconColor: AppColors.primary,
                        title: "Add Siri Shortcut",
                        subtitle: "Log activities hands-free"
                    ) {
                        showSiriInstructions = true
                    }
                } header: {
                    Text("Voice Shortcuts")
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
                    
                    SettingsTile(
                        icon: "trash",
                        iconColor: AppColors.error,
                        title: "Clear All Data",
                        subtitle: "Remove all logged activities"
                    ) {
                        showClearConfirmation = true
                    }
                } header: {
                    Text("Data")
                }
                
                // About section
                Section {
                    SettingsTile(
                        icon: "hand.raised",
                        iconColor: AppColors.lavender,
                        title: "Privacy Policy",
                        subtitle: nil
                    ) {}
                    
                    SettingsTile(
                        icon: "questionmark.circle",
                        iconColor: AppColors.textSoft,
                        title: "Support",
                        subtitle: nil
                    ) {}
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
        .sheet(isPresented: $showSiriInstructions) {
            SiriInstructionsSheet()
        }
        .alert("Clear All Data?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                repository.clearAll()
            }
        } message: {
            Text("This will permanently delete all your logged activities. This action cannot be undone.")
        }
        .alert("Create Family", isPresented: $showCreateFamily) {
            TextField("Family Name", text: $familyName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                Task {
                    do {
                        _ = try await familyService.createFamily(name: familyName)
                        await repository.syncDown()
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
                        _ = try await familyService.joinByCode(inviteCode)
                        await repository.syncDown()
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

// MARK: - Siri Instructions Sheet

struct SiriInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle bar
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.divider)
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, Spacing.sm)
            
            Spacer().frame(height: Spacing.lg)
            
            Text("Set Up Siri")
                .font(AppFonts.headlineLarge())
                .foregroundColor(AppColors.textDark)
            
            Spacer().frame(height: Spacing.md)
            
            Text("To log activities when your phone is locked:")
                .font(AppFonts.bodyLarge())
                .foregroundColor(AppColors.textSoft)
            
            Spacer().frame(height: Spacing.lg)
            
            InstructionStep(number: "1", text: "Open the Shortcuts app on your iPhone")
            InstructionStep(number: "2", text: "Tap + to create a new shortcut")
            InstructionStep(number: "3", text: "Search for \"Logaby\" and add the action")
            InstructionStep(number: "4", text: "Say \"Hey Siri, tell Logaby 4oz bottle\"")
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(AppFonts.titleLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primary)
                    .cornerRadius(16)
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(number)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.primary)
                )
            
            Text(text)
                .font(AppFonts.bodyLarge())
                .foregroundColor(AppColors.textDark)
        }
        .padding(.bottom, Spacing.md)
    }
}

#Preview {
    SettingsView(repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self, Diaper.self, Sleep.self, Weight.self).mainContext))
}
