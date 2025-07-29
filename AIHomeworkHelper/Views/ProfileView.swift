import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var storeManager: StoreKitManager
    @StateObject private var problemStorage = ProblemStorage.shared
    @State private var isEditingName = false
    @State private var tempName = ""
    @State private var showingPaywall = false
    @State private var showingDeleteConfirmation = false
    @State private var showingStore = false
    @State private var showingAchievements = false
    @State private var showingLeaderboard = false
    @State private var showingAvatarCustomization = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Statistics
                    statisticsSection
                    
                    // Progress & Social
                    progressSection
                    
                    // Account Settings
                    accountSection
                    
                    // Store Section
                    storeSection
                    
                    // App Settings
                    appSettingsSection
                    
                    // About Section
                    aboutSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingStore) {
                StoreView()
                    .environmentObject(userManager)
                    .environmentObject(storeManager)
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementDisplayView()
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
            .alert("Delete All History", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    problemStorage.problems.removeAll()
                }
            } message: {
                Text("Are you sure you want to delete all your problem history? This action cannot be undone.")
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Button(action: {
                showingAvatarCustomization = true
            }) {
                ZStack {
                    Circle()
                        .fill(userManager.avatarConfig.skinTone.color)
                        .frame(width: 100, height: 100)
                    
                    // Simple avatar representation
                    VStack(spacing: 0) {
                        // Hair
                        if userManager.avatarConfig.hairStyle != "none" {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(userManager.avatarConfig.hairColor.color)
                                .frame(width: 110, height: 60)
                                .offset(y: -50)
                        }
                        
                        // Eyes
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                        }
                        .offset(y: -20)
                        
                        // Smile
                        Image(systemName: "mouth.fill")
                            .font(.caption)
                            .foregroundColor(.black)
                            .offset(y: -10)
                    }
                    
                    // Accessory
                    if userManager.avatarConfig.accessory == "crown" {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .offset(y: -60)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                )
                .overlay(
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .background(Circle().fill(.white))
                        .offset(x: 35, y: 35)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Name
            if isEditingName {
                HStack {
                    TextField("Enter your name", text: $tempName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            saveUsername()
                        }
                    
                    Button("Save") {
                        saveUsername()
                    }
                    .font(.caption)
                }
                .frame(maxWidth: 200)
            } else {
                HStack {
                    Text(userManager.username.isEmpty ? "Student" : userManager.username)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        tempName = userManager.username
                        isEditingName = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Premium Badge
            if userManager.isPremium {
                Label("Premium Member", systemImage: "crown.fill")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
        .padding(.vertical)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Problems Solved",
                    value: "\(userManager.totalSolves)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: "+\(userManager.dailySolvesUsed)",
                    trendLabel: "today"
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(userManager.currentStreak) days",
                    icon: "flame.fill",
                    color: .orange,
                    trend: userManager.currentStreak > userManager.longestStreak - 1 ? "🔥" : "+1",
                    trendLabel: "keep going"
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Points",
                    value: "\(userManager.userPoints)",
                    icon: "star.fill",
                    color: .yellow,
                    trend: "+\(userManager.dailySolvesUsed * 10)",
                    trendLabel: "today"
                )
                
                StatCard(
                    title: "Badges Earned",
                    value: "\(userManager.unlockedBadges.count)",
                    icon: "rosette",
                    color: .purple,
                    trend: userManager.lastBadgeUnlocked?.isEmpty == true || userManager.lastBadgeUnlocked == nil ? "" : "NEW",
                    trendLabel: "achievement"
                )
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress & Social")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "trophy.fill",
                    title: "Achievements",
                    value: "\(userManager.unlockedBadges.count) unlocked",
                    color: .yellow
                ) {
                    showingAchievements = true
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "chart.bar.fill",
                    title: "Leaderboard",
                    value: "Compete",
                    color: .purple
                ) {
                    showingLeaderboard = true
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "person.crop.circle.badge.plus",
                    title: "Customize Avatar",
                    value: "Express yourself",
                    color: .blue
                ) {
                    showingAvatarCustomization = true
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
            
            VStack(spacing: 0) {
                if userManager.isPremium {
                    SettingsRow(
                        icon: "crown.fill",
                        title: "Subscription",
                        value: "Active",
                        color: .yellow
                    ) {
                        // Manage subscription
                    }
                } else {
                    SettingsRow(
                        icon: "sparkles",
                        title: "Upgrade to Premium",
                        value: "Unlimited Solves",
                        color: .blue
                    ) {
                        showingPaywall = true
                    }
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Restore Purchases",
                    color: .green
                ) {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Store")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "cart.fill",
                    title: "Power-Ups & Extras",
                    value: "New!",
                    color: .indigo
                ) {
                    showingStore = true
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "sparkles",
                    title: "Extra Solves",
                    value: userManager.isPremium ? "Unlimited" : "\(userManager.solvesRemaining) left",
                    color: .blue
                ) {
                    showingStore = true
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Settings")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    value: "On",
                    color: .red
                ) {
                    // Open notification settings
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "trash.fill",
                    title: "Clear History",
                    color: .red
                ) {
                    showingDeleteConfirmation = true
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    color: .blue
                ) {
                    // Open help
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    color: .gray
                ) {
                    // Open terms
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "lock.fill",
                    title: "Privacy Policy",
                    color: .gray
                ) {
                    // Open privacy policy
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "star.fill",
                    title: "Rate App",
                    color: .yellow
                ) {
                    // Open App Store rating
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func saveUsername() {
        userManager.updateUsername(tempName)
        isEditingName = false
    }
    
    private func getFavoriteSubject() -> String {
        let subjectCounts = Dictionary(grouping: problemStorage.problems, by: { $0.subject })
            .mapValues { $0.count }
        
        if let favorite = subjectCounts.max(by: { $0.value < $1.value }) {
            return favorite.key.rawValue
        }
        
        return "None yet"
    }
    
    private func getMembershipDuration() -> String {
        let firstProblemDate = problemStorage.problems.last?.createdAt ?? Date()
        let days = Calendar.current.dateComponents([.day], from: firstProblemDate, to: Date()).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    let trendLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                if !trend.isEmpty {
                    Text(trend)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !trendLabel.isEmpty && !trend.isEmpty {
                    Spacer()
                    Text(trendLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
        .environmentObject(StoreKitManager())
}