import SwiftUI
import SwiftData
import Defaults

struct QuranChapters: Hashable {
    let chapter_number: Int
    let chapter_verses: Int
    let revelation_order: Int
    let title_english: String
    let title_arabic: String
    let title_transliterated: String
    let title_turkish: String
    let title_french: String
    let title_german: String
    let title_bahasa: String
    let title_persian: String
    let title_tamil: String
    let title_swedish: String
    let title_russian: String
    let title_bengali: String
    let title_urdu: String
    let title_spanish: String

    init(from sd: QuranChaptersSD) {
        self.chapter_number = sd.chapter_number
        self.chapter_verses = sd.chapter_verses
        self.revelation_order = sd.revelation_order
        self.title_english = sd.title_english
        self.title_arabic = sd.title_arabic
        self.title_transliterated = sd.title_transliterated
        self.title_turkish = sd.title_turkish
        self.title_french = sd.title_french
        self.title_german = sd.title_german
        self.title_bahasa = sd.title_bahasa
        self.title_persian = sd.title_persian
        self.title_tamil = sd.title_tamil
        self.title_swedish = sd.title_swedish
        self.title_russian = sd.title_russian
        self.title_bengali = sd.title_bengali
        self.title_urdu = sd.title_urdu
        self.title_spanish = sd.title_spanish
    }

    static func fetchAll(context: ModelContext) -> [QuranChapters] {
        let descriptor = FetchDescriptor<QuranChaptersSD>(
            sortBy: [SortDescriptor(\.chapter_number)]
        )
        guard let results = try? context.fetch(descriptor) else { return [] }
        return results.map { QuranChapters(from: $0) }
    }

    static func fetch(chapterNumber: Int, context: ModelContext) -> QuranChapters? {
        let descriptor = FetchDescriptor<QuranChaptersSD>(
            predicate: #Predicate { $0.chapter_number == chapterNumber }
        )
        guard let result = try? context.fetch(descriptor).first else { return nil }
        return QuranChapters(from: result)
    }

    static func search(query: String, context: ModelContext) -> [QuranChapters] {
        let all = fetchAll(context: context)
        let queryCleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        return all.filter { chapter in
            let textToMatch = "\(chapter.chapter_number) \(chapter.getTitleInUserLanguage()) \(chapter.title_transliterated)".lowercased()
            return queryCleaned.split(separator: " ").allSatisfy { word in
                textToMatch.contains(word)
            }
        }
        .prefix(3)
        .sorted { $0.chapter_number < $1.chapter_number }
    }

    func getTitleInUserLanguage() -> String {
        switch Defaults[.quran_primary_language] {
        case .english: return title_english
        case .turkish: return title_turkish
        case .french: return title_french
        case .german: return title_german
        case .bahasa: return title_bahasa
        case .persian: return title_persian
        case .tamil: return title_tamil
        case .swedish: return title_swedish
        case .russian: return title_russian
        case .bengali: return title_bengali
        case .spanish: return title_spanish
        case .urdu: return title_urdu
        }
    }

    func getTitleInUserLanguage(_ language: QuranSelectablePrimaryLanguage) -> String {
        switch language {
        case .english: return title_english
        case .turkish: return title_turkish
        case .french: return title_french
        case .german: return title_german
        case .bahasa: return title_bahasa
        case .persian: return title_persian
        case .tamil: return title_tamil
        case .swedish: return title_swedish
        case .russian: return title_russian
        case .bengali: return title_bengali
        case .spanish: return title_spanish
        case .urdu: return title_urdu
        }
    }
}
