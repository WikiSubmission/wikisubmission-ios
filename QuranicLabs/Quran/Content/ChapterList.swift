import SwiftUI
import SwiftData
import Defaults

struct Quran_Content_ChapterList: View {
    @Binding var searchQuery: QuranQuery

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

    var body: some View {
        VStack {
            ForEach(filteredChapters.isEmpty ? allChapters : filteredChapters, id: \.self) { chapter in
                Quran_Element_ChapterCard(chapter: chapter)
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
