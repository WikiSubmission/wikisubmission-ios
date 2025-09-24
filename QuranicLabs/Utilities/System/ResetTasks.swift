import Foundation
import Defaults
import Clerk

extension Utilities.System {
    static func resetTasks() async {
        Task {
            // Run sign out tasks
            await Utilities.System.signOutTasks()
            
            // Sign out
            try? await Clerk.shared.signOut()
            
            // Clear prayer times
            await AppEnvironment.shared.PrayerTimesManager.removeSavedCity()
            
            // Reset all Defaults keys (including onboarded)
            Defaults.removeAll()
        }
    }
}
