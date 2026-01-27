import Foundation
import SwiftData
import Defaults

struct QuranUnified: Hashable {
    let index: QuranIndexSD
    let text: QuranTextSD
    let subtitle: QuranSubtitlesSD?
    let footnote: QuranFootnotesSD?
    let chapter: QuranChapters
    let wordByWord: [QuranWordByWordSD]
        
    private init(
        index: QuranIndexSD,
        text: QuranTextSD,
        subtitle: QuranSubtitlesSD?,
        footnote: QuranFootnotesSD?,
        chapter: QuranChapters,
        wordByWord: [QuranWordByWordSD]
    ) {
        self.index = index
        self.text = text
        self.subtitle = subtitle
        self.footnote = footnote
        self.chapter = chapter
        self.wordByWord = wordByWord
    }
        
    init(from index: QuranIndexSD, context: ModelContext) {
        let text = Self.fetchText(verseIndex: index.verse_index, context: context)!
        let subtitle = Self.fetchSubtitle(verseIndex: index.verse_index, context: context)
        let footnote = Self.fetchFootnote(verseIndex: index.verse_index, context: context)
        let chapter = QuranChapters.fetch(chapterNumber: index.chapter_number, context: context)!
        let wordByWord = Self.fetchWordByWord(verseIndex: index.verse_index, context: context)

        self.init(index: index, text: text, subtitle: subtitle, footnote: footnote, chapter: chapter, wordByWord: wordByWord)
    }

    init(from text: QuranTextSD, context: ModelContext) {
        let index = Self.fetchIndex(verseIndex: text.verse_index, context: context)!
        let subtitle = Self.fetchSubtitle(verseIndex: text.verse_index, context: context)
        let footnote = Self.fetchFootnote(verseIndex: text.verse_index, context: context)
        let chapter = QuranChapters.fetch(chapterNumber: text.chapter_number, context: context)!
        let wordByWord = Self.fetchWordByWord(verseIndex: text.verse_index, context: context)

        self.init(index: index, text: text, subtitle: subtitle, footnote: footnote, chapter: chapter, wordByWord: wordByWord)
    }

    init(from subtitle: QuranSubtitlesSD, context: ModelContext) {
        let index = Self.fetchIndex(verseIndex: subtitle.verse_index, context: context)!
        let text = Self.fetchText(verseIndex: subtitle.verse_index, context: context)!
        let footnote = Self.fetchFootnote(verseIndex: subtitle.verse_index, context: context)
        let chapter = QuranChapters.fetch(chapterNumber: subtitle.chapter_number, context: context)!
        let wordByWord = Self.fetchWordByWord(verseIndex: subtitle.verse_index, context: context)

        self.init(index: index, text: text, subtitle: subtitle, footnote: footnote, chapter: chapter, wordByWord: wordByWord)
    }

    init(from footnote: QuranFootnotesSD, context: ModelContext) {
        let index = Self.fetchIndex(verseIndex: footnote.verse_index, context: context)!
        let text = Self.fetchText(verseIndex: footnote.verse_index, context: context)!
        let subtitle = Self.fetchSubtitle(verseIndex: footnote.verse_index, context: context)
        let chapter = QuranChapters.fetch(chapterNumber: footnote.chapter_number, context: context)!
        let wordByWord = Self.fetchWordByWord(verseIndex: footnote.verse_index, context: context)

        self.init(index: index, text: text, subtitle: subtitle, footnote: footnote, chapter: chapter, wordByWord: wordByWord)
    }

    init(from wordByWord: QuranWordByWordSD, context: ModelContext) {
        let index = Self.fetchIndex(verseIndex: wordByWord.verse_index, context: context)!
        let text = Self.fetchText(verseIndex: wordByWord.verse_index, context: context)!
        let subtitle = Self.fetchSubtitle(verseIndex: wordByWord.verse_index, context: context)
        let footnote = Self.fetchFootnote(verseIndex: wordByWord.verse_index, context: context)
        let chapter = QuranChapters.fetch(chapterNumber: wordByWord.chapter_number, context: context)!
        let allWordByWord = Self.fetchWordByWord(verseIndex: wordByWord.verse_index, context: context)

        self.init(index: index, text: text, subtitle: subtitle, footnote: footnote, chapter: chapter, wordByWord: allWordByWord)
    }
}

