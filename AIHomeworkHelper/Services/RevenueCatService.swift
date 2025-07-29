import Foundation
import StoreKit

// Simplified RevenueCat-like service for subscriptions
// In production, use the actual RevenueCat SDK

class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()
    
    @Published var isPremium = false
    @Published var offerings: [Offering] = []
    @Published var purchaseInProgress = false
    
    private let userDefaults = UserDefaults.standard
    private let premiumKey = "isPremiumUser"
    
    init() {
        // Load saved premium status
        isPremium = userDefaults.bool(forKey: premiumKey)
        
        // Configure offerings
        setupOfferings()
        
        // Listen for transaction updates
        Task {
            await listenForTransactions()
        }
    }
    
    private func setupOfferings() {
        offerings = [
            Offering(
                identifier: "weekly",
                productId: Config.Products.weeklySubscription,
                price: "$1.99",
                priceValue: 1.99,
                title: "Weekly Pass",
                description: "Unlimited solves for 7 days",
                features: ["Unlimited homework help", "Priority support", "No ads"]
            ),
            Offering(
                identifier: "monthly",
                productId: Config.Products.monthlySubscription,
                price: "$4.99",
                priceValue: 4.99,
                title: "Monthly Pro",
                description: "Best value - Save 37%",
                features: ["Everything in Weekly", "Exclusive features", "Early access"],
                isMostPopular: true
            ),
            Offering(
                identifier: "lifetime",
                productId: Config.Products.lifetimeUnlock,
                price: "$49.99",
                priceValue: 49.99,
                title: "Lifetime Access",
                description: "One-time purchase, forever access",
                features: ["All features unlocked", "Future updates included", "Support development"]
            )
        ]
    }
    
    @MainActor
    func purchase(_ offering: Offering) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        // In production, use StoreKit 2 or RevenueCat SDK
        // For now, simulate a purchase
        
        // Find the product
        let products = try await Product.products(for: [offering.productId])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }
        
        // Purchase the product
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify and unlock premium
            switch verification {
            case .verified(let transaction):
                // Unlock premium features
                await unlockPremium()
                await transaction.finish()
            case .unverified:
                throw PurchaseError.verificationFailed
            }
            
        case .userCancelled:
            throw PurchaseError.cancelled
            
        case .pending:
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    @MainActor
    func restorePurchases() async throws {
        // Restore purchases
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == Config.Products.weeklySubscription ||
                   transaction.productID == Config.Products.monthlySubscription ||
                   transaction.productID == Config.Products.lifetimeUnlock {
                    await unlockPremium()
                }
            case .unverified:
                continue
            }
        }
    }
    
    private func unlockPremium() async {
        isPremium = true
        userDefaults.set(true, forKey: premiumKey)
        
        // Update user manager
        await MainActor.run {
            let userManager = UserManager()
            userManager.upgradeToPremium()
        }
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                if transaction.productID == Config.Products.weeklySubscription ||
                   transaction.productID == Config.Products.monthlySubscription ||
                   transaction.productID == Config.Products.lifetimeUnlock {
                    await unlockPremium()
                    await transaction.finish()
                }
            case .unverified:
                continue
            }
        }
    }
}

// MARK: - Models

struct Offering: Identifiable {
    let id = UUID()
    let identifier: String
    let productId: String
    let price: String
    let priceValue: Double
    let title: String
    let description: String
    let features: [String]
    var isMostPopular: Bool = false
}

enum PurchaseError: LocalizedError {
    case productNotFound
    case verificationFailed
    case cancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .verificationFailed:
            return "Purchase verification failed"
        case .cancelled:
            return "Purchase cancelled"
        case .pending:
            return "Purchase pending"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}