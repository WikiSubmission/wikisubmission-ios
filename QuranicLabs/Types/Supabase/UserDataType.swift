import Foundation

extension Types.Supabase {
    struct UserData: Decodable, Encodable {
        let quran_preferences: QuranPreferences
        let quran_bookmarks: Bookmarks
    }
    
    struct QuranPreferences: Decodable, Encodable {
        var arabic: Bool
        var subtitles: Bool
        var footnotes: Bool
        var transliteration: Bool
        var arabic_on_side: Bool
        var primary_language: String
        var secondary_language: String
        var font_size: Int
    }
    
    struct Bookmarks: Decodable, Encodable, Hashable {
        var id = UUID()
        var created_at: TimeInterval
        var updated_at: TimeInterval?
        var chapter_number: Int?
        var verse_id: String?
        var note: String?
        var category: String?
    }
}
