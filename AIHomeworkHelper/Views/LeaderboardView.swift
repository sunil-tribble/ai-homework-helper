import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeFrame = TimeFrame.weekly
    @State private var leaderboardData: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var userRank: Int?
    @State private var animateRows = false
    
    enum TimeFrame: String, CaseIterable {
        case daily = "Today"
        case weekly = "This Week"
        case monthly = "This Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Time frame selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedTimeFrame) {
                        HapticManager.shared.selection()
                    }
                    
                    if isLoading {
                        ProgressView("Loading rankings...")
                            .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // User's rank card
                                if let rank = userRank {
                                    userRankCard(rank: rank)
                                }
                                
                                // Top 3 podium
                                if leaderboardData.count >= 3 {
                                    podiumView
                                }
                                
                                // Rest of leaderboard
                                ForEach(Array(leaderboardData.enumerated()), id: \.element.id) { index, entry in
                                    if index >= 3 {
                                        LeaderboardRow(
                                            entry: entry,
                                            rank: index + 1,
                                            isCurrentUser: entry.isCurrentUser
                                        )
                                        .transition(.slide)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index - 2) * 0.05), value: animateRows)
                                        .opacity(animateRows ? 1 : 0)
                                        .offset(x: animateRows ? 0 : 50)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .onAppear {
                loadLeaderboardData()
                withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                    animateRows = true
                }
            }
            .onChange(of: selectedTimeFrame) {
                loadLeaderboardData()
            }
            .navigationTitle("Leaderboard")
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
    
    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 20) {
            // Second place
            if leaderboardData.count > 1 {
                PodiumPlace(
                    entry: leaderboardData[1],
                    rank: 2,
                    height: 120
                )
            }
            
            // First place
            if !leaderboardData.isEmpty {
                PodiumPlace(
                    entry: leaderboardData[0],
                    rank: 1,
                    height: 150
                )
            }
            
            // Third place
            if leaderboardData.count > 2 {
                PodiumPlace(
                    entry: leaderboardData[2],
                    rank: 3,
                    height: 100
                )
            }
        }
        .padding(.vertical)
    }
    
    private func userRankCard(rank: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Ranking")
                    .font(.headline)
                
                HStack {
                    Text("#\(rank)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("with \(userManager.userPoints) points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: getRankIcon(for: rank))
                .font(.largeTitle)
                .foregroundColor(getRankColor(for: rank))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.purple.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private func loadLeaderboardData() {
        isLoading = true
        
        // Simulate loading data - in production, fetch from Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Generate sample data
            var data: [LeaderboardEntry] = []
            
            // Add current user
            let currentUserEntry = LeaderboardEntry(
                id: "current_user",
                username: userManager.username.isEmpty ? "You" : userManager.username,
                points: userManager.userPoints,
                solveCount: userManager.totalSolves,
                streak: userManager.currentStreak,
                isCurrentUser: true,
                avatarIcon: "person.circle.fill"
            )
            data.append(currentUserEntry)
            
            // Add sample competitors
            let sampleNames = ["MathWiz", "StudyPro", "QuizMaster", "BrainStorm", "Scholar101", 
                             "AceStudent", "SmartCookie", "BookWorm", "Einstein Jr", "TopGrade"]
            
            for i in 0..<10 {
                data.append(LeaderboardEntry(
                    id: "user_\(i)",
                    username: sampleNames[i],
                    points: Int.random(in: 500...5000),
                    solveCount: Int.random(in: 50...500),
                    streak: Int.random(in: 0...30),
                    isCurrentUser: false,
                    avatarIcon: "person.circle.fill"
                ))
            }
            
            // Sort by points
            data.sort { $0.points > $1.points }
            
            // Find user rank
            if let index = data.firstIndex(where: { $0.isCurrentUser }) {
                userRank = index + 1
            }
            
            leaderboardData = data
            isLoading = false
        }
    }
    
    private func getRankIcon(for rank: Int) -> String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "rosette"
        case 4...10: return "star.fill"
        default: return "circle.fill"
        }
    }
    
    private func getRankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        case 4...10: return .blue
        default: return .gray
        }
    }
}

struct LeaderboardEntry {
    let id: String
    let username: String
    let points: Int
    let solveCount: Int
    let streak: Int
    let isCurrentUser: Bool
    let avatarIcon: String
}

struct PodiumPlace: View {
    let entry: LeaderboardEntry
    let rank: Int
    let height: CGFloat
    @State private var animateIn = false
    
    private var medalColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(entry.isCurrentUser ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: entry.avatarIcon)
                    .font(.title)
                    .foregroundColor(.white)
                
                // Medal overlay
                Image(systemName: "medal.fill")
                    .font(.caption)
                    .foregroundColor(medalColor)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    )
                    .offset(x: 20, y: 20)
            }
            
            Text(entry.username)
                .font(.caption)
                .fontWeight(entry.isCurrentUser ? .bold : .medium)
                .lineLimit(1)
            
            Text("\(entry.points)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Podium
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [medalColor, medalColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: height)
                
                Text("\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
        }
        .scaleEffect(animateIn ? 1 : 0.5)
        .opacity(animateIn ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6)
                .delay(Double(3 - rank) * 0.15),
            value: animateIn
        )
        .onAppear {
            animateIn = true
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(isCurrentUser ? .purple : .secondary)
                .frame(width: 40)
            
            // Avatar
            Image(systemName: entry.avatarIcon)
                .font(.title2)
                .foregroundColor(isCurrentUser ? .purple : .gray)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isCurrentUser ? Color.purple.opacity(0.1) : Color.gray.opacity(0.1))
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.username)
                    .font(.subheadline)
                    .fontWeight(isCurrentUser ? .bold : .medium)
                
                HStack(spacing: 12) {
                    Label("\(entry.points)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Label("\(entry.streak)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if isCurrentUser {
                Text("YOU")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.purple.opacity(0.05) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCurrentUser ? Color.purple.opacity(0.3) : Color.clear,
                            lineWidth: isCurrentUser ? 2 : 0
                        )
                )
        )
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(UserManager())
}