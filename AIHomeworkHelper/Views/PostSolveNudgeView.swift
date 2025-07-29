import SwiftUI

struct PostSolveNudgeView: View {
    @EnvironmentObject var userManager: UserManager
    @Binding var isPresented: Bool
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    @State private var animateElements = false
    
    var nudgeType: NudgeType {
        if userManager.totalSolves == 5 {
            return .firstMilestone
        } else if userManager.solvesRemaining == 0 {
            return .limitReached
        } else if userManager.currentStreak >= 3 && !userManager.isPremium {
            return .streakRisk
        } else if userManager.totalSolves > 10 && !userManager.isPremium {
            return .loyalUser
        } else {
            return .general
        }
    }
    
    enum NudgeType {
        case firstMilestone
        case limitReached
        case streakRisk
        case loyalUser
        case general
        
        var title: String {
            switch self {
            case .firstMilestone:
                return "🎉 You're crushing it!"
            case .limitReached:
                return "Daily limit reached!"
            case .streakRisk:
                return "🔥 Keep your streak alive!"
            case .loyalUser:
                return "You're a power user!"
            case .general:
                return "Level up your learning!"
            }
        }
        
        var message: String {
            switch self {
            case .firstMilestone:
                return "You've solved 5 problems! Join 50M+ students with unlimited access."
            case .limitReached:
                return "Unlock unlimited solves to keep learning today."
            case .streakRisk:
                return "Don't lose your \(UserManager().currentStreak)-day streak! Go unlimited."
            case .loyalUser:
                return "You've solved \(UserManager().totalSolves) problems! Time to upgrade?"
            case .general:
                return "Get unlimited solves, expert help, and more!"
            }
        }
        
        var benefits: [String] {
            switch self {
            case .firstMilestone, .general:
                return ["Unlimited homework help", "Step-by-step animations", "24/7 expert support"]
            case .limitReached:
                return ["Solve more problems today", "Never hit limits again", "Learn at your pace"]
            case .streakRisk:
                return ["Protect your streak", "Unlimited daily solves", "Exclusive streak badges"]
            case .loyalUser:
                return ["Priority support", "Advanced insights", "Pro learning tools"]
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Content
            VStack(spacing: 20) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Icon
                Image(systemName: nudgeType == .streakRisk ? "flame.fill" : "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateElements ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateElements)
                
                // Title
                Text(nudgeType.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(nudgeType.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Benefits
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(nudgeType.benefits, id: \.self) { benefit in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(benefit)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal)
                .opacity(animateElements ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateElements)
                
                // Price comparison
                HStack {
                    VStack(alignment: .leading) {
                        Text("Free")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("5 solves/day")
                            .font(.footnote)
                            .strikethrough()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Premium")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("Unlimited")
                            .font(.footnote)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 40)
                
                // CTA Button
                Button(action: {
                    onUpgrade()
                    isPresented = false
                }) {
                    HStack {
                        Text("Unlock Premium - $4.99/mo")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .scaleEffect(animateElements ? 1.0 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateElements)
                
                // Skip button
                Button(action: onDismiss) {
                    Text("Maybe later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Social proof
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("4.8/5 • 50M+ students • 98.5% accuracy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
            )
            .padding(.horizontal, 30)
            .scaleEffect(animateElements ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateElements)
        }
        .onAppear {
            animateElements = true
        }
    }
}

#Preview {
    PostSolveNudgeView(
        isPresented: .constant(true),
        onUpgrade: {},
        onDismiss: {}
    )
    .environmentObject(UserManager())
}