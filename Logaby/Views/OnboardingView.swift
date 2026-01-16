import SwiftUI

/// Onboarding screen with 3 swipeable slides
struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    onComplete()
                }
                .font(AppFonts.bodyLarge())
                .foregroundColor(AppColors.textSoft)
                .padding(Spacing.md)
            }
            
            // Pages
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "mic.fill",
                    iconColor: AppColors.primary,
                    title: "Voice-First Logging",
                    description: "Track feedings, diapers, and sleep with your voice. Perfect for those 3am moments."
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "waveform",
                    iconColor: AppColors.sage,
                    title: "Hands-Free with Siri",
                    description: "\"Hey Siri, tell Logaby 4oz bottle\"\n\nLog without unlocking your phone."
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: AppColors.lavender,
                    title: "Track Everything",
                    description: "See daily summaries, browse history, and never miss a detail about your little one."
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentPage == index ? AppColors.primary : AppColors.primary.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(Spacing.lg)
            
            // Next button
            Button {
                if currentPage < 2 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage == 2 ? "Get Started" : "Next")
                    .font(AppFonts.titleLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primary)
                    .cornerRadius(16)
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xl)
        }
        .background(AppColors.background)
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon container
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 56))
                        .foregroundColor(iconColor)
                )
            
            // Title
            Text(title)
                .font(AppFonts.headlineLarge())
                .foregroundColor(AppColors.textDark)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(AppFonts.bodyLarge())
                .foregroundColor(AppColors.textSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
