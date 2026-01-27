import Defaults
import SwiftData

@Model
final class QuranTextSD {
    @Attribute(.unique) var verse_index: Int
    var verse_id: String
    var english: String
    var arabic: String
    var transliterated: String
    var arabic_clean: String
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
    var urdu: String
    var persian_new: String
    var spanish: String
    
    init(verse_index: Int, verse_id: String, english: String, arabic: String, transliterated: String, arabic_clean: String, chapter_number: Int, verse_number: Int, turkish: String, french: String, german: String, bahasa: String, persian: String, tamil: String, swedish: String, russian: String, bengali: String, urdu: String, persian_new: String, spanish: String) {
        self.verse_index = verse_index
        self.verse_id = verse_id
        self.english = english
        self.arabic = arabic
        self.transliterated = transliterated
        self.arabic_clean = arabic_clean
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
        self.urdu = urdu
        self.persian_new = persian_new
        self.spanish = spanish
    }
}

extension QuranTextSD {
    func getTextInUserLanguage() -> String {
        return getTextInLanguage(Defaults[.quran_primary_language])
    }
    
    func getTextInUserLanguage(_ language: QuranSelectablePrimaryLanguage) -> String {
        return getTextInLanguage(language)
    }
    
    func getTextInUserLanguage(_ language: QuranSelectableSecondaryLanguage) -> String {
        switch language {
        case .none: return english
        case .english: return english
        case .turkish: return turkish
        case .french: return french
        case .german: return german
        case .bahasa: return bahasa
        case .persian: return persian
        case .persian_new: return persian_new
        case .tamil: return tamil
        case .swedish: return swedish
        case .russian: return russian
        case .bengali: return bengali
        case .spanish: return spanish
        case .urdu: return urdu
        }
    }
    
    func getTextInLanguage(_ language: QuranSelectablePrimaryLanguage) -> String {
        switch language {
        case .english: return english
        case .turkish: return turkish
        case .french: return french
        case .german: return german
        case .bahasa: return bahasa
        case .persian: return persian_new
        case .tamil: return tamil
        case .swedish: return swedish
        case .russian: return russian
        case .bengali: return bengali
        case .spanish: return spanish
        case .urdu: return urdu
        }
    }
}
