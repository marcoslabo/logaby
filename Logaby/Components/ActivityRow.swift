import SwiftUI

/// Activity list row with icon, text, and timestamp
struct ActivityRow: View {
    let activity: Activity
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: activity.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                )
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayText)
                    .font(AppFonts.titleLarge())
                    .foregroundColor(AppColors.textDark)
                
                // Show detail text with time/duration
                Text(activity.detailText)
                    .font(AppFonts.bodySmall())
                    .foregroundColor(AppColors.textSoft)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var accentColor: Color {
        switch activity.type {
        case .feeding: return AppColors.feedingAccent
        case .diaper: return AppColors.diaperAccent
        case .sleep: return AppColors.sleepAccent
        case .weight: return AppColors.weightAccent
        case .pumping: return AppColors.pumpingAccent
        }
    }
}

#Preview {
    VStack {
        ActivityRow(
            activity: Activity(type: .feeding, id: UUID(), timestamp: Date(), displayText: "4oz bottle", detailText: "at 8:30 PM", endTime: nil),
            onDelete: {}
        )
        ActivityRow(
            activity: Activity(type: .sleep, id: UUID(), timestamp: Date(), displayText: "Slept 2h", detailText: "2:00 PM - 4:00 PM", endTime: Date()),
            onDelete: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
