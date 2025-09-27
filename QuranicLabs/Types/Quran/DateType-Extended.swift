extension Types.Quran.Data {
    private var foreignReference: Types.Quran.ForeignData? {
        AppData.Quran.foreign.first { $0.verse_id == self.verse_id }
    }

    private var wordByWordReference: [Types.Quran.WordByWord] {
        AppData.Quran.wordByWord.filter { $0.verse_id == self.verse_id }
    }
    
    func getPrimaryText(for language: Types.Quran.PrimaryLanguage) -> String {
        switch language {
        case .english: return verse_text_english
        case .turkish: return foreignReference?.verse_text_turkish ?? verse_text_english
        case .french: return foreignReference?.verse_text_french ?? verse_text_english
        case .german: return foreignReference?.verse_text_german ?? verse_text_english
        case .bahasa: return foreignReference?.verse_text_bahasa ?? verse_text_english
        case .persian: return foreignReference?.verse_text_persian ?? verse_text_english
        case .tamil: return foreignReference?.verse_text_tamil ?? verse_text_english
        case .swedish: return foreignReference?.verse_text_swedish ?? verse_text_english
        case .russian: return foreignReference?.verse_text_russian ?? verse_text_english
        }
    }
    
    func getSecondaryText(for language: Types.Quran.SecondaryLanguage) -> String? {
        switch language {
        case .none: return nil
        case .english: return self.verse_text_english
        case .turkish: return foreignReference?.verse_text_turkish
        case .french: return foreignReference?.verse_text_french
        case .german: return foreignReference?.verse_text_german
        case .bahasa: return foreignReference?.verse_text_bahasa
        case .persian: return foreignReference?.verse_text_persian
        case .tamil: return foreignReference?.verse_text_tamil
        case .swedish: return foreignReference?.verse_text_swedish
        case .russian: return foreignReference?.verse_text_russian
        }
    }
    
    func getSubtitle(for language: Types.Quran.PrimaryLanguage) -> String? {
        switch language {
        case .english: return verse_subtitle_english
        case .turkish: return foreignReference?.verse_subtitle_turkish ?? verse_subtitle_english
        case .french: return foreignReference?.verse_subtitle_french ?? verse_subtitle_english
        case .german: return foreignReference?.verse_subtitle_german ?? verse_subtitle_english
        case .bahasa: return foreignReference?.verse_subtitle_bahasa ?? verse_subtitle_english
        case .persian: return foreignReference?.verse_subtitle_persian ?? verse_subtitle_english
        case .tamil: return foreignReference?.verse_subtitle_tamil ?? verse_subtitle_english
        case .swedish: return foreignReference?.verse_subtitle_swedish ?? verse_subtitle_english
        case .russian: return foreignReference?.verse_subtitle_russian ?? verse_subtitle_english
        }
    }
    
    func getFootnote(for language: Types.Quran.PrimaryLanguage) -> String? {
        switch language {
        case .english: return verse_footnote_english
        case .turkish: return foreignReference?.verse_footnote_turkish ?? verse_footnote_english
        case .french: return foreignReference?.verse_footnote_french ?? verse_footnote_english
        case .german: return foreignReference?.verse_footnote_german ?? verse_footnote_english
        case .bahasa: return foreignReference?.verse_footnote_bahasa ?? verse_footnote_english
        case .persian: return foreignReference?.verse_footnote_persian ?? verse_footnote_english
        case .tamil: return foreignReference?.verse_footnote_tamil ?? verse_footnote_english
        case .swedish: return foreignReference?.verse_footnote_swedish ?? verse_footnote_english
        case .russian: return foreignReference?.verse_footnote_russian ?? verse_footnote_english
        }
    }

    func getChapterTitle(for language: Types.Quran.PrimaryLanguage) -> String {
        switch language {
        case .english: return chapter_title_english
        case .turkish: return foreignReference?.chapter_title_turkish ?? chapter_title_english
        case .french: return foreignReference?.chapter_title_french ?? chapter_title_english
        case .german: return foreignReference?.chapter_title_german ?? chapter_title_english
        case .bahasa: return foreignReference?.chapter_title_bahasa ?? chapter_title_english
        case .persian: return foreignReference?.chapter_title_persian ?? chapter_title_english
        case .tamil: return foreignReference?.chapter_title_tamil ?? chapter_title_english
        case .swedish: return foreignReference?.chapter_title_swedish ?? chapter_title_english
        case .russian: return foreignReference?.chapter_title_russian ?? chapter_title_english
        }
    }

    func getWordByWord() -> [Types.Quran.WordByWord] {
        wordByWordReference.sorted { $0.word_index < $1.word_index }
    }
}
