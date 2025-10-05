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
        ) -> Types.Quran.SearchResult {
            var results: Types.Quran.SearchResult = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])

            let query = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty, query.count > 2 else {
                results.type = .invalid
                return results
            }
            
            if query.contains(",") && query.contains(":") {
                handleMultipleVerses(query: query, results: &results)
                results.type = .multipleVerses
                return results
            }
            
            let parsedQuery = Utilities.Quran.QueryParser.parse(query)
            
            if parsedQuery == .chapter {
                if let chapter = Int(query) {
                    results.chapters.append(chapter)
                }
            } else if parsedQuery == .verse {
                if let components = query.split(separator: ":").map({ String($0) }) as [String]?,
                   components.count == 2,
                   let chapter = Int(components[0]),
                   let verse = Int(components[1]),
                   isValidVerse(chapter: chapter, verse: verse) {
                    results.verseIDs.append(query)
                }
            } else if parsedQuery == .multipleVerses {
                let segments = query.split(separator: ",")
                for segment in segments {
                    let trimmedSegment = segment.trimmingCharacters(in: .whitespaces)
                    if trimmedSegment.contains("-") {
                        // Handle range within segment, e.g. "9:3-9"
                        let parts = trimmedSegment.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                        if parts.count == 2 {
                            let startPart = parts[0]
                            let endPart = parts[1]
                            // Parse chapter and start verse
                            let startComponents = startPart.split(separator: ":").map { String($0) }
                            guard startComponents.count == 2,
                                  let chapter = Int(startComponents[0]),
                                  let startVerse = Int(startComponents[1]),
                                  let endVerse = Int(endPart) else {
                                // Malformed range, skip
                                continue
                            }
                            if endVerse >= startVerse {
                                for v in startVerse...endVerse {
                                    if isValidVerse(chapter: chapter, verse: v) {
                                        results.verseIDs.append("\(chapter):\(v)")
                                    }
                                }
                            }
                        }
                    } else {
                        // Single verse id
                        if let components = trimmedSegment.split(separator: ":").map({ String($0) }) as [String]?,
                           components.count == 2,
                           let chapter = Int(components[0]),
                           let verse = Int(components[1]),
                           isValidVerse(chapter: chapter, verse: verse) {
                            results.verseIDs.append(trimmedSegment)
                        }
                    }
                }
            } else if parsedQuery == .verseRange {
                // Handle input like "2:33-35"
                let parts = query.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    let startPart = parts[0]
                    let endPart = parts[1]
                    let startComponents = startPart.split(separator: ":").map { String($0) }
                    guard startComponents.count == 2,
                          let chapter = Int(startComponents[0]),
                          let startVerse = Int(startComponents[1]),
                          let endVerse = Int(endPart) else {
                        // Malformed range, fallback to appending the query as is
                        results.verseIDs.append(query)
                        return results
                    }
                    if endVerse >= startVerse {
                        for v in startVerse...endVerse {
                            if isValidVerse(chapter: chapter, verse: v) {
                                results.verseIDs.append("\(chapter):\(v)")
                            }
                        }
                    } else {
                        results.verseIDs.append(query)
                    }
                } else {
                    results.verseIDs.append(query)
                }
            } else if parsedQuery == .search {
                let searchTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                for data in AppData.Quran.main {
                    let verseText = data.getPrimaryText(for: language).lowercased()
                    let subtitleText = data.getSubtitle(for: language)?.lowercased()
                    let footnoteText = data.getFootnote(for: language)?.lowercased()

                    func matches(_ text: String?) -> Bool {
                        guard let text = text else { return false }
                        if fuzzy {
                            return searchTerm
                                .split(separator: " ")
                                .allSatisfy { word in text.contains(word) }
                        } else {
                            return text.contains(searchTerm)
                        }
                    }

                    if matches(verseText) {
                        results.text.append(data)
                    }
                    if matches(subtitleText) {
                        results.subtitles.append(data)
                    }
                    if matches(footnoteText) {
                        results.footnotes.append(data)
                    }

                    if results.text.count >= 500 { break }
                }
            }

            return results
        }
    
        private static func handleMultipleVerses(query: String, results: inout Types.Quran.SearchResult) {
            let segments = query.split(separator: ",")
            for segment in segments {
                let trimmedSegment = segment.trimmingCharacters(in: .whitespaces)
                if trimmedSegment.contains("-") {
                    let parts = trimmedSegment.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        let startPart = parts[0]
                        let endPart = parts[1]
                        let startComponents = startPart.split(separator: ":").map { String($0) }
                        guard startComponents.count == 2,
                              let chapter = Int(startComponents[0]),
                              let startVerse = Int(startComponents[1]),
                              let endVerse = Int(endPart) else {
                            continue
                        }
                        if endVerse >= startVerse {
                            for v in startVerse...endVerse {
                                if isValidVerse(chapter: chapter, verse: v) {
                                    results.verseIDs.append("\(chapter):\(v)")
                                }
                            }
                        }
                    }
                } else {
                    if let components = trimmedSegment.split(separator: ":").map({ String($0) }) as [String]?,
                       components.count == 2,
                       let chapter = Int(components[0]),
                       let verse = Int(components[1]),
                       isValidVerse(chapter: chapter, verse: verse) {
                        results.verseIDs.append(trimmedSegment)
                    }
                }
            }
        }
        
        private static func isValidVerse(chapter: Int, verse: Int) -> Bool {
            guard let verses = AppData.Quran.versesByChapter[chapter] else { return false }
            return verses.contains { $0.verse_number == verse }
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
