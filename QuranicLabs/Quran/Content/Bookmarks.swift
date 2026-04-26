import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private struct BookmarkDestination: Identifiable {
    let chapterNumber: Int
    let verseNumber: Int?

    var id: String {
        if let verseNumber {
            return "\(chapterNumber):\(verseNumber)"
        }
        return "\(chapterNumber)"
    }
}

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
    @State private var showNoteSheet = false
    @State private var showImporter = false
    @State private var importError: Error?

    // Inputs
    @State private var noteInput = ""
    @State private var categoryInput = ""

    // Category rename
    @State private var showRenameCategorySheet = false
    @State private var renameCategoryOldName = ""
    @State private var renameCategoryNewName = ""

    // Selection
    @State private var activeBookmark: Bookmark?
    @State private var presentedBookmarkDestination: BookmarkDestination?

    // Multi-select
    @State private var isSelecting = false
    @State private var selectedKeys: Set<String> = []

    // Sort
    @State private var sortOrder: SortOrder = .newest

    // Search
    @State private var searchText = ""

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case chapter = "Chapter"
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bookmarks")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
                .sheet(isPresented: $showAddChapter) { addChapterSheet }
                .sheet(isPresented: $showAddVerse) { addVerseSheet }
                .sheet(isPresented: $showCategorySheet) { categorySheet }
                .sheet(isPresented: $showNoteSheet) { noteSheet }
                .sheet(isPresented: $showRenameCategorySheet) { renameCategorySheet }
                .sheet(item: $presentedBookmarkDestination) { destination in
                    NavigationStack {
                        Quran_Content_ChapterReader(
                            chapterNumber: destination.chapterNumber,
                            options: .init(scrollToVerseNumber: destination.verseNumber)
                        )
                    }
                }
                .fileImporter(
                    isPresented: $showImporter,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { handleImport($0) }
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

    // MARK: - Sorted & Filtered Bookmarks

    private var displayedBookmarks: [Bookmark] {
        var list = manager.filteredBookmarks

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            list = list.filter { bookmark in
                bookmark.key.contains(query)
                || (bookmark.notes?.lowercased().contains(query) ?? false)
                || (bookmark.category?.lowercased().contains(query) ?? false)
                || chapterTitle(for: bookmark)?.lowercased().contains(query) ?? false
            }
        }

        // Sort
        switch sortOrder {
        case .newest:
            list.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            list.sort { $0.createdAt < $1.createdAt }
        case .chapter:
            list.sort { ($0.chapterNumber ?? 0) < ($1.chapterNumber ?? 0) }
        }

        return list
    }

    private func chapterTitle(for bookmark: Bookmark) -> String? {
        guard let chapterNumber = bookmark.chapterNumber,
              let chapter = QuranChapters.fetch(chapterNumber: chapterNumber, context: modelContext) else { return nil }
        return chapter.title_english
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
                    .font(DS.Typography.titleLG)

                Text("Tap any verse to bookmark it, or use the buttons below to add chapters and verses.")
                    .font(DS.Typography.bodySM)
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
            .font(DS.Typography.bodySM)

            Spacer()
        }
        .padding()
    }

    // MARK: - Bookmark List

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Stats bar
                statsBar

                // Category chips
                if !manager.uniqueCategories.isEmpty {
                    categoryChips
                }

                // Selection toolbar
                if isSelecting {
                    selectionToolbar
                }

                // Bookmarks
                let bookmarks = displayedBookmarks
                ForEach(Array(bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                    bookmarkRow(bookmark, index: bookmarks.count - index)
                }
            }
            .padding(.bottom, 200)
        }
        .searchable(text: $searchText, prompt: "Search bookmarks...")
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: DS.Spacing.lg) {

            Spacer()

            // Sort
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        withAnimation { sortOrder = order }
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOrder.rawValue)
                }
            }
        }
        .font(DS.Typography.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        HStack(spacing: DS.Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.sm) {
                    categoryChip(label: "All", count: manager.bookmarks.count, isSelected: manager.selectedCategory == nil) {
                        withAnimation { manager.selectedCategory = nil }
                    }

                    ForEach(manager.uniqueCategories, id: \.self) { category in
                        let count = manager.bookmarks.filter { $0.category == category }.count
                        categoryChip(
                            label: category,
                            count: count,
                            isSelected: manager.selectedCategory == category
                        ) {
                            withAnimation {
                                manager.selectedCategory = manager.selectedCategory == category ? nil : category
                            }
                        }
                    }
                }
                .padding(.leading)
            }

            if !manager.uniqueCategories.isEmpty {
                Menu {
                    ForEach(manager.uniqueCategories, id: \.self) { category in
                        Menu(category) {
                            Button {
                                renameCategoryOldName = category
                                renameCategoryNewName = category
                                showRenameCategorySheet = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                manager.deleteCategory(category)
                            } label: {
                                Label("Remove from All", systemImage: "trash")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing)
            }
        }
        .padding(.bottom, DS.Spacing.md)
    }

    private func categoryChip(label: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                Text("\(count)")
                    .foregroundStyle(isSelected ? AnyShapeStyle(.accent.opacity(0.7)) : AnyShapeStyle(.tertiary))
            }
            .font(DS.Typography.caption)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.secondary.opacity(0.06)
            )
            .foregroundStyle(isSelected ? .accent : .primary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Selection Toolbar

    private var selectionToolbar: some View {
        HStack(spacing: DS.Spacing.lg) {
            Button {
                if selectedKeys.count == displayedBookmarks.count {
                    selectedKeys.removeAll()
                } else {
                    selectedKeys = Set(displayedBookmarks.map(\.key))
                }
            } label: {
                let allSelected = selectedKeys.count == displayedBookmarks.count && !displayedBookmarks.isEmpty
                Label(
                    allSelected ? "Deselect All" : "Select All",
                    systemImage: allSelected ? "checkmark.circle.fill" : "circle"
                )
            }

            Spacer()

            if !selectedKeys.isEmpty {
                // Batch category
                Button {
                    categoryInput = ""
                    activeBookmark = nil
                    showCategorySheet = true
                } label: {
                    Label("Tag (\(selectedKeys.count))", systemImage: "tag")
                }

                // Batch delete
                Button(role: .destructive) {
                    for key in selectedKeys {
                        manager.removeByKey(key)
                    }
                    selectedKeys.removeAll()
                    if manager.isEmpty { isSelecting = false }
                } label: {
                    Label("Delete (\(selectedKeys.count))", systemImage: "trash")
                }
                .foregroundStyle(.red)
            }
        }
        .font(DS.Typography.caption)
        .padding(.horizontal)
        .padding(.vertical, DS.Spacing.sm)
        .background(Color.secondary.opacity(0.05))
    }

    // MARK: - Bookmark Row

    private func bookmarkRow(_ bookmark: Bookmark, index: Int) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: DS.Spacing.md) {
                // Selection checkbox
                if isSelecting {
                    Button {
                        if selectedKeys.contains(bookmark.key) {
                            selectedKeys.remove(bookmark.key)
                        } else {
                            selectedKeys.insert(bookmark.key)
                        }
                    } label: {
                        Image(systemName: selectedKeys.contains(bookmark.key) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedKeys.contains(bookmark.key) ? .accent : .secondary)
                            .font(.title3)
                    }
                    .padding(.top, 14)
                }

                // Main content
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    // Header line
                    HStack(alignment: .firstTextBaseline) {
                        Text("Bookmark #\(index) · \(bookmark.createdAt.relativeFormatted())")
                            .font(DS.Typography.eyebrowSM)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        if let category = bookmark.category {
                            Button {
                                activeBookmark = bookmark
                                categoryInput = category
                                showCategorySheet = true
                            } label: {
                                Text(category)
                                    .font(DS.Typography.eyebrowSM)
                                    .tracking(0.5)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                                    .foregroundStyle(.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Note
                    if let notes = bookmark.notes, !notes.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(.accent)
                                .padding(.top, 1)
                            Text(notes)
                                .font(DS.Typography.bodySM)
                                .foregroundStyle(.accent)
                        }
                    }

                    // Content preview
                    contentPreview(bookmark)

                    // Footer: actions
                    if !isSelecting {
                        bookmarkActions(bookmark)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, DS.Spacing.lg)
            .contentShape(Rectangle())
            .contextMenu { bookmarkContextMenu(bookmark) }

            Divider().padding(.leading)
        }
    }

    // MARK: - Content Preview

    @ViewBuilder
    private func contentPreview(_ bookmark: Bookmark) -> some View {
        Button {
            navigateToBookmark(bookmark)
        } label: {
            Group {
                switch bookmark.type {
                case .chapter:
                    if let chapterNumber = bookmark.chapterNumber,
                       let chapter = QuranChapters.fetch(chapterNumber: chapterNumber, context: modelContext) {
                        Quran_Element_ChapterCard(
                            chapter: chapter,
                            hideBookmarkStatus: true
                        )
                        .allowsHitTesting(false)
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
                                linkToChapterContext: true,
                                hideBookmarkStatus: true
                            )
                        )
                        .allowsHitTesting(false)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bookmark Actions

    private func bookmarkActions(_ bookmark: Bookmark) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Spacer()

            actionChip(bookmark.category == nil ? "Tag" : "Edit Tag", icon: "tag") {
                activeBookmark = bookmark
                categoryInput = bookmark.category ?? ""
                showCategorySheet = true
            }

            actionChip(bookmark.notes == nil ? "Note" : "Edit Note", icon: "note.text") {
                activeBookmark = bookmark
                noteInput = bookmark.notes ?? ""
                showNoteSheet = true
            }

            actionChip("Delete", icon: "trash", destructive: true) {
                activeBookmark = bookmark
                showDeleteConfirmation = true
            }
        }
    }

    private func actionChip(_ label: String, icon: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(DS.Typography.eyebrowSM)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(destructive ? Color.red.opacity(0.1) : Color.secondary.opacity(0.08))
            )
            .foregroundStyle(destructive ? .red : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func bookmarkContextMenu(_ bookmark: Bookmark) -> some View {
        Button {
            navigateToBookmark(bookmark)
        } label: {
            Label("Go to \(bookmark.type == .verse ? "Verse" : "Chapter")", systemImage: "arrow.right.circle")
        }

        Divider()

        Button {
            activeBookmark = bookmark
            categoryInput = bookmark.category ?? ""
            showCategorySheet = true
        } label: {
            Label(bookmark.category == nil ? "Add Category" : "Edit Category", systemImage: "tag")
        }

        Button {
            activeBookmark = bookmark
            noteInput = bookmark.notes ?? ""
            showNoteSheet = true
        } label: {
            Label(bookmark.notes == nil ? "Add Note" : "Edit Note", systemImage: "note.text")
        }

        Divider()

        Button(role: .destructive) {
            manager.remove(bookmark)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Navigation

    private func navigateToBookmark(_ bookmark: Bookmark) {
        switch bookmark.type {
        case .verse:
            if let chapter = bookmark.chapterNumber, let verse = bookmark.verseNumber {
                presentedBookmarkDestination = .init(chapterNumber: chapter, verseNumber: verse)
                QuranReadingHistoryStore.shared.log(
                    action: .bookmarked,
                    detail: "Opened bookmark \(bookmark.key)",
                    chapterNumber: chapter,
                    verseId: bookmark.key,
                    verseNumber: verse
                )
            }
        case .chapter:
            if let chapter = bookmark.chapterNumber {
                presentedBookmarkDestination = .init(chapterNumber: chapter, verseNumber: nil)
                QuranReadingHistoryStore.shared.log(
                    action: .bookmarked,
                    detail: "Opened bookmarked Sura \(chapter)",
                    chapterNumber: chapter
                )
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Select / Done
            if !manager.isEmpty {
                Button {
                    withAnimation {
                        isSelecting.toggle()
                        if !isSelecting { selectedKeys.removeAll() }
                    }
                } label: {
                    Image(systemName: isSelecting ? "checkmark.circle" : "checklist")
                }
            }

            // More options
            Menu {
                Section {
                    Button {
                        showAddChapter = true
                    } label: {
                        Label("Add Chapter", systemImage: "book.closed")
                    }

                    Button {
                        showAddVerse = true
                    } label: {
                        Label("Add Verse", systemImage: "text.quote")
                    }
                }

                Section {
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
                    }
                }

                if !manager.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAllConfirmation = true
                        } label: {
                            Label("Delete All", systemImage: "trash")
                        }
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
        let isBatch = isSelecting && !selectedKeys.isEmpty && activeBookmark == nil

        return NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                if isBatch {
                    Label("\(selectedKeys.count) bookmarks selected", systemImage: "checkmark.circle.fill")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.accent)
                } else if let current = activeBookmark?.category, !current.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.secondary)
                        Text("Current:")
                            .foregroundStyle(.secondary)
                        Text(current)
                            .fontWeight(.semibold)
                    }
                    .font(DS.Typography.bodySM)
                }

                TextField("Category name", text: $categoryInput)
                    .textFieldStyle(.roundedBorder)

                if !manager.uniqueCategories.isEmpty {
                    Text("EXISTING TAGS")
                        .font(DS.Typography.eyebrowSM)
                        .tracking(1.5)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(manager.uniqueCategories, id: \.self) { suggestion in
                                let isSelected = categoryInput == suggestion
                                Button {
                                    categoryInput = isSelected ? "" : suggestion
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .font(DS.Typography.bodySM)
                                            .foregroundStyle(isSelected ? .white : .primary)
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(.horizontal, DS.Spacing.md)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.08))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                if !isBatch, activeBookmark?.category != nil {
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
            .navigationTitle(isBatch ? "Tag Selected" : "Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCategorySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isBatch {
                            for key in selectedKeys {
                                if let bookmark = manager.bookmarks.first(where: { $0.key == key }) {
                                    manager.updateCategory(bookmark, category: categoryInput)
                                }
                            }
                        } else if let bookmark = activeBookmark {
                            manager.updateCategory(bookmark, category: categoryInput)
                        }
                        showCategorySheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Note Sheet

    private var noteSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                if let bookmark = activeBookmark {
                    HStack(spacing: 6) {
                        Text(bookmark.type == .verse ? "VERSE" : "CHAPTER")
                            .font(DS.Typography.eyebrowSM)
                            .tracking(1)
                            .foregroundStyle(.secondary)
                        Text(bookmark.key)
                            .font(DS.Typography.label)
                    }
                }

                TextEditor(text: $noteInput)
                    .font(DS.Typography.body)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(DS.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.secondary.opacity(0.08))
                    )

                if activeBookmark?.notes != nil {
                    Button(role: .destructive) {
                        if let bookmark = activeBookmark {
                            manager.updateNotes(bookmark, notes: nil)
                            showNoteSheet = false
                        }
                    } label: {
                        Label("Remove Note", systemImage: "trash")
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNoteSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let bookmark = activeBookmark {
                            manager.updateNotes(bookmark, notes: noteInput)
                        }
                        showNoteSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Rename Category Sheet

    private var renameCategorySheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                Label("Renaming \"\(renameCategoryOldName)\"", systemImage: "tag.fill")
                    .font(DS.Typography.bodySM)
                    .foregroundStyle(.accent)

                Text("This will update all bookmarks with this category.")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)

                TextField("New category name", text: $renameCategoryNewName)
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
            .navigationTitle("Rename Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRenameCategorySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rename") {
                        manager.renameCategory(renameCategoryOldName, to: renameCategoryNewName)
                        showRenameCategorySheet = false
                    }
                    .disabled(renameCategoryNewName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Dialogs

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
                                    .font(DS.Typography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                Text(verse.text.english)
                                    .font(DS.Typography.bodySM)
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
