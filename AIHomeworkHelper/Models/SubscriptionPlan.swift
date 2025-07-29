import Foundation
import StoreKit

@available(iOS 17.0, *)
struct SubscriptionPlan: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: String
    let features: [String]
    let productType: Product.ProductType
    
    static let plans = [
        SubscriptionPlan(
            id: Config.Products.weeklySubscription,
            name: "Weekly Pass",
            description: "Unlimited solves for 7 days",
            price: "$4.99",
            features: [
                "Unlimited homework solves",
                "Step-by-step explanations",
                "Save & export solutions",
                "Priority support"
            ],
            productType: .autoRenewable
        ),
        SubscriptionPlan(
            id: Config.Products.monthlySubscription,
            name: "Monthly Pro",
            description: "Best value for regular students",
            price: "$9.99",
            features: [
                "Everything in Weekly Pass",
                "Advanced problem detection",
                "Multiple solution methods",
                "Study guides & tips"
            ],
            productType: .autoRenewable
        ),
        SubscriptionPlan(
            id: Config.Products.lifetimeUnlock,
            name: "Lifetime Access",
            description: "One-time purchase, forever access",
            price: "$49.99",
            features: [
                "All Pro features forever",
                "Future updates included",
                "Premium customer support",
                "Early access to new features"
            ],
            productType: .nonConsumable
        )
    ]
}