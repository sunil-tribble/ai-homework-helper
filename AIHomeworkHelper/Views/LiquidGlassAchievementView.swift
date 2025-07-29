import SwiftUI

struct LiquidGlassAchievementView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBadge: Badge?
    @State private var showingDetail = false
    @State private var animateIn = false
    @State private var particleSystem: ParticleSystem?
    @StateObject private var hapticManager = HapticManager.shared
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                AchievementBackgroundView()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Progress overview
                        progressOverview
                            .liquidTransition(isVisible: animateIn)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIn)
                        
                        // Achievement categories
                        achievementCategories
                        
                        // Badge grid
                        badgeGrid
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(badge: badge)
                    .environmentObject(userManager)
            }
            .onAppear {
                animateIn = true
            }
        }
    }
    
    private var progressOverview: some View {
        DepthCard(depth: .elevated) {
            VStack(spacing: 20) {
                // Overall progress
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Achievement Progress")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(userManager.unlockedBadges.count) of \(allBadges.count)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Badges Unlocked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(userManager.unlockedBadges.count) / CGFloat(allBadges.count))
                            .stroke(
                                LinearGradient(
                                    colors: [.purple, .blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((Double(userManager.unlockedBadges.count) / Double(allBadges.count)) * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                
                // Recent unlock
                if let recentBadge = userManager.lastBadgeUnlocked,
                   let badge = allBadges.first(where: { $0.id == recentBadge }) {
                    RecentUnlockCard(badge: badge)
                }
            }
            .padding()
        }
    }
    
    private var achievementCategories: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(BadgeCategory.allCases, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            unlockedCount: userManager.unlockedBadges.filter { badge in
                                allBadges.first(where: { $0.id == badge })?.category == category
                            }.count,
                            totalCount: allBadges.filter { $0.category == category }.count
                        )
                    }
                }
            }
        }
    }
    
    private var badgeGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Badges")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(allBadges) { badge in
                    BadgeCell(
                        badge: badge,
                        isUnlocked: userManager.unlockedBadges.contains(badge.id),
                        progress: getBadgeProgress(for: badge)
                    ) {
                        selectedBadge = badge
                        hapticManager.playGlassTouch()
                    }
                    .liquidTransition(isVisible: animateIn)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(allBadges.firstIndex(where: { $0.id == badge.id }) ?? 0) * 0.05),
                        value: animateIn
                    )
                }
            }
        }
    }
    
    private func getBadgeProgress(for badge: Badge) -> Double {
        switch badge.requirement {
        case .solveProblemCount(let count):
            return min(Double(userManager.totalSolves) / Double(count), 1.0)
        case .maintainStreak(let days):
            return min(Double(userManager.longestStreak) / Double(days), 1.0)
        case .earnPoints(let points):
            return min(Double(userManager.userPoints) / Double(points), 1.0)
        case .completeDaily:
            return userManager.dailySolvesUsed >= 5 ? 1.0 : Double(userManager.dailySolvesUsed) / 5.0
        case .perfectWeek:
            return userManager.weeklyProgress.allSatisfy { $0 } ? 1.0 : 
                   Double(userManager.weeklyProgress.filter { $0 }.count) / 7.0
        case .solveSubject(_, let count):
            return 0.5 // Placeholder - would need subject-specific tracking
        case .speedSolve:
            return 0.3 // Placeholder - would need timing tracking
        case .helpOthers:
            return 0.2 // Placeholder - would need social features
        case .other:
            return 0.0
        }
    }
}

// MARK: - Supporting Views

struct AchievementBackgroundView: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05),
                    Color.cyan.opacity(0.02)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating achievement icons
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: ["trophy", "star", "rosette", "crown", "medal"][index])
                    .font(.system(size: 30))
                    .foregroundColor(Color.purple.opacity(0.1))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -300...300)
                    )
                    .rotationEffect(.degrees(Double.random(in: -30...30)))
                    .animation(
                        .easeInOut(duration: Double.random(in: 15...25))
                            .repeatForever(autoreverses: true),
                        value: animateGradient
                    )
            }
        }
        .onAppear { animateGradient = true }
    }
}

struct CategoryCard: View {
    let category: BadgeCategory
    let unlockedCount: Int
    let totalCount: Int
    @State private var isPressed = false
    
