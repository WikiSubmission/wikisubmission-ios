import Foundation
import SwiftData

struct QuranSearchEngine {

    static func search(query: String, context: ModelContext) -> [QuranSearchResultItem] {
        let cleanedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedQuery.count >= 2 else { return [] }

        var results: [QuranSearchResultItem] = []

        // 1. Check for verse_id pattern (e.g., "2:255", "1:1")
        results.append(contentsOf: searchVerseIndex(query: cleanedQuery, context: context))

        // 2. Search chapter names (fast - only 114 chapters)
        results.append(contentsOf: searchChapters(query: cleanedQuery, context: context))

        // 3. Search text content
        results.append(contentsOf: searchText(query: cleanedQuery, context: context))

        // 4. Search subtitles
        results.append(contentsOf: searchSubtitles(query: cleanedQuery, context: context))

        // 5. Search footnotes
        results.append(contentsOf: searchFootnotes(query: cleanedQuery, context: context))

        // Deduplicate by verse_index, keeping highest priority hit type
        let deduplicated = deduplicateResults(results)

        // Sort: exceptional relevance (>0.85) first, then by verse_index
        return sortResults(deduplicated)
    }

    private static func searchVerseIndex(query: String, context: ModelContext) -> [QuranSearchResultItem] {
        // Check for verse_id pattern like "2:255" or "2 255"
        let verseIdPattern = query
            .replacingOccurrences(of: " ", with: ":")
            .split(separator: "-").first.map(String.init) ?? query

        // Direct match lookup
        if let unified = QuranUnified.fetchVerse(byId: verseIdPattern, context: context) {
            return [QuranSearchResultItem(
                unified: unified,
                hitType: .index,
                relevanceScore: 1.0
            )]
        }

        // Check if query looks like a verse reference (contains : or is numeric)
        let looksLikeVerseId = query.contains(":") || query.allSatisfy({ $0.isNumber || $0 == " " })
        guard looksLikeVerseId else { return [] }

        // Partial match for verse IDs
        let descriptor = FetchDescriptor<QuranIndexSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )

        guard let allIndices = try? context.fetch(descriptor) else {
            return []
        }

        var results: [QuranSearchResultItem] = []
        for index in allIndices where index.verse_id.contains(query) {
            let unified = QuranUnified(from: index, context: context)
            let score = index.verse_id == query ? 1.0 : 0.8
            results.append(QuranSearchResultItem(
                unified: unified,
                hitType: .index,
                relevanceScore: score
            ))
            if results.count >= 5 { break }
        }

