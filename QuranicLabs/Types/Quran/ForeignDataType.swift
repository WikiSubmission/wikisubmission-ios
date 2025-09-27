extension Types.Quran {
    struct ForeignData: Codable, Hashable {
        let verse_id: String

        // Chapter titles
        let chapter_title_turkish: String
        let chapter_title_french: String
        let chapter_title_german: String
        let chapter_title_bahasa: String
        let chapter_title_persian: String
        let chapter_title_tamil: String
        let chapter_title_swedish: String
        let chapter_title_russian: String

        // Verse text
        let verse_text_turkish: String?
        let verse_text_french: String?
        let verse_text_german: String?
        let verse_text_bahasa: String?
        let verse_text_persian: String?
        let verse_text_tamil: String?
        let verse_text_swedish: String?
        let verse_text_russian: String?

        // Verse subtitle
        let verse_subtitle_turkish: String?
        let verse_subtitle_french: String?
        let verse_subtitle_german: String?
        let verse_subtitle_bahasa: String?
        let verse_subtitle_persian: String?
        let verse_subtitle_tamil: String?
        let verse_subtitle_swedish: String?
        let verse_subtitle_russian: String?

        // Verse footnote
        let verse_footnote_turkish: String?
        let verse_footnote_french: String?
        let verse_footnote_german: String?
        let verse_footnote_bahasa: String?
        let verse_footnote_persian: String?
        let verse_footnote_tamil: String?
        let verse_footnote_swedish: String?
        let verse_footnote_russian: String?
    }
}
