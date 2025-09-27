import SwiftUI
import UserNotifications
import SheetKit

extension Utilities.System {
    @MainActor
    static func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                SheetKit().present {
                    ErrorView(details: .init(title: "Missing Notification Permission", message: "\(error.localizedDescription)", icon: "bell.slash", showPermissionSettingsButton: true))
                }
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                SheetKit().present {
                    ErrorView(details: .init(title: "Notification Permission Denied", message: "Enable it through your device settings", icon: "bell.slash", showPermissionSettingsButton: true))
                }
                
                // Optional: guide the user to settings to enable notifications
                DispatchQueue.main.async {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings)
                    }
                }
            }
        }
    }
    
    @MainActor
    static func registerForPushNotificationsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                registerForPushNotifications()
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
