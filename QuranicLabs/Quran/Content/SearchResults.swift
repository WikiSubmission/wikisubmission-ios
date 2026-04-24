import SwiftUI
import SwiftData

struct Quran_Content_SearchResults: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var searchQuery: QuranQuery
    var selectMode: QuranSelectMode

    @State private var searchResults: [QuranSearchResultItem] = []
    @State private var selectedFilter: SearchFilter = .all
    @State private var selectedSort: SearchSortOrder = .relevance
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    enum SearchSortOrder: String, CaseIterable {
        case relevance = "Relevance"
        case verseOrder = "Verse Order"
    }

    // Computed property for counts by hit type
    private var hitTypeCounts: [SearchHitType: Int] {
        QuranSearchEngine.countByHitType(searchResults)
    }

    // Computed property for available filters (those with results)
    private var availableFilters: [SearchFilter] {
        var filters: [SearchFilter] = [.all]
        for hitType in SearchHitType.allCases {
            if (hitTypeCounts[hitType] ?? 0) > 0 {
                filters.append(SearchFilter.from(hitType: hitType))
            }
        }
        return filters
    }

    // Filtered and sorted results
    private var filteredResults: [QuranSearchResultItem] {
        let filtered = QuranSearchEngine.filter(searchResults, by: selectedFilter)
        switch selectedSort {
        case .relevance:
            return filtered // Already sorted by relevance from search engine
        case .verseOrder:
            return filtered.sorted { (a: QuranSearchResultItem, b: QuranSearchResultItem) in
                a.unified.index.verse_index < b.unified.index.verse_index
            }
        }
    }

    private var totalResultCount: Int {
        searchResults.count
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 12) {
                Color.clear.frame(height: 0).id("search-results-top")
                
                if isSearching {
                    ProgressView()
                        .padding()
                        .padding(.bottom, 32)
                }

                if !isSearching && !searchResults.isEmpty {
                    // Sort picker (only show if more than 10 results)
                    if totalResultCount > 10 {
                        HStack {
                            Spacer()
                            sortPicker
                        }
                    }

                    // Filter buttons using FlexStack
                    if totalResultCount > 2 && availableFilters.count > 1 {
                        filterButtons
                            .padding(.bottom, 8)
                    }

                    // Results display
                    LazyVStack {
                        ForEach(filteredResults) { result in
                            Quran_Element_SearchResultCard(
                                result: result,
                                highlightPhrase: searchQuery.query,
                                selectMode: selectMode
                            )
                        }
                    }
                }
            }
            .onChange(of: searchQuery.query) { old, new in
                performSearch(query: new, proxy: proxy)
            }
        }
    }

    private var sortPicker: some View {
        Menu {
            ForEach(SearchSortOrder.allCases, id: \.self) { sort in
                Button {
                    withAnimation {
                        selectedSort = sort
                    }
                } label: {
                    HStack {
                        Text(sort.rawValue)
                        if selectedSort == sort {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Sort:")
                    .foregroundStyle(.secondary)
                HStack {
                    Text(selectedSort.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.accent)
            }
            .font(DS.Typography.caption)
        }
        .buttonStyle(.plain)
    }

    private var filterButtons: some View {
        FlexStack {
            ForEach(availableFilters) { filter in
                filterButton(for: filter)
            }
        }
    }

    private func filterButton(for filter: SearchFilter) -> some View {
        let count = countForFilter(filter)
        let isSelected = selectedFilter == filter

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                Text(filter.rawValue)
                Text("(\(count))")
            }
            .font(DS.Typography.caption)
            .fontWeight(isSelected ? .bold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.07) : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .accent : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func countForFilter(_ filter: SearchFilter) -> Int {
        if filter == .all {
            return totalResultCount
        }
        guard let hitType = filter.hitType else {
            return 0
        }
        return hitTypeCounts[hitType] ?? 0
    }

    // MARK: - Search Logic

    private func performSearch(query: String, proxy: ScrollViewProxy) {
        // Cancel any existing search task
        searchTask?.cancel()

        withAnimation {
            self.selectedFilter = .all
            self.selectedSort = .relevance
            self.selectMode.reset()
            proxy.scrollTo("search-results-top")

            // Minimum query length: 2 characters
            if query.isEmpty || query.count < 2 {
                searchResults = []
                isSearching = false
                return
            }

            isSearching = true
        }

        // Perform search on main actor (ModelContext requires it)
        searchTask = Task { @MainActor in
            // Small delay to debounce rapid typing
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

            guard !Task.isCancelled else { return }

            let results = QuranSearchEngine.search(query: query, context: modelContext)

            guard !Task.isCancelled else { return }

            withAnimation {
                self.searchResults = results
                self.isSearching = false

                if !results.isEmpty {
                    self.selectMode.canSelect = true
                    searchQuery.updateHistory()
                }
            }
        }
    }
}
