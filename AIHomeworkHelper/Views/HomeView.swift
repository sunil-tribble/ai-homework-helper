import SwiftUI
import CoreHaptics

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var storeManager: StoreKitManager
    @StateObject private var problemStorage = ProblemStorage.shared
    @State private var showingPaywall = false
    @State private var animateGradient = false
    @State private var showingBadgeDetail = false
    @State private var streakFireAnimation = false
    @State private var showingProgressDashboard = false
    @State private var showingLeaderboard = false
    @State private var showingAvatarCustomization = false
    @State private var welcomeAnimation = false
    @State private var pointsAnimation = false
    @State private var showingPointsParticles = false
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.teal.opacity(0.1)],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3), value: animateGradient)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Streak Card - Most prominent feature
                        streakCard
                        
                        // Header Card
                        headerCard
                        
                        // Progress Overview
                        progressOverview
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Recent Problems
                        if !problemStorage.problems.isEmpty {
                            recentProblemsSection
                        }
                        
                        // Study Tips
                        studyTipsSection
                    }
                    .padding()
                }
            }
            .onAppear {
                animateGradient = true
                streakFireAnimation = true
                welcomeAnimation = true
                
                // Play welcome sound if first launch today
                if userManager.dailySolvesUsed == 0 {
                    soundManager.play(.success)
                    hapticManager.impact(.light)
                }
            }
            .sheet(isPresented: $showingBadgeDetail) {
                BadgeDetailView()
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $showingProgressDashboard) {
                ProgressDashboardView()
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $showingLeaderboard) {
                LeaderboardView()
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $showingAvatarCustomization) {
                AvatarCustomizationView()
                    .environmentObject(userManager)
            }
            .navigationTitle("AI Homework Helper")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAvatarCustomization = true }) {
                        // Mini avatar preview
                        ZStack {
                            Circle()
                                .fill(userManager.avatarConfig.skinTone.color)
                                .frame(width: 35, height: 35)
                            
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(userManager.selectedTheme.primaryColor, lineWidth: 2)
                        )
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Streak")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(userManager.currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("days")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 8)
                    }
                }
                
                Spacer()
                
                ZStack {
                    // Fire effect background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange, Color.red.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 10)
                        .scaleEffect(streakFireAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: streakFireAnimation)
                    
                    Image(systemName: userManager.streakStatus.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: userManager.currentStreak > 0 ? [Color.orange, Color.red] : [Color.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: userManager.currentStreak)
                        .symbolEffect(.pulse.byLayer, options: .repeating, value: userManager.currentStreak > 0)
                        .shadow(color: userManager.currentStreak > 0 ? Color.orange : Color.clear, radius: 10)
                        .shadow(color: userManager.currentStreak > 0 ? Color.red.opacity(0.5) : Color.clear, radius: 20)
                }
            }
            
            // Weekly progress
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(userManager.weeklyProgress[day] ? Color.green : Color.white.opacity(0.3))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: userManager.weeklyProgress[day] ? "checkmark" : "")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                        
                        Text(["S", "M", "T", "W", "T", "F", "S"][day])
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                LinearGradient(
                    colors: userManager.currentStreak > 0 ? [Color.orange.opacity(0.8), Color.red.opacity(0.6)] : [Color.gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
        )
        .cornerRadius(20)
        .shadow(color: userManager.currentStreak > 0 ? Color.orange.opacity(0.4) : Color.gray.opacity(0.3), radius: 15, x: 0, y: 10)
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading) {
                    Text("Welcome back!")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(welcomeAnimation ? 1.0 : 0.8)
                        .opacity(welcomeAnimation ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: welcomeAnimation)
                    
                    Text("\(userManager.totalSolves) problems solved")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(welcomeAnimation ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: welcomeAnimation)
                }
                
                Spacer()
            }
            
            if userManager.isPremium {
                Label("Premium Member", systemImage: "crown.fill")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.3))
                    .cornerRadius(20)
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 8) {
                    Text("\(userManager.solvesRemaining) free solves remaining today")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Button(action: { showingPaywall = true }) {
                        Label("Upgrade to Premium", systemImage: "sparkles")
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.purple, Color.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Glass overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
        )
        .cornerRadius(20)
        .shadow(color: Color.purple.opacity(0.3), radius: 15, x: 0, y: 10)
    }
    
    private var progressOverview: some View {
        HStack(spacing: 16) {
            // Points card
            Button(action: { showingLeaderboard = true }) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                
                ZStack {
                    Text("\(userManager.userPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(pointsAnimation ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pointsAnimation)
                    
                    if showingPointsParticles {
                        ParticleSystem(
                            particleCount: 8,
                            duration: 1.0,
                            particleSize: 4,
                            colors: [.yellow, .orange],
                            spread: 30,
                            emissionShape: .circle(radius: 20)
                        )
                    }
                }
                .onChange(of: userManager.userPoints) { oldValue, newValue in
                    if newValue > oldValue {
                        pointsAnimation = true
                        showingPointsParticles = true
                        hapticManager.impact(.light)
                        soundManager.play(.pointsEarned)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pointsAnimation = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showingPointsParticles = false
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.5), Color.orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Badges card
            Button(action: { showingBadgeDetail = true }) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "rosette")
                            .foregroundColor(.purple)
                        Text("Badges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(userManager.unlockedBadges.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 16) {
                NavigationLink(destination: ScannerView()) {
                    QuickActionCard(
                        icon: "camera.fill",
                        title: "Scan Problem",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: HistoryView()) {
                    QuickActionCard(
                        icon: "clock.fill",
                        title: "View History",
                        color: .green
                    )
                }
            }
            
            HStack(spacing: 16) {
                Button(action: { showingProgressDashboard = true }) {
                    QuickActionCard(
                        icon: "chart.xyaxis.line",
                        title: "Progress",
                        color: .purple
                    )
                }
                
                NavigationLink(destination: ProfileView()) {
                    QuickActionCard(
                        icon: "person.fill",
                        title: "Profile",
                        color: .orange
                    )
                }
            }
        }
    }
    
    private var recentProblemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Problems")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: HistoryView()) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            ForEach(problemStorage.getRecentProblems(limit: 3)) { problem in
                NavigationLink(destination: SolutionView(problem: problem)) {
                    RecentProblemCard(problem: problem)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var studyTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Tips")
                .font(.headline)
            
            VStack(spacing: 12) {
                StudyTipCard(
                    icon: "lightbulb.fill",
                    tip: "Break complex problems into smaller steps",
                    color: .yellow
                )
                
                StudyTipCard(
                    icon: "book.fill",
                    tip: "Review similar problems to reinforce learning",
                    color: .orange
                )
                
                StudyTipCard(
                    icon: "star.fill",
                    tip: "Practice regularly for better retention",
                    color: .purple
                )
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .symbolEffect(.bounce, value: isPressed)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            ZStack {
                color
                
                // Glass effect
                LinearGradient(
                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Blur overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.2)
            }
        )
        .cornerRadius(16)
        .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed.toggle()
            }
            HapticManager.shared.impact(.medium)
            SoundManager.shared.play(.tap)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct RecentProblemCard: View {
    let problem: Problem
    
    var body: some View {
        HStack {
            Image(systemName: problem.subject.icon)
                .font(.title2)
                .foregroundColor(problem.subject.color)
                .frame(width: 50, height: 50)
                .background(problem.subject.color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(problem.questionText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(problem.subject.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(problem.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct StudyTipCard: View {
    let icon: String
    let tip: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        )
        .shadow(color: color.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(UserManager())
        .environmentObject(StoreKitManager())
}