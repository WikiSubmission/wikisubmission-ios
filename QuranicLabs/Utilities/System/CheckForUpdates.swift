import Foundation
import Supabase
import Defaults

extension Utilities.System {
    static func checkForAppUpdates() async {
        let now = Date()
        let lastChecked = Defaults[.last_checked_for_update] as Date?
        if let lastChecked = lastChecked, now.timeIntervalSince(lastChecked) < 7200 {
            // Less than 2 hours since last check, skip update check.
            return
        }

        do {
            let query: Utilities.System.WSiOSUpdates = try await Utilities.Supabase.client
                .from("ws-ios-updates")
                .select("*")
                .single()
                .execute()
                .value
            
            let liveVersion = query.ios_version
            let currentVersion = Info.version
            
            if liveVersion != currentVersion {
                Utilities.System.GlobalAlertManager.shared.showAlert(
                    title: "An app update is available",
                    subtitle: "You are on V\(currentVersion). An upgrade to V\(liveVersion) is now available.",
                    systemImage: "rectangle.grid.2x2.fill",
                    type: .notice,
                    showAppStoreButton: true
                )
            }
            // Update the last checked timestamp after successful check
            Defaults[.last_checked_for_update] = now
        } catch {
            print("Error checking for updates:", error.localizedDescription)
        }
    }
    
    struct WSiOSUpdates: Decodable {
        let ios_version: String
        let ios_version_notes: String
    }
}