    var progress: Double {
        totalCount > 0 ? Double(unlockedCount) / Double(totalCount) : 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: category.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: category.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(category.title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(unlockedCount)/\(totalCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .liquidGlass(style: .thin, luminosity: 0.8)
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct BadgeCell: View {
    let badge: Badge
    let isUnlocked: Bool
    let progress: Double
    let onTap: () -> Void
    @State private var isHovering = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Badge icon container
                ZStack {
                    // Background glow for unlocked badges
                    if isUnlocked {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        badge.color.opacity(0.3),
                                        badge.color.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 10)
                    }
                    
                    // Progress ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: isUnlocked ? [badge.color, badge.color.opacity(0.7)] : [.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    // Badge content
                    ZStack {
                        Circle()
                            .fill(isUnlocked ? badge.color : Color.gray)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isUnlocked ? 0.3 : 0.1),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                        
                        Image(systemName: badge.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, value: isHovering)
                    }
                    .rotation3DEffect(
                        .degrees(rotationAngle),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    
                    // Lock overlay for locked badges
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .offset(x: 25, y: 25)
                    }
                }
                
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
            }
            .frame(width: 100, height: 120)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovering = hovering
                }
                if hovering && isUnlocked {
                    withAnimation(.easeInOut(duration: 2)) {
                        rotationAngle = 360
                    }
                } else {
                    rotationAngle = 0
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentUnlockCard: View {
    let badge: Badge
    @State private var sparkle = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(badge.color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Image(systemName: badge.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                // Sparkle effect
                if sparkle {
                    ForEach(0..<4, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .offset(
                                x: cos(CGFloat(index) * .pi / 2) * 30,
                                y: sin(CGFloat(index) * .pi / 2) * 30
                            )
                            .scaleEffect(sparkle ? 1 : 0)
                            .opacity(sparkle ? 0 : 1)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Recently Unlocked!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(badge.name)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [badge.color, badge.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .liquidGlass(style: .thin, luminosity: 1.2)
        .cornerRadius(12)
        .onAppear {
            withAnimation(
                .easeOut(duration: 1)
                    .repeatForever(autoreverses: false)
            ) {
                sparkle = true
            }
        }
    }
}

struct BadgeDetailSheet: View {
    let badge: Badge
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var celebrateUnlock = false
    
    var isUnlocked: Bool {
        userManager.unlockedBadges.contains(badge.id)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [badge.color.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Badge display
                    ZStack {
                        if isUnlocked && celebrateUnlock {
                            ConfettiBurst(trigger: celebrateUnlock)
                        }
                        
                        Circle()
                            .fill(isUnlocked ? badge.color : Color.gray)
                            .frame(width: 150, height: 150)
                            .overlay(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(
                                color: isUnlocked ? badge.color.opacity(0.4) : .clear,
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                        
                        Image(systemName: badge.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, value: celebrateUnlock)
                    }
                    
                    // Badge info
                    VStack(spacing: 16) {
                        Text(badge.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isUnlocked ? [badge.color, badge.color.opacity(0.7)] : [.gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(badge.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Requirement
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(badge.color)
                            Text(badge.requirementDescription)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .liquidGlass(style: .ultraThin, luminosity: 0.8)
                        .cornerRadius(12)
                        
                        // Progress or unlock date
                        if isUnlocked {
                            Label("Unlocked!", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            ProgressView(value: getBadgeProgress()) {
                                Text("Progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tint(badge.color)
                            .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if isUnlocked {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        celebrateUnlock = true
                        HapticManager.shared.playUnlockPattern()
                    }
                }
            }
        }
    }
    
    private func getBadgeProgress() -> Double {
        // Same logic as in parent view
        switch badge.requirement {
        case .solveProblemCount(let count):
            return min(Double(userManager.totalSolves) / Double(count), 1.0)
        case .maintainStreak(let days):
            return min(Double(userManager.longestStreak) / Double(days), 1.0)
        default:
            return 0.5
        }
    }
}

// MARK: - Badge Model Extensions

enum BadgeCategory: String, CaseIterable {
    case academic = "Academic"
    case streak = "Consistency"
    case social = "Community"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .academic: return "graduationcap.fill"
        case .streak: return "flame.fill"
        case .social: return "person.3.fill"
        case .special: return "star.fill"
        }
    }
    
    var title: String {
        rawValue
    }
    
    var colors: [Color] {
        switch self {
        case .academic: return [.blue, .cyan]
        case .streak: return [.orange, .red]
        case .social: return [.green, .mint]
        case .special: return [.purple, .pink]
        }
    }
}

extension Badge {
    var category: BadgeCategory {
        switch requirement {
        case .solveProblemCount, .solveSubject, .speedSolve:
            return .academic
        case .maintainStreak, .completeDaily, .perfectWeek:
            return .streak
        case .helpOthers:
            return .social
        case .earnPoints, .other:
            return .special
        }
    }
    
    var requirementDescription: String {
        switch requirement {
        case .solveProblemCount(let count):
            return "Solve \(count) problems"
        case .maintainStreak(let days):
            return "Maintain a \(days)-day streak"
        case .earnPoints(let points):
            return "Earn \(points) points"
        case .solveSubject(let subject, let count):
            return "Solve \(count) \(subject) problems"
        case .completeDaily:
            return "Complete daily goals"
        case .perfectWeek:
            return "Complete a perfect week"
        case .speedSolve:
            return "Solve problems quickly"
        case .helpOthers:
            return "Help other students"
        case .other(let description):
            return description
        }
    }
}