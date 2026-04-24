import Foundation
import Defaults
import SwiftUI

// MARK: - Models

struct QuranReadingHistoryEntry: Codable, Hashable, Identifiable, Defaults.Serializable {
    var id: String { "\(chapterNumber)-\(verseId)-\(startedAt.timeIntervalSince1970)" }

    let chapterNumber: Int
    let chapterTitle: String
    let verseId: String
    let verseNumber: Int
    let excerpt: String
    let startedAt: Date
    var updatedAt: Date
}

// MARK: - Defaults Key

extension Defaults.Keys {
    static let quran_reading_history = Key<[QuranReadingHistoryEntry]>("quran_reading_history", default: [])
}

// MARK: - Store

@MainActor
class QuranReadingHistoryStore: ObservableObject {
    static let shared = QuranReadingHistoryStore()

    @Published private(set) var history: [QuranReadingHistoryEntry] = []

    /// Merge window: entries in the same chapter within this duration are merged
    private let mergeWindow: TimeInterval = 60 * 20 // 20 minutes
    private let maxEntries = 500

    private init() {
        history = Defaults[.quran_reading_history]
    }

    // MARK: - Record

    func record(chapterNumber: Int, chapterTitle: String, verseId: String, verseNumber: Int, excerpt: String) {
        let now = Date()

        // Check if we should merge with the most recent entry
        if let first = history.first,
           first.chapterNumber == chapterNumber,
           now.timeIntervalSince(first.updatedAt) < mergeWindow {
            // Merge: update the existing entry's verse position
            var updated = first
            updated.updatedAt = now
            // Only update verse info if it's a different verse (user scrolled)
            if updated.verseId != verseId {
                history[0] = QuranReadingHistoryEntry(
                    chapterNumber: chapterNumber,
                    chapterTitle: chapterTitle,
                    verseId: verseId,
                    verseNumber: verseNumber,
                    excerpt: excerpt,
                    startedAt: first.startedAt,
                    updatedAt: now
                )
            } else {
                history[0].updatedAt = now
            }
        } else {
            // New entry
            let entry = QuranReadingHistoryEntry(
                chapterNumber: chapterNumber,
                chapterTitle: chapterTitle,
                verseId: verseId,
                verseNumber: verseNumber,
                excerpt: excerpt.count > 96 ? String(excerpt.prefix(96)).appending("…") : excerpt,
                startedAt: now,
                updatedAt: now
            )
            history.insert(entry, at: 0)
        }

        // Deduplicate by id
        var seen = Set<String>()
        history = history.filter { seen.insert($0.id).inserted }

        // Limit
        if history.count > maxEntries {
            history = Array(history.prefix(maxEntries))
        }

        save()
    }

    func clear() {
        history = []
        save()
    }

    private func save() {
        Defaults[.quran_reading_history] = history
    }
}
