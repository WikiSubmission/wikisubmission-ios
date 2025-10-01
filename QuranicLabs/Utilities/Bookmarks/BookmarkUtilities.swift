import Defaults
import Clerk

extension Utilities.Bookmarks {
    
    static private func getLocalStore() -> [Types.Bookmarks.Bookmark] {
        return Defaults[.bookmarks]
    }

    static func syncWithDatabase() async throws -> Void {
        // Ensure sync necassary.
        guard Defaults[.bookmarked_synced] == false else {
            return
        }
        
        // Ensure internet.
        guard Utilities.System.NetworkMonitor.shared.hasInternet else {
            return
        }
        // Ensure valid user ID exists.
        guard let userId = await Clerk.shared.user?.id else {
            return
        }
        // Start sync.
        do {
            // Get local record, which is always up to date.
            let bookmarks = getLocalStore()
            
            // Fill in user_id for bookmarks created offline
            let bookmarksWithUserId = bookmarks.map { bookmark in
                var updated = bookmark
                if updated.user_id == nil {
                    updated.user_id = userId
                }
                return updated
            }
            
            // Upsert it to DB.
            try await Utilities.Supabase.authenticatedClient
                .from("ws-bookmarks")
                .upsert(bookmarksWithUserId, onConflict: "key")
                .execute()
            
            Defaults[.bookmarked_synced] = true // Mark synced status = TRUE.
        } catch {
            Defaults[.bookmarked_synced] = false // Mark synced status = FALSE.
            print("Error updating ws-bookmarks table:", error.localizedDescription)
        }
    }
    
    static func addBookmark(_ bookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        guard !bookmarks.contains(where: { $0.key == bookmark.key }) else { return }
        bookmarks.append(bookmark)
        Defaults[.bookmarks] = bookmarks
        Defaults[.bookmarked_synced] = false
        if Utilities.System.NetworkMonitor.shared.hasInternet {
            try? await Utilities.Bookmarks.syncWithDatabase()
        }
        return
    }
    
    static func removeBookmark(_ bookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        let initialCount = bookmarks.count
        bookmarks.removeAll(where: { $0.key == bookmark.key })
        guard bookmarks.count < initialCount else { return }
        Defaults[.bookmarks] = bookmarks
        Defaults[.bookmarked_synced] = false
        if Utilities.System.NetworkMonitor.shared.hasInternet {
            try? await Utilities.Bookmarks.syncWithDatabase()
        }
        return
    }
    
    static func editBookmark(_ bookmark: Types.Bookmarks.Bookmark, newBookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        guard let index = bookmarks.firstIndex(where: { $0.key == bookmark.key }) else { return }
        bookmarks[index] = newBookmark
        Defaults[.bookmarks] = bookmarks
        Defaults[.bookmarked_synced] = false
        if Utilities.System.NetworkMonitor.shared.hasInternet {
            try? await Utilities.Bookmarks.syncWithDatabase()
        }
        return
    }
    
    static func deleteAll() async throws {
        Defaults[.bookmarks] = []
        Defaults[.bookmarked_synced] = false
        if Utilities.System.NetworkMonitor.shared.hasInternet {
            try? await syncWithDatabase()
        }
    }
}

