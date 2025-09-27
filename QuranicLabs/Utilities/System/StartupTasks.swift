import Foundation
import Defaults

extension Utilities.System {
    static func startupTasks() async {
        Task {
            if UserDefaults.standard.bool(forKey: Defaults.Keys.prompted_for_notifications.name) {
                await Utilities.System.registerForPushNotificationsIfNeeded()
            }
        }
    }
}
