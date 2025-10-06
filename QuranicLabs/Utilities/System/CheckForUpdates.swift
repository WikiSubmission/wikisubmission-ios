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

        func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
            let v1Components = v1.split(separator: ".").compactMap { Int($0) }
            let v2Components = v2.split(separator: ".").compactMap { Int($0) }
            let maxCount = max(v1Components.count, v2Components.count)
            for i in 0..<maxCount {
                let v1Part = i < v1Components.count ? v1Components[i] : 0
                let v2Part = i < v2Components.count ? v2Components[i] : 0
                if v1Part > v2Part {
                    return true
                } else if v1Part < v2Part {
                    return false
                }
            }
            return false
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
            let liveVersionGreaterThanCurrentVersion = isVersion(liveVersion, greaterThan: currentVersion)
            
            if liveVersionGreaterThanCurrentVersion {
                Utilities.System.GlobalAlertManager.shared.showAlert(
                    title: "An app update is available",
                    subtitle: "You are on V\(currentVersion). An upgrade to V\(liveVersion) is now available.",
                    systemImage: "rectangle.grid.2x2.fill",
                    type: .notice,
                    showAppStoreButton: true
                )
            }
        
            if forceCheck && (liveVersion == currentVersion || !liveVersionGreaterThanCurrentVersion) {
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
