import SwiftUI
import SwiftData

/// History screen - All entries grouped by day with filtering
struct HistoryView: View {
    @ObservedObject var repository: ActivityRepository
    @State private var selectedFilter: ActivityType?
    @State private var groupedActivities: [(String, [Activity])] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterChips
                
                // Activity list
                if groupedActivities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .background(AppColors.background)
            .navigationTitle("History")
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                FilterChip(
                    label: "All",
                    isSelected: selectedFilter == nil,
                    color: AppColors.primary
                ) {
                    selectedFilter = nil
                    loadData()
                }
                
                ForEach(ActivityType.allCases) { type in
                    FilterChip(
                        label: type.rawValue.capitalized,
                        isSelected: selectedFilter == type,
                        color: colorFor(type)
                    ) {
                        selectedFilter = type
                        loadData()
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.sm)
        }
    }
    
    // MARK: - Activity List
    
    private var activityList: some View {
        List {
            ForEach(groupedActivities, id: \.0) { date, activities in
                Section {
                    ForEach(activities) { activity in
                        ActivityRow(activity: activity) {
                            repository.deleteActivity(activity)
                            loadData()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                } header: {
                    Text(date)
                        .font(AppFonts.titleLarge())
                        .foregroundColor(AppColors.textSoft)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .padding(.horizontal, Spacing.screenPadding)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textLight)
            
            Text("No activity yet")
                .font(AppFonts.headlineSmall())
                .foregroundColor(AppColors.textLight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func loadData() {
        let activities = repository.getAllActivities(filter: selectedFilter)
        groupedActivities = groupByDate(activities)
    }
    
    private func groupByDate(_ activities: [Activity]) -> [(String, [Activity])] {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        
        var grouped: [String: [Activity]] = [:]
        
        for activity in activities {
            let key: String
            if calendar.isDate(activity.timestamp, inSameDayAs: now) {
                key = "Today"
            } else if calendar.isDate(activity.timestamp, inSameDayAs: yesterday) {
                key = "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                key = formatter.string(from: activity.timestamp)
            }
            grouped[key, default: []].append(activity)
        }
        
        // Sort by date (Today first, then Yesterday, then chronologically)
        let sortOrder = ["Today", "Yesterday"]
        return grouped.sorted { a, b in
            let aIndex = sortOrder.firstIndex(of: a.key) ?? Int.max
            let bIndex = sortOrder.firstIndex(of: b.key) ?? Int.max
            if aIndex != bIndex { return aIndex < bIndex }
            return (a.value.first?.timestamp ?? .distantPast) > (b.value.first?.timestamp ?? .distantPast)
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

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.labelLarge())
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

#Preview {
    HistoryView(repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self, Diaper.self, Sleep.self, Weight.self).mainContext))
}
