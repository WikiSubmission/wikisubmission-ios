import Foundation

// MARK: - Search Hit Type

enum SearchHitType: String, CaseIterable, Identifiable, Hashable {
    case index = "Index"
    case chapter = "Chapters"
    case text = "Text"
    case subtitle = "Subtitles"
    case footnote = "Footnotes"

    var id: Self { self }

    var icon: String {
        switch self {
        case .index: return "number"
        case .chapter: return "book"
        case .text: return "text.alignleft"
        case .subtitle: return "text.badge.star"
        case .footnote: return "note.text"
        }
    }

    // Priority for deduplication (lower = higher priority)
    var priority: Int {
        switch self {
        case .index: return 0
        case .chapter: return 1
        case .text: return 2
        case .subtitle: return 3
        case .footnote: return 4
        }
    }
}

// MARK: - Search Result Item

struct QuranSearchResultItem: Identifiable, Hashable {
    let id = UUID()
    let unified: QuranUnified
    let hitType: SearchHitType
    let relevanceScore: Double
    let matchedChapter: QuranChapters?

    init(
        unified: QuranUnified,
        hitType: SearchHitType,
        relevanceScore: Double = 0.5,
        matchedChapter: QuranChapters? = nil
    ) {
        self.unified = unified
        self.hitType = hitType
        self.relevanceScore = relevanceScore
        self.matchedChapter = matchedChapter
    }

    static func == (lhs: QuranSearchResultItem, rhs: QuranSearchResultItem) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Search Filter

enum SearchFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case index = "Index"
    case chapters = "Chapters"
    case text = "Text"
    case subtitles = "Subtitles"
    case footnotes = "Footnotes"

    var id: Self { self }

    var hitType: SearchHitType? {
        switch self {
        case .all: return nil
        case .index: return .index
        case .chapters: return .chapter
        case .text: return .text
        case .subtitles: return .subtitle
        case .footnotes: return .footnote
        }
    }

    static func from(hitType: SearchHitType) -> SearchFilter {
        switch hitType {
        case .index: return .index
        case .chapter: return .chapters
        case .text: return .text
        case .subtitle: return .subtitles
        case .footnote: return .footnotes
        }
    }
}
