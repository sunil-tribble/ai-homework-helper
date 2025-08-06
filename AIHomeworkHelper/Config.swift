import Foundation

struct Config {
    // Backend API URL - Update this with your deployed backend URL
    static let backendURL: String = {
        // For development, use localhost
        #if DEBUG
        return "http://localhost:3000"
        #else
        // For production, use your deployed backend URL
        // Digital Ocean Deployment: https://159.203.129.37
        return "https://159.203.129.37"
        #endif
    }()
    
    // App configuration
    static let freeDailySolves = 5
    static let maxImageSize: CGFloat = 1024
    static let compressionQuality: CGFloat = 0.8
    
    // In-App Purchase Product IDs
    struct Products {
        static let weeklySubscription = "com.aihelper.homework.weekly"
        static let monthlySubscription = "com.aihelper.homework.monthly"
        static let lifetimeUnlock = "com.aihelper.homework.lifetime"
    }
    
    // API Configuration
    struct API {
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetries = 3
    }
}

// Environment-based configuration
extension Config {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var shouldShowDebugInfo: Bool {
        return isDebug
    }
}