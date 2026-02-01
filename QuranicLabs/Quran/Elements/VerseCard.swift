import SwiftUI
import SwiftData
import Defaults
import AlertKit

// [Custom parameters for verse card]
struct Quran_Element_VerseCard_Options {
    // [Highlights the query]
    var highlightPhrase = ""
    // [Highlights the arabic word at the specific index]
    var highlightArabicWordIndices: [Int]?
    // [Strips padding and background color in verse card]
    var unformatted = false
    // [Reference to select mode]
    var selectMode: QuranSelectMode? = nil
    // [Highlights the verse briefly]
    var isScrolledTo = false
    // [Adds a link to the chapter]
    var linkToChapterContext = false
    // [Adds a link to the verse info]
    var linkToVerseInfo = false
    // [Prevent router redirecting]
    var linkShouldNotReroute = false
    // [Disables navigation in word-by-word mode (for previews)]
    var disableInteractiveElements = false
}

// [View]
struct Quran_Element_VerseCard: View {
    @Environment(\.modelContext) private var modelContext
    
    // [Verse data: can be initialized via various data types]
    private var data: QuranUnified
        
    // [Options: for customization]
    let options: Quran_Element_VerseCard_Options
    
    // [Force renders the source element even if disabled in UserDefaults]
    private var specialInitSource: SpecialInitSources? = nil
    
    enum SpecialInitSources {
        case subtitle
        case footnote
    }
    
    // [Initializers]
    init(
        unified: QuranUnified,
        options: Quran_Element_VerseCard_Options = .init()
    ) {
        self.data = unified
        self.options = options
    }
    
    init(
        index: QuranIndexSD,
        context: ModelContext,
        options: Quran_Element_VerseCard_Options = .init()
    ) {
        self.data = QuranUnified(from: index, context: context)
        self.options = options
    }
    
    init(
        text: QuranTextSD,
        context: ModelContext,
        options: Quran_Element_VerseCard_Options = .init()
    ) {
        self.data = QuranUnified(from: text, context: context)
        self.options = options
    }
    
    init(
        subtitle: QuranSubtitlesSD,
        context: ModelContext,
        options: Quran_Element_VerseCard_Options = .init()
    ) {
        self.data = QuranUnified(from: subtitle, context: context)
        self.options = options
        self.specialInitSource = .subtitle
    }
    
    init(
        footnote: QuranFootnotesSD,
        context: ModelContext,
        options: Quran_Element_VerseCard_Options = .init()
    ) {
        self.data = QuranUnified(from: footnote, context: context)
        self.options = options
        self.specialInitSource = .footnote
    }
    
    init(
        wordByWord: QuranWordByWordSD,
        context: ModelContext,
        options: Quran_Element_VerseCard_Options = .init()
    ) {
        self.data = QuranUnified(from: wordByWord, context: context)
        self.options = options
    }

    // [Default/AppStorage settings]
    @Default(.arabic) var arabic
    @Default(.subtitles) var subtitles
    @Default(.footnotes) var footnotes
    @Default(.transliteration) var transliteration
    @Default(.font_size) var fontSize
    @Default(.quran_primary_language) var primaryLanguage
    @Default(.quran_secondary_language) var secondaryLanguage
    @Default(.last_read_verse_id) var lastReadVerse
    @Default(.quran_reader_style) var quranReaderStyle
    @Default(.word_by_word) var wordByWord
    @Default(.quran_arabic_font) var arabicFont

    // [Private/internal state variables]
    @State private var showHighlight = false
    @State private var visibilityStartDate: Date?
    @State private var visibilityCommitTask: Task<Void, Never>?
    @State private var wordByWordData: [QuranWordByWordSD]? = nil
    @State private var presentBookmarkSheet = false

    // [Environment]
    @Environment(\.colorScheme) var theme
    @Environment(\.dismiss) var dismiss
    
    // [Managers]
    @ObservedObject var bookmarkManager = BookmarkManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    // [Router]
    @ObservedObject var router = Router.shared

    private var isCurrentlyPlaying: Bool {
        guard let metadata = audioManager.currentTrack?.metadata,
              let chapterNumber = metadata.chapterNumber,
              let verseNumber = metadata.verseNumber else { return false }
        return chapterNumber == data.index.chapter_number && verseNumber == data.index.verse_number
    }

