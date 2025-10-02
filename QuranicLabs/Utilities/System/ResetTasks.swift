import Foundation
import Defaults

extension Utilities.System {
    static func resetTasks() async {
        Task {
            // Clear prayer times
            AppEnvironment.shared.PrayerTimesManager.removeSavedCity()
            
            // Reset necassary Defaults keys (including onboarded)
            Defaults.resetOnboardedState()
            Defaults.resetQuranPreferences()
            Defaults.resetPrayerTimeSettings()
        }
    }
}
