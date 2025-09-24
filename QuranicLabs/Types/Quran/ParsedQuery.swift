extension Types.Quran {
    enum ParsedQuery {
        case verse(chapter: Int, verse: Int)
        case verseRange(chapter: Int, start: Int, end: Int)
        case multipleVerses(chapter: Int, verses: [Int])
        case chapter(chapter: Int)
        case search(term: String, language: Types.Quran.PrimaryLanguage, fuzzy: Bool)
        case randomChapter
        case randomVerse
        case invalid(reason: String)
        
        /// Returns the type of query as a simple enum case without associated values
        var type: QueryType {
            switch self {
            case .verse: return .verse
            case .verseRange: return .verseRange
            case .multipleVerses: return .multipleVerses
            case .chapter: return .chapter
            case .search: return .search
            case .randomChapter: return .randomChapter
            case .randomVerse: return .randomVerse
            case .invalid: return .invalid
            }
        }
        
        enum QueryType: String {
            case verse, verseRange, multipleVerses, chapter, search, randomChapter, randomVerse, invalid
        }
    }
}
