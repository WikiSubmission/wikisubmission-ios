import Foundation
import Defaults
import AVFoundation

extension Utilities.System {
    static func startupTasks() async {
        // Register for push notifications (if applicable)
        Utilities.System.registerForPushNotificationsIfNeeded()
        
        // Check for app updates and notify (if applicable)
        await Utilities.System.checkForAppUpdates()
        
        // Configure audio instance
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }
    }
}
