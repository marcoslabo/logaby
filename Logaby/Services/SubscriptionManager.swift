import Foundation
import StoreKit

/// Manages in-app purchases using StoreKit 2
/// Handles the "First Months Pass" subscription ($19.99 for 6 months)
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Product IDs
    
    /// Product ID for "First Months Pass" - 6 months of full access
    static let firstMonthsPassID = "com.logaby.app.firstmonthspass"
    
    // MARK: - Published State
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    /// True if user has active subscription
    var hasActiveSubscription: Bool {
        purchasedProductIDs.contains(Self.firstMonthsPassID)
    }
    
    /// True if user is in trial period
    @Published private(set) var isInTrialPeriod = false
    
    // MARK: - Trial Management
    
    private let trialStartKey = "logaby_trial_start_date"
    private let trialDurationDays = 7
    
    /// Check if user is within free trial period
    var isTrialActive: Bool {
        guard let startDate = UserDefaults.standard.object(forKey: trialStartKey) as? Date else {
            // First launch - start trial
            startTrial()
            return true
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart < trialDurationDays
    }
    
    /// Days remaining in trial
    var trialDaysRemaining: Int {
        guard let startDate = UserDefaults.standard.object(forKey: trialStartKey) as? Date else {
            return trialDurationDays
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, trialDurationDays - daysSinceStart)
    }
    
    /// Start the free trial
    private func startTrial() {
        if UserDefaults.standard.object(forKey: trialStartKey) == nil {
            UserDefaults.standard.set(Date(), forKey: trialStartKey)
        }
    }
    
    // MARK: - Access Control
    
    /// True if user can access premium features (trial active OR subscription active)
    var canAccessPremiumFeatures: Bool {
        return isTrialActive || hasActiveSubscription
    }
    
    // MARK: - Private
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and check entitlements on init
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: [Self.firstMonthsPassID])
            products = storeProducts
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Check Entitlements
    
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is a non-consumable or active subscription
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        purchasedProductIDs = purchased
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let signedType):
            return signedType
        }
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        }
    }
}
