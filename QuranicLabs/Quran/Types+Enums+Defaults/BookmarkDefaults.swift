import Defaults

extension Defaults.Keys {
    // Legacy key - for migration only
    static let bookmarks = Key<[LegacyBookmark]>("bookmarks", default: [])

    // New bookmarks format
    static let bookmarks_v2 = Key<[Bookmark]>("bookmarks_v2", default: [])
}
