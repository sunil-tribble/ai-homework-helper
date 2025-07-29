import SwiftUI

@main
@available(iOS 17.0, *)
struct AIHomeworkHelperApp: App {
    @StateObject private var storeManager = StoreKitManager()
    @StateObject private var userManager = UserManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Apply theme customization at app launch
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .environmentObject(userManager)
                .environmentObject(notificationManager)
                .onAppear {
                    // Reset daily count if needed
                    userManager.checkAndResetDailyCount()
                    
                    // Request notification permissions
                    notificationManager.requestAuthorization()
                    
                    // Clear badge when app opens
                    notificationManager.clearBadge()
                }
                // TODO: Add OnboardingView once all files are properly added to Xcode project
                // The OnboardingView.swift file exists in Views/ but needs to be added to the target
            .preferredColorScheme(userManager.selectedTheme == .neon ? .dark : nil)
        }
    }
}