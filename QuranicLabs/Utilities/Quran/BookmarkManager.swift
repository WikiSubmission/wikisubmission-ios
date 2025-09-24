import Foundation
import PostgREST
import SwiftUI
import AlertKit
import Defaults

extension Utilities.Quran {
    class BookmarkManager: ObservableObject {
        @Published var bookmarks: [Types.Supabase.Bookmarks] = []
        @Published var isOnline = true
        @Published var syncStatus: SyncStatus = .synced
        
        enum SyncStatus {
            case synced             // Fully synced with server
            case syncing            // Currently syncing
            case pendingOffline     // No internet
            case pendingSignIn      // User not signed in
            case failed             // Last sync failed
        }
        
        static let shared = BookmarkManager()
        private var isSyncing = false

        private init() {
            loadLocalBookmarks()
            Task {
                await attemptSync()
            }
        }
        
        private func saveLocalBookmarks() {
            do {
                let data = try JSONEncoder().encode(bookmarks)
                Defaults[.local_bookmarks] = data
                print("Bookmarks saved locally")
            } catch {
                print("Failed to save local bookmarks: \(error)")
            }
        }
        
        private func loadLocalBookmarks() {
            guard let data = Defaults[.local_bookmarks] else {
                print("No local bookmarks found")
                return
            }
            
            do {
                bookmarks = try JSONDecoder().decode([Types.Supabase.Bookmarks].self, from: data)
                print("Loaded \(bookmarks.count) local bookmarks")
            } catch {
                print("Failed to load local bookmarks: \(error)")
                bookmarks = []
            }
        }
        
        private func updateSyncStatus() async {
            // Check internet
            let canProceed = await Utilities.System.ensureCanProceed([.ensureInternetConnection, .ensureLoggedIn])
            
            if !canProceed.success {
                if canProceed.failedCase == .ensureInternetConnection {
                    syncStatus = .pendingOffline
                } else if canProceed.failedCase == .ensureLoggedIn {
                    syncStatus = .pendingSignIn
                }
                return
            }
            
            // If currently syncing
            if isSyncing {
                syncStatus = .syncing
            } else {
                syncStatus = .synced
            }
        }

        func refresh() async {
            await updateSyncStatus()
            
            switch syncStatus {
            case .pendingOffline, .pendingSignIn:
                // Do nothing, just show local data
                isOnline = syncStatus == .pendingOffline
                print("Offline or not signed in, using local bookmarks")
            case .synced, .syncing, .failed:
                await syncWithServer()
            }
        }
        private func canSyncWithServer() async -> Bool {
            let status = await Utilities.System.ensureCanProceed([.ensureInternetConnection, .ensureLoggedIn])
            isOnline = status.success
            return status.success
        }
        
        private func attemptSync() async {
            await updateSyncStatus()
            
            if syncStatus == .synced || syncStatus == .failed {
                await syncWithServer()
            }
        }
        
        private func syncWithServer() async {
            guard !isSyncing else { return }
            guard await canSyncWithServer() else { return }
            
            isSyncing = true
            syncStatus = .syncing
            
            do {
                let serverBookmarks = try await fetchServerBookmarks()
                let mergedBookmarks = mergeBookmarks(local: bookmarks, server: serverBookmarks)
                
                bookmarks = mergedBookmarks
                try await upsertToServer(mergedBookmarks)
                saveLocalBookmarks()
                Defaults[.last_bookmarks_sync] = Date()
                Defaults[.has_pending_bookmark_changes] = false
                syncStatus = .synced
                
                print("Bookmarks synced successfully")
            } catch {
                syncStatus = .failed
                print("Sync failed: \(error)")
            }
            
            isSyncing = false
        }
    
        private func fetchServerBookmarks() async throws -> [Types.Supabase.Bookmarks] {
            let response = try await Utilities.Supabase.client
                .from("ws-user-data")
                .select("quran_bookmarks")
                .execute()
                                        
            return decodeBookmarkData(response).sorted { $0.created_at > $1.created_at }
        }
        
        private func mergeBookmarks(local: [Types.Supabase.Bookmarks], server: [Types.Supabase.Bookmarks]) -> [Types.Supabase.Bookmarks] {
            var mergedBookmarks: [UUID: Types.Supabase.Bookmarks] = [:]
            
            // Add server bookmarks first
            for bookmark in server {
                mergedBookmarks[bookmark.id] = bookmark
            }
            
            // Add/update with local bookmarks (local takes precedence for conflicts)
            for bookmark in local {
                if let existing = mergedBookmarks[bookmark.id] {
                    // Safely unwrap updated_at
                    if let newUpdated = bookmark.updated_at, let existingUpdated = existing.updated_at {
                        if newUpdated > existingUpdated {
                            mergedBookmarks[bookmark.id] = bookmark
                        }
                    } else if bookmark.updated_at != nil {
                        // If existing.updated_at is nil, prefer the one with a value
                        mergedBookmarks[bookmark.id] = bookmark
                    }
                    // If both are nil, keep existing
                } else {
                    mergedBookmarks[bookmark.id] = bookmark
                }
            }
            
            return Array(mergedBookmarks.values).sorted { $0.created_at > $1.created_at }
        }

