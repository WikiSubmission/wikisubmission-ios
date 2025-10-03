import SwiftUI
import Defaults
import SheetKit

struct QuranView: View {
    @Binding var shouldScrollToTop: Bool

    var initialQuery: String? = nil
    var autoFocus: Bool = false
    
    @State private var query: String = ""
    @State private var typingState: SearchbarTypingState = .idle
    @State private var queryState: SearchbarQueryState = .idle
    @State private var queryResults: [Types.Quran.Data] = []
    @State private var queryResultsType: Types.Quran.ParsedQuery? = nil
    
    @FocusState private var isKeyboardActive: Bool
    
    @Default(.sort_chapters_by_revelation_order) var sortChaptersByRevelationOrder
    
    @Environment(\.openURL) private var openURL

    private var initialQueryValue: String {
        initialQuery ?? ""
    }
    
    @Default(.last_played_verse) var lastPlayedVerse
    @Default(.daily_verse) var dailyVerse
    @Default(.last_opened_chapter) var lastOpenedChapter

    var body: some View {
        NavigationStack {
            VStack(spacing: 4) {
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    Section(header:
                        VStack {
                            searchBarView
                        }
                    ) {
                        VStack(spacing: 4) {
                            // Bottom text
                            searchBarBottomTextView

                            // Chapter options
                            chapterOptionsRow
                            
                            // Default view: list of chapters
                            chapterListView
                            
                            // Search results suggestions (if applicable)
                            searchResultsSuggestionsView
                            
                            // Search results view
                            searchResultsView
                            
                            Color.clear.frame(height: 32)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .scrollBounceBehavior(.basedOnSize)
                .padding(.horizontal)
                .toolbar { toolbarMenu }
                .onChange(of: typingState) { _, state in
                    if state == .doneTyping {
                        shouldScrollToTop = true
                    }
                }
                .onChange(of: isKeyboardActive) { _, state in
                    if state == true {
                        shouldScrollToTop = true
                    }
                }
            }
        }
        .task {
            if !initialQueryValue.isEmpty {
                query = initialQueryValue
                performSearch(initialQueryValue)
            }
            if autoFocus {
                DispatchQueue.main.async {
                    isKeyboardActive = true
                }
            }
        }
    }
    
    private var searchBarView: some View {
        Searchbar<Types.Quran.Data>(
            query: $query,
            typingState: $typingState,
            queryState: $queryState,
            queryResults: $queryResults,
            queryFunction: queryFunction,
            placeholder: "Verse, chapter, or text",
            autoFocus: false
        )
        .focused($isKeyboardActive)
    }
    
    private var searchBarBottomTextView: some View {
        VStack {
            
            if queryResults.isEmpty && !query.isEmpty && queryState == .done {
                HStack {
                    Text("No verse/(s) found with **'\(query)'**")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            if queryResults.count > 1 {
                Section {
                    HStack(alignment: .center) {
                        if queryResultsType?.type == .search {
                            Text("**\(queryResults.count == 500 ? "500+" : "\(queryResults.count)")** verses found with '\(query)'")
                        }
                        Spacer()
                        if queryResults.count > 1 {
                            Button {
                                SheetKit().presentWithEnvironment {
                                    QuranShareVerses(data: queryResults)
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .buttonStyle(SignatureButtonStyle())
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var searchResultsSuggestionsView: some View {
        VStack {
            // Suggestion: chapter
            if queryResultsType?.type == .chapter && queryResults.first != nil {
                QuranChapterCard(chapter: queryResults.first?.chapter_number ?? 1)
                Divider()
                    .padding(.vertical, 4)
            }
        }
    }
    
    private var searchResultsView: some View {
        LazyVStack(spacing: 8) {
            ForEach(queryResults, id: \.verse_id) { verse in
                QuranVerseCard(id: verse.verse_id, highlight: query, linkToChapter: true)
            }
        }
    }
    
    private var chapterOptionsRow: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                if queryResults.isEmpty {
                    HStack {
                        Button {
                            withAnimation {
                                sortChaptersByRevelationOrder.toggle()
                            }
                        } label: {
                            Label(sortChaptersByRevelationOrder ? "Revelation Order" : "Standard Order", systemImage: "arrow.up.arrow.down")
                        }

                        Button {
                            withAnimation {
                                SheetKit().presentWithEnvironment {
                                    WebView(url: URL(string: "https://library.wikisubmission.org/file/quran-the-final-testament")!)
                                }
                            }
                        } label: {
                            Label("PDF", systemImage: "arrow.down.document.fill")
                        }
                        
                        if let chapter = Int(lastPlayedVerse.split(separator: ":")[0]), AppData.Quran.versesByChapter[chapter]?.last?.verse_id != lastPlayedVerse {
                            NavigationLink {
                                NavigationStack {
                                    QuranReaderView(chapter: chapter, scrollToVerseID: lastPlayedVerse)
                                        .onAppear {
                                            Utilities.Quran.QuranAudioManager.shared.playQueue(AppData.Quran.versesByChapter[chapter] ?? [], startFromVerse: Int(lastPlayedVerse.split(separator: ":")[1]))
                                        }
                                }
                            } label: {
                                Label("Play \(lastPlayedVerse)", systemImage: "play.square.stack.fill")
                            }
                        }
                        
                        if let dailyVerse = dailyVerse, let chapter = Int(dailyVerse.split(separator: ":")[0]) {
                            NavigationLink {
                                NavigationStack {
                                    QuranReaderView(chapter: chapter, scrollToVerseID: dailyVerse)
                                }
                            } label: {
                                Label("Daily Verse", systemImage: "book.pages.fill")
                            }
                        }
                        
                        NavigationLink {
                            NavigationStack {
                                QuranReaderView(chapter: lastOpenedChapter)
                            }
                        } label: {
                            Label("Sura \(lastOpenedChapter)", systemImage: "text.line.magnify")
                        }
                    }
                    .buttonStyle(SignatureButtonStyle())
                    .padding(.vertical, 8)
                }
            }
        }
        .font(.caption)
    }
    
    private var chapterListView: some View {
        VStack(spacing: 8) {
            if queryResults.isEmpty {
                let sortedChapters = AppData.Quran.chapters.sorted { lhs, rhs in
                    if sortChaptersByRevelationOrder {
                        return lhs.revelation_order < rhs.revelation_order
                    } else {
                        return lhs.chapter_number < rhs.chapter_number
                    }
                }
                
                ForEach(Array(sortedChapters.enumerated()), id: \.element) { index, chapter in
                    QuranChapterCard(
                        chapter: chapter.chapter_number,
                        displayIndex: sortChaptersByRevelationOrder
                            ? "\(index + 1)" // position in revelation order
                            : "\(chapter.chapter_number)" // normal chapter number
                    )
                }
            }
        }
    }
    
    private var toolbarMenu: some View {
        // Loading Spinner
        HStack(alignment: .center, spacing: 0) {
            if queryState == .loading {
                ProgressView()
            }
            
            NavigationLink {
                QuranBookmarks()
            } label: {
                Label("Bookmarks", systemImage: "bookmark")
                    .labelStyle(.iconOnly)
            }
            
            Menu {
                // Reader Settings
                QuranMenu()
                
                // Navigations
                Section {
                    NavigationLink {
                        QuranRandomVerse()
                    } label: {
                        Label("Random Verse", systemImage: "sparkles")
                    }
                }
            } label: {
                Label("Options", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
        }
    }
    
    private func performSearch(_ term: String) {
        query = term
        queryState = .loading
        queryFunction(query: query) { _ in
            queryState = .done
        }
    }
    
    func queryFunction(query: String, completion: @escaping (Result<[Types.Quran.Data], Error>) -> Void) {
        Task.detached(priority: .userInitiated) {
            let parsed = await Utilities.Quran.QueryParser.parse(query)

            // Update queryResultsType on the main actor
            await MainActor.run {
                withAnimation { self.queryResultsType = parsed }
            }

            var tempResults: [Types.Quran.Data] = []

            switch parsed {
            case .verse(let chapter, let verse):
                tempResults = Utilities.Quran.DataAPI.fetchVerse(chapter: chapter, verse: verse)
            case .verseRange(let chapter, let start, let end):
                tempResults = Utilities.Quran.DataAPI.fetchRange(chapter: chapter, start: start, end: end)
            case .multipleVerses(let chapter, let verses):
                tempResults = Utilities.Quran.DataAPI.fetchMultiple(chapter: chapter, verses: verses)
            case .chapter(let chapter):
                tempResults = Utilities.Quran.DataAPI.fetchChapter(chapter: chapter)
            case .search(let term, let language, let fuzzy):
                tempResults = await MainActor.run {
                    Utilities.Quran.DataAPI.search(term: term, language: language, fuzzy: fuzzy)
                }
            case .randomChapter:
                tempResults = Utilities.Quran.DataAPI.randomChapter()
            case .randomVerse:
                if let verse = Utilities.Quran.DataAPI.randomVerse() { tempResults = [verse] }
            case .invalid:
                tempResults = []
            }

            // Make results immutable before passing to MainActor.run
            let resultsCopy = tempResults

            await MainActor.run {
                withAnimation { completion(.success(resultsCopy)) }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.shared)
}
