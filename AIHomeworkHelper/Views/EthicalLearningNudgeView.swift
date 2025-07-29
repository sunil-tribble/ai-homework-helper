import SwiftUI

struct EthicalLearningNudgeView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var animateElements = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.green.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.green],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .scaleEffect(animateElements ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateElements)
                        
                        // Title
                        Text("Learn Better with Hints")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Description
                        Text("We believe in learning, not just getting answers. That's why we show you helpful hints before revealing the full solution.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 16) {
                            BenefitRow(
                                icon: "lightbulb.fill",
                                title: "Build Understanding",
                                description: "Hints guide you to discover solutions yourself",
                                color: .yellow
                            )
                            
                            BenefitRow(
                                icon: "graduationcap.fill",
                                title: "Better Retention",
                                description: "Learning through hints improves memory",
                                color: .blue
                            )
                            
                            BenefitRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Improved Grades",
                                description: "Understanding concepts leads to better test scores",
                                color: .green
                            )
                            
                            BenefitRow(
                                icon: "shield.fill",
                                title: "Academic Integrity",
                                description: "Develop skills while maintaining honesty",
                                color: .purple
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
                        
                        // Quote
                        VStack(spacing: 8) {
                            Text("Give a student an answer and they solve for a day. Teach them to think and they solve for a lifetime.")
                                .font(.callout)
                                .italic()
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("— Educational Proverb")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Continue button
                        Button(action: {
                            userManager.hasSeenEthicalNudge = true
                            dismiss()
                        }) {
                            Text("Got it, let's learn!")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .scaleEffect(animateElements ? 1.0 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateElements)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Welcome to Ethical Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        userManager.hasSeenEthicalNudge = true
                        dismiss()
                    }
                    .font(.caption)
                }
            }
        }
        .onAppear {
            animateElements = true
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    EthicalLearningNudgeView()
        .environmentObject(UserManager())
}