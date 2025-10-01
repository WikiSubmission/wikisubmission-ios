import Foundation
import Defaults

extension Utilities.System {
    static func startupTasks() async {
        Task {
            // Register for push notifications, if needed.
            if UserDefaults.standard.bool(forKey: Defaults.Keys.prompted_for_notifications.name) {
                await Utilities.System.registerForPushNotificationsIfNeeded()
            }
            
            // Sync bookmarks, if needed, and possible.
            if UserDefaults.standard.bool(forKey: Defaults.Keys.bookmarked_synced.name) && Utilities.System.NetworkMonitor.shared.hasInternet {
                try? await Utilities.Bookmarks.syncWithDatabase()
            }
        }
    }
}
