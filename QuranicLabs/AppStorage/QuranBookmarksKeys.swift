import Defaults
import Foundation

extension Defaults.Keys {
    static let bookmarks = Key<[Types.Bookmarks.Bookmark]>("bookmarks", default: [])
    static let bookmarked_synced = Key<Bool>("synced", default: false)
}
