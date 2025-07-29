import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var showGradient = false
    @State private var particlesActive = false
    @State private var logoRotation = 0.0
    @State private var pulseAnimation = false
    @State private var showContent = false
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [Color.blue, Color.purple, Color.teal],
                startPoint: showGradient ? .topLeading : .bottomTrailing,
                endPoint: showGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .opacity(showGradient ? 1 : 0.7)
            .animation(.easeInOut(duration: 2), value: showGradient)
            
            // Background particles for magical effect
            if particlesActive {
                ParticleSystem(
                    particleCount: 20,
                    duration: 4.0,
                    particleSize: 3,
                    colors: [.white.opacity(0.3), .blue.opacity(0.3), .purple.opacity(0.3)],
                    spread: 200,
                    emissionShape: .circle(radius: 150)
                )
                .allowsHitTesting(false)
            }
            
            VStack(spacing: 20) {
                // App Icon with enhanced animations
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                        .scaleEffect(pulseAnimation ? 1.3 : 0.9)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .blur(radius: isAnimating ? 10 : 20)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isAnimating ? 1 : 0.8)
                        .rotation3DEffect(
                            .degrees(logoRotation),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10)
                        .symbolEffect(.pulse, value: isAnimating)
                }
                
                VStack(spacing: 8) {
                    // Animated text with staggered appearance
                    HStack(spacing: 2) {
                        ForEach(Array("AI Homework Helper".enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.03),
                                    value: showContent
                                )
                        }
                    }
                    
                    Text("Your Smart Study Companion")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .shimmer()
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: showContent)
                }
                
                // Loading dots animation
                if showContent {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.top, 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Version info
            VStack {
                Spacer()
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 30)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(1), value: showContent)
            }
        }
        .onAppear {
            // Start all animations
            withAnimation(.easeOut(duration: 1)) {
                isAnimating = true
                showGradient = true
            }
            
            // Show content with delay
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showContent = true
            }
            
            // Enable additional effects
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = true
                particlesActive = true
                
                // Subtle haptic on logo appearance
                hapticManager.impact(.light)
            }
            
            // Logo 3D rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                logoRotation = 360
            }
            
            // Welcome sound
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                soundManager.play(.success)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}