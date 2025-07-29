import Foundation
import SwiftUI

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    let points: Int
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case streak = "Streak Master"
        case solver = "Problem Solver"
        case explorer = "Explorer"
        case social = "Social Learner"
        case special = "Special"
        
        var color: Color {
            switch self {
            case .streak: return .orange
            case .solver: return .blue
            case .explorer: return .purple
            case .social: return .green
            case .special: return .yellow
            }
        }
    }
}

enum AchievementRequirement: Codable {
    case streakDays(Int)
    case totalSolves(Int)
    case solveInRow(Int)
    case subjectsExplored(Int)
    case perfectWeek
    case firstSolve
    case shareScore
    case customizeAvatar
    
    func progress(_ userManager: UserManager) -> (Int, Int) {
        switch self {
        case .streakDays(let days):
            return (userManager.currentStreak, days)
        case .totalSolves(let count):
            return (userManager.totalSolves, count)
        case .solveInRow(let count):
            return (0, count) // Would need tracking
        case .subjectsExplored(let count):
            return (3, count) // Hardcoded for now
        case .perfectWeek:
            let completed = userManager.weeklyProgress.filter { $0 }.count
            return (completed, 7)
        case .firstSolve:
            return (userManager.totalSolves > 0 ? 1 : 0, 1)
        case .shareScore:
            return (0, 1) // Would need tracking
        case .customizeAvatar:
            return (userManager.avatarConfig.accessory != "none" ? 1 : 0, 1)
        }
    }
}

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?
    
    private init() {
        loadAchievements()
    }
    
    private func loadAchievements() {
        achievements = [
            // Streak Achievements
            Achievement(
                id: "streak_3",
                title: "Getting Started",
                description: "Maintain a 3-day streak",
                icon: "flame.fill",
                category: .streak,
                requirement: .streakDays(3),
                points: 50
            ),
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Maintain a 7-day streak",
                icon: "flame.fill",
                category: .streak,
                requirement: .streakDays(7),
                points: 100
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Maintain a 30-day streak",
                icon: "flame.circle.fill",
                category: .streak,
                requirement: .streakDays(30),
                points: 500
            ),
            
            // Solver Achievements
            Achievement(
                id: "first_solve",
                title: "First Steps",
                description: "Solve your first problem",
                icon: "star.fill",
                category: .solver,
                requirement: .firstSolve,
                points: 25
            ),
            Achievement(
                id: "solver_10",
                title: "Problem Solver",
                description: "Solve 10 problems",
                icon: "checkmark.seal.fill",
                category: .solver,
                requirement: .totalSolves(10),
                points: 75
            ),
            Achievement(
                id: "solver_50",
                title: "Math Enthusiast",
                description: "Solve 50 problems",
                icon: "star.circle.fill",
                category: .solver,
                requirement: .totalSolves(50),
                points: 200
            ),
            Achievement(
                id: "solver_100",
                title: "Century Club",
                description: "Solve 100 problems",
                icon: "crown.fill",
                category: .solver,
                requirement: .totalSolves(100),
                points: 500
            ),
            
            // Explorer Achievements
            Achievement(
                id: "explorer_subjects",
                title: "Subject Explorer",
                description: "Try problems from 5 different subjects",
                icon: "book.fill",
                category: .explorer,
                requirement: .subjectsExplored(5),
                points: 150
            ),
            Achievement(
                id: "perfect_week",
                title: "Perfect Week",
                description: "Solve problems every day for a week",
                icon: "calendar.badge.checkmark",
                category: .explorer,
                requirement: .perfectWeek,
                points: 200
            ),
            
            // Social Achievements
            Achievement(
                id: "customize_avatar",
                title: "Express Yourself",
                description: "Customize your avatar",
                icon: "person.crop.circle.badge.plus",
                category: .social,
                requirement: .customizeAvatar,
                points: 50
            ),
            Achievement(
                id: "share_score",
                title: "Proud Learner",
                description: "Share your progress",
                icon: "square.and.arrow.up",
                category: .social,
                requirement: .shareScore,
                points: 75
            ),
            
            // Special Achievements
            Achievement(
                id: "solve_5_row",
                title: "On Fire!",
                description: "Solve 5 problems in a row",
                icon: "flame.circle.fill",
                category: .special,
                requirement: .solveInRow(5),
                points: 150
            )
        ]
    }
    
    func checkAchievements(for userManager: UserManager) {
        for i in 0..<achievements.count {
            guard !achievements[i].isUnlocked else { continue }
            
            let (current, total) = achievements[i].requirement.progress(userManager)
            if current >= total {
                unlockAchievement(at: i, for: userManager)
            }
        }
    }
    
    private func unlockAchievement(at index: Int, for userManager: UserManager) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        recentlyUnlocked = achievements[index]
        
        // Award points
        userManager.awardPoints(achievements[index].points)
        
        // Play celebration
        Task { @MainActor in
            SoundManager.shared.play(.badgeUnlock)
            HapticManager.shared.notification(.success)
        }
        
        // Save to UserDefaults
        userManager.unlockedBadges.insert(achievements[index].id)
        userManager.lastBadgeUnlocked = achievements[index].id
        
        // Clear after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.recentlyUnlocked = nil
        }
    }
}