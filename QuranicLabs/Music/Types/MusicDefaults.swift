import Defaults

extension Defaults.Keys {
    /// URLs of favorited tracks (stored as strings for persistence)
    static let music_favorites = Key<[String]>("music_favorites", default: [])
}

extension Defaults {
    static func resetMusicPreferences() {
        Defaults.Keys.music_favorites.reset()
    }
}
