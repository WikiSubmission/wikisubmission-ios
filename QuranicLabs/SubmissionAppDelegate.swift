import UIKit
import SwiftUI
import UserNotifications
import SheetKit
import Defaults

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        UserDefaults.standard.set(token, forKey: "device_token")
        print("Device Token: \(token)")
        
        // TODO: Send token to your server along with the user's latest city
        Task {
            try? await Utilities.Supabase.NotificationsTable.syncWithServer()
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications:", error)
    }
    
    // Optional: handle notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Called when user taps on a notification
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier
        
        print("Tapped \(category) notification")
                
        let userInfo = response.notification.request.content.userInfo
                
        if category == "PRAYER_TIMES" {
            SheetKit().present {
                PrayerTimesView()
            }
        }
        
        if let verseId = userInfo["verse_id"] as? String {
            
            print("Tapped on verse \(verseId)")
            
            if category == "DAILY_VERSE" {
                Defaults[.daily_verse] = verseId
            }
        }
        
        if let chapterNumber = userInfo["chapter_number"] as? Int {
            if category == "DAILY_CHAPTER" {
                Defaults[.daily_chapter] = chapterNumber
            }
        }
        
        if let deepLink = userInfo["deepLink"] as? String, let url = URL(string: deepLink) {
            UIApplication.shared.open(url)
        }
        
        completionHandler()
    }
}
