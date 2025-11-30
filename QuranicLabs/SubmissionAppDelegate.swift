import UIKit
import SwiftUI
import UserNotifications
import Defaults
import SheetKit
import Combine

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private var pendingNotificationLaunch: ([AnyHashable: Any], String?)?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Check for notification that launched the app
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            let category = notification["category"] as? String
            // Store this to handle after app setup is complete
            self.pendingNotificationLaunch = (notification, category)
        }
        // Add observer to process when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(processPendingNotificationIfNeeded),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        UserDefaults.standard.set(token, forKey: Defaults.Keys.device_token.name)
        print("Device Token: \(token)")
        
        Task {
            try? await Utilities.Notifications.syncWithDatabase()
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications:", error)
    }
    
    // Handle notifications when app is in FOREGROUND
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let category = notification.request.content.categoryIdentifier
        
        // Only update UserDefaults, don't trigger deep links when in foreground
        updateUserDefaultsFromNotification(userInfo: userInfo, category: category)
        
        completionHandler([.banner, .sound])
    }
    
    // Handle notification TAPS (background or foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let category = response.notification.request.content.categoryIdentifier
        
        // Only trigger deep links when user actually taps the notification
        handleNotificationTap(userInfo: userInfo, category: category)
        
        completionHandler()
    }
    
    // Update UserDefaults from notification payload
    private func updateUserDefaultsFromNotification(userInfo: [AnyHashable: Any], category: String?) {
        let actualCategory = category ?? (userInfo["category"] as? String)
                
        if let verseId = (userInfo["verse_id"] as? String) ?? (userInfo["verse_id"] as? Int).map({ "\($0)" }) {
            if actualCategory == "daily_verse" {
                UserDefaults.standard.set(verseId, forKey: Defaults.Keys.daily_verse.name)
            }
        }
        
        if let chapterNumber = (userInfo["chapter_number"] as? Int) ?? (userInfo["chapter_number"] as? String).flatMap({ Int($0) }) {
            if actualCategory == "daily_chapter" {
                UserDefaults.standard.set(chapterNumber, forKey: Defaults.Keys.daily_chapter.name)
            }
        }
    }
    
    // Handle deep links when notification is tapped
    private func handleNotificationTap(userInfo: [AnyHashable: Any], category: String?) {
        updateUserDefaultsFromNotification(userInfo: userInfo, category: category)
        
        // Handle deep link
        guard let deepLink = userInfo["deepLink"] as? String,
              let url = URL(string: deepLink),
              url.scheme == "wikisubmission" else { return }
        
        // Post notification to trigger deep link after a delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: .deepLinkTriggered,
                object: nil,
                userInfo: ["url": url]
            )
        }
    }
    
    @objc private func processPendingNotificationIfNeeded() {
        guard let (userInfo, category) = pendingNotificationLaunch else { return }
        
        // Handle the notification tap that launched the app
        handleNotificationTap(userInfo: userInfo, category: category)
        
        pendingNotificationLaunch = nil
        
        // Remove observer after processing
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
}

extension Notification.Name {
    static let deepLinkTriggered = Notification.Name("deepLinkTriggered")
}
