import SwiftData
import Defaults

@Model
final class QuranSubtitlesSD {
    @Attribute(.unique) var verse_index: Int
    var verse_id: String
    var english: String
    var chapter_number: Int
    var verse_number: Int
    var turkish: String
    var french: String
    var german: String
    var bahasa: String
    var persian: String
    var tamil: String
    var swedish: String
    var russian: String
    var bengali: String
    var spanish: String
    var urdu: String
    
    init(verse_index: Int, verse_id: String, english: String, chapter_number: Int, verse_number: Int, turkish: String, french: String, german: String, bahasa: String, persian: String, tamil: String, swedish: String, russian: String, bengali: String, spanish: String, urdu: String) {
        self.verse_index = verse_index
        self.verse_id = verse_id
        self.english = english
        self.chapter_number = chapter_number
        self.verse_number = verse_number
        self.turkish = turkish
        self.french = french
        self.german = german
        self.bahasa = bahasa
        self.persian = persian
        self.tamil = tamil
        self.swedish = swedish
        self.russian = russian
        self.bengali = bengali
        self.spanish = spanish
        self.urdu = urdu
    }
}

extension QuranSubtitlesSD {
    func getTextInUserLanguage() -> String {
        return getTextInLanguage(Defaults[.quran_primary_language])
    }
    
    func getTextInUserLanguage(_ language: QuranSelectablePrimaryLanguage) -> String {
        return getTextInLanguage(language)
    }
    
    func getTextInLanguage(_ language: QuranSelectablePrimaryLanguage) -> String {
        switch language {
        case .english: return english
        case .turkish: return turkish
        case .french: return french
        case .german: return german
        case .bahasa: return bahasa
        case .persian: return persian
        case .tamil: return tamil
        case .swedish: return swedish
        case .russian: return russian
        case .bengali: return bengali
        case .spanish: return spanish
        case .urdu: return urdu
        }
    }
}
