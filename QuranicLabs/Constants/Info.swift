import Foundation

struct Info {
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    static let appStoreURL = "https://apple.co/3uMVbz1"
    static let contactEmail = "developer@wikisubmission.org"
    static let developerDiscordLink = "https://discord.gg/ArTXN6cwtk"
}
