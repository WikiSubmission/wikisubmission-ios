import Foundation

extension Types.Quran {
    struct SearchResult: Identifiable {
        var id = UUID()
        var type: Types.Quran.ParsedQuery
        var chapters: [Int]
        var verseIDs: [String]
        var text: [Types.Quran.Data]
        var subtitles: [Types.Quran.Data]
        var footnotes: [Types.Quran.Data]
    }
}
