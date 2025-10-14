import Foundation

struct Info {
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    static let appStoreURL = "https://apps.apple.com/app/submission-religion-of-god/id6444260632"
    static let appStoreURLShortened = "https://apple.co/3uMVbz1"
    static let contactEmail = "developer@wikisubmission.org"
    static let developerDiscordLink = "https://discord.gg/ArTXN6cwtk"
    static let practicesEndpoint = "https://practices.wikisubmission.org"
    static let cdnEndpoint = "https://cdn.wikisubmission.org"
}
