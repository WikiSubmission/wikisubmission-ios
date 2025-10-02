import Foundation
import Defaults

extension Utilities.System {
    static func startupTasks() async {
        // Sync bookmarks with iCloud (if needed, e.g. reinstalled app)
        Utilities.Bookmarks.syncLocalBookmarksWithICloud()
        
        // Keep updating iCloud version with Defaults (source of truth)
        Utilities.Bookmarks.startICloudObserver()
        
        // Register for push notifications (if applicable)
        Utilities.System.registerForPushNotificationsIfNeeded()
    }
}
