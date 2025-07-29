import SwiftUI

struct AchievementDisplayView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Achievement.AchievementCategory?
    @State private var showingDetail = false
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Overview
                        achievementStats
                        
                        // Category Filter
                        categoryFilter
                        
                        // Achievements Grid
                        achievementsGrid
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(achievement: achievement)
                    .environmentObject(userManager)
            }
            .overlay(alignment: .top) {
                if let recentAchievement = achievementManager.recentlyUnlocked {
                    AchievementUnlockedBanner(achievement: recentAchievement)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
        }
        .onAppear {
            achievementManager.checkAchievements(for: userManager)
        }
    }
    
    private var achievementStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatBox(
                    title: "Unlocked",
                    value: "\(unlockedCount)/\(achievementManager.achievements.count)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatBox(
                    title: "Points Earned",
                    value: "\(totalPoints)",
                    icon: "star.fill",
                    color: .blue
                )
                
                StatBox(
                    title: "Completion",
                    value: "\(Int(completionPercentage))%",
                    icon: "chart.pie.fill",
                    color: .green
                )
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * completionPercentage / 100, height: 12)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionPercentage)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }
                
                ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var achievementsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(achievement: achievement) {
                    selectedAchievement = achievement
                }
                .environmentObject(userManager)
            }
        }
    }
    
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievementManager.achievements.filter { $0.category == category }
        }
        return achievementManager.achievements
    }
    
    private var unlockedCount: Int {
        achievementManager.achievements.filter { $0.isUnlocked }.count
    }
    
    private var totalPoints: Int {
        achievementManager.achievements
            .filter { $0.isUnlocked }
            .reduce(0) { $0 + $1.points }
    }
    
    private var completionPercentage: Double {
        guard !achievementManager.achievements.isEmpty else { return 0 }
        return Double(unlockedCount) / Double(achievementManager.achievements.count) * 100
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let action: () -> Void
    @EnvironmentObject var userManager: UserManager
    @State private var progress: CGFloat = 0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon with lock overlay
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? achievement.category.color : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if !achievement.isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(achievement.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text("\(achievement.points) pts")
                        .font(.caption2)
                        .foregroundColor(achievement.isUnlocked ? achievement.category.color : .secondary)
                }
                
                // Progress indicator
                if !achievement.isUnlocked {
                    ProgressView(value: progress)
                        .tint(achievement.category.color)
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(achievement.isUnlocked ? Color.white : Color.gray.opacity(0.1))
                    .shadow(
                        color: achievement.isUnlocked ? achievement.category.color.opacity(0.3) : Color.clear,
                        radius: achievement.isUnlocked ? 8 : 0
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        achievement.isUnlocked ? achievement.category.color.opacity(0.3) : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(achievement.isUnlocked ? 1 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !achievement.isUnlocked {
                let (current, total) = achievement.requirement.progress(userManager)
                withAnimation(.easeOut(duration: 0.6)) {
                    progress = CGFloat(current) / CGFloat(max(1, total))
                }
            }
        }
    }
}

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [achievement.category.color, achievement.category.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    if !achievement.isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                
                // Title and Description
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(achievement.points) points")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                
                // Progress
                if !achievement.isUnlocked {
                    VStack(spacing: 12) {
                        let (current, total) = achievement.requirement.progress(userManager)
                        
                        ProgressView(value: Double(current), total: Double(total))
                            .tint(achievement.category.color)
                        
                        Text("\(current) / \(total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                
                // Unlock Date
                if achievement.isUnlocked, let date = achievement.unlockedDate {
                    Label("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Achievement Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementUnlockedBanner: View {
    let achievement: Achievement
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.category.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(achievement.title)
                    .font(.headline)
            }
            
            Spacer()
            
            Text("+\(achievement.points)")
                .font(.headline)
                .foregroundColor(achievement.category.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)
        )
        .padding(.horizontal)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -50)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    AchievementDisplayView()
        .environmentObject(UserManager())
}