import SwiftUI
import Defaults
import SheetKit

struct QuranReaderView: View {
    var chapter: Int
    var scrollToVerseID: String? = nil
    
    @State private var data: [Types.Quran.Data] = []
    
    @Default(.primary_language) private var primaryLanguage
    @Default(.bookmarks) var bookmarks
    
    @ObservedObject var audioManager = Utilities.Quran.QuranAudioManager.shared
    
    var body: some View {
        VStack {
            if data.count > 0 {
                chapterHeader
                verseList
            } else {
                ProgressView()
            }
        }
        .padding(.horizontal, 12)
        .onAppear {
            Task {
                DispatchQueue.main.async {
                    self.data = AppData.Quran.versesByChapter[chapter] ?? []
                }
            }
        }
        .toolbar {
            toolbar
        }
    }
    
    private var chapterHeader: some View {
        QuranChapterCard(chapter: chapter, removeBookmarkedIcon: true, displayOnly: true)
    }
    
    private var verseList: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    Color.clear.frame(height: 0).id("top")
                    VStack {
                        ForEach(data, id: \.verse_id) { verse in
                            QuranVerseCard(id: verse.verse_id, isScrolledTo: scrollToVerseID == verse.verse_id ? true : false)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .onChange(of: audioManager.currentVerse) { _, verse in
                    if let verse = verse {
                        withAnimation {
                            proxy.scrollTo(verse.verse_id, anchor: .top)
                        }
                    }
                }
                .onAppear {
                    Task {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let scrollToVerseID = scrollToVerseID {
                                withAnimation {
                                    proxy.scrollTo(scrollToVerseID, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack(alignment: .center, spacing: 0) {
            // Play button
            Button {
                if !audioManager.isPlaying {
                    if let startFromVerseID = scrollToVerseID {
                        let startingVerse = Int(startFromVerseID.split(separator: ":")[1])
                        Utilities.Quran.QuranAudioManager.shared.playQueue(data, startFromVerse: startingVerse)
                    } else {
                        Utilities.Quran.QuranAudioManager.shared.playQueue(data)
                    }
                } else {
                    Utilities.Quran.QuranAudioManager.shared.stopQueue()
                }
            } label: {
                Image(systemName: audioManager.isPlaying ? "stop.fill" : "play")
                    .foregroundStyle(audioManager.isPlaying ? .red : .accent)
            }
            
            // Bookmark button
            Button {
                Task {
                    if let bookmark = bookmarks.first(where: {
                        $0.key == String(chapter)
                    }) {
                        try? await Utilities.Bookmarks.removeBookmark(bookmark)
                    } else {
                        try? await Utilities.Bookmarks.addBookmark(.init(
                            created_at: Date().ISO8601Format(),
                            updated_at: nil,
                            type: .chapter,
                            key: String(chapter),
                            category: nil,
                            notes: nil,
                        ))
                        
                        SheetKit().presentWithEnvironment {
                            QuranBookmarks()
                        }
                    }
                }
            } label: {
                let isBookmarked = bookmarks.contains(where: { $0.key == String(chapter) })
                Label("", systemImage: isBookmarked ? "star.fill" : "star")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(isBookmarked ? .orange : .accent)
            }
            
            // Share button
            Button {
                SheetKit().presentWithEnvironment {
                    QuranShareVerses(data: data)
                }
            } label: {
                Label("", systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
            }
            
            // Settings button
            QuranMenu()
        }
    }
}

#Preview {
    NavigationStack {
        QuranReaderView(chapter: 19)
            .environmentObject(AppEnvironment.shared)
    }
}
