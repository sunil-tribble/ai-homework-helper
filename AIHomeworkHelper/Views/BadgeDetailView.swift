import SwiftUI

struct BadgeDetailView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    let allBadges: [(id: String, name: String, description: String, icon: String, color: Color)] = [
        // Solve milestones
        ("first_solve", "First Steps", "Solve your first problem", "star.fill", .yellow),
        ("solves_10", "Problem Solver", "Solve 10 problems", "10.circle.fill", .blue),
        ("solves_25", "Quick Learner", "Solve 25 problems", "25.circle.fill", .green),
        ("solves_50", "Dedicated Student", "Solve 50 problems", "50.circle.fill", .orange),
        ("solves_100", "Century Club", "Solve 100 problems", "100.circle.fill", .purple),
        ("solves_250", "Knowledge Seeker", "Solve 250 problems", "book.fill", .red),
        ("solves_500", "Scholar", "Solve 500 problems", "graduationcap.fill", .indigo),
        ("solves_1000", "Master Mind", "Solve 1000 problems", "brain.head.profile", .pink),
        
        // Streak milestones
        ("streak_3", "Getting Started", "3-day streak", "flame.fill", .orange),
        ("streak_7", "Week Warrior", "7-day streak", "calendar.badge.7", .red),
        ("streak_14", "Fortnight Force", "14-day streak", "calendar.badge.14", .orange),
        ("streak_30", "Monthly Master", "30-day streak", "calendar.badge.30", .red),
        ("streak_50", "Streak Legend", "50-day streak", "flame.circle.fill", .orange),
        ("streak_100", "Century Streak", "100-day streak", "star.circle.fill", .yellow),
        
        // Special achievements
        ("perfect_week", "Perfect Week", "Solve problems 7 days in a row", "checkmark.seal.fill", .green),
        ("premium_member", "Premium Member", "Join the premium club", "crown.fill", .yellow)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Header
                        statsHeader
                        
                        // Badge Categories
                        VStack(alignment: .leading, spacing: 20) {
                            badgeSection(title: "Solve Milestones", badges: allBadges.filter { $0.id.starts(with: "solves_") || $0.id == "first_solve" })
                            badgeSection(title: "Streak Achievements", badges: allBadges.filter { $0.id.starts(with: "streak_") })
                            badgeSection(title: "Special Badges", badges: allBadges.filter { $0.id == "perfect_week" || $0.id == "premium_member" })
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Badges & Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var statsHeader: some View {
        VStack(spacing: 16) {
            Text("Your Progress")
                .font(.headline)
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(userManager.unlockedBadges.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Unlocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(allBadges.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int((Double(userManager.unlockedBadges.count) / Double(allBadges.count)) * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (Double(userManager.unlockedBadges.count) / Double(allBadges.count)), height: 10)
                        .animation(.spring(), value: userManager.unlockedBadges.count)
                }
            }
            .frame(height: 10)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
    
    private func badgeSection(title: String, badges: [(id: String, name: String, description: String, icon: String, color: Color)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(badges, id: \.id) { badge in
                    BadgeCard(
                        badge: badge,
                        isUnlocked: userManager.unlockedBadges.contains(badge.id),
                        isNew: userManager.lastBadgeUnlocked == badge.id
                    )
                }
            }
        }
    }
}

struct BadgeCard: View {
    let badge: (id: String, name: String, description: String, icon: String, color: Color)
    let isUnlocked: Bool
    let isNew: Bool
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? badge.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: badge.icon)
                        .font(.title2)
                        .foregroundColor(isUnlocked ? badge.color : .gray.opacity(0.5))
                    
                    if !isUnlocked {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if isNew {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("NEW")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 25, y: -25)
                    }
                }
                
                Text(badge.name)
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 100, height: 100)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    if isUnlocked {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [badge.color.opacity(0.5), badge.color.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                }
            )
            .scaleEffect(isUnlocked ? 1.0 : 0.95)
            .animation(.spring(response: 0.3), value: isUnlocked)
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showingDetail) {
            BadgeDetailPopover(badge: badge, isUnlocked: isUnlocked)
                .presentationCompactAdaptation(.popover)
        }
    }
}

struct BadgeDetailPopover: View {
    let badge: (id: String, name: String, description: String, icon: String, color: Color)
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? badge.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isUnlocked ? badge.color : .gray.opacity(0.5))
            }
            
            Text(badge.name)
                .font(.headline)
            
            Text(badge.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if isUnlocked {
                Label("Unlocked!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Keep going!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
    }
}

#Preview {
    BadgeDetailView()
        .environmentObject(UserManager())
}