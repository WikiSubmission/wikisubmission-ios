import Foundation
import Defaults

extension Utilities.Bookmarks {
    
    private static let iCloudBookmarksKey = "wikisubmission-bookmarks"
    
    /// Returns bookmarks stored locally in user defaults.
    static private func getLocalStore() -> [Types.Bookmarks.Bookmark] {
        return Defaults[.bookmarks]
    }
    
    static func getBookmarksFromiCloud() -> [Types.Bookmarks.Bookmark] {
        let store = NSUbiquitousKeyValueStore.default
        if let data = store.data(forKey: Self.iCloudBookmarksKey),
           let bookmarks = try? JSONDecoder().decode([Types.Bookmarks.Bookmark].self, from: data) {
            return bookmarks
        }
        return []
    }
    
    static func saveBookmarksToiCloud(_ bookmarks: [Types.Bookmarks.Bookmark]) {
        let store = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(bookmarks) {
            store.set(data, forKey: Self.iCloudBookmarksKey)
            store.synchronize()
        }
    }

    /// Adds a bookmark to local storage and syncs it to iCloud
    static func addBookmark(_ bookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        guard !bookmarks.contains(where: { $0.key == bookmark.key }) else { return }
        bookmarks.append(bookmark)
        Defaults[.bookmarks] = bookmarks
        saveBookmarksToiCloud(bookmarks)
    }
    
    /// Removes a bookmark from local storage and syncs the change to iCloud
    static func removeBookmark(_ bookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        let initialCount = bookmarks.count
        bookmarks.removeAll(where: { $0.key == bookmark.key })
        guard bookmarks.count < initialCount else { return }
        Defaults[.bookmarks] = bookmarks
        saveBookmarksToiCloud(bookmarks)
    }
    
    /// Edits a bookmark in local storage and syncs the change to iCloud
    static func editBookmark(_ bookmark: Types.Bookmarks.Bookmark, newBookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        guard let index = bookmarks.firstIndex(where: { $0.key == bookmark.key }) else { return }
        bookmarks[index] = newBookmark
        Defaults[.bookmarks] = bookmarks
        saveBookmarksToiCloud(bookmarks)
    }
    
    /// Deletes all bookmarks locally and in iCloud
    static func deleteAll() async throws {
        Defaults[.bookmarks] = []
        saveBookmarksToiCloud([])
    }
    
    /// Syncs local storage bookmarks with bookmarks from iCloud
    static func syncLocalBookmarksWithICloud() {
        // Load bookmarks from both sources
        let iCloudBookmarks = getBookmarksFromiCloud()
        let localBookmarks = Defaults[.bookmarks]
        
        // Merge without duplicates (by .key)
        var combined: [Types.Bookmarks.Bookmark] = localBookmarks
        for icloudBookmark in iCloudBookmarks {
            if !combined.contains(where: { $0.key == icloudBookmark.key }) {
                combined.append(icloudBookmark)
            }
        }
        // Save merged list to both local and iCloud
        Defaults[.bookmarks] = combined
        saveBookmarksToiCloud(combined)
    }
    
    /// Starts observing iCloud changes and syncs them to local storage when they occur
    static func startICloudObserver() {
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default, queue: .main) { _ in
            syncLocalBookmarksWithICloud()
        }
    }
}
