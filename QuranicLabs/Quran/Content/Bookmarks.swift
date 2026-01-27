import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct Quran_Content_Bookmarks: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BookmarkManager.shared
    @ObservedObject private var router = Router.shared

    // Presentation state
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showAddChapter = false
    @State private var showAddVerse = false
    @State private var showCategorySheet = false
    @State private var showNoteAlert = false
    @State private var showImporter = false
    @State private var importError: Error?

    // Inputs
    @State private var noteInput = ""
    @State private var categoryInput = ""

    // Selection
    @State private var activeBookmark: Bookmark?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bookmarks")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
                .sheet(isPresented: $showAddChapter) { addChapterSheet }
                .sheet(isPresented: $showAddVerse) { addVerseSheet }
                .sheet(isPresented: $showCategorySheet) { categorySheet }
                .fileImporter(
                    isPresented: $showImporter,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { handleImport($0) }
                .alert("Bookmark Note", isPresented: $showNoteAlert) { noteAlertContent }
                .confirmationDialog(
                    "Delete all bookmarks?",
                    isPresented: $showDeleteAllConfirmation,
                    titleVisibility: .visible
                ) { deleteAllDialogContent }
                .confirmationDialog(
                    "Delete this bookmark?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) { deleteDialogContent }
                .alert("Import Failed", isPresented: .init(
                    get: { importError != nil },
                    set: { if !$0 { importError = nil } }
                )) {
                    Button("OK") { importError = nil }
                } message: {
                    Text(importError?.localizedDescription ?? "Unknown error")
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if manager.isEmpty {
            emptyState
        } else {
            bookmarkList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Bookmarks")
                    .font(.title3.bold())

                Text("Tap any verse to bookmark it, or use the buttons below to add chapters and verses.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            HStack(spacing: 12) {
                Button {
                    showAddChapter = true
                } label: {
                    Label("Add Chapter", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    showAddVerse = true
                } label: {
                    Label("Add Verse", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline)

            Spacer()
        }
        .padding()
    }

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick add buttons
                HStack(spacing: 12) {
                    Button {
                        showAddChapter = true
                    } label: {
                        Label("Chapter", systemImage: "plus.circle.fill")
                    }

                    Button {
                        showAddVerse = true
                    } label: {
                        Label("Verse", systemImage: "plus.circle.fill")
                    }

                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal)

                // Bookmarks
                ForEach(manager.sortedBookmarks) { bookmark in
                    bookmarkCard(bookmark)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Bookmark Card

    private func bookmarkCard(_ bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Note badge
            if let notes = bookmark.notes, !notes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.caption2)
                    Text(notes)
                        .font(.caption)
                        .lineLimit(2)
                }
                .foregroundStyle(.accent)
                .fontWeight(.medium)
            }

            // Content - wrapped in button for custom navigation
            switch bookmark.type {
            case .chapter:
                if let chapterNumber = bookmark.chapterNumber,
                   let chapter = QuranChapters.fetch(chapterNumber: chapterNumber, context: modelContext) {
                    Quran_Element_ChapterCard(chapter: chapter)
                }
            case .verse:
                if let unified = QuranUnified.fetchVerse(
                    chapter: bookmark.chapterNumber ?? 1,
                    verse: bookmark.verseNumber ?? 1,
                    context: modelContext
                ) {
                    Quran_Element_VerseCard(
                        unified: unified,
                        options: .init(
                            linkToChapterContext: true
                        )
                    )
                }
            }

            // Footer
            bookmarkFooter(bookmark)
        }
    }

    private func navigateToBookmark(_ bookmark: Bookmark) {
        dismiss()
        router.selectTab(.quran)
        router.popToRoot(for: .quran)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch bookmark.type {
            case .verse:
                if let chapter = bookmark.chapterNumber, let verse = bookmark.verseNumber {
                    router.push(.chapter(chapterNumber: chapter, scrollToVerseNumber: verse))
                }
            case .chapter:
                if let chapter = bookmark.chapterNumber {
                    router.push(.chapter(chapterNumber: chapter))
                }
            }
        }
    }

    private func bookmarkFooter(_ bookmark: Bookmark) -> some View {
        HStack {
            // Date
            Text(bookmark.createdAt.relativeFormatted())
                .foregroundStyle(.secondary)

            // Category badge
            if let category = bookmark.category {
                Text(category)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .foregroundStyle(.accent)
            }

            Spacer()

            // Actions
            HStack(spacing: 16) {
                Button {
                    activeBookmark = bookmark
                    categoryInput = bookmark.category ?? ""
                    showCategorySheet = true
                } label: {
                    Image(systemName: bookmark.category == nil ? "tag" : "tag.fill")
                }

                Button {
                    activeBookmark = bookmark
                    noteInput = bookmark.notes ?? ""
                    showNoteAlert = true
                } label: {
                    Image(systemName: bookmark.notes == nil ? "note.text" : "note.text.badge.plus")
                }

                Button {
                    activeBookmark = bookmark
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .font(.caption)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Category filter
            if !manager.uniqueCategories.isEmpty {
                Menu {
                    Button {
                        manager.selectedCategory = nil
                    } label: {
                        HStack {
                            Text("All")
                            if manager.selectedCategory == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach(manager.uniqueCategories, id: \.self) { category in
                        Button {
                            manager.selectedCategory = category
                        } label: {
                            HStack {
                                Text(category)
                                if manager.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: manager.selectedCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(manager.selectedCategory == nil ? Color.primary : Color.accentColor)
                }
            }

            // More options
            Menu {
                Button {
                    showImporter = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                if !manager.isEmpty {
                    Button {
                        manager.shareExport()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Add Chapter Sheet

    private var addChapterSheet: some View {
        NavigationStack {
            List {
                ForEach(1...114, id: \.self) { chapter in
                    let isBookmarked = manager.isChapterBookmarked(chapter)
                    Button {
                        if !isBookmarked {
                            manager.addChapter(chapter)
                        }
                        showAddChapter = false
                    } label: {
                        HStack {
                            Text("Chapter \(chapter)")
                                .foregroundStyle(.primary)

                            if let chapterData = QuranChapters.fetch(chapterNumber: chapter, context: modelContext) {
                                Text(chapterData.title_english)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isBookmarked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            } else {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddChapter = false }
                }
            }
        }
    }

    // MARK: - Add Verse Sheet

    private var addVerseSheet: some View {
        AddVerseSheet(
            modelContext: modelContext,
            onAdd: { verseId in
                manager.addVerse(verseId)
                showAddVerse = false
            },
            onCancel: { showAddVerse = false }
        )
    }

    // MARK: - Category Sheet

    private var categorySheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let current = activeBookmark?.category, !current.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.secondary)
                        Text("Current:")
                            .foregroundStyle(.secondary)
                        Text(current)
                            .fontWeight(.semibold)
                    }
                }

                TextField("Category name", text: $categoryInput)
                    .textFieldStyle(.roundedBorder)

                if !manager.uniqueCategories.isEmpty {
                    Text("Suggestions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(manager.uniqueCategories, id: \.self) { suggestion in
                                Button {
                                    categoryInput = suggestion
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                        Spacer()
                                        if categoryInput == suggestion {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.accent)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                if activeBookmark?.category != nil {
                    Button(role: .destructive) {
                        if let bookmark = activeBookmark {
                            manager.updateCategory(bookmark, category: nil)
                            showCategorySheet = false
                        }
                    } label: {
                        Label("Remove Category", systemImage: "trash")
                    }
                }
            }
            .padding()
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCategorySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let bookmark = activeBookmark {
                            manager.updateCategory(bookmark, category: categoryInput)
                            showCategorySheet = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Alerts & Dialogs

    @ViewBuilder
    private var noteAlertContent: some View {
        TextField("Note", text: $noteInput)
        Button("Save") {
            if let bookmark = activeBookmark {
                manager.updateNotes(bookmark, notes: noteInput)
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    @ViewBuilder
    private var deleteAllDialogContent: some View {
        Button("Delete All", role: .destructive) {
            manager.deleteAll()
        }
        Button("Cancel", role: .cancel) {}
    }

    @ViewBuilder
    private var deleteDialogContent: some View {
        Button("Delete", role: .destructive) {
            if let bookmark = activeBookmark {
                manager.remove(bookmark)
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Import Handler

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "FileAccess", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Unable to access file"
                    ])
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: url)
                try manager.importBookmarks(from: data, merge: true)
            } catch {
                importError = error
            }
        case .failure(let error):
            importError = error
        }
    }
}

// MARK: - Add Verse Sheet

private struct AddVerseSheet: View {
    let modelContext: ModelContext
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    @State private var searchText = ""
    @State private var results: [QuranUnified] = []
    @State private var debounceTask: Task<Void, Never>?
    @ObservedObject private var manager = BookmarkManager.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(results, id: \.index.verse_id) { verse in
                    let isBookmarked = manager.isBookmarked(verse.index.verse_id)
                    Button {
                        if !isBookmarked {
                            onAdd(verse.index.verse_id)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            if isBookmarked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            } else {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(verse.index.verse_id)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(verse.text.english)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search verse...")
            .onChange(of: searchText) { _, newValue in
                debounceTask?.cancel()
                debounceTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await search(newValue)
                }
            }
            .onAppear {
                // Load first chapter by default
                Task { await loadInitial() }
            }
            .navigationTitle("Add Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }

    @MainActor
    private func loadInitial() async {
        results = QuranUnified.fetchChapter(1, context: modelContext)
    }

    @MainActor
    private func search(_ query: String) async {
        if query.isEmpty {
            await loadInitial()
            return
        }

        // Search by verse ID first, then by content
        let byId = QuranUnified.searchVerseIds(query: query, context: modelContext)
        if !byId.isEmpty {
            results = Array(byId.prefix(50))
        } else {
            results = Array(QuranUnified.search(query: query, context: modelContext).prefix(50))
        }
    }
}

// MARK: - Date Extension

private extension Date {
    func relativeFormatted() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 {
            return "Just now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    Quran_Content_Bookmarks()
}
