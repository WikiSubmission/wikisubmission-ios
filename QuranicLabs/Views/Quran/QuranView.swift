import SwiftUI
import Defaults
import SheetKit

struct QuranView: View {
    var hideSearchbar: Bool = false
    var initialQuery: String? = nil
    var autoFocus: Bool = false
    
    @State private var query: String = ""
    @State private var typingState: SearchbarTypingState = .idle
    @State private var queryState: SearchbarQueryState = .idle
    @State private var queryResults: [Types.Quran.Data] = []
    @State private var queryResultsType: Types.Quran.ParsedQuery? = nil
    @State private var showScrollToTop: Bool = false
    
    @FocusState private var isKeyboardActive: Bool
    
    @Default(.sort_chapters_by_revelation_order) var sortChaptersByRevelationOrder
    
    @Environment(\.openURL) private var openURL

    private var initialQueryValue: String {
        initialQuery ?? ""
    }

    var body: some View {
        NavigationStack {
            
            VStack(spacing: 4) {
                if !hideSearchbar {
                    // Search bar area
                    VStack(spacing: 4) {
                        // Search bar
                        searchBarView
                        
                        // Search bar (bottom text)
                        searchBarBottomTextView
                    }
                    .padding(.horizontal)
                }

                // Main content area
                ScrollViewReader { proxy in

                    // Scrollable
                    ScrollView(.vertical, showsIndicators: true) {
                        // Top anchor
                        Color.clear.frame(height: 0).id("top")
                        
                        // Chapter options
                        chapterOptionsRow
                        
                        // Default view: list of chapters
                        chapterListView
                        
                        // Search results suggestions (if applicable)
                        searchResultsSuggestionsView
                        
                        // Search results view
                        searchResultsView
                    }
                    .frame(maxWidth: .infinity)
                    // Scroll to top on query change
                    .onChange(of: queryResults) { _, _ in
                        withAnimation {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                    // Overlay button: a "scroll to top"
                    .overlay(
                        Group {
                            if showScrollToTop {
                                Button {
                                    withAnimation(.spring()) {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                } label: {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.accentColor))
                                }
                                .padding()
                            }
                        },
                        alignment: .bottomTrailing
                    )
                }
                .padding(.horizontal)
                .toolbar { toolbarMenu }
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
            placeholder: "Verse, chapter, text...",
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
                                Label("Share/copy...", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(SignatureButtonStyle())
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 0.5)
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
                    }
                    .buttonStyle(SignatureButtonStyle())
                }
            }
        }
        .font(.caption)
        .padding(.bottom, 4)
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
    QuranView()
        .environmentObject(Utilities.Quran.BookmarkManager.shared)
}
