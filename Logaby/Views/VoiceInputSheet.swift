import SwiftUI
import SwiftData

/// Voice input sheet with improved error handling and user guidance
struct VoiceInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @ObservedObject var repository: ActivityRepository
    
    @State private var confirmationMessage: String?
    @State private var hasError = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showExamples = false
    
    var onComplete: () -> Void
    
    // Example phrases for each category
    private let examplePhrases = [
        ("🍼", "Feeding", ["4oz bottle", "fed 150ml formula", "nursed 10 mins left"]),
        ("👶", "Diaper", ["wet diaper", "poopy diaper", "changed diaper"]),
        ("😴", "Sleep", ["baby asleep", "slept from 2pm to 4pm", "napped 2 hours"]),
        ("⚖️", "Weight", ["weighs 8 pounds", "9 lbs 4oz"]),
        ("🤱", "Pumping", ["pumped 4oz", "pumped 120ml"])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.divider)
                .frame(width: 40, height: 4)
                .padding(.top, Spacing.md)
            
            Spacer().frame(height: Spacing.md)
            
            // Title
            Text(titleText)
                .font(AppFonts.headlineMedium())
                .foregroundColor(AppColors.textDark)
            
            Spacer().frame(height: Spacing.md)
            
            // Tappable mic button (smaller)
            Button {
                handleMicTap()
            } label: {
                ZStack {
                    Circle()
                        .fill(micColor)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .shadow(color: micColor.opacity(0.3), radius: 16, x: 0, y: 4)
                    
                    Image(systemName: micIcon)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                startPulseAnimation()
            }
            
            Spacer().frame(height: Spacing.xs)
            
            // Action button text
            Text(actionText)
                .font(AppFonts.bodySmall())
                .foregroundColor(AppColors.textSoft)
            
            Spacer().frame(height: Spacing.md)
            
            // Always show transcript
            Text(transcriptDisplayText)
                .font(AppFonts.bodyLarge())
                .foregroundColor(hasError ? AppColors.error : AppColors.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .frame(minHeight: 30)
            
            Spacer().frame(height: Spacing.sm)
            
            // Examples view (below transcript)
            if showExamples {
                examplesView
            } else if let message = confirmationMessage, !hasError {
                Text(message)
                    .font(AppFonts.bodyMedium())
                    .foregroundColor(AppColors.success)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
            
            // Help button
            if !showExamples && confirmationMessage == nil {
                Button {
                    showExamples = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                        Text("What can I say?")
                    }
                    .font(AppFonts.bodySmall())
                    .foregroundColor(AppColors.primary)
                }
                .padding(.bottom, Spacing.md)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 420)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .task {
            await startListening()
        }
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }
    
    // MARK: - Examples View
    
    private var examplesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(examplePhrases, id: \.1) { emoji, category, phrases in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Text(emoji)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category)
                                .font(AppFonts.labelLarge())
                                .foregroundColor(AppColors.textDark)
                            Text(phrases.joined(separator: " • "))
                                .font(AppFonts.bodySmall())
                                .foregroundColor(AppColors.textSoft)
                        }
                    }
                }
                
                // Close examples button
                Button {
                    showExamples = false
                    if hasError {
                        retryRecording()
                    }
                } label: {
                    Text(hasError ? "Try Again" : "Got it!")
                        .font(AppFonts.titleLarge())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .frame(maxHeight: 180)
    }
    
    // MARK: - Computed Properties
    
    private var titleText: String {
        if showExamples {
            return "Example Phrases"
        }
        if confirmationMessage != nil {
            return hasError ? "Didn't catch that" : "Logged! ✓"
        }
        return speechRecognizer.isRecording ? "Listening..." : "Ready"
    }
    
    private var micColor: Color {
        if confirmationMessage != nil {
            return hasError ? AppColors.error : AppColors.success
        }
        return AppColors.primary
    }
    
    private var micIcon: String {
        if confirmationMessage != nil {
            return hasError ? "arrow.clockwise" : "checkmark"
        }
        return speechRecognizer.isRecording ? "mic.fill" : "mic"
    }
    
    private var actionText: String {
        if confirmationMessage != nil {
            return hasError ? "Tap to try again" : ""
        }
        return speechRecognizer.isRecording ? "Tap when done" : "Tap to start"
    }
    
    private var transcriptDisplayText: String {
        if speechRecognizer.transcript.isEmpty {
            return speechRecognizer.isRecording ? "Listening..." : ""
        }
        return speechRecognizer.transcript
    }
    
    // MARK: - Actions
    
    private func handleMicTap() {
        if hasError && confirmationMessage != nil {
            retryRecording()
        } else if speechRecognizer.isRecording {
            stopAndProcess()
        } else if !speechRecognizer.isRecording && confirmationMessage == nil {
            speechRecognizer.startRecording()
        }
    }
    
    private func startListening() async {
        let authorized = await speechRecognizer.requestAuthorization()
        guard authorized else {
            confirmationMessage = "Microphone access needed. Enable in Settings."
            hasError = true
            return
        }
        
        // Note: We don't use onFinalResult - we process when user taps the mic
        // This prevents duplicate logging
        
        speechRecognizer.startRecording()
    }
    
    private func retryRecording() {
        confirmationMessage = nil
        hasError = false
        showExamples = false
        speechRecognizer.startRecording()
    }
    
    private func stopAndProcess() {
        let transcript = speechRecognizer.transcript
        speechRecognizer.stopRecording()
        
        if !transcript.isEmpty {
            processInput(transcript)
        } else {
            showError("No speech detected")
        }
    }
    
    private func processInput(_ transcript: String) {
        guard !transcript.isEmpty else { return }
        
        // Use async Task to call AI parser
        Task {
            await processInputAsync(transcript)
        }
    }
    
    private func processInputAsync(_ transcript: String) async {
        // Always use AI parser (with local fallback built-in)
        let result = await VoiceParser.parseWithAI(transcript)
        
        await MainActor.run {
            switch result {
            case .feeding(let feeding):
                repository.addFeeding(feeding)
                showConfirmation("Logged \(feeding.displayText)")
                
            case .diaper(let diaper):
                repository.addDiaper(diaper)
                showConfirmation("Logged \(diaper.displayText.lowercased())")
                
            case .sleepStart(let sleep):
                repository.startSleep(sleep)
                showConfirmation("Started sleep timer 😴")
                
            case .sleepEnd:
                if let activeSleep = repository.getActiveSleep() {
                    repository.endSleep(id: activeSleep.id)
                    showConfirmation("Baby woke up! Slept \(activeSleep.durationMinutes) min")
                } else {
                    showError("No active sleep to end")
                }
                
            case .sleepCompleted(let sleep):
                repository.startSleep(sleep)
                showConfirmation("Logged \(sleep.displayText) 😴")
                
            case .weight(let weight):
                repository.addWeight(weight)
                showConfirmation("Logged \(weight.displayText)")
                
            case .pumping(let pumping):
                repository.addPumping(pumping)
                showConfirmation("Logged \(pumping.displayText) 🤱")
                
            case .error(_):
                // Show examples instead of raw error
                showError("Try one of the examples below")
                showExamples = true
            }
        }
    }
    
    /// Helper to save a parsed activity, returns true on success
    private func saveActivity(_ result: ParseResult) -> Bool {
        switch result {
        case .feeding(let feeding):
            repository.addFeeding(feeding)
            return true
        case .diaper(let diaper):
            repository.addDiaper(diaper)
            return true
        case .sleepStart(let sleep):
            repository.startSleep(sleep)
            return true
        case .sleepEnd:
            if let activeSleep = repository.getActiveSleep() {
                repository.endSleep(id: activeSleep.id)
                return true
            }
            return false
        case .sleepCompleted(let sleep):
            repository.startSleep(sleep)
            return true
        case .weight(let weight):
            repository.addWeight(weight)
            return true
        case .pumping(let pumping):
            repository.addPumping(pumping)
            return true
        case .error:
            return false
        }
    }
    
    private func showConfirmation(_ message: String) {
        confirmationMessage = message
        hasError = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete()
            dismiss()
        }
    }
    
    private func showError(_ message: String) {
        confirmationMessage = message
        hasError = true
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.08
        }
    }
}

#Preview {
    Color.black.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            VoiceInputSheet(
                repository: ActivityRepository(modelContext: try! ModelContainer(for: Feeding.self).mainContext),
                onComplete: {}
            )
            .presentationDetents([.height(480)])
            .presentationDragIndicator(.hidden)
        }
}
