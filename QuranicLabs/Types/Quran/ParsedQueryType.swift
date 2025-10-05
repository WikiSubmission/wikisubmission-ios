extension Types.Quran {
    enum ParsedQuery: String {
        case verse
        case verseRange
        case multipleVerses
        case chapter
        case search
        case invalid
        case unknown
    }
}
