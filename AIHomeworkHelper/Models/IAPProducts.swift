import StoreKit
import Foundation

// In-app purchase products for additional monetization
struct IAPProducts {
    // One-time purchases
    static let removeAds = "com.aihomeworkhelper.removeads"
    static let expertBoost = "com.aihomeworkhelper.expertboost"  // Priority human tutor access
    static let unlimitedHistory = "com.aihomeworkhelper.unlimitedhistory"
    static let advancedInsights = "com.aihomeworkhelper.advancedinsights"
    
    // Consumables
    static let extraSolves5 = "com.aihomeworkhelper.extrasolves5"  // 5 extra solves
    static let extraSolves20 = "com.aihomeworkhelper.extrasolves20"  // 20 extra solves
    static let extraSolves50 = "com.aihomeworkhelper.extrasolves50"  // 50 extra solves
    
    // Themes and customization
    static let darkTheme = "com.aihomeworkhelper.darktheme"
    static let oceanTheme = "com.aihomeworkhelper.oceantheme"
    static let galaxyTheme = "com.aihomeworkhelper.galaxytheme"
    static let customAvatar = "com.aihomeworkhelper.customavatar"
    
    // Study tools
    static let flashcardCreator = "com.aihomeworkhelper.flashcards"
    static let practiceTestGenerator = "com.aihomeworkhelper.practicetests"
    static let studyPlanner = "com.aihomeworkhelper.studyplanner"
    
    // All product IDs for loading
    static let allProductIDs: Set<String> = [
        removeAds,
        expertBoost,
        unlimitedHistory,
        advancedInsights,
        extraSolves5,
        extraSolves20,
        extraSolves50,
        darkTheme,
        oceanTheme,
        galaxyTheme,
        customAvatar,
        flashcardCreator,
        practiceTestGenerator,
        studyPlanner
    ]
}

// Product details for display
struct IAPProductInfo {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: ProductCategory
    let defaultPrice: String  // Fallback price
    
    enum ProductCategory {
        case boost
        case consumable
        case theme
        case tool
        
        var displayName: String {
            switch self {
            case .boost: return "Power-Ups"
            case .consumable: return "Extra Solves"
            case .theme: return "Themes & Style"
            case .tool: return "Study Tools"
            }
        }
        
        var color: Color {
            switch self {
            case .boost: return .purple
            case .consumable: return .blue
            case .theme: return .pink
            case .tool: return .green
            }
        }
    }
    
    static let allProducts: [IAPProductInfo] = [
        // Boosts
        IAPProductInfo(
            id: IAPProducts.removeAds,
            name: "Remove Ads",
            description: "Enjoy an ad-free experience forever",
            icon: "minus.circle.fill",
            category: .boost,
            defaultPrice: "$2.99"
        ),
        IAPProductInfo(
            id: IAPProducts.expertBoost,
            name: "Expert Boost",
            description: "Priority access to human tutors",
            icon: "person.2.fill",
            category: .boost,
            defaultPrice: "$9.99"
        ),
        IAPProductInfo(
            id: IAPProducts.unlimitedHistory,
            name: "Unlimited History",
            description: "Access all past solutions forever",
            icon: "clock.arrow.circlepath",
            category: .boost,
            defaultPrice: "$4.99"
        ),
        IAPProductInfo(
            id: IAPProducts.advancedInsights,
            name: "Advanced Insights",
            description: "Detailed learning analytics & reports",
            icon: "chart.xyaxis.line",
            category: .boost,
            defaultPrice: "$6.99"
        ),
        
        // Consumables
        IAPProductInfo(
            id: IAPProducts.extraSolves5,
            name: "5 Extra Solves",
            description: "Get 5 additional problem solves",
            icon: "5.circle.fill",
            category: .consumable,
            defaultPrice: "$0.99"
        ),
        IAPProductInfo(
            id: IAPProducts.extraSolves20,
            name: "20 Extra Solves",
            description: "Get 20 additional problem solves",
            icon: "20.circle.fill",
            category: .consumable,
            defaultPrice: "$2.99"
        ),
        IAPProductInfo(
            id: IAPProducts.extraSolves50,
            name: "50 Extra Solves",
            description: "Get 50 additional problem solves",
            icon: "50.circle.fill",
            category: .consumable,
            defaultPrice: "$5.99"
        ),
        
        // Themes
        IAPProductInfo(
            id: IAPProducts.darkTheme,
            name: "Dark Theme",
            description: "Easy on the eyes for night studying",
            icon: "moon.fill",
            category: .theme,
            defaultPrice: "$1.99"
        ),
        IAPProductInfo(
            id: IAPProducts.oceanTheme,
            name: "Ocean Theme",
            description: "Calming blue waves design",
            icon: "water.waves",
            category: .theme,
            defaultPrice: "$1.99"
        ),
        IAPProductInfo(
            id: IAPProducts.galaxyTheme,
            name: "Galaxy Theme",
            description: "Study among the stars",
            icon: "sparkles",
            category: .theme,
            defaultPrice: "$1.99"
        ),
        IAPProductInfo(
            id: IAPProducts.customAvatar,
            name: "Custom Avatar",
            description: "Create your unique study buddy",
            icon: "person.crop.circle.badge.plus",
            category: .theme,
            defaultPrice: "$3.99"
        ),
        
        // Study Tools
        IAPProductInfo(
            id: IAPProducts.flashcardCreator,
            name: "Flashcard Creator",
            description: "Turn solutions into study cards",
            icon: "rectangle.stack.fill",
            category: .tool,
            defaultPrice: "$4.99"
        ),
        IAPProductInfo(
            id: IAPProducts.practiceTestGenerator,
            name: "Practice Tests",
            description: "Generate custom practice exams",
            icon: "doc.text.magnifyingglass",
            category: .tool,
            defaultPrice: "$7.99"
        ),
        IAPProductInfo(
            id: IAPProducts.studyPlanner,
            name: "Study Planner",
            description: "AI-powered study schedule creator",
            icon: "calendar.badge.clock",
            category: .tool,
            defaultPrice: "$5.99"
        )
    ]
}

import SwiftUI