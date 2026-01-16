import SwiftUI

/// Reusable stat card for the dashboard grid
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(AppFonts.labelLarge())
                    .foregroundColor(AppColors.textSoft)
            }
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textDark)
                
                Text(subtitle)
                    .font(AppFonts.bodyMedium())
                    .foregroundColor(AppColors.textSoft)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
    }
}

#Preview {
    StatCard(
        title: "Feedings",
        value: "12",
        subtitle: "oz",
        accentColor: AppColors.feedingAccent,
        icon: "drop.fill"
    )
    .frame(width: 160, height: 100)
    .padding()
    .background(AppColors.background)
}
