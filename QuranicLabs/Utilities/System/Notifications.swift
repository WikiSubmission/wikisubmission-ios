import Foundation
import SwiftUI
import Defaults
import UserNotifications

extension Utilities.System {
    static func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if error != nil {
                Utilities.System.GlobalAlertManager.shared.showAlert(title: "Missing Notifications Permission", systemImage: "bell.slash", type: .error, showSettingsButton: true)
                
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                Utilities.System.GlobalAlertManager.shared.showAlert(title: "Notifications Are Disabled", systemImage: "bell.slash", type: .error, showSettingsButton: true)
            }
        }
    }
    
    static func registerForPushNotificationsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                Task { @MainActor in
                    if UserDefaults.standard.bool(forKey: Defaults.Keys.prompted_for_notifications.name) {
                        registerForPushNotifications()
                    }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied, .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }
}
