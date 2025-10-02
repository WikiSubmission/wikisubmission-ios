import Defaults

extension Types.Bookmarks {
    struct Bookmark: Encodable, Decodable, Hashable, Defaults.Serializable {
        let created_at: String
        let updated_at: String?
        let type: Types.Bookmarks.BookmarkType
        let key: String
        let category: String?
        let notes: String?
    }
    
    enum BookmarkType: String, Encodable, Decodable, Hashable, Defaults.Serializable {
        case chapter, verse
    }
}
