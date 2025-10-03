import Foundation
import Defaults
import AVFoundation

extension Utilities.System {
    static func startupTasks() async {
        // Sync bookmarks with iCloud (if needed, e.g. reinstalled app)
        Utilities.Bookmarks.syncLocalBookmarksWithICloud()
        
        // Keep updating iCloud version with Defaults (source of truth)
        Utilities.Bookmarks.startICloudObserver()
        
        // Register for push notifications (if applicable)
        Utilities.System.registerForPushNotificationsIfNeeded()
        
        // Configure audio instance
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }
    }
}
