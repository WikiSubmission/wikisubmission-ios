import SwiftData

@Model
final class QuranWordByWordSD {
    @Attribute(.unique) var index: Int
    var verse_index: Int
    var verse_id: String
    var word_index: Int
    var root_word: String?
    var arabic: String
    var english: String
    var transliterated: String
    var meanings: String?
    var chapter_number: Int
    var verse_number: Int
    
    init(index: Int, verse_index: Int, verse_id: String, word_index: Int, root_word: String?, arabic: String, english: String, transliterated: String, meanings: String?, chapter_number: Int, verse_number: Int) {
        self.index = index
        self.verse_index = verse_index
        self.verse_id = verse_id
        self.word_index = word_index
        self.root_word = root_word
        self.arabic = arabic
        self.english = english
        self.transliterated = transliterated
        self.meanings = meanings
        self.chapter_number = chapter_number
        self.verse_number = verse_number
    }
}


