import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var tabChangeAnimation = false
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        ZStack {
            // Dynamic background based on theme
            userManager.selectedTheme.backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: userManager.selectedTheme)
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        TabItemView(
                            icon: "house.fill",
                            title: "Home",
                            isSelected: selectedTab == 0
                        )
                    }
                    .tag(0)
                
                ScannerView()
                    .tabItem {
                        TabItemView(
                            icon: "camera.fill",
                            title: "Scan",
                            isSelected: selectedTab == 1
                        )
                    }
                    .tag(1)
                
                HistoryView()
                    .tabItem {
                        TabItemView(
                            icon: "clock.fill",
                            title: "History",
                            isSelected: selectedTab == 2
                        )
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        TabItemView(
                            icon: "person.fill",
                            title: "Profile",
                            isSelected: selectedTab == 3
                        )
                    }
                    .tag(3)
            }
            .tint(userManager.selectedTheme.primaryColor)
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabChange(from: oldValue, to: newValue)
            }
            
            // Tab change particle effect
            if tabChangeAnimation {
                ParticleSystem(
                    particleCount: 15,
                    duration: 1.0,
                    particleSize: 6,
                    colors: [userManager.selectedTheme.primaryColor, userManager.selectedTheme.secondaryColor],
                    spread: 50,
                    emissionShape: .point
                )
                .allowsHitTesting(false)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 50)
            }
        }
        .preferredColorScheme(userManager.selectedTheme == .neon ? .dark : nil)
    }
    
    private func handleTabChange(from oldTab: Int, to newTab: Int) {
        // Haptic feedback
        hapticManager.selection()
        
        // Sound effect
        soundManager.play(.tap)
        
        // Trigger particle animation
        withAnimation(.easeOut(duration: 0.3)) {
            tabChangeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tabChangeAnimation = false
        }
        
        previousTab = oldTab
    }
}

struct TabItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    @State private var animateSelection = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .symbolEffect(.bounce, value: isSelected)
                .scaleEffect(isSelected ? 1.1 : 1.0)
            
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                animateSelection = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreKitManager())
        .environmentObject(UserManager())
}