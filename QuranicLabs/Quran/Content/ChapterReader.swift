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
    @State private var scrollProgress: CGFloat = 0
    @State private var appeared = false
    @State private var scrollProxy: ScrollViewProxy?

    var chapterNumber: Int
    var options: Quran_Content_ChapterReader_Options = .init()

    @State private var scrolledToVerseOnce = false

    @Default(.quran_primary_language) var quranPrimaryLanguage
    @Default(.quran_reader_style) var quranReaderStyle

    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                VStack {
                    if data.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Group {
                            switch quranReaderStyle {
                            case .cards, .wordByWord: cardReader
                            case .book: bookReader
                            }
                            if AudioManager.shared.currentTrack != nil {
                                Color.clear.frame(height: 56)
                                    .removeParentListStyle()
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                    }
                }
                .task {
                    scrollProxy = proxy
                    selectMode.canSelect = true
                    // Wait for the push animation to finish before fetching
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    data = QuranUnified.fetchChapter(chapterNumber, context: modelContext)
                    withAnimation(.easeOut(duration: 0.3)) { appeared = true }
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

            // Top progress bar
            if !data.isEmpty {
                ReaderProgressBar(progress: scrollProgress, verseCount: data.count) { verseIndex in
                    guard verseIndex < data.count else { return }
                    scrollProxy?.scrollTo(data[verseIndex].index.verse_index, anchor: .top)
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
    
    @Environment(\.colorScheme) private var theme

    @ViewBuilder
    private var chapterHeader: some View {
        if let chapter = data.first?.chapter {
            VStack {
                // Foreground content
                VStack(spacing: DS.Spacing.sm) {
                    Text(chapter.title_arabic)
                        .font(DS.Typography.quote)
                        .foregroundStyle(.accent)
                    
                    Text(chapter.getTitleInUserLanguage(quranPrimaryLanguage))
                        .font(DS.Typography.heroMD)
                        .multilineTextAlignment(.center)

                    Text("\(chapter.title_transliterated) • \(chapter.chapter_verses) verses".uppercased())
                        .font(DS.Typography.eyebrow)
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.xl)
            .background(
                Color.secondary.opacity(theme == .dark ? 0.10 : 0.06)
                    .padding(.top, -500)
            )
        }
    }

    var cardReader: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                chapterHeader

                Group {
                    ForEach(Array(data.enumerated()), id: \.element) { index, i in
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
                        .background(VersePositionTracker(index: index))
                    }
                    chapterNavigation
                        .padding(.horizontal)
                }
            }
        }
        .coordinateSpace(name: "readerScroll")
        .onPreferenceChange(VerseFramePreferenceKey.self) { frames in
            updateProgress(from: frames)
        }
    }

    var bookReader: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                chapterHeader

                Group {
                    ForEach(Array(data.enumerated()), id: \.element) { index, i in
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
                        .background(VersePositionTracker(index: index))
                    }
                    chapterNavigation
                        .padding(.horizontal)
                }
            }
        }
        .coordinateSpace(name: "readerScroll")
        .onPreferenceChange(VerseFramePreferenceKey.self) { frames in
            updateProgress(from: frames)
        }
    }

    @ObservedObject private var router = Router.shared

    private var chapterNavigation: some View {
        HStack {
            if chapterNumber > 1 {
                Button {
                    router.pop(from: .quran)
                    DispatchQueue.main.async {
                        router.push(.chapter(chapterNumber: chapterNumber - 1))
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Sura \(chapterNumber - 1)")
                    }
                    .font(DS.Typography.eyebrow)
                }
                .buttonStyle(SignatureButtonStyle())
            }

            Spacer()

            if chapterNumber < 114 {
                Button {
                    router.pop(from: .quran)
                    DispatchQueue.main.async {
                        router.push(.chapter(chapterNumber: chapterNumber + 1))
                    }
                } label: {
                    HStack {
                        Text("Sura \(chapterNumber + 1)")
                        Image(systemName: "chevron.right")
                    }
                    .font(DS.Typography.eyebrow)
                }
                .buttonStyle(SignatureButtonStyle())
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
        guard !scrolledToVerseOnce, let target = scrollToVerseIndex else { return }
        scrolledToVerseOnce = true

        // First jump without animation to force LazyVStack to materialize the target
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo(target, anchor: .top)

            // Then refine with animation — use .top so large cards show from their start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(target, anchor: .top)
                }
            }
        }
    }

    // MARK: - Progress Tracking

    private func updateProgress(from frames: [Int: CGFloat]) {
        guard !data.isEmpty else { return }

        // Find the verse closest to the top tracking line (24pt from top)
        let trackingLine: CGFloat = 24
        var closestIndex = 0
        var closestDistance: CGFloat = .infinity

        for (index, minY) in frames {
            let distance = abs(minY - trackingLine)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        // Check if last verse is visible (near bottom of screen)
        if let lastMinY = frames[data.count - 1], lastMinY < UIScreen.main.bounds.height {
            withAnimation(.easeOut(duration: 0.18)) { scrollProgress = 1.0 }
            recordHistory(at: data.count - 1)
            return
        }

        let newProgress = CGFloat(closestIndex) / CGFloat(max(data.count - 1, 1))
        let snapped = newProgress > 0.9 ? 1.0 : newProgress

        withAnimation(.easeOut(duration: 0.18)) { scrollProgress = snapped }
        recordHistory(at: closestIndex)
    }

    @State private var lastRecordedIndex: Int?
    @State private var historyDebounceTask: Task<Void, Never>?

    private func recordHistory(at index: Int) {
        guard index != lastRecordedIndex, index < data.count else { return }
        lastRecordedIndex = index

        historyDebounceTask?.cancel()
        historyDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s dwell time
            guard !Task.isCancelled else { return }
            let verse = data[index]
            await QuranReadingHistoryStore.shared.record(
                chapterNumber: chapterNumber,
                chapterTitle: verse.chapter.title_english,
                verseId: verse.index.verse_id,
                verseNumber: verse.index.verse_number,
                excerpt: verse.text.english
            )
        }
    }
}

