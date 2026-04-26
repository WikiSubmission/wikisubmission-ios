import Foundation
import Defaults
import SwiftUI

// MARK: - Action Type

enum ReadingAction: String, Codable, CaseIterable, Defaults.Serializable {
    case opened = "Opened"
    case read = "Read"
    case searched = "Searched"
    case bookmarked = "Bookmarked"
    case randomVerse = "Random"
    case listened = "Listened"

    var icon: String {
        switch self {
        case .opened: return "arrow.right.circle"
        case .read: return "book.closed"
        case .searched: return "magnifyingglass"
        case .bookmarked: return "bookmark"
        case .randomVerse: return "dice"
        case .listened: return "waveform"
        }
    }

    var verb: String {
        switch self {
        case .opened: return "Opened"
        case .read: return "Read"
        case .searched: return "Searched"
        case .bookmarked: return "Opened bookmark"
        case .randomVerse: return "Random verse"
        case .listened: return "Listened to"
        }
    }
}

// MARK: - Event (lifecycle step within a session)

struct ReadingEvent: Codable, Hashable, Identifiable, Defaults.Serializable {
    var id: String { "\(action.rawValue)-\(timestamp.timeIntervalSince1970)" }
    let action: ReadingAction
    let detail: String
    let timestamp: Date
}

// MARK: - Session (the top-level entry)

struct QuranReadingSession: Codable, Hashable, Identifiable, Defaults.Serializable {
    let sessionId: String
    var id: String { sessionId }

    let chapterNumber: Int
    let chapterTitle: String
    let chapterVerses: Int
    var verseId: String
    var verseNumber: Int
    var excerpt: String
    let action: ReadingAction
    let startedAt: Date
    var updatedAt: Date
    var events: [ReadingEvent]

    var chapterLabel: String {
        "Sura \(chapterNumber): \(chapterTitle)"
    }

    var chapterProgress: Double {
        guard chapterVerses > 0 else { return 0 }
        return Double(verseNumber) / Double(chapterVerses)
    }

    var duration: TimeInterval {
        min(updatedAt.timeIntervalSince(startedAt), 1200)
    }

    // MARK: - Init

    init(chapterNumber: Int, chapterTitle: String, chapterVerses: Int = 0, verseId: String, verseNumber: Int, excerpt: String, action: ReadingAction, startedAt: Date, updatedAt: Date, events: [ReadingEvent] = []) {
        self.sessionId = "\(chapterNumber)-\(verseId)-\(Int(startedAt.timeIntervalSince1970))"
        self.chapterNumber = chapterNumber
        self.chapterTitle = chapterTitle
        self.chapterVerses = chapterVerses
        self.verseId = verseId
        self.verseNumber = verseNumber
        self.excerpt = excerpt.count > 96 ? String(excerpt.prefix(96)).appending("...") : excerpt
        self.action = action
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.events = events
    }
}

// MARK: - Defaults Key

extension Defaults.Keys {
    static let quran_reading_sessions = Key<[QuranReadingSession]>("quran_reading_sessions_v2", default: [])
}

// MARK: - Store

@MainActor
class QuranReadingHistoryStore: ObservableObject {
    static let shared = QuranReadingHistoryStore()

    @Published private(set) var history: [QuranReadingSession] = []

    private let mergeWindow: TimeInterval = 60 * 20
    private let maxEntries = 500

    private init() {
        history = Defaults[.quran_reading_sessions]
    }

    // MARK: - Record (verse tracking, merges into existing session)

    func record(chapterNumber: Int, chapterTitle: String, verseId: String, verseNumber: Int, chapterVerses: Int = 0, excerpt: String, action: ReadingAction = .read) {
        let now = Date()

        if var first = history.first,
           first.chapterNumber == chapterNumber,
           now.timeIntervalSince(first.updatedAt) < mergeWindow {
            // Merge into existing session
            if first.verseId != verseId {
                first.events.append(ReadingEvent(
                    action: .read,
                    detail: "Scrolled to \(verseId)",
                    timestamp: now
                ))
                first.verseId = verseId
                first.verseNumber = verseNumber
                first.excerpt = excerpt.count > 96 ? String(excerpt.prefix(96)).appending("...") : excerpt
            }
            first.updatedAt = now
            history[0] = first
        } else {
            // New session
            let event = ReadingEvent(
                action: action,
                detail: "\(action.verb) \(chapterTitle) (\(chapterNumber)) at \(verseId)",
                timestamp: now
            )
            let session = QuranReadingSession(
                chapterNumber: chapterNumber,
                chapterTitle: chapterTitle,
                chapterVerses: chapterVerses,
                verseId: verseId,
                verseNumber: verseNumber,
                excerpt: excerpt,
                action: action,
                startedAt: now,
                updatedAt: now,
                events: [event]
            )
            history.insert(session, at: 0)
        }

        trim()
        save()
    }

    // MARK: - Log (one-off action, creates a session with a single event)

    func log(action: ReadingAction, detail: String, chapterNumber: Int = 0, chapterTitle: String = "", chapterVerses: Int = 0, verseId: String = "", verseNumber: Int = 0, excerpt: String = "") {
        let now = Date()
        let event = ReadingEvent(action: action, detail: detail, timestamp: now)
        let session = QuranReadingSession(
            chapterNumber: chapterNumber,
            chapterTitle: chapterTitle,
            chapterVerses: chapterVerses,
            verseId: verseId,
            verseNumber: verseNumber,
            excerpt: excerpt,
            action: action,
            startedAt: now,
            updatedAt: now,
            events: [event]
        )
        history.insert(session, at: 0)
        trim()
        save()
    }

    func remove(_ session: QuranReadingSession) {
        history.removeAll { $0.id == session.id }
        save()
    }

    func removeAll(where predicate: (QuranReadingSession) -> Bool) {
        history.removeAll(where: predicate)
        save()
    }

    func clear() {
        history = []
        save()
    }

    private func trim() {
        var seen = Set<String>()
        history = history.filter { seen.insert($0.id).inserted }
        if history.count > maxEntries {
            history = Array(history.prefix(maxEntries))
        }
    }

    private func save() {
        Defaults[.quran_reading_sessions] = history
    }
}
