import SwiftUI
import Defaults
import SheetKit

struct QuranView: View {
    @Binding var shouldScrollToTop: Bool
    
    /// Search function.
    @FocusState private var searchBarFocused
    @StateObject private var liveInput = QueryDebouncer()
    @State private var query = ""
    @State private var typingState: SearchbarTypingState = .idle
    
    @State private var searchResults: Types.Quran.SearchResult = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
    @State private var searchResultsFiltered: Types.Quran.SearchResult = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
    @State private var searchResultsLoading = false
    @State private var searchResultsFilter: SearchResultsFilterTypes = .all
    
    @Environment(\.colorScheme) var theme
        
    @Default(.sort_chapters_by_revelation_order) var sortChaptersByRevelationOrder
    @Default(.primary_language) var primaryLanguage
    @Default(.last_played_verse) var lastPlayedVerse
    @Default(.daily_chapter) var dailyChapter
    @Default(.daily_verse) var dailyVerse
    @Default(.last_opened_chapter) var lastOpenedChapter
    
    enum SearchResultsFilterTypes: String, CaseIterable {
        case all, text, subtitles, footnotes
    }

    var body: some View {
        NavigationStack {
            VStack {
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    // Root level section, with pinned search bar.
                    Section(header: searchBar.padding(.top, 4)) {
                        // Section: Chapter list section (if no results).
                        if !hasSearchResults {
                            Section {
                                chapterList
                            }
                        }
                        
                        // Section: Search results (if results).
                        if hasSearchResults {
                            Section {
                                searchResultList
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .toolbar {
                toolbarMenu
            }
        }
    }
    
    private var hasSearchResults: Bool {
        return searchResults.chapters.count > 0 || searchResults.verseIDs.count > 0 || searchResults.text.count > 0 || searchResults.subtitles.count > 0 || searchResults.footnotes.count > 0
    }
    
    private var totalResultsCount: Int {
        return searchResults.chapters.count + searchResults.verseIDs.count + searchResults.text.count + searchResults.subtitles.count + searchResults.footnotes.count
    }
    
    private var hasMultipleSearchResultTypes: Bool {
        let counts = [
                searchResults.chapters.count,
                searchResults.verseIDs.count,
                searchResults.text.count,
                searchResults.subtitles.count,
                searchResults.footnotes.count
        ]
        
        let nonEmptyTypes = counts.filter { $0 > 0 }.count
        
        return nonEmptyTypes > 1
    }
    
    private var singleSearchResultType: SearchResultsFilterTypes {
        if searchResults.text.count > 0 { return .text }
        if searchResults.subtitles.count > 0 { return .subtitles }
        if searchResults.footnotes.count > 0 { return .footnotes }
        else { return .all }
    }
    
    private var singleSearchResultTypeName: String {
        if searchResults.chapters.count > 0 { return "chapter" }
        if searchResults.verseIDs.count > 0 { return "verse" }
        if searchResults.text.count > 0 { return "text" }
        if searchResults.subtitles.count > 0 { return "subtitle" }
        if searchResults.footnotes.count > 0 { return "footnote" }
        
        return "results"
    }
    
    private var singleSearchResultData: Types.Quran.SearchResult {
        if searchResults.text.count > 0 { return .init(type: .verse, chapters: [], verseIDs: [], text: searchResults.text, subtitles: [], footnotes: []) }
        if searchResults.subtitles.count > 0 { return .init(type: .verse, chapters: [], verseIDs: [], text: [], subtitles: searchResults.subtitles, footnotes: []) }
        if searchResults.footnotes.count > 0 { return .init(type: .verse, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: searchResults.footnotes) }
        
        return .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            ZStack {
                Image(systemName: typingState == .typing ? "ellipsis" : "magnifyingglass")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20, height: 20)
            }
            .frame(width: 20, height: 20)
            .padding(.leading)
            
            TextField("", text: $liveInput.text, prompt:
                        Text("Chapter, verse, or text")
                .foregroundStyle(.gray)
            )
                .font(.title2)
                .foregroundColor(.accentColor)
                .padding(.leading, 8)
                .padding(.vertical, 10)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchBarFocused)
                .onAppear {
                    if query.isEmpty { typingState = .idle }
                }
            
            if !liveInput.text.isEmpty {
                Button {
                    searchBarFocused = true
                    liveInput.text = ""
                    typingState = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.trailing)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(theme == .dark ? Color.black : Color.white))
        .animation(.easeInOut(duration: 0.2), value: liveInput.text.isEmpty)
        .onAppear { if query.isEmpty { typingState = .idle } }
        .onChange(of: liveInput.debouncedText) { _, finalQuery in
            query = finalQuery
            
            // Done typing. Run the query:
            if !finalQuery.isEmpty {
                shouldScrollToTop = true
                typingState = .doneTyping
                searchResultsFilter = .all
                searchResultsFiltered = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                searchResultsLoading = true
                
                
                DispatchQueue.main.async {
                    searchResults = Utilities.Quran.DataAPI.search(term: finalQuery)
                    searchResultsLoading = false
                                        
                    if !hasMultipleSearchResultTypes {
                        self.searchResultsFilter = singleSearchResultType
                        self.searchResultsFiltered = singleSearchResultData
                    }
                }
            } else {
                typingState = .idle
                searchResults = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                searchResultsFiltered = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                searchResultsLoading = false
            }
        }
        .onChange(of: liveInput.text) { _, finalQuery in
            if !finalQuery.isEmpty { typingState = .typing }
        }
    }
    
    private var chapterList: some View {
        VStack(spacing: 8) {
            
            if query.count > 0 && !searchResultsLoading && typingState == .doneTyping {
                Text("No results found for '\(query)'")
                    .font(.footnote)
                    .fontWeight(.light)
                    .foregroundStyle(.secondary)
                    .pushToLeft()
            }
            
            VStack(spacing: 4) {
                quickActionsRow

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
    
    private var searchResultList: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if hasMultipleSearchResultTypes {
                        Button {
                            withAnimation {
                                searchResultsFiltered = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                                searchResultsFilter = .all
                            }
                        } label: {
                            Text("All (\(totalResultsCount))")
                        }
                        .fontWeight(searchResultsFilter == .all ? .bold : .regular)
                    }
                    
                    if searchResults.text.count > 0 {
                        Button {
                            withAnimation {
                                searchResultsFiltered = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                                searchResults.type = searchResults.type
                                searchResultsFiltered.subtitles = searchResults.text
                                searchResultsFilter = .text
                            }
                        } label: {
                            Text("Text (\(searchResults.text.count))")
                        }
                        .fontWeight(searchResultsFilter == .text ? .bold : .regular)
                    }
                    
                    if searchResults.subtitles.count > 0 {
                        Button {
                            withAnimation {
                                searchResultsFiltered = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                                searchResults.type = searchResults.type
                                searchResultsFiltered.subtitles = searchResults.subtitles
                                searchResultsFilter = .subtitles
                            }
                        } label: {
                            Text("Subtitles (\(searchResults.subtitles.count))")
                        }
                        .fontWeight(searchResultsFilter == .subtitles ? .bold : .regular)
                    }
                    
                    if searchResults.footnotes.count > 0 {
                        Button {
                            withAnimation {
                                searchResultsFiltered = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
                                searchResults.type = searchResults.type
                                searchResultsFiltered.subtitles = searchResults.footnotes
                                searchResultsFilter = .footnotes
                            }
                        } label: {
                            Text("Footnotes (\(searchResults.footnotes.count))")
                        }
                        .fontWeight(searchResultsFilter == .footnotes ? .bold : .regular)
                    }
                    
                    Spacer()
                }
                .font(.footnote)
                .buttonStyle(SignatureButtonStyle())
            }
            
            ForEach(searchResultsFilter == .all ? searchResults.chapters : searchResultsFiltered.chapters, id: \.self) { chapter in
                QuranChapterCard(chapter: chapter)
            }
            
            ForEach(searchResultsFilter == .all ? searchResults.verseIDs : searchResultsFiltered.verseIDs, id: \.self) { verseId in
                QuranVerseCard(id: verseId)
            }
            
            ForEach(searchResultsFilter == .all ? searchResults.text : searchResultsFiltered.text, id: \.self) { verse in
                QuranVerseCard(id: verse.verse_id, highlight: query)
            }
            
            ForEach(searchResultsFilter == .all ? searchResults.subtitles : searchResultsFiltered.subtitles, id: \.self) { verse in
                QuranVerseCard(id: verse.verse_id, highlight: query)
            }
            
            ForEach(searchResultsFilter == .all ? searchResults.footnotes : searchResultsFiltered.footnotes, id: \.self) { verse in
                QuranVerseCard(id: verse.verse_id, highlight: query)
            }
        }
    }
    
    private var quickActionsRow: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                if !hasSearchResults {
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
                        
                        if let chapter = Int(lastPlayedVerse.split(separator: ":")[0]), AppData.Quran.versesByChapter[chapter]?.last?.verse_id != lastPlayedVerse, Utilities.Quran.QuranAudioManager.shared.isPlaying == false {
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
                        
                        if let dailyChapter = dailyChapter {
                            NavigationLink {
                                NavigationStack {
                                    QuranReaderView(chapter: dailyChapter)
                                }
                            } label: {
                                Label("Daily Chapter", systemImage: "book.pages.fill")
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
                    }
                    .buttonStyle(SignatureButtonStyle())
                    .padding(.vertical, 8)
                }
            }
        }
        .font(.caption)
    }
    
