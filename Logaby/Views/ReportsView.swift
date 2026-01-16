import SwiftUI
import SwiftData

/// Reports view showing summaries for healthcare professionals
struct ReportsView: View {
    @ObservedObject var repository: ActivityRepository
    
    @State private var selectedRange: DateRange = .week
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var customEndDate = Date()
    @State private var report: ReportSummary?
    @State private var showExportSheet = false
    @State private var showCustomDatePicker = false
    
    enum DateRange: String, CaseIterable {
        case week = "Week"
        case twoWeeks = "2 Weeks"
        case month = "Month"
        case custom = "Custom"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Date range picker
                    dateRangePicker
                    
                    // Custom date picker section
                    if selectedRange == .custom {
                        customDateSection
                    }
                    
                    // Date range display
                    if let report = report {
                        Text(dateRangeText(report))
                            .font(AppFonts.bodyMedium())
                            .foregroundColor(AppColors.textSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let report = report {
                        // Feeding summary
                        reportCard(
                            title: "Feeding",
                            icon: "drop.fill",
                            color: AppColors.feedingAccent,
                            stats: [
                                ("Total", "\(String(format: "%.1f", report.totalFeedingOz)) oz"),
                                ("Count", "\(report.feedingCount)"),
                                ("Avg/Day", "\(String(format: "%.1f", report.avgFeedingOzPerDay)) oz")
                            ]
                        )
                        
                        // Sleep summary
                        reportCard(
                            title: "Sleep",
                            icon: "moon.fill",
                            color: AppColors.sleepAccent,
                            stats: [
                                ("Total", "\(String(format: "%.1f", report.totalSleepHours)) hrs"),
                                ("Count", "\(report.sleepCount)"),
                                ("Avg/Day", "\(String(format: "%.1f", report.avgSleepHoursPerDay)) hrs")
                            ]
                        )
                        
                        // Diaper summary
                        reportCard(
                            title: "Diapers",
                            icon: "sparkles",
                            color: AppColors.diaperAccent,
                            stats: [
                                ("Total", "\(report.diaperCount)"),
                                ("Wet", "\(report.wetDiaperCount)"),
                                ("Dirty", "\(report.dirtyDiaperCount)")
                            ]
                        )
                        
                        // Weight summary
                        if let startWeight = report.startWeight, let endWeight = report.endWeight {
                            reportCard(
                                title: "Weight",
                                icon: "scalemass.fill",
                                color: AppColors.weightAccent,
                                stats: [
                                    ("Start", "\(String(format: "%.1f", startWeight)) lbs"),
                                    ("End", "\(String(format: "%.1f", endWeight)) lbs"),
                                    ("Change", formatWeightChange(report.weightChange))
                                ]
                            )
                        }
                        
                        // Export button
                        Button {
                            showExportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export for Healthcare Provider")
                            }
                            .font(AppFonts.titleLarge())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.primary)
                            .cornerRadius(16)
                        }
                        .padding(.top, Spacing.md)
                    }
                }
                .padding(Spacing.screenPadding)
            }
            .background(AppColors.background)
            .navigationTitle("Reports")
        }
        .onAppear {
            generateReport()
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(report: report, repository: repository)
        }
    }
    
    // MARK: - Date Range Picker
    
    private var dateRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach([DateRange.week, DateRange.twoWeeks, DateRange.month, DateRange.custom], id: \.self) { range in
                    Button {
                        selectedRange = range
                        generateReport()
                    } label: {
                        Text(range.rawValue)
                            .font(AppFonts.labelLarge())
                            .foregroundColor(selectedRange == range ? .white : AppColors.primary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedRange == range ? AppColors.primary : AppColors.primary.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Date Section
    
    private var customDateSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.textSoft)
                    DatePicker("", selection: $customStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.primary)
                        .onChange(of: customStartDate) { _, _ in
                            generateReport()
                        }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.textSoft)
                    DatePicker("", selection: $customEndDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.primary)
                        .onChange(of: customEndDate) { _, _ in
                            generateReport()
                        }
                }
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Report Card
    
    private func reportCard(title: String, icon: String, color: Color, stats: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(AppFonts.headlineSmall())
                    .foregroundColor(AppColors.textDark)
            }
            
            HStack {
                ForEach(stats, id: \.0) { label, value in
                    VStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textDark)
                        Text(label)
                            .font(AppFonts.bodySmall())
                            .foregroundColor(AppColors.textSoft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    
    private func dateRangeText(_ report: ReportSummary) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: report.startDate)) → \(formatter.string(from: report.endDate))"
    }
    
    private func formatWeightChange(_ change: Double?) -> String {
        guard let change = change else { return "—" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change)) lbs"
    }
    
    private func generateReport() {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        let endDate: Date
        
        switch selectedRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            endDate = now
        case .twoWeeks:
            startDate = calendar.date(byAdding: .day, value: -14, to: now)!
            endDate = now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            endDate = now
        case .custom:
            startDate = customStartDate
            endDate = customEndDate
        }
        
        report = repository.generateReport(from: startDate, to: endDate)
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    let report: ReportSummary?
    let repository: ActivityRepository
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Baby Care Report")
                        .font(AppFonts.headlineLarge())
                    
                    if let report = report {
                        Text(dateRangeText(report))
                            .font(AppFonts.bodyLarge())
                            .foregroundColor(AppColors.textSoft)
                        
                        Divider()
                        
                        // Feeding section
                        sectionHeader("Feeding Summary")
                        bulletPoint("Total intake: \(String(format: "%.1f", report.totalFeedingOz)) oz")
                        bulletPoint("Number of feedings: \(report.feedingCount)")
                        bulletPoint("Average per day: \(String(format: "%.1f", report.avgFeedingOzPerDay)) oz")
                        
                        // Sleep section
                        sectionHeader("Sleep Summary")
                        bulletPoint("Total sleep: \(String(format: "%.1f", report.totalSleepHours)) hours")
                        bulletPoint("Number of naps: \(report.sleepCount)")
                        bulletPoint("Average per day: \(String(format: "%.1f", report.avgSleepHoursPerDay)) hours")
                        
                        // Diaper section
                        sectionHeader("Diaper Summary")
                        bulletPoint("Total changes: \(report.diaperCount)")
                        bulletPoint("Wet diapers: \(report.wetDiaperCount)")
                        bulletPoint("Dirty diapers: \(report.dirtyDiaperCount)")
                        
                        // Weight section
                        if let start = report.startWeight, let end = report.endWeight {
                            sectionHeader("Weight Progress")
                            bulletPoint("Starting weight: \(String(format: "%.1f", start)) lbs")
                            bulletPoint("Ending weight: \(String(format: "%.1f", end)) lbs")
                            if let change = report.weightChange {
                                bulletPoint("Change: \(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) lbs")
                            }
                        }
                    }
                }
                .padding(Spacing.screenPadding)
            }
            .background(AppColors.background)
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: generateReportText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func dateRangeText(_ report: ReportSummary) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: report.startDate)) - \(formatter.string(from: report.endDate))"
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.headlineSmall())
            .foregroundColor(AppColors.textDark)
            .padding(.top, Spacing.md)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("•")
            Text(text)
        }
        .font(AppFonts.bodyLarge())
        .foregroundColor(AppColors.textDark)
    }
    
    private func generateReportText() -> String {
        guard let report = report else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var text = """
        BABY CARE REPORT
        \(formatter.string(from: report.startDate)) - \(formatter.string(from: report.endDate))
        
        FEEDING SUMMARY
        • Total intake: \(String(format: "%.1f", report.totalFeedingOz)) oz
        • Number of feedings: \(report.feedingCount)
        • Average per day: \(String(format: "%.1f", report.avgFeedingOzPerDay)) oz
        
        SLEEP SUMMARY
        • Total sleep: \(String(format: "%.1f", report.totalSleepHours)) hours
        • Number of naps: \(report.sleepCount)
        • Average per day: \(String(format: "%.1f", report.avgSleepHoursPerDay)) hours
        
        DIAPER SUMMARY
        • Total changes: \(report.diaperCount)
        • Wet diapers: \(report.wetDiaperCount)
        • Dirty diapers: \(report.dirtyDiaperCount)
        """
        
        if let start = report.startWeight, let end = report.endWeight {
            text += """
            
            WEIGHT PROGRESS
            • Starting weight: \(String(format: "%.1f", start)) lbs
            • Ending weight: \(String(format: "%.1f", end)) lbs
            """
            if let change = report.weightChange {
                text += "\n• Change: \(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) lbs"
            }
        }
        
        text += "\n\nGenerated by Logaby"
        return text
    }
}

#Preview {
    ReportsView(repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self, Diaper.self, Sleep.self, Weight.self).mainContext))
}
