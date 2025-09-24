import SwiftUI
import Defaults

extension Utilities.Quran {
    
    struct QueryParser {
        @MainActor
        static func parse(_ input: String) -> Types.Quran.ParsedQuery {
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !trimmed.isEmpty else {
                return .invalid(reason: "Empty query")
            }

            // MARK: - Chapter only (e.g., "1")
            if let chapterOnly = trimmed.range(of: #"^(\d+)$"#, options: .regularExpression) {
                if let chapter = Int(trimmed[chapterOnly]) {
                    return .chapter(chapter: chapter)
                }
            }

            // MARK: - Single verse (e.g., "1:1")
            if let verseMatch = trimmed.range(of: #"^(\d+)[:\s]+(\d+)$"#, options: .regularExpression) {
                let parts = trimmed[verseMatch].split { ": ".contains($0) }.compactMap { Int($0) }
                if parts.count == 2 {
                    return .verse(chapter: parts[0], verse: parts[1])
                }
            }

            // MARK: - Verse range (e.g., "1:1-5")
            if let rangeMatch = trimmed.range(of: #"^(\d+)[:\s]+(\d+)[-\s]+(\d+)$"#, options: .regularExpression) {
                let parts = trimmed[rangeMatch].split { ": -".contains($0) }.compactMap { Int($0) }
                if parts.count == 3 {
                    return .verseRange(chapter: parts[0], start: parts[1], end: parts[2])
                }
            }

            // MARK: - Multiple verses (e.g., "1:1, 2:3, 10:1-2")
            let multipleRegex = #"^(?:\d+:\d+(?:-\d+)?\s*,\s*)*\d+:\d+(?:-\d+)?$"#
            if trimmed.range(of: multipleRegex, options: .regularExpression) != nil {
                let segments = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                var parsed: [Types.Quran.ParsedQuery] = []

                for seg in segments {
                    // Handle single verse (e.g. 7:8)
                    if let match = seg.range(of: #"^(\d+):(\d+)$"#, options: .regularExpression) {
                        let parts = seg[match].split(separator: ":").compactMap { Int($0) }
                        if parts.count == 2 {
                            parsed.append(.verse(chapter: parts[0], verse: parts[1]))
                            continue
                        }
                    }

                    // Handle verse range (e.g. 10:1-2)
                    if let match = seg.range(of: #"^(\d+):(\d+)-(\d+)$"#, options: .regularExpression) {
                        let parts = seg[match].split { ": -".contains($0) }.compactMap { Int($0) }
                        if parts.count == 3 {
                            parsed.append(.verseRange(chapter: parts[0], start: parts[1], end: parts[2]))
                            continue
                        }
                    }

                    return .invalid(reason: "Invalid sub-query: \(seg)")
                }

                if parsed.allSatisfy({
                    if case .verse( _, _) = $0 { return true } else { return false }
                }) {
                    let chapters = Set(parsed.compactMap {
                        if case .verse(let chapter, _) = $0 { return chapter } else { return nil }
                    })
                    if chapters.count == 1 {
                        let chapter = chapters.first!
                        let verses = parsed.compactMap {
                            if case .verse(_, let v) = $0 { return v } else { return nil }
                        }
                        return .multipleVerses(chapter: chapter, verses: verses)
                    }
                }

                return .invalid(reason: "Multiple chapters or ranges not supported in multipleVerses")
            }

            // MARK: - Special keywords
            switch trimmed {
            case "random chapter": return .randomChapter
            case "random verse": return .randomVerse
            default:
                return .search(term: trimmed, language: Defaults[.primary_language], fuzzy: true)
            }
        }
    }
}
