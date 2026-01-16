import SwiftUI
import SwiftData

/// View for managing scheduled reminders
struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reminder.hour) private var reminders: [Reminder]
    
    @State private var showAddReminder = false
    @State private var showTemplates = false
    @State private var editingReminder: Reminder?
    @State private var notificationStatus: String = "Checking..."
    
    var body: some View {
        NavigationStack {
            List {
                // Notification permission section
                if notificationStatus != "Authorized" {
                    Section {
                        permissionBanner
                    }
                }
                
                // Templates section
                Section {
                    Button {
                        showTemplates = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(AppColors.primary)
                            Text("Apply Schedule Template")
                                .foregroundColor(AppColors.textDark)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppColors.textLight)
                        }
                    }
                } header: {
                    Text("Templates")
                }
                
                // Reminders list
                Section {
                    if reminders.isEmpty {
                        emptyState
                    } else {
                        ForEach(reminders) { reminder in
                            reminderRow(reminder)
                        }
                        .onDelete(perform: deleteReminders)
                    }
                } header: {
                    Text("Your Reminders")
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddReminder) {
                AddReminderSheet { reminder in
                    addReminder(reminder)
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatePickerSheet { template in
                    applyTemplate(template)
                }
            }
            .sheet(item: $editingReminder) { reminder in
                EditReminderSheet(reminder: reminder) {
                    updateReminder(reminder)
                }
            }
        }
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    // MARK: - Views
    
    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.orange)
                Text("Notifications Disabled")
                    .font(AppFonts.labelLarge())
                    .foregroundColor(AppColors.textDark)
            }
            
            Text("Enable notifications to receive reminders.")
                .font(AppFonts.bodySmall())
                .foregroundColor(AppColors.textSoft)
            
            Button("Enable Notifications") {
                Task {
                    let granted = await NotificationService.shared.requestAuthorization()
                    notificationStatus = granted ? "Authorized" : "Denied"
                }
            }
            .font(AppFonts.labelLarge())
            .foregroundColor(AppColors.primary)
        }
        .padding(.vertical, Spacing.xs)
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textLight)
            
            Text("No reminders yet")
                .font(AppFonts.bodyMedium())
                .foregroundColor(AppColors.textSoft)
            
            Text("Tap + to add a reminder or use a template")
                .font(AppFonts.bodySmall())
                .foregroundColor(AppColors.textLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    private func reminderRow(_ reminder: Reminder) -> some View {
        Button {
            editingReminder = reminder
        } label: {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: reminder.icon)
                    .font(.system(size: 20))
                    .foregroundColor(colorFor(reminder.activityType))
                    .frame(width: 32)
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(AppFonts.bodyMedium())
                        .foregroundColor(AppColors.textDark)
                    
                    Text(reminder.daysString)
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.textSoft)
                }
                
                Spacer()
                
                // Time
                Text(reminder.timeString)
                    .font(AppFonts.titleLarge())
                    .foregroundColor(reminder.isEnabled ? AppColors.textDark : AppColors.textLight)
                
                // Toggle
                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { newValue in
                        reminder.isEnabled = newValue
                        updateReminder(reminder)
                    }
                ))
                .labelsHidden()
                .tint(AppColors.primary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func checkNotificationStatus() {
        Task {
            let status = await NotificationService.shared.checkAuthorization()
            switch status {
            case .authorized:
                notificationStatus = "Authorized"
            case .denied:
                notificationStatus = "Denied"
            case .notDetermined:
                notificationStatus = "Not Asked"
            default:
                notificationStatus = "Unknown"
            }
        }
    }
    
    private func addReminder(_ reminder: Reminder) {
        modelContext.insert(reminder)
        NotificationService.shared.scheduleReminder(reminder)
    }
    
    private func updateReminder(_ reminder: Reminder) {
        try? modelContext.save()
        NotificationService.shared.scheduleReminder(reminder)
    }
    
    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            NotificationService.shared.cancelReminder(reminder)
            modelContext.delete(reminder)
        }
    }
    
    private func applyTemplate(_ template: ScheduleTemplate) {
        // Clear existing reminders
        for reminder in reminders {
            NotificationService.shared.cancelReminder(reminder)
            modelContext.delete(reminder)
        }
        
        // Add template reminders
        for reminder in template.createReminders() {
            modelContext.insert(reminder)
            NotificationService.shared.scheduleReminder(reminder)
        }
    }
    
    private func colorFor(_ type: ActivityType) -> Color {
        switch type {
        case .feeding: return AppColors.feedingAccent
        case .diaper: return AppColors.diaperAccent
        case .sleep: return AppColors.sleepAccent
        case .weight: return AppColors.weightAccent
        case .pumping: return AppColors.pumpingAccent
        }
    }
}

// MARK: - Add Reminder Sheet

struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var activityType: ActivityType = .feeding
    @State private var time = Date()
    
    let onSave: (Reminder) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Reminder Title", text: $title)
                
                Picker("Activity Type", selection: $activityType) {
                    ForEach(ActivityType.allCases) { type in
                        Label(type.rawValue.capitalized, systemImage: type.icon)
                            .tag(type)
                    }
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                        let reminder = Reminder(
                            title: title.isEmpty ? "\(activityType.rawValue.capitalized) Time" : title,
                            activityType: activityType,
                            hour: components.hour ?? 8,
                            minute: components.minute ?? 0
                        )
                        onSave(reminder)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Reminder Sheet

struct EditReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var reminder: Reminder
    @State private var time: Date
    
    let onSave: () -> Void
    
    init(reminder: Reminder, onSave: @escaping () -> Void) {
        self.reminder = reminder
        self.onSave = onSave
        
        var components = DateComponents()
        components.hour = reminder.hour
        components.minute = reminder.minute
        _time = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Reminder Title", text: $reminder.title)
                
                Picker("Activity Type", selection: $reminder.activityType) {
                    ForEach(ActivityType.allCases) { type in
                        Label(type.rawValue.capitalized, systemImage: type.icon)
                            .tag(type)
                    }
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .onChange(of: time) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        reminder.hour = components.hour ?? 8
                        reminder.minute = components.minute ?? 0
                    }
                
                Toggle("Enabled", isOn: $reminder.isEnabled)
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Template Picker Sheet

struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (ScheduleTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                templateRow(ScheduleTemplate.momsOnCall)
            }
            .navigationTitle("Schedule Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func templateRow(_ template: ScheduleTemplate) -> some View {
        Button {
            onSelect(template)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(template.name)
                        .font(AppFonts.titleLarge())
                        .foregroundColor(AppColors.textDark)
                    
                    Spacer()
                    
                    Text("\(template.reminders.count) reminders")
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.textSoft)
                }
                
                Text(template.description)
                    .font(AppFonts.bodySmall())
                    .foregroundColor(AppColors.textSoft)
                
                // Preview times
                Text(template.reminders.prefix(3).map { 
                    String(format: "%d:%02d", $0.hour, $0.minute) 
                }.joined(separator: " • ") + "...")
                    .font(AppFonts.labelLarge())
                    .foregroundColor(AppColors.primary)
            }
            .padding(.vertical, Spacing.xs)
        }
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: Reminder.self, inMemory: true)
}