        return results
    }

    private static func searchChapters(query: String, context: ModelContext) -> [QuranSearchResultItem] {
        var results: [QuranSearchResultItem] = []

        for chapter in QuranChapters.fetchAll(context: context) {
            let textToMatch = "\(chapter.chapter_number) \(chapter.getTitleInUserLanguage()) \(chapter.title_transliterated) \(chapter.title_english) \(chapter.title_arabic)".lowercased()

            if simpleMatch(text: textToMatch, query: query) {
                // Get the first verse of the chapter
                if let firstVerse = QuranUnified.fetchVerse(chapter: chapter.chapter_number, verse: 1, context: context) {
                    let score = calculateRelevanceScore(text: textToMatch, query: query)
                    results.append(QuranSearchResultItem(
                        unified: firstVerse,
                        hitType: .chapter,
                        relevanceScore: score,
                        matchedChapter: chapter
                    ))
                }
            }

            if results.count >= 5 { break }
        }

        return results
    }

    private static func searchText(query: String, context: ModelContext) -> [QuranSearchResultItem] {
        let descriptor = FetchDescriptor<QuranTextSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )

        guard let allTexts = try? context.fetch(descriptor) else {
            return []
        }

        var results: [QuranSearchResultItem] = []

        for text in allTexts {
            let textToMatch = text.getTextInUserLanguage().lowercased()

            if simpleMatch(text: textToMatch, query: query) {
                let unified = QuranUnified(from: text, context: context)
                let score = calculateRelevanceScore(text: textToMatch, query: query)
                results.append(QuranSearchResultItem(
                    unified: unified,
                    hitType: .text,
                    relevanceScore: score
                ))
            }
        }

        return results
    }

    private static func searchSubtitles(query: String, context: ModelContext) -> [QuranSearchResultItem] {
        let descriptor = FetchDescriptor<QuranSubtitlesSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )

        guard let allSubtitles = try? context.fetch(descriptor) else {
            return []
        }

        var results: [QuranSearchResultItem] = []

        for subtitle in allSubtitles {
            let textToMatch = subtitle.getTextInUserLanguage().lowercased()

            if simpleMatch(text: textToMatch, query: query) {
                let unified = QuranUnified(from: subtitle, context: context)
                let score = calculateRelevanceScore(text: textToMatch, query: query)
                results.append(QuranSearchResultItem(
                    unified: unified,
                    hitType: .subtitle,
                    relevanceScore: score
                ))
            }
        }

        return results
    }

    private static func searchFootnotes(query: String, context: ModelContext) -> [QuranSearchResultItem] {
        let descriptor = FetchDescriptor<QuranFootnotesSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )

        guard let allFootnotes = try? context.fetch(descriptor) else {
            return []
        }

        var results: [QuranSearchResultItem] = []

        for footnote in allFootnotes {
            let textToMatch = footnote.getTextInUserLanguage().lowercased()

            if simpleMatch(text: textToMatch, query: query) {
                let unified = QuranUnified(from: footnote, context: context)
                let score = calculateRelevanceScore(text: textToMatch, query: query)
                results.append(QuranSearchResultItem(
                    unified: unified,
                    hitType: .footnote,
                    relevanceScore: score
                ))
            }
        }

        return results
    }

    private static func simpleMatch(text: String, query: String) -> Bool {
        let queryWords = query.split(separator: " ").map(String.init)

        // All query words must be present (AND logic)
        return queryWords.allSatisfy { queryWord in
            text.contains(queryWord)
        }
    }

    private static func calculateRelevanceScore(text: String, query: String) -> Double {
        // Exact match: 1.0
        if text == query {
            return 1.0
        }

        var score = 0.3 // Base score for any match

        // Text starts with query: +0.4
        if text.hasPrefix(query) {
            score += 0.4
        }

        // Text contains exact query: +0.3
        if text.contains(query) {
            score += 0.3
        }

        // Word-level matching: +0.3
        let queryWords = query.split(separator: " ")
        let textWords = text.split(separator: " ")
        let matchedWords = queryWords.filter { qWord in
            textWords.contains { tWord in
                tWord.lowercased().hasPrefix(String(qWord).lowercased())
            }
        }
        if !queryWords.isEmpty {
            score += 0.3 * Double(matchedWords.count) / Double(queryWords.count)
        }

        return min(score, 1.0)
    }

    private static func deduplicateResults(_ results: [QuranSearchResultItem]) -> [QuranSearchResultItem] {
        var seenVerseIndices: [Int: QuranSearchResultItem] = [:]

        for result in results {
            let verseIndex = result.unified.index.verse_index

            if let existing = seenVerseIndices[verseIndex] {
                // Keep the one with higher priority hit type (lower priority number)
                if result.hitType.priority < existing.hitType.priority {
                    seenVerseIndices[verseIndex] = result
                } else if result.hitType.priority == existing.hitType.priority && result.relevanceScore > existing.relevanceScore {
                    seenVerseIndices[verseIndex] = result
                }
            } else {
                seenVerseIndices[verseIndex] = result
            }
        }

        return Array(seenVerseIndices.values)
    }

    private static func sortResults(_ results: [QuranSearchResultItem]) -> [QuranSearchResultItem] {
        return results.sorted { a, b in
            // Exceptional relevance (>0.85) comes first
            let aExceptional = a.relevanceScore > 0.85
            let bExceptional = b.relevanceScore > 0.85

            if aExceptional && !bExceptional {
                return true
            } else if !aExceptional && bExceptional {
                return false
            } else if aExceptional && bExceptional {
                // Both exceptional: sort by relevance score descending
                return a.relevanceScore > b.relevanceScore
            } else {
                // Neither exceptional: sort by verse_index
                return a.unified.index.verse_index < b.unified.index.verse_index
            }
        }
    }

    static func countByHitType(_ results: [QuranSearchResultItem]) -> [SearchHitType: Int] {
        var counts: [SearchHitType: Int] = [:]
        for hitType in SearchHitType.allCases {
            counts[hitType] = results.filter { $0.hitType == hitType }.count
        }
        return counts
    }

    static func filter(_ results: [QuranSearchResultItem], by filter: SearchFilter) -> [QuranSearchResultItem] {
        guard let hitType = filter.hitType else {
            return results
        }
        return results.filter { $0.hitType == hitType }
    }
}
