import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleStreakReminders()
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleStreakReminders() {
        // Remove existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Morning reminder - 8 AM
        scheduleDailyNotification(
            identifier: "morning-streak",
            title: "🌅 Start Your Day Right!",
            body: "Keep your streak alive with a morning solve",
            hour: 8,
            minute: 0
        )
        
        // Afternoon reminder - 3 PM
        scheduleDailyNotification(
            identifier: "afternoon-streak",
            title: "📚 Homework Time!",
            body: "Don't forget to maintain your \(UserManager().currentStreak)-day streak",
            hour: 15,
            minute: 0
        )
        
        // Evening reminder - 8 PM
        scheduleDailyNotification(
            identifier: "evening-streak",
            title: "🔥 Streak at Risk!",
            body: "Complete today's solve before midnight to keep your streak",
            hour: 20,
            minute: 0
        )
    }
    
    private func scheduleDailyNotification(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleStreakCelebration(streak: Int) {
        let content = UNMutableNotificationContent()
        
        switch streak {
        case 3:
            content.title = "🎉 3-Day Streak!"
            content.body = "You're building a great habit! Keep it up!"
        case 7:
            content.title = "🔥 One Week Strong!"
            content.body = "Amazing dedication! You've unlocked a new badge!"
        case 14:
            content.title = "💪 Two Week Warrior!"
            content.body = "You're unstoppable! Check out your new rewards!"
        case 30:
            content.title = "🏆 30-Day Legend!"
            content.body = "Incredible achievement! You've earned exclusive rewards!"
        case 50:
            content.title = "⭐ 50-Day Superstar!"
            content.body = "You're in the top 1% of learners! Amazing!"
        case 100:
            content.title = "👑 100-DAY GENIUS!"
            content.body = "Legendary status achieved! You're truly exceptional!"
        default:
            return
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.mp3"))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak-celebration-\(streak)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func scheduleUpgradeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📚 You're Out of Solves!"
        content.body = "Upgrade to Premium for unlimited homework help"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "upgrade-reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Error clearing badge: \(error)")
                }
            }
        }
    }
}