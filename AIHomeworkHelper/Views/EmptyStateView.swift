import SwiftUI

/// Reusable empty state view with delightful animations
struct EmptyStateView: View {
    let type: EmptyStateType
    let action: (() -> Void)?
    
    @State private var animateIcon = false
    @State private var animateText = false
    @State private var floatingAnimation = false
    
    init(type: EmptyStateType, action: (() -> Void)? = nil) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated illustration
            ZStack {
                // Background shape
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [type.color.opacity(0.1), type.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(animateIcon ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateIcon)
                
                // Floating elements
                if type == .noHistory {
                    ForEach(0..<3) { index in
                        Image(systemName: "doc.text")
                            .font(.title3)
                            .foregroundColor(type.color.opacity(0.3))
                            .offset(
                                x: cos(CGFloat(index) * 2 * .pi / 3) * 60,
                                y: sin(CGFloat(index) * 2 * .pi / 3) * 60
                            )
                            .rotationEffect(.degrees(floatingAnimation ? 360 : 0))
                            .animation(
                                .linear(duration: 20)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: floatingAnimation
                            )
                    }
                }
                
                // Main icon
                Image(systemName: type.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [type.color, type.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: animateIcon)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateIcon)
            }
            .frame(height: 180)
            .floating(amplitude: 15)
            
            // Text content
            VStack(spacing: 12) {
                Text(type.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateText)
                
                Text(type.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animateText)
            }
            
            // Action button
            if let action = action {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    SoundManager.shared.play(.tap)
                    action()
                }) {
                    HStack {
                        Image(systemName: type.actionIcon)
                        Text(type.actionText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [type.color, type.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: type.color.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(animateText ? 1 : 0.8)
                .opacity(animateText ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.7), value: animateText)
                .pulse()
            }
        }
        .onAppear {
            animateIcon = true
            animateText = true
            floatingAnimation = true
        }
    }
}

enum EmptyStateType {
    case noHistory
    case noResults
    case noConnection
    case noBadges
    case noResources
    
    var icon: String {
        switch self {
        case .noHistory:
            return "clock.badge.xmark"
        case .noResults:
            return "magnifyingglass.circle"
        case .noConnection:
            return "wifi.slash"
        case .noBadges:
            return "rosette"
        case .noResources:
            return "book.closed"
        }
    }
    
    var title: String {
        switch self {
        case .noHistory:
            return "No History Yet"
        case .noResults:
            return "No Results Found"
        case .noConnection:
            return "No Internet Connection"
        case .noBadges:
            return "No Badges Yet"
        case .noResources:
            return "No Resources Available"
        }
    }
    
    var message: String {
        switch self {
        case .noHistory:
            return "Start solving problems to build your learning history!"
        case .noResults:
            return "Try adjusting your search or filters to find what you're looking for."
        case .noConnection:
            return "Please check your internet connection and try again."
        case .noBadges:
            return "Keep learning and solving problems to unlock achievement badges!"
        case .noResources:
            return "Additional learning resources will appear here as you progress."
        }
    }
    
    var actionText: String {
        switch self {
        case .noHistory:
            return "Scan First Problem"
        case .noResults:
            return "Clear Filters"
        case .noConnection:
            return "Try Again"
        case .noBadges:
            return "Start Learning"
        case .noResources:
            return "Explore Topics"
        }
    }
    
    var actionIcon: String {
        switch self {
        case .noHistory:
            return "camera.fill"
        case .noResults:
            return "arrow.counterclockwise"
        case .noConnection:
            return "arrow.clockwise"
        case .noBadges:
            return "sparkles"
        case .noResources:
            return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .noHistory:
            return .blue
        case .noResults:
            return .orange
        case .noConnection:
            return .red
        case .noBadges:
            return .purple
        case .noResources:
            return .green
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        EmptyStateView(type: .noHistory) {
            print("Action tapped")
        }
        
        EmptyStateView(type: .noBadges)
    }
}