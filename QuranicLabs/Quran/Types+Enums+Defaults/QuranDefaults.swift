import Defaults

extension Defaults.Keys {
    static let arabic = Key<Bool>("arabic", default: false)
    static let subtitles = Key<Bool>("subtitles", default: true)
    static let footnotes = Key<Bool>("footnotes", default: true)
    static let transliteration = Key<Bool>("transliteration", default: false)
    
    static let quran_primary_language = Key<QuranSelectablePrimaryLanguage>("quran_primary_language", default: .english)
    static let quran_secondary_language = Key<QuranSelectableSecondaryLanguage>("quran_secondary_language", default: .none)
    
    static let font_size = Key<Double>("font_size", default: 19)
    static let arabic_font_size = Key<Double>("arabic_font_size", default: 23)
    
    static let sort_chapters_by_revelation_order = Key<Bool>("sort_chapters_by_revelation_order", default: false)
    
    static let quran_reciter = Key<QuranReciters>("quran_reciter", default: .onyx)
    static let last_read_verse_id = Key<String>("last_read_verse_id", default: "1:1")
    
    static let quran_search_history = Key<[String]>("quran_search_history", default: [])
    static let quran_reader_style = Key<QuranReadingStyle>("quran_reading_style", default: .book)
    static let word_by_word = Key<Bool>("word_by_word", default: false)
    static let quran_arabic_font = Key<QuranArabicFont>("quran_arabic_font", default: .amiriQuran)
}

extension Defaults {
    static func resetQuranPreferences() {
        Defaults.Keys.arabic.reset()
        Defaults.Keys.subtitles.reset()
        Defaults.Keys.footnotes.reset()
        Defaults.Keys.transliteration.reset()
        Defaults.Keys.font_size.reset()
        Defaults.Keys.arabic_font_size.reset()
        Defaults.Keys.sort_chapters_by_revelation_order.reset()
        Defaults.Keys.quran_reciter.reset()
        Defaults.Keys.last_read_verse_id.reset()
        Defaults.Keys.quran_search_history.reset()
        Defaults.Keys.quran_reader_style.reset()
        Defaults.Keys.word_by_word.reset()
        Defaults.Keys.quran_arabic_font.reset()
    }
}