extension QuranUnified {
    private static func fetchIndex(verseIndex: Int, context: ModelContext) -> QuranIndexSD? {
        return try? context.fetch(FetchDescriptor<QuranIndexSD>(
            predicate: #Predicate { $0.verse_index == verseIndex }
        )).first
    }
    
    private static func fetchText(verseIndex: Int, context: ModelContext) -> QuranTextSD? {
        return try? context.fetch(FetchDescriptor<QuranTextSD>(
            predicate: #Predicate { $0.verse_index == verseIndex }
        )).first
    }
    
    private static func fetchSubtitle(verseIndex: Int, context: ModelContext) -> QuranSubtitlesSD? {
        return try? context.fetch(FetchDescriptor<QuranSubtitlesSD>(
            predicate: #Predicate { $0.verse_index == verseIndex }
        )).first
    }
    
    private static func fetchFootnote(verseIndex: Int, context: ModelContext) -> QuranFootnotesSD? {
        return try? context.fetch(FetchDescriptor<QuranFootnotesSD>(
            predicate: #Predicate { $0.verse_index == verseIndex }
        )).first
    }
    
    private static func fetchWordByWord(verseIndex: Int, context: ModelContext) -> [QuranWordByWordSD] {
        let descriptor = FetchDescriptor<QuranWordByWordSD>(
            predicate: #Predicate { $0.verse_index == verseIndex },
            sortBy: [SortDescriptor(\.word_index)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
            
    static func fetchChapter(_ chapterNumber: Int, context: ModelContext) -> [QuranUnified] {
        let descriptor = FetchDescriptor<QuranIndexSD>(
            predicate: #Predicate { $0.chapter_number == chapterNumber },
            sortBy: [SortDescriptor(\.verse_number)]
        )
        
        guard let indices = try? context.fetch(descriptor) else {
            return []
        }
        
        return indices.map { QuranUnified(from: $0, context: context) }
    }
    
    static func fetchChapter(_ chapter: QuranChapters, context: ModelContext) -> [QuranUnified] {
        return fetchChapter(chapter.chapter_number, context: context)
    }
    
    static func fetchVerse(chapter: Int, verse: Int, context: ModelContext) -> QuranUnified? {
        let descriptor = FetchDescriptor<QuranIndexSD>(
            predicate: #Predicate {
                $0.chapter_number == chapter && $0.verse_number == verse
            }
        )
        
        guard let index = try? context.fetch(descriptor).first else {
            return nil
        }
        
        return QuranUnified(from: index, context: context)
    }
    
    static func fetchVerse(byId verseId: String, context: ModelContext) -> QuranUnified? {
        let descriptor = FetchDescriptor<QuranIndexSD>(
            predicate: #Predicate { $0.verse_id == verseId }
        )
        
        guard let index = try? context.fetch(descriptor).first else {
            return nil
        }
        
        return QuranUnified(from: index, context: context)
    }
    
    static func fetchVerse(byIndex verseIndex: Int, context: ModelContext) -> QuranUnified? {
        guard let index = fetchIndex(verseIndex: verseIndex, context: context) else {
            return nil
        }
        
        return QuranUnified(from: index, context: context)
    }
    
    static func search(query: String, context: ModelContext) -> [QuranUnified] {
        guard !query.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<QuranTextSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let allTexts = try? context.fetch(descriptor) else {
            return []
        }
        
        let queryCleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let queryWords = queryCleaned.split(separator: " ")
        
        let filtered = allTexts.filter { text in
            let textToMatch = text.getTextInUserLanguage().lowercased()
            return queryWords.allSatisfy { word in
                textToMatch.contains(word)
            }
        }
        
        return filtered.map { QuranUnified(from: $0, context: context) }
    }
    
    static func search(query: String, language: QuranSelectablePrimaryLanguage, context: ModelContext) -> [QuranUnified] {
        guard !query.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<QuranTextSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let allTexts = try? context.fetch(descriptor) else {
            return []
        }
        
        let queryCleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let queryWords = queryCleaned.split(separator: " ")
        
        let filtered = allTexts.filter { text in
            let textToMatch = text.getTextInLanguage(language).lowercased()
            return queryWords.allSatisfy { word in
                textToMatch.contains(word)
            }
        }
        
        return filtered.map { QuranUnified(from: $0, context: context) }
    }
    
    static func searchSubtitles(query: String, context: ModelContext) -> [QuranUnified] {
        guard !query.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<QuranSubtitlesSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let allSubtitles = try? context.fetch(descriptor) else {
            return []
        }
        
        let queryCleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let queryWords = queryCleaned.split(separator: " ")
        
        let filtered = allSubtitles.filter { subtitle in
            let textToMatch = subtitle.getTextInUserLanguage().lowercased()
            return queryWords.allSatisfy { word in
                textToMatch.contains(word)
            }
        }
        
        return filtered.map { QuranUnified(from: $0, context: context) }
    }
    
    static func searchFootnotes(query: String, context: ModelContext) -> [QuranUnified] {
        guard !query.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<QuranFootnotesSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let allFootnotes = try? context.fetch(descriptor) else {
            return []
        }
        
        let queryCleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let queryWords = queryCleaned.split(separator: " ")
        
        let filtered = allFootnotes.filter { footnote in
            let textToMatch = footnote.getTextInUserLanguage().lowercased()
            return queryWords.allSatisfy { word in
                textToMatch.contains(word)
            }
        }
        
        return filtered.map { QuranUnified(from: $0, context: context) }
    }
    
    static func searchVerseIds(query: String, context: ModelContext) -> [QuranUnified] {
        guard !query.isEmpty else { return [] }
        
        let queryCleaned = query.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-")[0]
            .split(separator: ",")[0]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for direct match first
        if let directMatch = fetchVerse(byId: String(queryCleaned), context: context) {
            return [directMatch]
        }
        
        // Otherwise search for partial matches
        let descriptor = FetchDescriptor<QuranIndexSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let allIndices = try? context.fetch(descriptor) else {
            return []
        }
        
        let queryWords = queryCleaned.split(separator: " ")
        let filtered = allIndices.filter { index in
            let textToMatch = index.verse_id
            return queryWords.allSatisfy { word in
                textToMatch.contains(word)
            }
        }
        
        return Array(filtered.prefix(3)).map { QuranUnified(from: $0, context: context) }
    }
    
    static func fetchAll(context: ModelContext) -> [QuranUnified] {
        let descriptor = FetchDescriptor<QuranIndexSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let indices = try? context.fetch(descriptor) else {
            return []
        }
        
        return indices.map { QuranUnified(from: $0, context: context) }
    }
}

extension QuranUnified {
    func formatToText() -> String {
        var baseText = ""
        
        if Defaults[.subtitles], let subtitle = self.subtitle {
            baseText += "\(subtitle.getTextInUserLanguage())\n\n"
        }
        
        baseText += "[\(self.index.verse_id)] \(self.text.getTextInUserLanguage())\n\n"
        
        if Defaults[.quran_secondary_language] != .none {
            baseText += "[\(self.index.verse_id)] \(self.text.getTextInUserLanguage(Defaults[.quran_secondary_language]))\n\n"
        }
        
        if Defaults[.arabic] {
            baseText += "\(self.text.arabic)\n\n"
        }
        
        if Defaults[.transliteration] {
            baseText += "\(self.text.transliterated)\n\n"
        }
        
        if Defaults[.footnotes], let footnote = self.footnote {
            baseText += "\(footnote.getTextInUserLanguage())\n\n"
        }
        
        return baseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
