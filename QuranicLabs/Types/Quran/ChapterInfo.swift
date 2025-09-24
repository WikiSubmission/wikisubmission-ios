extension Types.Quran {
    struct ChapterInfo: Codable, Hashable {
        let chapter_number: Int
        let revelation_order: Int
        let chapter_verses: Int
        let chapter_title_english: String
        let chapter_title_arabic: String
        let chapter_title_transliterated: String
        let chapter_title_turkish: String
        let chapter_title_french: String
        let chapter_title_german: String
        let chapter_title_bahasa: String
        let chapter_title_persian: String
        let chapter_title_tamil: String
        let chapter_title_swedish: String
        let chapter_title_russian: String
        
        func getChapterTitle(for language: Types.Quran.PrimaryLanguage) -> String {
            switch language {
            case .english: return chapter_title_english
            case .turkish: return self.chapter_title_turkish
            case .french: return self.chapter_title_french
            case .german: return self.chapter_title_german
            case .bahasa: return self.chapter_title_bahasa
            case .persian: return self.chapter_title_persian
            case .tamil: return self.chapter_title_tamil
            case .swedish: return self.chapter_title_swedish
            case .russian: return self.chapter_title_russian
            }
        }
    }
}