    private var toolbarMenu: some View {
        // Loading Spinner
        HStack(alignment: .center, spacing: 0) {
            if searchResultsLoading {
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
}


//import SwiftUI
//import Defaults
//import SheetKit
//
//struct QuranView: View {
//    @Binding var shouldScrollToTop: Bool
//
//    var initialQuery: String? = nil
//    var autoFocus: Bool = false
//    
//    @State private var query: String = ""
//    @State private var isSearching: Bool = false
//    @State private var queryResults: Types.Quran.QuranSearchResult? = .init(type: .unknown, chapters: [], verseIDs: [], text: [], subtitles: [], footnotes: [])
//    @State private var queryResultsType: Types.Quran.ParsedQuery? = nil
//    @State private var queryResultsFilter: QueryResultsFilterTypes = .all
//    @State private var queryResultsDisplayed: [Types.Quran.Data] = []
//    
//    @FocusState private var isKeyboardActive: Bool
//    
//    @Default(.sort_chapters_by_revelation_order) var sortChaptersByRevelationOrder
//    
//    @Environment(\.openURL) private var openURL
//
//    private var initialQueryValue: String {
//        initialQuery ?? ""
//    }
//    
//    @Default(.primary_language) var primaryLanguage
//    @Default(.last_played_verse) var lastPlayedVerse
//    @Default(.daily_verse) var dailyVerse
//    @Default(.last_opened_chapter) var lastOpenedChapter
//    
//    enum QueryResultsFilterTypes: String, CaseIterable {
//        case all, text, subtitles, footnotes
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 4) {
//                LazyVStack(pinnedViews: [.sectionHeaders]) {
//                    Section(header:
//                        VStack {
//                            searchBarView
//                        }
//                    ) {
//                        VStack(spacing: 4) {
//                            // Bottom text
//                            searchBarBottomTextView
//
//                            // Chapter options
//                            chapterOptionsRow
//                            
//                            // Default view: list of chapters
//                            chapterListView
//                            
//                            // Search results suggestions (if applicable)
//                            searchResultsSuggestionsView
//                            
//                            // Search results view
//                            searchResultsView
//                            
//                            Color.clear.frame(height: 32)
//                        }
//                    }
//                }
//                .frame(maxWidth: .infinity)
//                .scrollBounceBehavior(.basedOnSize)
//                .padding(.horizontal)
//                .toolbar { toolbarMenu }
//                .onChange(of: isKeyboardActive) { _, state in
//                    if state == true {
//                        shouldScrollToTop = true
//                    }
//                }
//            }
//        }
//        .task {
//            if !initialQueryValue.isEmpty {
//                query = initialQueryValue
//                performSearch(initialQueryValue)
//            }
//            if autoFocus {
//                DispatchQueue.main.async {
//                    isKeyboardActive = true
//                }
//            }
//        }
//    }
//    
//    private var totalResults: Int {
//        (queryResults?.text.count ?? 0) + (queryResults?.subtitles.count ?? 0) + (queryResults?.footnotes.count ?? 0)
//    }
//    
//    private var searchBarView: some View {
//        HStack {
//            TextField("Verse, chapter, or text", text: $query, onCommit: {
//                performSearch(query)
//            })
//            .textFieldStyle(RoundedBorderTextFieldStyle())
//            .focused($isKeyboardActive)
//            .disableAutocorrection(true)
//            .autocapitalization(.none)
//            
//            Button(action: {
//                performSearch(query)
//            }) {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(query.isEmpty ? .gray : .accentColor)
//            }
//            .disabled(query.isEmpty)
//        }
//    }
//    
//    private var searchBarBottomTextView: some View {
//        VStack {
//            
//            if (queryResultsDisplayed.isEmpty && !query.isEmpty && !isSearching) {
//                HStack {
//                    Text("No verse/(s) found with **'\(query)'**")
//                        .foregroundStyle(.secondary)
//                        .font(.caption)
//                    Spacer()
//                }
//                .padding(.vertical, 8)
//            }
//            
//            if queryResultsDisplayed.count > 1 {
//                Section {
//                    HStack(alignment: .center) {
//                        if queryResultsType == .search {
//                            Text("**\(totalResults == 500 ? "500+" : "\(totalResults)")** verses found with '\(query)'")
//                        }
//                        Spacer()
//                        if totalResults > 1 {
//                            Button {
//                                SheetKit().presentWithEnvironment {
//                                    QuranShareVerses(data: queryResultsDisplayed)
//                                }
//                            } label: {
//                                Image(systemName: "square.and.arrow.up")
//                            }
//                            .buttonStyle(SignatureButtonStyle())
//                        }
//                    }
//                    .foregroundStyle(.secondary)
//                    .font(.caption)
//                }
//                .padding(.top, 4)
//            }
//            
//            if totalResults > 0 {
//                searchResultsFilterView
//            }
//        }
//    }
//    
//    private var searchResultsSuggestionsView: some View {
//        VStack {
//            // Suggestion: chapter
//            if queryResultsType == .verse {
//                if let firstID = queryResults?.verseIDs.first,
//                   let chapterPart = firstID.split(separator: ":").first,
//                   let chapter = Int(chapterPart) {
//                    QuranChapterCard(chapter: chapter)
//                }
//                
//                Divider()
//                    .padding(.vertical, 4)
//            }
//        }
//    }
//    
//    private var searchResultsFilterView: some View {
//        VStack {
//            let subtitles = queryResults?.subtitles ?? []
//            let footnotes = queryResults?.footnotes ?? []
//            if totalResults > 1 {
//                HStack {
//                    if subtitles.count > 0 || footnotes.count > 0 {
//                        Button {
//                            withAnimation {
//                                queryResultsFilter = .all
//                            }
//                        } label: {
//                            Text("All (\(totalResults))")
//                        }
//                        .fontWeight(queryResultsFilter == .all ? .bold : .regular)
//                    }
//                    
//                    if subtitles.count > 0 {
//                        Button {
//                            withAnimation {
//                                queryResultsFilter = .subtitles
//                            }
//                        } label: {
//                            Text("Subtitles (\(subtitles.count))")
//                        }
//                        .fontWeight(queryResultsFilter == .subtitles ? .bold : .regular)
//                    }
//                    
//                    if footnotes.count > 0 {
//                        Button {
//                            withAnimation {
//                                queryResultsFilter = .footnotes
//                            }
//                        } label: {
//                            Text("Footnotes (\(footnotes.count))")
//                        }
//                        .fontWeight(queryResultsFilter == .footnotes ? .bold : .regular)
//                    }
//                    Spacer()
//                }
//                .font(.footnote)
//                .buttonStyle(SignatureButtonStyle())
//            }
//        }
//    }
//    
//    private var queryResultsFiltered: [Types.Quran.Data] {
//        switch queryResultsFilter {
//        case .all:
//            return queryResultsDisplayed
//        case .text:
//            return queryResults?.text ?? []
//        case .subtitles:
//            return queryResults?.subtitles ?? []
//        case .footnotes:
//            return queryResults?.footnotes ?? []
//        }
//    }
//    
//    private var searchResultsView: some View {
//        LazyVStack(spacing: 8) {
//            ForEach(queryResultsFiltered.count > 0 ? queryResultsFiltered : (queryResults?.text ?? []), id: \.verse_id) { verse in
//                QuranVerseCard(id: verse.verse_id, highlight: query, linkToChapter: true)
//            }
//        }
//    }
//    
//    private var chapterOptionsRow: some View {
//        VStack {
//            ScrollView(.horizontal, showsIndicators: false) {
//                if (queryResults?.text.isEmpty ?? true) {
//                    HStack {
//                        Button {
//                            withAnimation {
//                                sortChaptersByRevelationOrder.toggle()
//                            }
//                        } label: {
//                            Label(sortChaptersByRevelationOrder ? "Revelation Order" : "Standard Order", systemImage: "arrow.up.arrow.down")
//                        }
//
//                        Button {
//                            withAnimation {
//                                SheetKit().presentWithEnvironment {
//                                    WebView(url: URL(string: "https://library.wikisubmission.org/file/quran-the-final-testament")!)
//                                }
//                            }
//                        } label: {
//                            Label("PDF", systemImage: "arrow.down.document.fill")
//                        }
//                        
//                        if let chapter = Int(lastPlayedVerse.split(separator: ":")[0]), AppData.Quran.versesByChapter[chapter]?.last?.verse_id != lastPlayedVerse, Utilities.Quran.QuranAudioManager.shared.isPlaying == false {
//                            NavigationLink {
//                                NavigationStack {
//                                    QuranReaderView(chapter: chapter, scrollToVerseID: lastPlayedVerse)
//                                        .onAppear {
//                                            Utilities.Quran.QuranAudioManager.shared.playQueue(AppData.Quran.versesByChapter[chapter] ?? [], startFromVerse: Int(lastPlayedVerse.split(separator: ":")[1]))
//                                        }
//                                }
//                            } label: {
//                                Label("Play \(lastPlayedVerse)", systemImage: "play.square.stack.fill")
//                            }
//                        }
//                        
//                        if let dailyVerse = dailyVerse, let chapter = Int(dailyVerse.split(separator: ":")[0]) {
//                            NavigationLink {
//                                NavigationStack {
//                                    QuranReaderView(chapter: chapter, scrollToVerseID: dailyVerse)
//                                }
//                            } label: {
//                                Label("Daily Verse", systemImage: "book.pages.fill")
//                            }
//                        }
//                    }
//                    .buttonStyle(SignatureButtonStyle())
//                    .padding(.vertical, 8)
//                }
//            }
//        }
//        .font(.caption)
//    }
//    
//    private var chapterListView: some View {
//        VStack(spacing: 8) {
//            if (queryResults?.text.isEmpty ?? true) {
//                let sortedChapters = AppData.Quran.chapters.sorted { lhs, rhs in
//                    if sortChaptersByRevelationOrder {
//                        return lhs.revelation_order < rhs.revelation_order
//                    } else {
//                        return lhs.chapter_number < rhs.chapter_number
//                    }
//                }
//                
//                ForEach(Array(sortedChapters.enumerated()), id: \.element) { index, chapter in
//                    QuranChapterCard(
//                        chapter: chapter.chapter_number,
//                        displayIndex: sortChaptersByRevelationOrder
//                            ? "\(index + 1)" // position in revelation order
//                            : "\(chapter.chapter_number)" // normal chapter number
//                    )
//                }
//            }
//        }
//    }
//    
//    private var toolbarMenu: some View {
//        // Loading Spinner
//        HStack(alignment: .center, spacing: 0) {
//            if isSearching {
//                ProgressView()
//            }
//            
//            NavigationLink {
//                QuranBookmarks()
//            } label: {
//                Label("Bookmarks", systemImage: "bookmark")
//                    .labelStyle(.iconOnly)
//            }
//            
//            Menu {
//                // Reader Settings
//                QuranMenu()
//                
//                // Navigations
//                Section {
//                    NavigationLink {
//                        QuranRandomVerse()
//                    } label: {
//                        Label("Random Verse", systemImage: "sparkles")
//                    }
//                }
//            } label: {
//                Label("Options", systemImage: "ellipsis.circle")
//                    .labelStyle(.iconOnly)
//            }
//        }
//    }
//    
//    private func performSearch(_ term: String) {
//        guard !term.isEmpty else { return }
//        query = term
//        isSearching = true
//        Task {
//            let results = Utilities.Quran.DataAPI.search(term: query, language: primaryLanguage, fuzzy: true)
//            await MainActor.run {
//                withAnimation {
//                    queryResults = results
//                    queryResultsType = results.type
//                    queryResultsDisplayed = results.text + results.subtitles + results.footnotes
//                    queryResultsFilter = .all
//                    isSearching = false
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    HomeView()
//        .environmentObject(AppEnvironment.shared)
//}
