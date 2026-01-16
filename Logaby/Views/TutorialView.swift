import SwiftUI

/// First-time user tutorial with step-by-step walkthrough
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasSeenTutorial: Bool
    @State private var currentStep = 0
    
    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "mic.fill",
            iconColor: AppColors.primary,
            title: "Voice First",
            description: "Tap the mic button and speak naturally. Just say what happened!",
            examples: ["\"Fed 4oz bottle\"", "\"Wet diaper\"", "\"Baby fell asleep\""]
        ),
        TutorialStep(
            icon: "text.bubble.fill",
            iconColor: AppColors.feedingAccent,
            title: "Natural Language",
            description: "Talk like you normally would. We understand many phrases:",
            examples: ["\"Nursed 15 minutes left side\"", "\"Changed a poopy diaper\"", "\"Pumped 3oz\""]
        ),
        TutorialStep(
            icon: "list.bullet.clipboard.fill",
            iconColor: AppColors.sleepAccent,
            title: "Multiple Activities",
            description: "Log several things at once by saying \"and\" or \"also\":",
            examples: ["\"Fed 4oz and changed diaper\"", "\"Pumped 3oz, also baby napped 2 hours\""]
        ),
        TutorialStep(
            icon: "chart.bar.fill",
            iconColor: AppColors.diaperAccent,
            title: "Track Everything",
            description: "View your history, see daily summaries, and generate reports for doctor visits.",
            examples: nil
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    completeTutorial()
                }
                .font(AppFonts.bodyMedium())
                .foregroundColor(AppColors.textSoft)
                .padding()
            }
            
            Spacer()
            
            // Content
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    stepView(steps[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Spacer()
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? AppColors.primary : AppColors.divider)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, Spacing.lg)
            
            // Next/Done button
            Button {
                if currentStep < steps.count - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    completeTutorial()
                }
            } label: {
                Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
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
    
    private func stepView(_ step: TutorialStep) -> some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(step.iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: step.icon)
                    .font(.system(size: 48))
                    .foregroundColor(step.iconColor)
            }
            .padding(.bottom, Spacing.md)
            
            // Title
            Text(step.title)
                .font(AppFonts.headlineLarge())
                .foregroundColor(AppColors.textDark)
            
            // Description
            Text(step.description)
                .font(AppFonts.bodyLarge())
                .foregroundColor(AppColors.textSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
            
            // Examples
            if let examples = step.examples {
                VStack(spacing: Spacing.sm) {
                    ForEach(examples, id: \.self) { example in
                        Text(example)
                            .font(AppFonts.bodyMedium())
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
    
    private func completeTutorial() {
        hasSeenTutorial = true
        dismiss()
    }
}

// MARK: - Tutorial Step Model

struct TutorialStep {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let examples: [String]?
}

#Preview {
    TutorialView(hasSeenTutorial: .constant(false))
}
