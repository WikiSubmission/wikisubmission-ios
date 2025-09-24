import Defaults

extension Defaults.Keys {
    static let arabic = Key<Bool>("arabic", default: false)
    static let subtitles = Key<Bool>("subtitles", default: true)
    static let footnotes = Key<Bool>("footnotes", default: true)
    static let transliteration = Key<Bool>("transliteration", default: false)
    static let arabic_on_side = Key<Bool>("arabic_on_side", default: true)

    static let primary_language = Key<Types.Quran.PrimaryLanguage>("primary_language", default: .english)
    static let secondary_language = Key<Types.Quran.SecondaryLanguage>("secondary_language", default: .none)
    
    static let font_size = Key<Double>("font_size", default: 19)
    
    static let sort_chapters_by_revelation_order = Key<Bool>("sort_chapters_by_revelation_order", default: false)
}