    var body: some View {
        HStack(spacing: 12) {
            // [Select button: if select mode is active]
            if let selectMode = options.selectMode, selectMode.isActive {
                selectButton(selectMode: selectMode)
            }

            // [Main content]
            VStack(alignment: .leading, spacing: quranReaderStyle == .book ? 8 : 4) {
                // [Verse header]
                verseHeader

                // [Subtitle]
                subtitleView

                // [Text content]
                textContent

                // [Footnote]
                footnoteView
            }
        }
        .padding(cardPadding)
        .frame(maxWidth: quranReaderStyle == .book ? 600 : .infinity, alignment: .leading)
        .background(cardBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .sheet(isPresented: $presentBookmarkSheet, content: {
            Quran_Content_Bookmarks()
        })
        .contextMenu { verseContextMenu }
        .onAppear(perform: handleOnAppear)
        .background(visibilityTracker)
    }

    @ViewBuilder
    private var verseHeader: some View {
        switch quranReaderStyle {
        case .cards:
            HStack {
                HStack(spacing: 1) {
                    Text("\(data.index.chapter_number)")
                    Text(":")
                    Text("\(data.index.verse_number)")
                        .foregroundStyle(.secondary)
                }
                .font(.title2)
                .fontWeight(.bold)
                .padding(8)
                .background(
                    Color.secondary
                        .opacity(0.06)
                        .padding(-2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                Spacer()
                if options.linkToChapterContext {
                    Button {
                        router.push(.chapter(
                            chapterNumber: data.index.chapter_number,
                            scrollToVerseNumber: data.index.verse_number
                        ))
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        case .book:
            EmptyView()
        }
    }

    @ViewBuilder
    private var subtitleView: some View {
        if subtitles || specialInitSource == .subtitle, let subtitle = data.subtitle {
            HStack {
                Spacer()
                ConditionalHighlight(
                    text: subtitle.getTextInUserLanguage(),
                    query: options.highlightPhrase
                )
                .font(.system(size: CGFloat(fontSize) - 6))
                .foregroundStyle(.accent)
                .fontWeight(.semibold)
                .environment(\.layoutDirection, primaryLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
                .padding(.leading, quranReaderStyle == .book ? 12 : 0)
                Spacer()
            }
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // [Primary text]
            primaryTextView

            // [Secondary text]
            if secondaryLanguage != .none {
                secondaryTextView
            }

            // [Transliteration]
            if transliteration {
                transliterationView
            }

            // [Arabic text]
            if arabic {
                arabicTextView
            }
        }
    }

    private var primaryTextView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if quranReaderStyle == .book {
                Text("\(options.linkToChapterContext ? data.index.verse_id : String(data.index.verse_number))")
                    .font(.system(size: CGFloat(fontSize) - 6, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(minWidth: options.linkToChapterContext ? 44 : 24, alignment: .trailing)
                    .padding(.trailing, 8)
                    .fixedSize()
            }
            ConditionalHighlight(
                text: data.text.getTextInUserLanguage(),
                query: options.highlightPhrase
            )
            .font(.system(size: CGFloat(fontSize), design: quranReaderStyle == .book ? .serif : .default))
            .lineSpacing(quranReaderStyle == .book ? 8 : 0)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if quranReaderStyle == .book && options.linkToChapterContext {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.leading, 8)
            }
        }
    }

    private var secondaryTextView: some View {
        HStack {
            ConditionalHighlight(
                text: data.text.getTextInUserLanguage(secondaryLanguage),
                query: options.highlightPhrase
            )
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .font(.system(size: CGFloat(fontSize), design: quranReaderStyle == .book ? .serif : .default))
        .environment(\.layoutDirection, secondaryLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
        .foregroundStyle(.secondary)
        .padding(.leading, quranReaderStyle == .book ? bookTextLeadingPadding : 0)
    }

    private var transliterationView: some View {
        HStack {
            Text(data.text.transliterated)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .font(.system(size: CGFloat(fontSize), design: quranReaderStyle == .book ? .serif : .default))
        .foregroundStyle(.secondary)
        .padding(.leading, quranReaderStyle == .book ? bookTextLeadingPadding : 0)
    }

    private var arabicTextView: some View {
        Group {
            if wordByWord {
                // Expanded word-by-word layout with transliteration and english
                arabicWordByWordExpandedView
            } else {
                // Compact flowing text with optional highlighting
                arabicCompactView
                    .font(arabicFont.font(size: CGFloat(fontSize + 4)))
                    .lineSpacing(arabicFont.lineSpacing)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .tracking(1.6)
        .padding(.leading, quranReaderStyle == .book ? bookTextLeadingPadding : 0)
    }

    /// Compact Arabic text view - flowing text with proper RTL and highlighting support
    private var arabicCompactView: some View {
        Group {
            if hasArabicWordsToHighlight {
                // Use word-by-word rendering with highlights
                Text(arabicAttributedString)
            } else {
                // Use original Arabic text for proper RTL flow
                Text(data.text.arabic)
            }
        }
    }

    /// Whether any Arabic words need highlighting
    private var hasArabicWordsToHighlight: Bool {
        data.wordByWord.contains { shouldHighlightWord($0) }
    }

    /// Builds an AttributedString for Arabic text with word highlighting
    private var arabicAttributedString: AttributedString {
        var result = AttributedString()
        // Build in reverse order for proper RTL display
        let words = data.wordByWord.sorted { $0.word_index > $1.word_index }.reversed()

        for (index, word) in words.enumerated() {
            var wordAttr = AttributedString(word.arabic)

            // Apply highlight if this word should be highlighted
            if shouldHighlightWord(word) {
                wordAttr.backgroundColor = .yellow.opacity(0.4)
            }

            result.append(wordAttr)

            // Add space between words (except after last word)
            if index < words.count - 1 {
                result.append(AttributedString(" "))
            }
        }

        return result
    }

    /// Checks if a word should be highlighted based on index list or English translation match
    private func shouldHighlightWord(_ word: QuranWordByWordSD) -> Bool {
        // Check if word index is in the explicit highlight list
        if let highlightIndices = options.highlightArabicWordIndices,
           highlightIndices.contains(word.word_index) {
            return true
        }

        // Check if any search term matches the word's English translation
        let query = options.highlightPhrase.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            // Split query into individual words and check each
            let searchTerms = query.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            for term in searchTerms {
                if word.english.localizedCaseInsensitiveContains(term) {
                    return true
                }
            }
        }

        return false
    }

    /// Expanded word-by-word layout showing Arabic, transliteration, and English for each word
    private var arabicWordByWordExpandedView: some View {
        FlexStack(horizontalSpacing: 8, verticalSpacing: 12) {
            ForEach(data.wordByWord.sorted { $0.word_index < $1.word_index }, id: \.word_index) { word in
                wordByWordCard(word: word)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    /// Individual word card for expanded word-by-word view
    @ViewBuilder
    private func wordByWordCard(word: QuranWordByWordSD) -> some View {
        let isHighlighted = shouldHighlightWord(word)
        let cardContent = wordByWordCardContent(word: word, isHighlighted: isHighlighted)

        if options.disableInteractiveElements {
            cardContent
        } else {
            Button {
                router.push(.wordInfo(
                    chapterNumber: data.index.chapter_number,
                    verseNumber: data.index.verse_number,
                    wordIndex: word.word_index
                ))
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
        }
    }

    /// Content for word-by-word card (separated for reuse)
    private func wordByWordCardContent(word: QuranWordByWordSD, isHighlighted: Bool) -> some View {
        VStack(spacing: 6) {
            // Arabic word
            Text(word.arabic)
                .font(arabicFont.font(size: CGFloat(fontSize + 2)))
                .foregroundStyle(isHighlighted ? Color.accentColor : .primary)

            // Transliteration and English
            VStack(spacing: 2) {
                Text(word.transliterated)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.accentColor.opacity(0.9))

                Text(word.english)
                    .tracking(1)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: 100)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isHighlighted ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    /// Leading padding for text elements in book style to align with verse ID column
    private var bookTextLeadingPadding: CGFloat {
        options.linkToChapterContext ? 52 : 32
    }

    @ViewBuilder
    private var footnoteView: some View {
        if footnotes || specialInitSource == .footnote, let footnote = data.footnote {
            HStack {
                ConditionalHighlight(
                    text: footnote.getTextInUserLanguage(),
                    query: options.highlightPhrase
                )
                .italic()
                .font(.system(size: CGFloat(fontSize) - 6))
                .foregroundStyle(.secondary)
                .fontWeight(quranReaderStyle == .cards ? .light : .regular)
                .environment(\.layoutDirection, primaryLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
                .multilineTextAlignment(primaryLanguage.isRightToLeft ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(.top, quranReaderStyle == .cards ? 8 : 8)
            .padding(.leading, quranReaderStyle == .book ? bookTextLeadingPadding : 0)
        }
    }

    private func selectButton(selectMode: QuranSelectMode) -> some View {
        Button(action: toggleSelection) {
            Image(systemName: selectMode.selection.contains(data) ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(selectMode.selection.contains(data) ? .blue : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var cardPadding: CGFloat {
        if options.unformatted { return 0 }
        return quranReaderStyle == .book ? 12 : 12
    }

    private var cardBackground: some View {
        Group {
            switch quranReaderStyle {
            case .cards:
                Color.secondary
                    .opacity(cardBackgroundOpacity)
                    .padding(options.unformatted ? 0 : -4)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            case .book:
                Color.secondary
                    .opacity(bookBackgroundOpacity)
            }
        }
    }

    private var cardBackgroundOpacity: Double {
        if options.unformatted { return 0 }
        if isCurrentlyPlaying { return theme == .dark ? 0.18 : 0.22 }
        if options.selectMode?.selection.contains(data) == true { return 0.17 }
        if showHighlight { return theme == .dark ? 0.12 : 0.18 }
        return 0.06
    }

    private var bookBackgroundOpacity: Double {
        if options.unformatted { return 0 }
        if isCurrentlyPlaying { return theme == .dark ? 0.18 : 0.22 }
        if options.selectMode?.selection.contains(data) == true { return 0.17 }
        if showHighlight { return theme == .dark ? 0.12 : 0.18 }
        return 0
    }
    
    private var isVerseBookmarked: Bool {
        return bookmarkManager.isVerseBookmarked(chapter: data.index.chapter_number, verse: data.index.verse_number)
    }

    private var verseContextMenu: some View {
        Section("VERSE \(data.index.verse_id)") {
            Button {
                if isVerseBookmarked {
                    bookmarkManager.removeByKey(data.index.verse_id)
                } else {
                    bookmarkManager.addVerse(data.index.verse_id)
                    presentBookmarkSheet = true
                }
            } label: {
                Label(isVerseBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isVerseBookmarked ? "bookmark.slash" : "bookmark")
            }
            Button {
                shareText(data.formatToText())
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                UIPasteboard.general.string = data.formatToText()
                AlertKitAPI.present(
                    title: "\(data.index.verse_id) Copied",
                    icon: .done,
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            } label: {
                Label("Copy", systemImage: "document.on.document")
            }
            if !options.disableInteractiveElements, let selectMode = options.selectMode {
                Button {
                    selectMode.reset()
                    selectMode.canSelect = true
                    selectMode.isActive = true
                    toggleSelection()
                } label: {
                    Label("Select", systemImage: "hand.tap")
                }
            }
            Button {
                audioManager.play(data, modelContext: modelContext)
            } label: {
                Label("Play", systemImage: "play")
            }
            Button {
                router.navigate(to: .verseInfo(chapterNumber: data.index.chapter_number, verseNumber: data.index.verse_number))
            } label: {
                Label("Info", systemImage: "info.circle")
            }
        }
    }

    private func handleTap() {
        if options.selectMode?.isActive == true {
            toggleSelection()
        } else if options.linkToChapterContext {
            if options.linkShouldNotReroute {
                router.append(.chapter(chapterNumber: data.index.chapter_number, scrollToVerseNumber: data.index.verse_number))
            } else {
                dismiss()
                router.popToRoot(for: .quran)
                router.navigate(to: .chapter(chapterNumber: data.index.chapter_number, scrollToVerseNumber: data.index.verse_number))
            }
        } else if options.linkToVerseInfo {
            if options.linkShouldNotReroute {
                router.append(.verseInfo(chapterNumber: data.index.chapter_number, verseNumber: data.index.verse_number))
            } else {
                dismiss()
                router.popToRoot(for: .quran)
                router.navigate(to: .verseInfo(chapterNumber: data.index.chapter_number, verseNumber: data.index.verse_number))
            }
        }
    }

    private func handleOnAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if options.isScrolledTo {
                withAnimation {
                    showHighlight = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showHighlight = false
                    }
                }
            }
        }
    }

    private var visibilityTracker: some View {
        GeometryReader { geo in
            Color.clear
                .onChange(of: geo.frame(in: .global).minY) { _, minY in
                    let isVisible = minY > 50 && minY < 400
                    if isVisible {
                        if visibilityStartDate == nil {
                            visibilityStartDate = Date()
                            visibilityCommitTask?.cancel()
                            visibilityCommitTask = Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    lastReadVerse = data.index.verse_id
                                }
                            }
                        }
                    } else {
                        visibilityStartDate = nil
                        visibilityCommitTask?.cancel()
                        visibilityCommitTask = nil
                    }
                }
        }
    }
    
    // [Toggle selection if select mode is active]
    private func toggleSelection() {
        guard let selectMode = options.selectMode else { return }
        if selectMode.selection.contains(data) {
            selectMode.removeSelection(data)
        } else {
            selectMode.addSelection(data)
        }
    }
}
