import SwiftUI
import StoreKit

/// Paywall view shown when trial expires or user wants to subscribe
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header with Logo
                    VStack(spacing: Spacing.md) {
                        // Logo - baby face icon
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Text("👶")
                                .font(.system(size: 50))
                        }
                        
                        Text("First Months Pass")
                            .font(AppFonts.headlineLarge())
                            .foregroundColor(AppColors.textDark)
                        
                        Text("6 months of peace of mind")
                            .font(AppFonts.bodyLarge())
                            .foregroundColor(AppColors.textSoft)
                    }
                    .padding(.top, Spacing.lg)
                    
                    // Problem we're solving
                    VStack(spacing: Spacing.sm) {
                        Text("Is she eating enough?\nIs he actually gaining weight?")
                            .font(AppFonts.titleLarge())
                            .foregroundColor(AppColors.textDark)
                            .multilineTextAlignment(.center)
                        
                        Text("Stop guessing. Start knowing.")
                            .font(AppFonts.bodyMedium())
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.semibold)
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primary.opacity(0.08))
                    .cornerRadius(16)
                    
                    // What you get
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Everything you need:")
                            .font(AppFonts.labelLarge())
                            .foregroundColor(AppColors.textSoft)
                        
                        FeatureRow(icon: "mic.fill", text: "Voice logging — just tap & speak")
                        FeatureRow(icon: "scalemass.fill", text: "Track feedings, diapers, sleep & weight")
                        FeatureRow(icon: "doc.text.fill", text: "Reports for your pediatrician")
                        FeatureRow(icon: "person.2.fill", text: "Sync with your partner")
                        FeatureRow(icon: "bell.fill", text: "Feeding reminders")
                    }
                    .padding(Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(20)
                    
                    // No account needed callout
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(AppColors.sage)
                        Text("No account needed — data stays on your phone")
                            .font(AppFonts.bodySmall())
                            .foregroundColor(AppColors.textSoft)
                    }
                    .padding(Spacing.md)
                    .background(AppColors.sage.opacity(0.15))
                    .cornerRadius(12)
                    
                    // Price
                    VStack(spacing: Spacing.sm) {
                        Text("$19.99")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        
                        Text("One payment. 6 months of access.")
                            .font(AppFonts.bodyLarge())
                            .foregroundColor(AppColors.textSoft)
                        
                        Text("Just $3.33/month")
                            .font(AppFonts.labelLarge())
                            .foregroundColor(AppColors.sage)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(AppColors.sage.opacity(0.2))
                            .cornerRadius(20)
                        
                        // Purchase button
                        Button {
                            if let product = subscriptionManager.products.first {
                                Task {
                                    await purchase(product)
                                }
                            }
                        } label: {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            } else {
                                Text("Get the First Months Pass")
                                    .font(AppFonts.titleLarge())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            }
                        }
                        .background(AppColors.primary)
                        .cornerRadius(16)
                        .disabled(isPurchasing || subscriptionManager.products.isEmpty)
                        .padding(.top, Spacing.md)
                        
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .padding(.top, Spacing.sm)
                        }
                    }
                    
                    // Restore purchases
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(AppFonts.bodyMedium())
                            .foregroundColor(AppColors.primary)
                    }
                    
                    // Legal
                    VStack(spacing: Spacing.xs) {
                        Text("One-time purchase for 6 months of access. Does not auto-renew.")
                            .font(AppFonts.bodySmall())
                            .foregroundColor(AppColors.textLight)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: Spacing.md) {
                            Link("Privacy Policy", destination: URL(string: "https://logaby.com/privacy.html")!)
                            Text("·")
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        }
                        .font(AppFonts.bodySmall())
                        .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xl)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSoft)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func purchase(_ product: Product) async {
        isPurchasing = true
        
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isPurchasing = false
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(AppFonts.bodyMedium())
                .foregroundColor(AppColors.textDark)
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
