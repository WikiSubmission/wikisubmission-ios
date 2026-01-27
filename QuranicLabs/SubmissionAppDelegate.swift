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
    
    // Handle deep links when notification is tapped
    private func handleNotificationTap(userInfo: [AnyHashable: Any], category: String?) {
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
