import SwiftUI

/// Onboarding screen with 4 swipeable slides
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
                    icon: "scalemass.fill",
                    iconColor: AppColors.primary,
                    title: "Every Ounce Matters",
                    description: "Is she eating enough? Is he gaining weight?\n\nIn the first weeks, peace of mind comes from knowing—not guessing."
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "mic.fill",
                    iconColor: AppColors.sage,
                    title: "Just Speak",
                    description: "\"Fed 4oz bottle\"\n\"Wet diaper\"\n\"She weighs 8 pounds 2 ounces\"\n\nHands full at 3am? Just tap and talk."
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "heart.text.square.fill",
                    iconColor: AppColors.lavender,
                    title: "Ready for the Pediatrician",
                    description: "How many wet diapers? How much did she eat?\n\nWalk into every visit with the answers they need."
                )
                .tag(2)
                
                OnboardingPage(
                    icon: "person.2.fill",
                    iconColor: AppColors.feedingAccent,
                    title: "Private & Secure",
                    description: "Your data stays on your phone—always private.\n\nOptionally sync with your partner so everyone stays on the same page."
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentPage == index ? AppColors.primary : AppColors.primary.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(Spacing.lg)
            
            // Next button
            Button {
                if currentPage < 3 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage == 3 ? "Get Started" : "Next")
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
