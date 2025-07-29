import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case `default` = "Default"
    case cosmic = "Cosmic"
    case nature = "Nature"
    case neon = "Neon"
    
    var name: String { rawValue }
    
    var primaryColor: Color {
        switch self {
        case .default: return .blue
        case .cosmic: return .purple
        case .nature: return .green
        case .neon: return .pink
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .default: return .purple
        case .cosmic: return .indigo
        case .nature: return .brown
        case .neon: return .orange
        }
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}