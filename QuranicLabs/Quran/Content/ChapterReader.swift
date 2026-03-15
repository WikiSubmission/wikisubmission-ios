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
                ZStack(alignment: .trailing) {
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

                    // Verse scrubber — only shown for chapters with enough verses to warrant it
                    if data.count > 20 {
                        ChapterScrubber(verses: data, chapterNumber: chapterNumber) { verseIndex in
                            proxy.scrollTo(verseIndex, anchor: .top)
                        }
                    }
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
    
    @ViewBuilder
    private var chapterHeader: some View {
        if let chapter = data.first?.chapter {
            VStack(spacing: 6) {
                Text("\(chapter.getTitleInUserLanguage(quranPrimaryLanguage))")
                    .font(.system(size: 36))
                    .fontWeight(.ultraLight)

                Text("\(chapter.title_transliterated) • \(chapter.chapter_verses) verses")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    var cardReader: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                chapterHeader
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
                chapterNavigation
            }
        }
    }

    var bookReader: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                chapterHeader
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
                chapterNavigation
            }
        }
    }

    @ObservedObject private var router = Router.shared

    private var chapterNavigation: some View {
        HStack {
            if chapterNumber > 1 {
                Button {
                    router.pop(from: .quran)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        router.push(.chapter(chapterNumber: chapterNumber - 1))
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Sura \(chapterNumber - 1)")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if chapterNumber < 114 {
                Button {
                    router.pop(from: .quran)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        router.push(.chapter(chapterNumber: chapterNumber + 1))
                    }
                } label: {
                    HStack {
                        Text("Sura \(chapterNumber + 1)")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 24)
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

// MARK: - Chapter Scrubber

private struct ChapterScrubber: View {
    let verses: [QuranUnified]
    let chapterNumber: Int
    let onScroll: (Int) -> Void

    @State private var isDragging = false
    @State private var thumbFraction: CGFloat = 0
    @State private var activeIndex: Int = 0

    private let trackW: CGFloat = 3
    private let thumbH: CGFloat = 36
    private let edgePad: CGFloat = 52
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geo in
            let trackH = max(1, geo.size.height - edgePad * 2)
            let thumbOffset = thumbFraction * max(0, trackH - thumbH)

            ZStack(alignment: .topTrailing) {
                // Tooltip badge
                if isDragging {
                    Text("\(chapterNumber):\(verses[activeIndex].index.verse_number)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .fixedSize()
                        .offset(x: -18, y: edgePad + thumbOffset + thumbH / 2 - 13)
                        .transition(.opacity)
                }

                // Track
                Capsule()
                    .fill(Color.secondary.opacity(isDragging ? 0.35 : 0.2))
                    .frame(width: trackW, height: trackH)
                    .offset(y: edgePad)

                // Thumb
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: isDragging ? trackW + 2 : trackW, height: thumbH)
                    .offset(y: edgePad + thumbOffset)
            }
            .frame(width: 20, alignment: .trailing)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        if !isDragging {
                            feedbackGenerator.prepare()
                            withAnimation(.easeOut(duration: 0.1)) { isDragging = true }
                        }
                        let y = min(max(value.location.y - edgePad, 0), trackH)
                        let newFraction = y / trackH
                        thumbFraction = newFraction
                        let idx = min(max(Int(newFraction * CGFloat(verses.count - 1)), 0), verses.count - 1)
                        if idx != activeIndex {
                            activeIndex = idx
                            feedbackGenerator.impactOccurred()
                            onScroll(verses[idx].index.verse_index)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) { isDragging = false }
                    }
            )
        }
        .frame(width: 20)
        .onAppear { feedbackGenerator.prepare() }
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
