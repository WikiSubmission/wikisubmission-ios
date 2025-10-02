import Defaults
import Foundation

extension Defaults.Keys {
    static let bookmarks = Key<[Types.Bookmarks.Bookmark]>("bookmarks", default: [])
}
