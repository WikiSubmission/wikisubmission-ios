import SwiftUI
import Defaults

struct Quran: View {
    // [Search query: shared with certain child views]
    @State private var searchQuery: QuranQuery = .init()
    
    // [Select mode state: shared with certain child views]
    @State private var selectMode = QuranSelectMode()
    
    // [Search bar presented state]
    @State private var searchBarIsPresented = false
    
    // [Global app router]
    @ObservedObject var router = Router.shared
        
    var body: some View {
        NavigationStack(path: router.pathBinding(for: .quran)) {
            home
                .navigationTitle("Quran")
                .navigationDestination(for: Router.Destination.self) { destination in
                    router.view(for: destination)
                }
                // [Searchbar]
                .searchable(
                    text: $searchQuery.rawInput,
                    isPresented: $searchBarIsPresented,
                    placement: .toolbar,
                    prompt: "Chapter, verse, or text"
                )
                .autocorrectionDisabled()
                // [Toolbar]
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Quran_Content_ToolbarRow()
                    }
                }
                // [Modifiers for searchbar]
                .onSubmit(of: .search) {
                    searchQuery.commitQuery()
                }
                .onChange(of: searchQuery.query) { _, new in
                    selectMode.reset()
                }
                .onChange(of: searchQuery.rawInput) { _, new in
                    if new.isEmpty {
                        searchQuery.reset()
                        selectMode.reset()
                    }
                }
                .onChange(of: router.openQuranSearchBar) { _, new in
                    if new {
                        searchQuery.reset()
                        selectMode.reset()
                        router.popToRoot(for: .quran)
                        // Dismiss first then re-present to ensure focus
                        searchBarIsPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            searchBarIsPresented = true
                        }
                        router.openQuranSearchBar = false
                    }
                }
        }
        .environmentObject(router)
    }

    var home: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    // [Space right below search bar]
                    Group {
                        if searchBarIsPresented && searchQuery.query.isEmpty {
                            // [Search history]
                            Quran_Element_SearchHistory(
                                searchQuery: $searchQuery
                            )
                        } else if !searchBarIsPresented {
                            // [Button options]
                            Quran_Content_OptionsRow(
                                searchQuery: $searchQuery
                            )
                        }
                    }
                    // [Main content]
                    Group {
                        VStack(spacing: 12) {
                            // [Search results]
                            Quran_Content_SearchResults(
                                searchQuery: $searchQuery,
                                selectMode: selectMode
                            )
                            Divider()
                            // [114 chapters list]
                            Quran_Content_ChapterList(
                                searchQuery: $searchQuery
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                if AudioManager.shared.currentTrack != nil {
                    Color.clear.frame(height: 56)
                }
            }
            .frame(maxWidth: .infinity)
            
            if selectMode.canSelect {
                Quran_Element_SelectVersesTrigger(
                    selectMode: selectMode,
                    toolbarContext: false
                )
            }
        }
    }
}
