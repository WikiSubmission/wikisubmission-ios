import Defaults
import Foundation

extension Defaults.Keys {
    static let local_bookmarks = Key<Data?>("local_bookmarks", default: nil)
    static let last_bookmarks_sync = Key<Date?>("last_bookmarks_sync", default: nil)
    static let has_pending_bookmark_changes = Key<Bool>("has_pending_bookmark_changes", default: false)
}
