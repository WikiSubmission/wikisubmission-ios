import SwiftUI

@MainActor
class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()
    static let backgroundCheckInterval: TimeInterval = 5 * 60 // 5 minutes

    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var releaseNotes: String?
    @Published var trackViewUrl: String?

    private var backgroundCheckTimer: Timer?
    private let urlSession: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.urlSession = URLSession(configuration: config)

        startBackgroundCheckTimer()
    }

    private func startBackgroundCheckTimer() {
        backgroundCheckTimer?.invalidate()
        backgroundCheckTimer = Timer.scheduledTimer(withTimeInterval: Self.backgroundCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForUpdates()
            }
        }
    }

    func checkForUpdates() async {
        guard NetworkManager.shared.hasInternet else { return }

        do {
            let timestamp = Int(Date().timeIntervalSince1970)
            let urlString = "https://itunes.apple.com/lookup?bundleId=\(About.bundleIdentifier)&_t=\(timestamp)"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await urlSession.data(for: request)
            let lookupResponse = try JSONDecoder().decode(LookupResponse.self, from: data)

            guard let appInfo = lookupResponse.results.first else {
                print("iTunes API: App info not found")
                return
            }

            let liveVersion = appInfo.version
            let currentVersion = About.version

            if isVersion(liveVersion, greaterThan: currentVersion) {
                latestVersion = liveVersion
                releaseNotes = appInfo.releaseNotes
                trackViewUrl = appInfo.trackViewUrl
                updateAvailable = true
                print("App update available: \(liveVersion)")
            } else {
                updateAvailable = false
                print("✓ App is up to date (\(currentVersion))")
            }
        } catch {
            print("Error checking for app updates: \(error.localizedDescription)")
        }
    }

    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(parts1.count, parts2.count)
        let padded1 = parts1 + Array(repeating: 0, count: maxCount - parts1.count)
        let padded2 = parts2 + Array(repeating: 0, count: maxCount - parts2.count)
        return padded1.lexicographicallyPrecedes(padded2) == false && padded1 != padded2
    }

    func openAppStore() {
        if let urlString = trackViewUrl, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: About.appStoreURL) {
            UIApplication.shared.open(url)
        }
    }

    private struct LookupResponse: Decodable {
        struct AppInfo: Decodable {
            let version: String
            let releaseNotes: String?
            let trackViewUrl: String?
        }
        let results: [AppInfo]
    }
}
