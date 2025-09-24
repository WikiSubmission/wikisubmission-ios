extension Types.Quran {
    struct Data: Identifiable, Codable, Hashable {
        var id: String { verse_id }
        let verse_id: String
        let verse_id_arabic: String
        let chapter_number: Int
        let verse_number: Int
        let verse_index: Int
        let verse_index_numbered: Int?
        let chapter_verses: Int
        let chapter_revelation_order: Int

        // Chapter title
        let chapter_title_english: String
        let chapter_title_arabic: String
        let chapter_title_transliterated: String

        // Verse text
        let verse_text_english: String
        let verse_text_arabic: String
        let verse_text_arabic_clean: String
        let verse_text_transliterated: String

        // Verse subtitle
        let verse_subtitle_english: String?

        // Verse footnote
        let verse_footnote_english: String?
    }
}
