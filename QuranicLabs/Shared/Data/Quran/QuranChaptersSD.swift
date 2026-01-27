import SwiftData

@Model
final class QuranChaptersSD {
    @Attribute(.unique) var chapter_number: Int
    var chapter_verses: Int
    var revelation_order: Int
    var title_english: String
    var title_arabic: String
    var title_transliterated: String
    var title_turkish: String
    var title_french: String
    var title_german: String
    var title_bahasa: String
    var title_persian: String
    var title_tamil: String
    var title_swedish: String
    var title_russian: String
    var title_bengali: String
    var title_urdu: String
    var title_spanish: String

    init(
        chapter_number: Int,
        chapter_verses: Int,
        revelation_order: Int,
        title_english: String,
        title_arabic: String,
        title_transliterated: String,
        title_turkish: String,
        title_french: String,
        title_german: String,
        title_bahasa: String,
        title_persian: String,
        title_tamil: String,
        title_swedish: String,
        title_russian: String,
        title_bengali: String,
        title_urdu: String,
        title_spanish: String
    ) {
        self.chapter_number = chapter_number
        self.chapter_verses = chapter_verses
        self.revelation_order = revelation_order
        self.title_english = title_english
        self.title_arabic = title_arabic
        self.title_transliterated = title_transliterated
        self.title_turkish = title_turkish
        self.title_french = title_french
        self.title_german = title_german
        self.title_bahasa = title_bahasa
        self.title_persian = title_persian
        self.title_tamil = title_tamil
        self.title_swedish = title_swedish
        self.title_russian = title_russian
        self.title_bengali = title_bengali
        self.title_urdu = title_urdu
        self.title_spanish = title_spanish
    }
}