// MARK: - Progress Bar

private struct ReaderProgressBar: View {
    let progress: CGFloat
    let verseCount: Int
    let onScrub: (Int) -> Void

    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0
    @State private var activeVerse: Int = 0

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var displayProgress: CGFloat {
        isDragging ? dragProgress : progress
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: isDragging ? 8 : 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.55), Color.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * displayProgress, 24), height: isDragging ? 8 : 4)

                // Verse tooltip while scrubbing
                if isDragging && verseCount > 0 {
                    let thumbX = min(max(geo.size.width * dragProgress, 32), geo.size.width - 32)
                    Text("Verse \(activeVerse)")
                        .font(DS.Typography.eyebrowSM)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .fixedSize()
                        .position(x: thumbX, y: -18)
                        .transition(.opacity)
                }
            }
            .frame(height: isDragging ? 8 : 4)
            .contentShape(Rectangle().inset(by: -20))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        if !isDragging {
                            feedbackGenerator.prepare()
                            withAnimation(.easeOut(duration: 0.1)) { isDragging = true }
                        }
                        let fraction = min(max(value.location.x / geo.size.width, 0), 1)
                        dragProgress = fraction
                        let verseIndex = min(max(Int(fraction * CGFloat(verseCount - 1)), 0), verseCount - 1)
                        if verseIndex != activeVerse {
                            activeVerse = verseIndex
                            feedbackGenerator.impactOccurred()
                            onScrub(verseIndex)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) { isDragging = false }
                    }
            )
        }
        .frame(height: isDragging ? 8 : 4)
        .padding(.horizontal)
        .opacity(0.9)
        .animation(.easeOut(duration: 0.15), value: isDragging)
    }
}

// MARK: - Verse Position Tracking

private struct VerseFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct VersePositionTracker: View {
    let index: Int

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: VerseFramePreferenceKey.self,
                    value: [index: geo.frame(in: .named("readerScroll")).minY]
                )
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
