import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    @State private var animatePage = false
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    let pages = [
        OnboardingPage(
            title: "Welcome to AI Homework Helper",
            subtitle: "Your personal AI tutor is here!",
            icon: "brain.head.profile",
            color: .blue,
            description: "Get instant help with any homework problem using advanced AI technology."
        ),
        OnboardingPage(
            title: "Scan & Solve",
            subtitle: "Just snap a photo",
            icon: "camera.viewfinder",
            color: .purple,
            description: "Take a photo of your homework, and we'll provide step-by-step solutions."
        ),
        OnboardingPage(
            title: "Track Progress",
            subtitle: "Build learning streaks",
            icon: "flame.fill",
            color: .orange,
            description: "Earn points, unlock badges, and watch your knowledge grow every day!"
        ),
        OnboardingPage(
            title: "Ready to Start?",
            subtitle: "Let's ace those grades!",
            icon: "sparkles",
            color: .green,
            description: "Join millions of students improving their grades with AI assistance."
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [pages[currentPage].color.opacity(0.2), pages[currentPage].color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        hapticManager.impact(.light)
                        soundManager.play(.tap)
                        withAnimation(.spring()) {
                            showOnboarding = false
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            isCurrentPage: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldValue, newValue in
                    hapticManager.selection()
                    soundManager.play(.tap)
                    animatePage = true
                }
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[index].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical)
                
                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring()) {
                            currentPage += 1
                        }
                    } else {
                        hapticManager.playSuccessPattern()
                        soundManager.play(.success)
                        withAnimation(.spring()) {
                            showOnboarding = false
                        }
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                            .symbolEffect(.bounce, value: currentPage)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Capsule()
                            .fill(pages[currentPage].color)
                            .shadow(color: pages[currentPage].color.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isCurrentPage: Bool
    @State private var iconAnimation = false
    @State private var textAnimation = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.color.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
                    .scaleEffect(iconAnimation ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: iconAnimation)
                
                // Background circle
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconAnimation ? 1.0 : 0.8)
                    .rotationEffect(.degrees(iconAnimation ? 10 : -10))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: iconAnimation)
                
                // Floating particles
                if isCurrentPage {
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(page.color.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .offset(
                                x: cos(CGFloat(index) * .pi / 3) * 100,
                                y: sin(CGFloat(index) * .pi / 3) * 100
                            )
                            .scaleEffect(iconAnimation ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: iconAnimation
                            )
                    }
                }
            }
            .frame(height: 250)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .opacity(textAnimation ? 1 : 0)
                    .offset(y: textAnimation ? 0 : 20)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(page.color)
                    .opacity(textAnimation ? 1 : 0)
                    .offset(y: textAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: textAnimation)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(textAnimation ? 1 : 0)
                    .offset(y: textAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: textAnimation)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            iconAnimation = true
            textAnimation = true
        }
        .onChange(of: isCurrentPage) { _, newValue in
            if newValue {
                // Reset and restart animations when page becomes current
                iconAnimation = false
                textAnimation = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    iconAnimation = true
                    textAnimation = true
                }
            }
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}