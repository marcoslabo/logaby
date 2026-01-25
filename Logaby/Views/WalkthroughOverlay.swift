import SwiftUI

/// Sequential tooltip walkthrough for first-time users
/// Shows on first launch (after tutorial) and when help button is pressed
struct WalkthroughOverlay: View {
    @Binding var isShowing: Bool
    @State private var currentStep = 0
    
    private let steps: [WalkthroughStep] = [
        WalkthroughStep(
            title: "Voice Logging",
            description: "This is where it all starts! Tap the mic button to speak and log anything.",
            alignment: .bottom,  // Position near bottom, pointing at mic button
            arrowDirection: .down
        ),
        WalkthroughStep(
            title: "Daily Summary",
            description: "See today's totals at a glance - feeding, sleep, diapers, weight.",
            alignment: .top,  // Position near top, pointing at stats
            arrowDirection: .up
        ),
        WalkthroughStep(
            title: "History",
            description: "View all your logged activities. Swipe left to delete.",
            alignment: .bottom,  // Position near bottom, pointing at tab bar
            arrowDirection: .down
        ),
        WalkthroughStep(
            title: "Reports",
            description: "Generate summaries for doctor visits.",
            alignment: .bottom,  // Position near bottom, pointing at tab bar
            arrowDirection: .down
        ),
        WalkthroughStep(
            title: "Settings",
            description: "Set up Siri, reminders, and family sharing.",
            alignment: .bottom,  // Position near bottom, pointing at tab bar
            arrowDirection: .down
        )
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    advanceStep()
                }
            
            // Tooltip positioned based on alignment
            VStack(spacing: 0) {
                if steps[currentStep].alignment == .bottom {
                    Spacer()
                }
                
                tooltipCard
                
                if steps[currentStep].alignment == .top {
                    Spacer()
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    private var tooltipCard: some View {
        VStack(spacing: 0) {
            // Arrow pointing UP (above the card)
            if steps[currentStep].arrowDirection == .up {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.cardBackground)
                    .offset(y: 4)
            }
            
            // Card content
            VStack(spacing: Spacing.sm) {
                HStack {
                    Text(steps[currentStep].title)
                        .font(AppFonts.titleLarge())
                        .foregroundColor(AppColors.textDark)
                    
                    Spacer()
                    
                    Text("\(currentStep + 1)/\(steps.count)")
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.textLight)
                }
                
                Text(steps[currentStep].description)
                    .font(AppFonts.bodyMedium())
                    .foregroundColor(AppColors.textSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .font(AppFonts.bodyMedium())
                        .foregroundColor(AppColors.textSoft)
                    }
                    
                    Spacer()
                    
                    Button(currentStep < steps.count - 1 ? "Next" : "Done") {
                        advanceStep()
                    }
                    .font(AppFonts.labelLarge())
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .padding(.top, Spacing.xs)
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            
            // Arrow pointing DOWN (below the card)
            if steps[currentStep].arrowDirection == .down {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.cardBackground)
                    .offset(y: -4)
            }
        }
    }
    
    private var topPadding: CGFloat {
        switch currentStep {
        case 1: return 250  // Daily Summary - push down from top to be below stats
        default: return 20
        }
    }
    
    private var bottomPadding: CGFloat {
        switch currentStep {
        case 0: return 180  // Voice Logging - above mic button
        case 2, 3, 4: return 120  // Tab bar items - above tab bar
        default: return 20
        }
    }
    
    private func advanceStep() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            isShowing = false
        }
    }
}

// MARK: - Walkthrough Step Model

struct WalkthroughStep {
    let title: String
    let description: String
    let alignment: TooltipAlignment
    let arrowDirection: ArrowDirection
    
    enum TooltipAlignment {
        case top
        case bottom
    }
    
    enum ArrowDirection {
        case up
        case down
    }
}

#Preview {
    WalkthroughOverlay(isShowing: .constant(true))
}
