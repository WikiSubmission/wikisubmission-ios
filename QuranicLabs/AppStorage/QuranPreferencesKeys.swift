import Defaults

extension Defaults.Keys {
    static let arabic = Key<Bool>("arabic", default: false)
    static let subtitles = Key<Bool>("subtitles", default: true)
    static let footnotes = Key<Bool>("footnotes", default: true)
    static let transliteration = Key<Bool>("transliteration", default: false)
    static let arabic_on_side = Key<Bool>("arabic_on_side", default: true)

    static let primary_language = Key<Types.Quran.PrimaryLanguage>("primary_language", default: .english)
    static let secondary_language = Key<Types.Quran.SecondaryLanguage>("secondary_language", default: .none)
    
    static let use_serif_font_design = Key<Bool>("use_serif_font_design", default: false)
    static let font_size = Key<Double>("font_size", default: 19)
    
    static let sort_chapters_by_revelation_order = Key<Bool>("sort_chapters_by_revelation_order", default: false)
    
    static let quran_reciter = Key<QuranReciters>("quran_reciter", default: .mishary)
    static let last_played_verse = Key<String>("last_played_verse", default: "1:1")
    static let last_opened_chapter = Key<Int>("last_opened_chapter", default: 39)
    static let last_read_verse = Key<String>("last_read_verse", default: "1:1")
}

extension Defaults {
    static func resetQuranPreferences() {
        Defaults.Keys.arabic.reset()
        Defaults.Keys.subtitles.reset()
        Defaults.Keys.footnotes.reset()
        Defaults.Keys.transliteration.reset()
        Defaults.Keys.arabic_on_side.reset()
        Defaults.Keys.primary_language.reset()
        Defaults.Keys.secondary_language.reset()
        Defaults.Keys.font_size.reset()
        Defaults.Keys.sort_chapters_by_revelation_order.reset()
    }
}