        @MainActor
        func clearAll(onlyLocally: Bool = false, showAlert: Bool = false) async {
            bookmarks.removeAll()
            saveLocalBookmarks()
            
            if await canSyncWithServer() && !onlyLocally {
                do {
                    try await upsertToServer([])
                    Defaults[.has_pending_bookmark_changes] = false
                } catch {
                    Defaults[.has_pending_bookmark_changes] = true
                    print("Failed to clear server bookmarks: \(error)")
                }
            } else {
                Defaults[.has_pending_bookmark_changes] = true
            }
            
            if showAlert {
                AlertKitAPI.present(
                    title: "All bookmarks cleared",
                    icon: .done,
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            }
        }

        @MainActor
        func addChapter(_ chapter: Int, note: String? = nil) async {
            let newBookmark = Types.Supabase.Bookmarks(
                created_at: Date().timeIntervalSince1970,
                updated_at: Date().timeIntervalSince1970,
                chapter_number: chapter,
                note: note
            )
            
            bookmarks.append(newBookmark)
            saveLocalBookmarks()
            
            if await canSyncWithServer() {
                do {
                    try await upsertToServer(bookmarks)
                    Defaults[.has_pending_bookmark_changes] = false
                } catch {
                    Defaults[.has_pending_bookmark_changes] = true
                    print("Failed to sync chapter bookmark: \(error)")
                }
            } else {
                Defaults[.has_pending_bookmark_changes] = true
            }
            
            AlertKitAPI.present(
                title: "Chapter \(chapter) bookmarked",
                icon: .done,
                style: .iOS17AppleMusic,
                haptic: .success
            )
        }

        @MainActor
        func addVerse(_ verse_id: String, note: String? = nil, hideAlert: Bool = false) async {
            let newBookmark = Types.Supabase.Bookmarks(
                created_at: Date().timeIntervalSince1970,
                updated_at: Date().timeIntervalSince1970,
                verse_id: verse_id,
                note: note
            )
            
            bookmarks.append(newBookmark)
            saveLocalBookmarks()
            
            if await canSyncWithServer() {
                do {
                    try await upsertToServer(bookmarks)
                    Defaults[.has_pending_bookmark_changes] = false
                } catch {
                    Defaults[.has_pending_bookmark_changes] = true
                    print("Failed to sync verse bookmark: \(error)")
                }
            } else {
                Defaults[.has_pending_bookmark_changes] = true
            }
            
            if !hideAlert {
                AlertKitAPI.present(
                    title: "\(verse_id) bookmarked",
                    icon: .done,
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            }
        }
        
        @MainActor
        func addNote(bookmarkID: UUID, note: String) async {
            if let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) {
                bookmarks[index].note = note
                bookmarks[index].updated_at = Date().timeIntervalSince1970
                saveLocalBookmarks()
                
                if await canSyncWithServer() {
                    do {
                        try await upsertToServer(bookmarks)
                        Defaults[.has_pending_bookmark_changes] = false
                    } catch {
                        Defaults[.has_pending_bookmark_changes] = true
                        print("Failed to sync note: \(error)")
                    }
                } else {
                    Defaults[.has_pending_bookmark_changes] = true
                }
                
                AlertKitAPI.present(
                    title: "Note added",
                    icon: .done,
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            } else {
                AlertKitAPI.present(
                    title: "Bookmark not found",
                    icon: .error,
                    style: .iOS17AppleMusic,
                    haptic: .error
                )
            }
        }
        
        @MainActor
        func addCategory(bookmarkID: UUID, category: String) async {
            if let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) {
                bookmarks[index].category = category
                bookmarks[index].updated_at = Date().timeIntervalSince1970
                saveLocalBookmarks()
                
                if await canSyncWithServer() {
                    do {
                        try await upsertToServer(bookmarks)
                        Defaults[.has_pending_bookmark_changes] = false
                    } catch {
                        Defaults[.has_pending_bookmark_changes] = true
                        print("Failed to sync category: \(error)")
                    }
                } else {
                    Defaults[.has_pending_bookmark_changes] = true
                }
                
                AlertKitAPI.present(
                    title: "Category added",
                    icon: .done,
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            } else {
                AlertKitAPI.present(
                    title: "Bookmark not found",
                    icon: .error,
                    style: .iOS17AppleMusic,
                    haptic: .error
                )
            }
        }
        
        @MainActor
        func removeCategory(bookmarkID: UUID) async {
            if let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) {
                bookmarks[index].category = nil
                bookmarks[index].updated_at = Date().timeIntervalSince1970
                saveLocalBookmarks()
                
                if await canSyncWithServer() {
                    do {
                        try await upsertToServer(bookmarks)
                        Defaults[.has_pending_bookmark_changes] = false
                    } catch {
                        Defaults[.has_pending_bookmark_changes] = true
                        print("Failed to sync category removal: \(error)")
                    }
                } else {
                    Defaults[.has_pending_bookmark_changes] = true
                }
                
                AlertKitAPI.present(
                    title: "Category removed",
                    icon: .done,
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            } else {
                AlertKitAPI.present(
                    title: "Bookmark not found",
                    icon: .error,
                    style: .iOS17AppleMusic,
                    haptic: .error
                )
            }
        }
        
        @MainActor
        func remove(bookmarkID: UUID) async {
            bookmarks.removeAll { $0.id == bookmarkID }
            saveLocalBookmarks()
            
            if await canSyncWithServer() {
                do {
                    try await upsertToServer(bookmarks)
                    Defaults[.has_pending_bookmark_changes] = false
                } catch {
                    Defaults[.has_pending_bookmark_changes] = true
                    print("Failed to sync removal: \(error)")
                }
            } else {
                Defaults[.has_pending_bookmark_changes] = true
            }
            
            AlertKitAPI.present(
                title: "Removed bookmark",
                icon: .done,
                style: .iOS17AppleMusic,
                haptic: .success
            )
        }
        
        func get(chapter: Int? = nil, verseID: String? = nil) -> Types.Supabase.Bookmarks? {
            if let chapter = chapter {
                return self.bookmarks.first { $0.chapter_number == chapter }
            }
            
            if let verseID = verseID {
                return self.bookmarks.first { $0.verse_id == verseID }
            }
            
            return nil
        }
        
        func isBookmarked(chapter: Int? = nil, verseID: String? = nil) -> Bool {
            if let chapter = chapter {
                return self.bookmarks.contains { $0.chapter_number == chapter }
            }
            
            if let verseID = verseID {
                return self.bookmarks.contains { $0.verse_id == verseID }
            }
            
            return false
        }
        
        func hasNote(_ bookmark: Types.Supabase.Bookmarks?) -> Bool {
            guard let bookmark = bookmark else { return false }
            guard let note = bookmark.note else { return false }
            return !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
            
        func hasCategory(_ bookmark: Types.Supabase.Bookmarks?) -> Bool {
            guard let bookmark = bookmark else { return false }
            guard let category = bookmark.category else { return false }
            return !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var uniqueCategories: [String] {
            let categories = bookmarks.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
            return Array(Set(categories)).sorted()
        }
        
        func forceSyncWithServer() async {
            await syncWithServer()
        }
        
        private func upsertToServer(_ bookmarks: [Types.Supabase.Bookmarks]) async throws {
            let _: PostgrestResponse<Void> = try await Utilities.Supabase.client
                .from("ws-user-data")
                .upsert(["quran_bookmarks": bookmarks])
                .execute()
        }
        
        func decodeBookmarkData(_ data: PostgrestResponse<Void>?) -> [Types.Supabase.Bookmarks] {
            let string = data?.string()
            
            guard let string = string,
                  let data = string.data(using: .utf8) else {
                return []
            }

            struct Wrapper: Decodable {
                let quran_bookmarks: [Types.Supabase.Bookmarks]
            }

            do {
                let wrappers = try JSONDecoder().decode([Wrapper].self, from: data)
                return wrappers.flatMap { $0.quran_bookmarks }
            } catch {
                print("Error decoding bookmark data", error.localizedDescription)
                return []
            }
        }
        
        @available(*, deprecated, message: "Use refresh() instead")
        func ensureCanProceed() async -> Bool {
            return await canSyncWithServer()
        }
        
        @available(*, deprecated, message: "Use upsertToServer() instead")
        func upsert(_ bookmarks: [Types.Supabase.Bookmarks]) async throws {
            try await upsertToServer(bookmarks)
        }
        
        @available(*, deprecated, message: "Use fetchServerBookmarks() instead")
        func listAll() async throws -> [Types.Supabase.Bookmarks] {
            return try await fetchServerBookmarks()
        }
        
        var hasPendingChanges: Bool {
            return Defaults[.has_pending_bookmark_changes]
        }
        
        var lastSyncDate: Date? {
            return Defaults[.last_bookmarks_sync]
        }
    }
}
