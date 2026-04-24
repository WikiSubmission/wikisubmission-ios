import Foundation
import Defaults
import SwiftUI

// MARK: - Bookmark Types

struct Bookmark: Codable, Hashable, Identifiable, Defaults.Serializable {
    var id: String { key }
    let createdAt: Date
    var updatedAt: Date?
    let type: BookmarkType
    let key: String // verse_id like "1:1" or chapter number like "1"
    var category: String?
    var notes: String?

    enum BookmarkType: String, Codable, Hashable {
        case chapter
        case verse
    }

    // Parse verse_id to get chapter and verse numbers
    var chapterNumber: Int? {
        if type == .chapter {
            return Int(key)
        }
        return key.split(separator: ":").first.flatMap { Int($0) }
    }

    var verseNumber: Int? {
        guard type == .verse else { return nil }
        return key.split(separator: ":").last.flatMap { Int($0) }
    }
}

// MARK: - Bookmark Manager

@MainActor
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published private(set) var bookmarks: [Bookmark] = []
    @Published var selectedCategory: String? = nil

    private init() {
        loadBookmarks()
    }

    // MARK: - Computed Properties

    var filteredBookmarks: [Bookmark] {
        guard let category = selectedCategory else { return bookmarks }
        return bookmarks.filter { $0.category == category }
    }

    var sortedBookmarks: [Bookmark] {
        filteredBookmarks.sorted { $0.createdAt > $1.createdAt }
    }

    var uniqueCategories: [String] {
        let categories = bookmarks.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(categories)).sorted()
    }

    var isEmpty: Bool {
        bookmarks.isEmpty
    }

    // MARK: - CRUD Operations

    func add(_ bookmark: Bookmark) {
        guard !bookmarks.contains(where: { $0.key == bookmark.key }) else { return }
        bookmarks.append(bookmark)
        save()
    }

    func addVerse(_ verseId: String, category: String? = nil, notes: String? = nil) {
        let bookmark = Bookmark(
            createdAt: Date(),
            updatedAt: nil,
            type: .verse,
            key: verseId,
            category: category,
            notes: notes
        )
        add(bookmark)
    }

    func addChapter(_ chapterNumber: Int, category: String? = nil, notes: String? = nil) {
        let bookmark = Bookmark(
            createdAt: Date(),
            updatedAt: nil,
            type: .chapter,
            key: String(chapterNumber),
            category: category,
            notes: notes
        )
        add(bookmark)
    }

    func remove(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.key == bookmark.key }
        save()
    }

    func removeByKey(_ key: String) {
        bookmarks.removeAll { $0.key == key }
        save()
    }

    func update(_ bookmark: Bookmark, category: String? = nil, notes: String? = nil) {
        guard let index = bookmarks.firstIndex(where: { $0.key == bookmark.key }) else { return }
        var updated = bookmark
        updated.updatedAt = Date()
        if let category = category {
            updated.category = category.isEmpty ? nil : category
        }
        if let notes = notes {
            updated.notes = notes.isEmpty ? nil : notes
        }
        bookmarks[index] = updated
        save()
    }

    func updateCategory(_ bookmark: Bookmark, category: String?) {
        guard let index = bookmarks.firstIndex(where: { $0.key == bookmark.key }) else { return }
        var updated = bookmark
        updated.updatedAt = Date()
        updated.category = category?.trimmingCharacters(in: .whitespacesAndNewlines)
        if updated.category?.isEmpty == true { updated.category = nil }
        bookmarks[index] = updated
        save()
    }

    func updateNotes(_ bookmark: Bookmark, notes: String?) {
        guard let index = bookmarks.firstIndex(where: { $0.key == bookmark.key }) else { return }
        var updated = bookmark
        updated.updatedAt = Date()
        updated.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        if updated.notes?.isEmpty == true { updated.notes = nil }
        bookmarks[index] = updated
        save()
    }

    func renameCategory(_ oldName: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        for i in bookmarks.indices {
            if bookmarks[i].category == oldName {
                bookmarks[i].category = trimmed.isEmpty ? nil : trimmed
                bookmarks[i].updatedAt = Date()
            }
        }
        if selectedCategory == oldName {
            selectedCategory = trimmed.isEmpty ? nil : trimmed
        }
        save()
    }

    func deleteCategory(_ name: String) {
        for i in bookmarks.indices {
            if bookmarks[i].category == name {
                bookmarks[i].category = nil
                bookmarks[i].updatedAt = Date()
            }
        }
        if selectedCategory == name {
            selectedCategory = nil
        }
        save()
    }

    func deleteAll() {
        bookmarks = []
        save()
    }

    func isBookmarked(_ key: String) -> Bool {
        bookmarks.contains { $0.key == key }
    }

    func isVerseBookmarked(chapter: Int, verse: Int) -> Bool {
        isBookmarked("\(chapter):\(verse)")
    }

    func isChapterBookmarked(_ chapter: Int) -> Bool {
        isBookmarked(String(chapter))
    }

    func toggle(_ verseId: String) {
        if isBookmarked(verseId) {
            removeByKey(verseId)
        } else {
            addVerse(verseId)
        }
    }

    // MARK: - Import/Export

    func exportBookmarks() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(bookmarks)
    }

    func importBookmarks(from data: Data, merge: Bool = true) throws {
        // Try new format first
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var imported: [Bookmark] = []

        if let newFormat = try? decoder.decode([Bookmark].self, from: data) {
            imported = newFormat
        } else {
            // Try legacy format
            let legacyImported = try JSONDecoder().decode([LegacyBookmark].self, from: data)
            let iso8601 = ISO8601DateFormatter()

            imported = legacyImported.map { old in
                Bookmark(
                    createdAt: iso8601.date(from: old.created_at) ?? Date(),
                    updatedAt: old.updated_at.flatMap { iso8601.date(from: $0) },
                    type: old.type == .chapter ? .chapter : .verse,
                    key: old.key,
                    category: old.category,
                    notes: old.notes
                )
            }
        }

        if merge {
            for bookmark in imported {
                if !bookmarks.contains(where: { $0.key == bookmark.key }) {
                    bookmarks.append(bookmark)
                }
            }
        } else {
            bookmarks = imported
        }
        save()
    }

    func shareExport() {
        guard let data = exportBookmarks() else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "QuranBookmarks-\(dateFormatter.string(from: Date())).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
            shareText(tempURL.path)
        } catch {
            print("Failed to export bookmarks: \(error)")
        }
    }

    // MARK: - Persistence

    private func loadBookmarks() {
        // Load from new format first (using Defaults package)
        let storedBookmarks = Defaults[.bookmarks_v2]
        if !storedBookmarks.isEmpty {
            bookmarks = storedBookmarks
            return
        }

        // Try to migrate from old format (LegacyBookmark)
        let oldBookmarks = Defaults[.bookmarks]
        if !oldBookmarks.isEmpty {
            let iso8601 = ISO8601DateFormatter()
            bookmarks = oldBookmarks.map { old in
                Bookmark(
                    createdAt: iso8601.date(from: old.created_at) ?? Date(),
                    updatedAt: old.updated_at.flatMap { iso8601.date(from: $0) },
                    type: old.type == .chapter ? .chapter : .verse,
                    key: old.key,
                    category: old.category,
                    notes: old.notes
                )
            }
            save() // Save migrated bookmarks to new format
            return
        }

        bookmarks = []
    }

    private func save() {
        Defaults[.bookmarks_v2] = bookmarks
    }

    // MARK: - Migration (for external calls)

    static func migrateFromLegacy() {
        let oldBookmarks = Defaults[.bookmarks]
        guard !oldBookmarks.isEmpty else { return }

        // Check if already migrated
        let existingBookmarks = Defaults[.bookmarks_v2]
        guard existingBookmarks.isEmpty else { return }

        let iso8601 = ISO8601DateFormatter()
        var newBookmarks: [Bookmark] = []

        for old in oldBookmarks {
            let createdAt = iso8601.date(from: old.created_at) ?? Date()
            let updatedAt = old.updated_at.flatMap { iso8601.date(from: $0) }

            let bookmark = Bookmark(
                createdAt: createdAt,
                updatedAt: updatedAt,
                type: old.type == .chapter ? .chapter : .verse,
                key: old.key,
                category: old.category,
                notes: old.notes
            )
            newBookmarks.append(bookmark)
        }

        Defaults[.bookmarks_v2] = newBookmarks

        // Reload manager
        Task { @MainActor in
            BookmarkManager.shared.loadBookmarks()
        }
    }
}

struct LegacyBookmark: Encodable, Decodable, Hashable, Defaults.Serializable {
    let created_at: String
    let updated_at: String?
    let type: LegacyBookmarkType
    let key: String
    let category: String?
    let notes: String?
}

enum LegacyBookmarkType: String, Encodable, Decodable, Hashable, Defaults.Serializable {
    case chapter, verse
}
