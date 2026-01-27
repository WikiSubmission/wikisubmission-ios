import SwiftUI
import SwiftData
import Defaults

struct Quran_Content_ChapterReader_Options {
    var scrollToVerseIndex: Int? = nil
    var scrollToVerseNumber: Int? = nil
    var scrollToVerseId: String? = nil
}

struct Quran_Content_ChapterReader: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var audio = AudioManager.shared

    @State private var data: [QuranUnified] = []
    @State private var selectMode = QuranSelectMode()

    var chapterNumber: Int
    var options: Quran_Content_ChapterReader_Options = .init()

    @State private var scrolledToVerseOnce = false

    @Default(.quran_primary_language) var quranPrimaryLanguage
    @Default(.quran_reader_style) var quranReaderStyle

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                VStack {
                    if data.isEmpty {
                        ProgressView()
                    } else {
                        switch quranReaderStyle {
                        case .cards: cardReader
                        case .book: bookReader
                        }
                        if AudioManager.shared.currentTrack != nil {
                            Color.clear.frame(height: 56)
                                .removeParentListStyle()
                        }
                    }
                }
                .padding(.horizontal)
                .task {
                    selectMode.canSelect = true
                    data = QuranUnified.fetchChapter(chapterNumber, context: modelContext)
                    scrollIfNeeded(proxy: proxy)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            if selectMode.canSelect && selectMode.selection.count > 0 {
                                Quran_Element_SelectVersesActions(selectMode: selectMode, toolbarMode: true)
                            }

                            Quran_Element_SelectVersesTrigger(selectMode: selectMode, toolbarContext: true)
                            
                            Button {
                                if !audio.isPlaying {
                                    let chapter = QuranUnified.fetchChapter(chapterNumber, context: modelContext)
                                    
                                    audio.play((scrollToVerseIndex != nil
                                                ? chapter.first { $0.index.verse_index == scrollToVerseIndex }
                                                : chapter[0])!,
                                               modelContext: modelContext
                                    )
                                } else {
                                    audio.stop()
                                }
                            } label: {
                                Image(systemName: audio.isPlaying ? "stop.fill" : "play.fill")
                            }

                            Quran_Element_QuickSettings()
                        }
                    }
                }
                .onChange(of: audio.currentTrack?.id) { _, _ in
                    scrollToCurrentTrack(proxy: proxy)
                }
            }
        }
        .navigationTitle("Sura \(chapterNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scrollToCurrentTrack(proxy: ScrollViewProxy) {
        guard let metadata = audio.currentTrack?.metadata,
              let trackChapter = metadata.chapterNumber,
              let verseIndex = metadata.verseIndex,
              trackChapter == chapterNumber else { return }

        withAnimation {
            proxy.scrollTo(verseIndex, anchor: .center)
        }
    }
    
    var cardReader: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                ForEach(data, id: \.self) { i in
                    Quran_Element_VerseCard(
                        unified: i,
                        options: .init(
                            selectMode: selectMode,
                            isScrolledTo: options.scrollToVerseIndex == i.index.verse_index ||
                                        options.scrollToVerseId == i.index.verse_id ||
                                        options.scrollToVerseNumber == i.index.verse_number,
                            linkToVerseInfo: true,
                            linkShouldNotReroute: true
                        )
                    )
                    .id(i.index.verse_index)
                }
            }
        }
    }
    
    var bookReader: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                ForEach(data, id: \.self) { i in
                    Quran_Element_VerseCard(
                        unified: i,
                        options: .init(
                            selectMode: selectMode,
                            isScrolledTo: options.scrollToVerseIndex == i.index.verse_index ||
                                        options.scrollToVerseId == i.index.verse_id ||
                                        options.scrollToVerseNumber == i.index.verse_number,
                            linkToVerseInfo: true,
                            linkShouldNotReroute: true
                        )
                    )
                    .id(i.index.verse_index)
                }
            }
        }
    }
    
    var scrollToVerseIndex: Int? {
        if let scrollToVerseIndex = self.options.scrollToVerseIndex {
            return scrollToVerseIndex
        } else if let scrollToVerseId = self.options.scrollToVerseId {
            return QuranUnified.fetchVerse(byId: scrollToVerseId, context: modelContext)?.index.verse_index
        } else if let scrollToVerseNumber = self.options.scrollToVerseNumber {
            return QuranUnified.fetchVerse(chapter: chapterNumber, verse: scrollToVerseNumber, context: modelContext)?.index.verse_index
        } else {
            return nil
        }
    }
    
    private func scrollIfNeeded(proxy: ScrollViewProxy) {
        if !scrolledToVerseOnce, scrollToVerseIndex != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    proxy.scrollTo(scrollToVerseIndex, anchor: .center)
                    self.scrolledToVerseOnce = true
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for:
            QuranFootnotesSD.self,
            QuranIndexSD.self,
            QuranSubtitlesSD.self,
            QuranTextSD.self,
            QuranWordByWordSD.self,
        configurations: ModelConfiguration()
    )
    
    let context = container.mainContext
    
     NavigationStack {
         Quran_Content_ChapterReader(chapterNumber: 19, options: .init(
            scrollToVerseNumber: 5
         ))
    }
    .modelContainer(container)
}
