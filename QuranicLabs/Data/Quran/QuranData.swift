import Foundation

extension AppData.Quran {
    
    static let main: [Types.Quran.Data] = Bundle.main.decode(
        [Types.Quran.Data].self,
        from: "ws-quran_2025-09-10.json"
    )
    
    static let foreign: [Types.Quran.ForeignData] = Bundle.main.decode(
        [Types.Quran.ForeignData].self,
        from: "ws-quran-foreign_2025-09-10.json"
    )
    
    static let wordByWord: [Types.Quran.WordByWord] = Bundle.main.decode(
        [Types.Quran.WordByWord].self,
        from: "ws-quran-word-by-word_2025-09-19.json"
    )
    
    static let chapters: [Types.Quran.ChapterInfo] = {
        let englishChapters = AppData.Quran.main
            .filter { $0.verse_number == 1 }

        let foreignChapters = AppData.Quran.foreign
            .filter { $0.verse_id.hasSuffix(":1") }

        return englishChapters.map { english in
            let foreign = foreignChapters.first { $0.verse_id.hasPrefix("\(english.chapter_number):1") }

            return Types.Quran.ChapterInfo(
                chapter_number: english.chapter_number,
                revelation_order: english.chapter_revelation_order,
                chapter_verses: english.chapter_verses,
                chapter_title_english: english.chapter_title_english,
                chapter_title_arabic: english.chapter_title_arabic,
                chapter_title_transliterated: english.chapter_title_transliterated,
                chapter_title_turkish: foreign?.chapter_title_turkish ?? "",
                chapter_title_french: foreign?.chapter_title_french ?? "",
                chapter_title_german: foreign?.chapter_title_german ?? "",
                chapter_title_bahasa: foreign?.chapter_title_bahasa ?? "",
                chapter_title_persian: foreign?.chapter_title_persian ?? "",
                chapter_title_tamil: foreign?.chapter_title_tamil ?? "",
                chapter_title_swedish: foreign?.chapter_title_swedish ?? "",
                chapter_title_russian: foreign?.chapter_title_russian ?? ""
            )
        }
    }()
    
    static let sampleVerse = main.first { $0.verse_id == "2:20" }
    
    // MARK: - Precomputed caches for fast lookups
    static let versesByID: [String: Types.Quran.Data] = {
        Dictionary(uniqueKeysWithValues: main.map { ($0.verse_id, $0) })
    }()
    
    static let versesByChapter: [Int: [Types.Quran.Data]] = {
        Dictionary(grouping: main, by: { $0.chapter_number })
    }()
    
    static let versesByChapterAndNumber: [String: Types.Quran.Data] = {
        Dictionary(uniqueKeysWithValues: main.map { ("\($0.chapter_number)-\($0.verse_number)", $0) })
    }()
    
    // MARK: - Lookup methods
    
    static func verseByID(_ id: String) -> Types.Quran.Data? {
        versesByID[id]
    }
    
    static func verse(chapter: Int, verse: Int) -> Types.Quran.Data? {
        versesByChapterAndNumber["\(chapter)-\(verse)"]
    }
    
    // MARK: - Precomputed caches for WordByWord lookups
    static let wordByWordByVerseID: [String: [Types.Quran.WordByWord]] = {
        Dictionary(grouping: wordByWord, by: { $0.verse_id })
    }()
    
    static let wordByWordByRoot: [String: [Types.Quran.WordByWord]] = {
        Dictionary(grouping: wordByWord, by: { $0.root_word })
    }()
    
    // MARK: - Lookup methods
    static func wordByWordData(forVerseID verseID: String) -> [Types.Quran.WordByWord]? {
        wordByWordByVerseID[verseID]
    }
    
    static func versesWithRoot(_ root: String) -> [Types.Quran.WordByWord]? {
        wordByWordByRoot[root]
    }
}
