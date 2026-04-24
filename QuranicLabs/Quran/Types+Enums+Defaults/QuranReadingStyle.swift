import Defaults

enum QuranReadingStyle: String, CaseIterable, Defaults.Serializable {
    case book = "Book"
    case cards = "Cards"
    case wordByWord = "Word by Word"

    var systemImage: String {
        switch self {
        case .book:
            return "text.quote"
        case .cards:
            return "rectangle.grid.1x2"
        case .wordByWord:
            return "character.book.closed"
        }
    }

    /// Whether this style uses the cards visual layout
    var isCardsBased: Bool {
        self == .cards || self == .wordByWord
    }
}
