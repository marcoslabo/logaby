import SwiftUI

/// Floating action button for voice input
struct MicButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 64, height: 64)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    MicButton(action: {})
        .padding()
        .background(AppColors.background)
}
