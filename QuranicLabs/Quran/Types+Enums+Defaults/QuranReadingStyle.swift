import Defaults

enum QuranReadingStyle: String, CaseIterable, Defaults.Serializable {
    case book = "Book"
    case cards = "Cards"
    
    var systemImage: String {
        switch self {
        case .book:
            return "text.quote"
        case .cards:
            return "rectangle.grid.1x2"
        }
    }
}
