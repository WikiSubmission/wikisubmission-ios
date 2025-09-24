import SwiftUI
import Defaults

extension Utilities.Quran {

    struct DataAPI {

        static func fetchVerse(chapter: Int, verse: Int) -> [Types.Quran.Data] {
            if let v = AppData.Quran.verse(chapter: chapter, verse: verse) {
                return [v]
            }
            return []
        }

        static func fetchRange(chapter: Int, start: Int, end: Int) -> [Types.Quran.Data] {
            guard let verses = AppData.Quran.versesByChapter[chapter] else { return [] }
            return verses.filter { ($0.verse_number >= start && $0.verse_number <= end) }
        }

        static func fetchMultiple(chapter: Int, verses: [Int]) -> [Types.Quran.Data] {
            guard let chapterVerses = AppData.Quran.versesByChapter[chapter] else { return [] }
            let verseSet = Set(verses)
            return chapterVerses.filter { verseSet.contains($0.verse_number) }
        }

        static func fetchChapter(chapter: Int) -> [Types.Quran.Data] {
            return AppData.Quran.versesByChapter[chapter] ?? []
        }

        @MainActor
        static func search(
            term: String,
            language: Types.Quran.PrimaryLanguage = .english,
            fuzzy: Bool = true,
            secondary: Types.Quran.SecondaryLanguage = .none
        ) -> [Types.Quran.Data] {
            let showSubtitles = Defaults[.subtitles]
            let showFootnotes = Defaults[.footnotes]

            let query = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty, query.count > 2 else { return [] }

            var results: [Types.Quran.Data] = []

            for data in AppData.Quran.main {
                let verseText = data.getPrimaryText(for: language).lowercased()
                let subtitleText = showSubtitles ? data.getSubtitle(for: language)?.lowercased() ?? "" : ""
                let footnoteText = showFootnotes ? data.getFootnote(for: language)?.lowercased() ?? "" : ""

                func matches(_ text: String) -> Bool {
                    if fuzzy {
                        return query.split(separator: " ").allSatisfy { word in text.contains(word) }
                    } else {
                        return text.contains(query)
                    }
                }

                if matches(verseText) || matches(subtitleText) || matches(footnoteText) {
                    results.append(data)

                    if results.count >= 500 { break }
                }
            }

            return results
        }
    
        static func randomChapter() -> [Types.Quran.Data] {
            guard let chapter = (1...114).randomElement() else { return [] }
            return fetchChapter(chapter: chapter)
        }

        static func randomVerse() -> Types.Quran.Data? {
            AppData.Quran.main.randomElement()
        }
    }
}
