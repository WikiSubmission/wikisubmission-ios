import SwiftData

@Model
final class QuranIndexSD {
    @Attribute(.unique) var verse_index: Int
    var verse_id: String
    var chapter_number: Int
    var verse_number: Int
    var chapter_verses: Int
    var verse_id_arabic: String
    
    init(verse_index: Int, verse_id: String, chapter_number: Int, verse_number: Int, chapter_verses: Int, verse_id_arabic: String) {
        self.verse_index = verse_index
        self.verse_id = verse_id
        self.chapter_number = chapter_number
        self.verse_number = verse_number
        self.chapter_verses = chapter_verses
        self.verse_id_arabic = verse_id_arabic
    }
}
