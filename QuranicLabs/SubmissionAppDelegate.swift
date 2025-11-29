import UIKit
import SwiftUI
import UserNotifications
import Defaults
import SheetKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Check for notification that launched the app
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            let category = notification["category"] as? String
            // Store this to handle after app setup is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                self.handleNotification(userInfo: notification, category: category)
            }
        }
        
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let category = notification.request.content.categoryIdentifier
        handleNotification(userInfo: userInfo, category: category)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let category = response.notification.request.content.categoryIdentifier
        handleNotification(userInfo: userInfo, category: category)
        completionHandler()
    }
    
    private func handleNotification(userInfo: [AnyHashable: Any], category: String?) {
        // Try to get category from parameter first, then from payload
        let actualCategory = category ?? (userInfo["category"] as? String)
                
        if let verseId = (userInfo["verse_id"] as? String) ?? (userInfo["verse_id"] as? Int).map({ "\($0)" }) {
            if actualCategory == "daily_verse" {
                print("Setting daily verse to \(verseId)")
                UserDefaults.standard.set(verseId, forKey: Defaults.Keys.daily_verse.name)
            }
        }
        
        if let chapterNumber = (userInfo["chapter_number"] as? Int) ?? (userInfo["chapter_number"] as? String).flatMap({ Int($0) }) {
            if actualCategory == "daily_chapter" {
                print("Setting daily chapter to \(chapterNumber)")
                UserDefaults.standard.set(chapterNumber, forKey: Defaults.Keys.daily_chapter.name)
            }
        }

        if let deepLink = userInfo["deepLink"] as? String, let url = URL(string: deepLink) {
            if deepLink == "wikisubmission://prayer-times" && Defaults[.active_tab] != .prayer {
                Defaults[.active_tab] = .prayer
            }
            
            guard url.scheme == "wikisubmission" else { return }
            
            if url.host == "verse" {
                Defaults[.active_tab] = .home
                let verseId = url.lastPathComponent
                let chapter = Int(verseId.split(separator: ":")[0]) ?? 1
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(
                            chapter: chapter,
                            scrollToVerseID: verseId
                        )
                    }
                }
            } else if url.host == "chapter" {
                Defaults[.active_tab] = .home
                let chapterNumber = Int(url.lastPathComponent) ?? 1
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(
                            chapter: chapterNumber
                        )
                    }
                }
            }
        }
    }
}
