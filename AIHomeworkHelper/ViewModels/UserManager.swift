import Foundation
import SwiftUI

class UserManager: ObservableObject {
    @Published var dailySolvesUsed: Int = 0
    @Published var isPremium: Bool = false
    @Published var username: String = ""
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastSolveDate: Date?
    @Published var totalSolves: Int = 0
    @Published var weeklyProgress: [Bool] = Array(repeating: false, count: 7)
    @Published var showStreakCelebration = false
    @Published var userPoints: Int = 0
    @Published var unlockedBadges: Set<String> = []
    @Published var lastBadgeUnlocked: String?
    @Published var avatarConfig = AvatarConfiguration()
    @Published var selectedTheme: AppTheme = .default
    @Published var hasSeenOnboarding = false
    @Published var hasSeenEthicalNudge = false
    @Published var hasEnabledNotifications = false
    @Published var dailyGoal = 3
    @Published var reminderTime = Date()
    @Published var weeklyStreakGoal = 5
    @Published var monthlyGoal = 20
    @Published var extraSolves: Int = 0
    
    private let userDefaults = UserDefaults.standard
    
    var solvesRemaining: Int {
        isPremium ? 999 : max(0, (5 + extraSolves) - dailySolvesUsed)
    }
    
    var canSolve: Bool {
        isPremium || solvesRemaining > 0
    }
    
    var streakStatus: StreakStatus {
        if currentStreak == 0 {
            return .notStarted
        } else if Calendar.current.isDateInToday(lastSolveDate ?? Date()) {
            return .completed
        } else if Calendar.current.isDateInYesterday(lastSolveDate ?? Date()) {
            return .inProgress
        } else {
            return .broken
        }
    }
    
    init() {
        loadUserData()
        updateDailyProgress()
        checkForMissedStreak()
    }
    
