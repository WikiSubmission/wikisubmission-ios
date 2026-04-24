import SwiftUI
import SwiftData
import Defaults

struct Quran_Content_ChapterList: View {
    @Binding var searchQuery: QuranQuery

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    @Environment(\.modelContext) private var modelContext

    @State private var filteredChapters: [QuranChapters] = []

    @Default(.sort_chapters_by_revelation_order) private var sortByRevelationOrder

    private var allChapters: [QuranChapters] {
        QuranChapters.fetchAll(context: modelContext).sorted {
            sortByRevelationOrder
                ? $0.revelation_order < $1.revelation_order
                : $0.chapter_number < $1.chapter_number
        }
    }

    private var displayedChapters: [QuranChapters] {
        filteredChapters.isEmpty ? allChapters : filteredChapters
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(Array(displayedChapters.enumerated()), id: \.element.chapter_number) { index, chapter in
                Quran_Element_ChapterCard(
                    chapter: chapter,
                    revelationOrderIndex: sortByRevelationOrder ? index + 1 : nil
                )
            }
        }
        .onChange(of: searchQuery.query) { old, new in
            let cleanedQuery = new.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            if cleanedQuery.isEmpty {
                filteredChapters = []
                return
            }

            filteredChapters = QuranChapters.search(query: new, context: modelContext)
        }
    }
}
