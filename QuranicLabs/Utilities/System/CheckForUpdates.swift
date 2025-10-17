import Foundation
import Supabase
import Defaults

extension Utilities.System {
    static func checkForAppUpdates(forceCheck: Bool = false) async {
        guard Utilities.System.NetworkMonitor.shared.hasInternet else {
            Utilities.System.GlobalAlertManager.shared.showAlert(title: "No Internet Connection", subtitle: "An internet connection is required to check for updates.", systemImage: "wifi.slash", type: .error)
            return
        }
        
        let now = Date()
        let lastChecked = Defaults[.last_checked_for_update] as Date?
        if let lastChecked = lastChecked, now.timeIntervalSince(lastChecked) < 7200 && !forceCheck || forceCheck && now.timeIntervalSince(lastChecked) < 5 {
            // Less than 2 hours since last check (or, force update too soon), skip update check.
            return
        }

        func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
            let parts1 = v1.split(separator: ".").compactMap { Int($0) }
            let parts2 = v2.split(separator: ".").compactMap { Int($0) }
            let maxCount = max(parts1.count, parts2.count)
            let padded1 = parts1 + Array(repeating: 0, count: maxCount - parts1.count)
            let padded2 = parts2 + Array(repeating: 0, count: maxCount - parts2.count)
            return padded1.lexicographicallyPrecedes(padded2) == false && padded1 != padded2
        }

        do {
            let timestamp = Int(Date().timeIntervalSince1970)
            let urlString = "https://itunes.apple.com/lookup?bundleId=\(Info.bundleIdentifier)&_t=\(timestamp)"
            guard let url = URL(string: urlString) else {
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent") // mimic browser
            let (data, _) = try await URLSession.shared.data(for: request)
            let lookupResponse = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard let appInfo = lookupResponse.results.first else {
                print("iTunes API: App info not found")
                return
            }
            let liveVersion = appInfo.version
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

            else if forceCheck && (liveVersion == currentVersion || !liveVersionGreaterThanCurrentVersion) {
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
    
    struct LookupResponse: Decodable {
        struct AppInfo: Decodable {
            let version: String
            let releaseNotes: String?
            let trackViewUrl: String?
        }
        let results: [AppInfo]
    }
}
