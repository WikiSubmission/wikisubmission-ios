import SwiftUI
import SwiftData

struct Quran_Content_RandomVerse: View {
    @Environment(\.modelContext) private var modelContext
    @State private var data: QuranUnified? = nil
    
    var body: some View {
        VStack {
            if let data = data {
                Quran_Content_ChapterReader(
                    chapterNumber: data.chapter.chapter_number,
                    options: .init(
                        scrollToVerseIndex: data.index.verse_index
                    )
                )
            } else {
                ProgressView()
            }
        }
        .task {
            loadRandomVerse()
        }
    }
    
    private func loadRandomVerse() {
        let descriptor = FetchDescriptor<QuranIndexSD>(
            sortBy: [SortDescriptor(\.verse_index)]
        )
        
        guard let allIndices = try? modelContext.fetch(descriptor),
              let randomIndex = allIndices.randomElement() else {
            return
        }
        
        self.data = QuranUnified(from: randomIndex, context: modelContext)
    }
}
