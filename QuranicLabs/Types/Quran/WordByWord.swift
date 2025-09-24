extension Types.Quran {
    struct WordByWord: Codable, Hashable {
        let verse_id: String
        let word_index: Int
        let global_index: Int
        
        let root_word: String
        let english_text: String
        let arabic_text: String
        let transliterated_text: String
        
        let meanings: String
    }
}
