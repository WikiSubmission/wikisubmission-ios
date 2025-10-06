import Foundation
import Supabase
import Defaults

extension Utilities.System {
    static func checkForAppUpdates(forceCheck: Bool = false) async {
        let now = Date()
        let lastChecked = Defaults[.last_checked_for_update] as Date?
        if let lastChecked = lastChecked, now.timeIntervalSince(lastChecked) < 7200 && !forceCheck || forceCheck && now.timeIntervalSince(lastChecked) < 5 {
            // Less than 2 hours since last check (or, force update too soon), skip update check.
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
        
            if forceCheck && liveVersion == currentVersion {
                Utilities.System.GlobalAlertManager.shared.showAlert(
                    title: "You're on the latest version",
                    subtitle: "You are on V\(currentVersion) (latest). We'll let you know if there's an update.",
                    systemImage: "rectangle.grid.2x2.fill",
                    type: .notice,
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
