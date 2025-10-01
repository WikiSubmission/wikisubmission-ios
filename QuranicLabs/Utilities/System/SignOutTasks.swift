import Foundation
import Defaults

extension Utilities.System {
    static func signOutTasks() async {
        // Sync bookmarks
        if UserDefaults.standard.bool(forKey: Defaults.Keys.bookmarked_synced.name) == false {
            Task {
                try? await Utilities.Bookmarks.syncWithDatabase()
            }
        }
    }
}
