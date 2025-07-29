import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var problemStorage = ProblemStorage.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange = TimeRange.week
    @State private var animateCharts = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time range selector
                        timeRangeSelector
                        
                        // Stats Overview
                        statsOverview
                        
                        // Activity Chart
                        activityChart
                        
                        // Subject Distribution
                        subjectDistribution
                        
                        // Learning Insights
                        learningInsights
                        
                        // Achievement Progress
                        achievementProgress
                    }
                    .padding()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateCharts = true
                }
            }
            .navigationTitle("Progress Dashboard")
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
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var statsOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            DashboardStatCard(
                title: "Total Solves",
                value: "\(userManager.totalSolves)",
                icon: "checkmark.circle.fill",
                color: .green,
                trend: "+\(getWeeklySolves())",
                trendLabel: "this week"
            )
            
            DashboardStatCard(
                title: "Current Streak",
                value: "\(userManager.currentStreak)",
                icon: "flame.fill",
                color: .orange,
                trend: userManager.streakStatus == .completed ? "Active" : "Build it!",
                trendLabel: userManager.streakStatus == .completed ? "today ✓" : ""
            )
            
            DashboardStatCard(
                title: "Points Earned",
                value: "\(userManager.userPoints)",
                icon: "star.fill",
                color: .yellow,
                trend: "+\(getWeeklyPoints())",
                trendLabel: "this week"
            )
            
            DashboardStatCard(
                title: "Badges",
                value: "\(userManager.unlockedBadges.count)",
                icon: "rosette",
                color: .purple,
                trend: "\(getRecentBadges())",
                trendLabel: "new this week"
            )
        }
    }
    
    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Overview")
                .font(.headline)
            
            // Weekly activity heatmap
            VStack(spacing: 12) {
                HStack {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Last 4 weeks
                ForEach(0..<4, id: \.self) { week in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            ActivityCell(
                                intensity: getActivityIntensity(week: week, day: day),
                                isToday: isToday(week: week, day: day)
                            )
                            .opacity(animateCharts ? 1 : 0)
                            .animation(.easeOut.delay(Double(week * 7 + day) * 0.02), value: animateCharts)
                        }
                    }
                }
                
                // Legend
                HStack {
                    Text("Less")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { level in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(activityColor(for: Double(level) / 4.0))
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var subjectDistribution: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Distribution")
                .font(.headline)
            
            let subjectCounts = getSubjectDistribution()
            
            VStack(spacing: 12) {
                ForEach(subjectCounts.sorted(by: { $0.value > $1.value }), id: \.key) { subject, count in
                    HStack {
                        Image(systemName: subject.icon)
                            .foregroundColor(subject.color)
                            .frame(width: 30)
                        
                        Text(subject.rawValue)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(subject.color.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(subject.color)
                                        .frame(width: geometry.size.width * (Double(count) / Double(userManager.totalSolves)))
                                        .animation(.spring(), value: animateCharts),
                                    alignment: .leading
                                )
                        }
                        .frame(width: 100, height: 8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var learningInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Insights")
                .font(.headline)
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "lightbulb.fill",
                    title: "Best Time to Study",
                    value: getBestStudyTime(),
                    color: .yellow
                )
                
                InsightRow(
                    icon: "target",
                    title: "Success Rate",
                    value: "\(Int(getSuccessRate()))%",
                    color: .green
                )
                
                InsightRow(
                    icon: "timer",
                    title: "Avg. Daily Solves",
                    value: "\(getAverageDailySolves())",
                    color: .blue
                )
                
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Learning Trend",
                    value: getLearningTrend(),
                    color: .purple
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var achievementProgress: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Next Achievements")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AchievementDisplayView().environmentObject(userManager)) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                // Next streak milestone
                if let nextStreakMilestone = getNextStreakMilestone() {
                    AchievementProgressRow(
                        icon: "flame.fill",
                        title: "\(nextStreakMilestone)-Day Streak",
                        current: userManager.currentStreak,
                        total: nextStreakMilestone,
                        color: .orange
                    )
                }
                
                // Next solve milestone
                if let nextSolveMilestone = getNextSolveMilestone() {
                    AchievementProgressRow(
                        icon: "star.fill",
                        title: "\(nextSolveMilestone) Total Solves",
                        current: userManager.totalSolves,
                        total: nextSolveMilestone,
                        color: .blue
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // Helper functions
    private func getWeeklySolves() -> Int {
        // Calculate solves in the last 7 days
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return problemStorage.problems.filter { $0.createdAt > weekAgo }.count
    }
    
    private func getWeeklyPoints() -> Int {
        // Estimate based on weekly solves
        return getWeeklySolves() * 15 // Average points per solve
    }
    
    private func getRecentBadges() -> Int {
        // This would need tracking of badge unlock dates
        return userManager.lastBadgeUnlocked != nil ? 1 : 0
    }
    
    private func getActivityIntensity(week: Int, day: Int) -> Double {
        // Simulate activity data - in real app, track actual daily solves
        if week == 0 && day < 3 {
            return Double.random(in: 0.3...1.0)
        }
        return Double.random(in: 0...1.0)
    }
    
    private func isToday(week: Int, day: Int) -> Bool {
        if week == 0 {
            let calendar = Calendar.current
            let today = calendar.component(.weekday, from: Date()) - 1
            return day == today
        }
        return false
    }
    
    private func activityColor(for intensity: Double) -> Color {
        if intensity == 0 { return Color.gray.opacity(0.1) }
        if intensity < 0.25 { return Color.green.opacity(0.3) }
        if intensity < 0.5 { return Color.green.opacity(0.5) }
        if intensity < 0.75 { return Color.green.opacity(0.7) }
        return Color.green
    }
    
    private func getSubjectDistribution() -> [Subject: Int] {
        var distribution: [Subject: Int] = [:]
        for problem in problemStorage.problems {
            distribution[problem.subject, default: 0] += 1
        }
        return distribution
    }
    
    private func getBestStudyTime() -> String {
        // In real app, analyze solve timestamps
        return "3-5 PM"
    }
    
    private func getSuccessRate() -> Double {
        // All problems have solutions in this app
        return 100.0
    }
    
    private func getAverageDailySolves() -> Double {
        guard userManager.totalSolves > 0 else { return 0 }
        // Estimate based on total solves and account age
        return Double(userManager.totalSolves) / max(1, Double(userManager.longestStreak))
    }
    
    private func getLearningTrend() -> String {
        let recent = getWeeklySolves()
        if recent > 10 { return "Excellent ↑" }
        if recent > 5 { return "Good →" }
        return "Keep going!"
    }
    
    private func getNextStreakMilestone() -> Int? {
        let milestones = [3, 7, 14, 30, 50, 100]
        return milestones.first { $0 > userManager.currentStreak }
    }
    
    private func getNextSolveMilestone() -> Int? {
        let milestones = [10, 25, 50, 100, 250, 500, 1000]
        return milestones.first { $0 > userManager.totalSolves }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    let trendLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !trend.isEmpty {
                HStack(spacing: 4) {
                    Text(trend)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                    
                    if !trendLabel.isEmpty {
                        Text(trendLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.5), color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

struct ActivityCell: View {
    let intensity: Double
    let isToday: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(activityColor)
            .frame(height: 30)
            .overlay(
                isToday ? 
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.purple, lineWidth: 2) : nil
            )
    }
    
    private var activityColor: Color {
        if intensity == 0 { return Color.gray.opacity(0.1) }
        if intensity < 0.25 { return Color.green.opacity(0.3) }
        if intensity < 0.5 { return Color.green.opacity(0.5) }
        if intensity < 0.75 { return Color.green.opacity(0.7) }
        return Color.green
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct AchievementProgressRow: View {
    let icon: String
    let title: String
    let current: Int
    let total: Int
    let color: Color
    
    private var progress: Double {
        Double(current) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(current)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    ProgressDashboardView()
        .environmentObject(UserManager())
}