    func incrementDailySolves() {
        dailySolvesUsed += 1
        totalSolves += 1
        updateStreak()
        updateWeeklyProgress()
        saveUserData()
        
        // Award points
        awardPoints(10)
        
        // Check achievements
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Achievement checking happens in AchievementManager
        }
    }
    
    func resetDailySolves() {
        guard !Calendar.current.isDateInToday(lastSolveDate ?? Date()) else { return }
        dailySolvesUsed = 0
        saveUserData()
    }
    
    func checkAndResetDailyCount() {
        resetDailySolves()
    }
    
    func incrementSolveCount() {
        incrementDailySolves()
    }
    
    func upgradeToPremium() {
        isPremium = true
        saveUserData()
    }
    
    func updateUsername(_ name: String) {
        username = name
        saveUserData()
    }
    
    func updateAvatar(base: String? = nil, hairStyle: String? = nil, hairColor: Color? = nil, 
                      skinTone: Color? = nil, accessory: String? = nil, 
                      background: String? = nil, theme: AppTheme? = nil) {
        // Update avatar configuration
        // Note: This is a simplified update since the actual properties might differ
        if let accessory = accessory {
            avatarConfig.accessory = accessory
        }
        if let hairStyle = hairStyle {
            avatarConfig.hairStyle = hairStyle
        }
        if let theme = theme {
            selectedTheme = theme
        }
        
        saveUserData()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        if let lastDate = lastSolveDate {
            if calendar.isDateInToday(lastDate) {
                // Already solved today, no streak update needed
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // Continuing streak
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First solve
            currentStreak = 1
        }
        
        lastSolveDate = today
        longestStreak = max(longestStreak, currentStreak)
        
        // Check for streak milestones
        checkStreakMilestones()
    }
    
    private func checkForMissedStreak() {
        guard let lastDate = lastSolveDate else { return }
        
        let calendar = Calendar.current
        let daysSinceLastSolve = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        
        if daysSinceLastSolve > 1 {
            // Streak was broken
            currentStreak = 0
        }
    }
    
    private func updateWeeklyProgress() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) - 1 // 0-6
        
        // Reset weekly progress on Sunday if it's a new week
        if weekday == 0 && !weeklyProgress[0] {
            weeklyProgress = Array(repeating: false, count: 7)
        }
        
        weeklyProgress[weekday] = true
        updateDailyProgress()
    }
    
    private func updateDailyProgress() {
        let calendar = Calendar.current
        let today = Date()
        
        // Check if we've already marked today
        if let lastDate = lastSolveDate, calendar.isDateInToday(lastDate) {
            let weekday = calendar.component(.weekday, from: today) - 1
            weeklyProgress[weekday] = true
        }
    }
    
    private func checkStreakMilestones() {
        switch currentStreak {
        case 3, 7, 14, 30, 50, 100:
            showStreakCelebration = true
            awardPoints(currentStreak * 10)
            
            // Schedule notification
            NotificationManager.shared.scheduleStreakCelebration(streak: currentStreak)
            
            // Play celebration
            Task { @MainActor in
                SoundManager.shared.play(.streakCelebration)
                HapticManager.shared.playStreakCelebration()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showStreakCelebration = false
            }
        default:
            break
        }
    }
    
    func awardPoints(_ points: Int) {
        userPoints += points
        saveUserData()
        
        // Visual feedback
        Task { @MainActor in
            HapticManager.shared.impact(.light)
            SoundManager.shared.play(.pointsEarned)
        }
    }
    
    // MARK: - Persistence
    
    private func loadUserData() {
        isPremium = userDefaults.bool(forKey: "isPremium")
        username = userDefaults.string(forKey: "username") ?? ""
        dailySolvesUsed = userDefaults.integer(forKey: "dailySolvesUsed")
        currentStreak = userDefaults.integer(forKey: "currentStreak")
        longestStreak = userDefaults.integer(forKey: "longestStreak")
        totalSolves = userDefaults.integer(forKey: "totalSolves")
        userPoints = userDefaults.integer(forKey: "userPoints")
        hasSeenOnboarding = userDefaults.bool(forKey: "hasSeenOnboarding")
        hasSeenEthicalNudge = userDefaults.bool(forKey: "hasSeenEthicalNudge")
        hasEnabledNotifications = userDefaults.bool(forKey: "hasEnabledNotifications")
        dailyGoal = userDefaults.integer(forKey: "dailyGoal") == 0 ? 3 : userDefaults.integer(forKey: "dailyGoal")
        weeklyStreakGoal = userDefaults.integer(forKey: "weeklyStreakGoal") == 0 ? 5 : userDefaults.integer(forKey: "weeklyStreakGoal")
        monthlyGoal = userDefaults.integer(forKey: "monthlyGoal") == 0 ? 20 : userDefaults.integer(forKey: "monthlyGoal")
        extraSolves = userDefaults.integer(forKey: "extraSolves")
        
        if let lastSolveDateTimestamp = userDefaults.object(forKey: "lastSolveDate") as? TimeInterval {
            lastSolveDate = Date(timeIntervalSince1970: lastSolveDateTimestamp)
        }
        
        if let savedBadges = userDefaults.array(forKey: "unlockedBadges") as? [String] {
            unlockedBadges = Set(savedBadges)
        }
        
        if let progressData = userDefaults.array(forKey: "weeklyProgress") as? [Bool] {
            weeklyProgress = progressData
        }
        
        if let avatarData = userDefaults.data(forKey: "avatarConfig"),
           let config = try? JSONDecoder().decode(AvatarConfiguration.self, from: avatarData) {
            avatarConfig = config
        }
        
        if let themeRawValue = userDefaults.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: themeRawValue) {
            selectedTheme = theme
        }
        
        if let reminderTimeInterval = userDefaults.object(forKey: "reminderTime") as? TimeInterval {
            reminderTime = Date(timeIntervalSince1970: reminderTimeInterval)
        }
        
        // Reset daily solves if it's a new day
        resetDailySolves()
    }
    
    private func saveUserData() {
        userDefaults.set(isPremium, forKey: "isPremium")
        userDefaults.set(username, forKey: "username")
        userDefaults.set(dailySolvesUsed, forKey: "dailySolvesUsed")
        userDefaults.set(currentStreak, forKey: "currentStreak")
        userDefaults.set(longestStreak, forKey: "longestStreak")
        userDefaults.set(totalSolves, forKey: "totalSolves")
        userDefaults.set(userPoints, forKey: "userPoints")
        userDefaults.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        userDefaults.set(hasSeenEthicalNudge, forKey: "hasSeenEthicalNudge")
        userDefaults.set(hasEnabledNotifications, forKey: "hasEnabledNotifications")
        userDefaults.set(dailyGoal, forKey: "dailyGoal")
        userDefaults.set(weeklyStreakGoal, forKey: "weeklyStreakGoal")
        userDefaults.set(monthlyGoal, forKey: "monthlyGoal")
        userDefaults.set(extraSolves, forKey: "extraSolves")
        userDefaults.set(Array(unlockedBadges), forKey: "unlockedBadges")
        userDefaults.set(weeklyProgress, forKey: "weeklyProgress")
        userDefaults.set(selectedTheme.rawValue, forKey: "selectedTheme")
        userDefaults.set(reminderTime.timeIntervalSince1970, forKey: "reminderTime")
        
        if let lastDate = lastSolveDate {
            userDefaults.set(lastDate.timeIntervalSince1970, forKey: "lastSolveDate")
        }
        
        if let avatarData = try? JSONEncoder().encode(avatarConfig) {
            userDefaults.set(avatarData, forKey: "avatarConfig")
        }
    }
}

// MARK: - Supporting Types

struct AvatarConfiguration: Codable {
    var skinTone: SkinTone = .medium
    var hairStyle: String = "short"
    var hairColor: HairColor = .brown
    var accessory: String = "none"
    var outfit: String = "casual"
    
    enum SkinTone: String, CaseIterable, Codable {
        case light, medium, dark
        
        var color: Color {
            switch self {
            case .light: return Color(red: 1.0, green: 0.9, blue: 0.8)
            case .medium: return Color(red: 0.9, green: 0.7, blue: 0.6)
            case .dark: return Color(red: 0.6, green: 0.4, blue: 0.3)
            }
        }
    }
    
    enum HairColor: String, CaseIterable, Codable {
        case black, brown, blonde, red, gray
        
        var color: Color {
            switch self {
            case .black: return .black
            case .brown: return Color(red: 0.4, green: 0.2, blue: 0.1)
            case .blonde: return Color(red: 1.0, green: 0.9, blue: 0.5)
            case .red: return Color(red: 0.8, green: 0.3, blue: 0.1)
            case .gray: return .gray
            }
        }
    }
}

enum StreakStatus {
    case notStarted
    case broken
    case inProgress
    case completed
    
    var color: Color {
        switch self {
        case .notStarted, .broken:
            return .gray
        case .inProgress:
            return .orange
        case .completed:
            return .green
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted:
            return "flame.circle"
        case .broken:
            return "flame.slash.circle"
        case .inProgress:
            return "flame.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}