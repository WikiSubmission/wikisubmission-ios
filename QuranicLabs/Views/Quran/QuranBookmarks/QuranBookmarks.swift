import Defaults
import SwiftUI

struct QuranBookmarks: View {
    // Defaults
    @Default(.bookmarks) private var bookmarks
    @Default(.primary_language) private var primaryLanguage

    // Presentation State
    @State private var presentDeleteAllBookmarksDialog = false
    @State private var presentDeleteBookmarkDialog = false
    @State private var presentAddNote = false
    @State private var presentAddCategory = false
    @State private var presentSignInFlow = false
    @State private var presentAddChapter = false
    @State private var presentAddVerse = false

    // Inputs
    @State private var noteInput = ""
    @State private var categoryInput = ""

    // Verse search
    @State private var verseSearchInput = ""
    @State private var verseSearchResults: [Types.Quran.Data] = []
    @State private var verseDebounceTask: DispatchWorkItem? = nil

    // Selection
    @State private var activeBookmark: Types.Bookmarks.Bookmark?
    @State private var selectedCategory: String? = nil

    // Helpers
    private static let iso8601 = ISO8601DateFormatter()

    private var filteredBookmarks: [Types.Bookmarks.Bookmark] {
        guard let selectedCategory else { return bookmarks }
        return bookmarks.filter { ($0.category ?? "") == selectedCategory }
    }

    private var sortedFilteredBookmarks: [Types.Bookmarks.Bookmark] {
        filteredBookmarks.sorted { lhs, rhs in
            guard
                let l = Self.iso8601.date(from: lhs.created_at),
                let r = Self.iso8601.date(from: rhs.created_at)
            else { return false }
            return l > r
        }
    }

    var uniqueCategories: [String] {
        let categories = bookmarks.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
        return Array(Set(categories)).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                topBarView
                if bookmarks.isEmpty {
                    emptyStateView
                } else {
                    bookmarksListView
                }
            }
            .padding()
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .presentationDragIndicator(.visible)
            .toolbar { bookmarksToolbar }
            // Sheets
            .sheet(isPresented: $presentAddChapter) { addChapterSheet }
            .sheet(isPresented: $presentAddVerse) { addVerseSheet }

            // Bulk delete dialog
            .confirmationDialog(
                "Are you sure you want to delete all bookmarks?",
                isPresented: $presentDeleteAllBookmarksDialog,
                titleVisibility: .visible
            ) {
                Group {
                    Button("Delete All", role: .destructive) {
                        Task { try? await Utilities.Bookmarks.deleteAll() }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            // Single delete dialog
            .confirmationDialog(
                "Are you sure you want to delete this bookmark?",
                isPresented: $presentDeleteBookmarkDialog,
                titleVisibility: .visible
            ) {
                Group {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let activeBookmark = activeBookmark {
                                try? await Utilities.Bookmarks.removeBookmark(activeBookmark)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            // Note alert
            .alert("Bookmark Note", isPresented: $presentAddNote) {
                Group {
                    TextField("Note", text: $noteInput)
                    Button("Save") {
                        Task {
                            if let bookmark = activeBookmark {
                                let updatedBookmark = Types.Bookmarks.Bookmark(
                                    created_at: bookmark.created_at,
                                    updated_at: Date().ISO8601Format(),
                                    type: bookmark.type,
                                    key: bookmark.key,
                                    category: bookmark.category,
                                    notes: noteInput,
                                )
                                let _ = try? await Utilities.Bookmarks.editBookmark(bookmark, newBookmark: updatedBookmark)
                            }
                        }
                    }
                    .disabled(noteInput.isEmpty && (activeBookmark?.notes?.isEmpty ?? true))
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text(activeBookmark?.notes == nil ? "Add a note" : "Edit note")
            }

            // Category sheet (kept inline, but more compact)
            .sheet(isPresented: $presentAddCategory) { categorySheet }
        }
    }
    
    @ViewBuilder private var topBarView: some View {
        HStack {
            addChapterButton
            addVerseButton
            Spacer()
        }
        .font(.caption2)
    }

    @ViewBuilder private var emptyStateView: some View {
        ScrollView {
            VStack {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.primary)
                    Text("You have no bookmarks yet.\n\nClick on any chapter or verse to add them here.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task {
                            if let randomVerse = AppData.Quran.main.randomElement() {
                                try? await Utilities.Bookmarks.addBookmark(.init(
                                    created_at: Date().ISO8601Format(),
                                    updated_at: nil,
                                    type: .verse,
                                    key: randomVerse.verse_id,
                                    category: "Random",
                                    notes: nil,
                                ))
                            }
                        }
                    } label: {
                        Text("Add a random verse...")
                    }
                }
                .font(.caption)
            }
        }
    }

    private var bookmarksListView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(sortedFilteredBookmarks, id: \.self) { i in
                    bookmarkItem(for: i)
                }
            }
        }
    }

    @ToolbarContentBuilder private var bookmarksToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            HStack(spacing: 0) {
                if !uniqueCategories.isEmpty {
                    Menu {
                        Button {
                            withAnimation { selectedCategory = nil }
                        } label: {
                            HStack {
                                Text("All Categories")
                                if selectedCategory == nil {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        ForEach(uniqueCategories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text(category)
                                    if selectedCategory == category {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Filter: \(selectedCategory ?? "All Categories")", systemImage: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedCategory == nil ? .accent : .orange)
                    }
                }
                
                Menu {
                    Button {
                        presentDeleteAllBookmarksDialog = true
                    } label: {
                        Label("Delete all bookmarks", systemImage: "x.circle.fill")
                    }
                    .foregroundStyle(.red)
                    
                    QuranMenu()
                } label: {
                    Label("", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                }
                
            }
        }
    }

    @ViewBuilder private func bookmarkItem(for i: Types.Bookmarks.Bookmark) -> some View {
        VStack(spacing: 8) {
            if i.notes != nil {
                HStack(spacing: 3) {
                    Image(systemName: "quote.bubble.fill")
                    Text("\(i.notes ?? "")")
                    Spacer()
                }
                .foregroundStyle(.accent)
                .fontWeight(.semibold)
            }

            if i.type == .verse {
                QuranVerseCard(id: i.key, linkToChapter: true, removeBookmarkedIcon: true)
            }

            if i.type == .chapter {
                if let chapterNumber = Int(i.key) {
                    QuranChapterCard(chapter: chapterNumber)
                }
            }

            HStack {
                Text(i.created_at.formattedRelativeDate())
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    activeBookmark = i
                    presentAddCategory = true
                    categoryInput = i.category ?? ""
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: i.category == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        Text("Category")
                    }
                }

                Button {
                    activeBookmark = i
                    presentAddNote = true
                    noteInput = i.notes ?? ""
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: i.notes == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        Text("Note")
                    }
                }

                Button {
                    activeBookmark = i
                    presentDeleteBookmarkDialog = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "x.circle.fill")
                        Text("Delete")
                    }
                    .foregroundStyle(.red)
                }
            }
            .font(.caption2)
            .padding(.horizontal)
        }
    }

    private var addChapterButton: some View {
        Button { presentAddChapter = true } label: {
            HStack(spacing: 3) {
                Image(systemName: "plus.circle.fill")
                Text("Add chapter...")
            }
        }
    }

    private var addVerseButton: some View {
        Button { presentAddVerse = true } label: {
            HStack(spacing: 3) {
                Image(systemName: "plus.circle.fill")
                Text("Add verse...")
            }
        }
    }

    private var addChapterSheet: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(AppData.Quran.chapters.sorted { $0.chapter_number < $1.chapter_number }, id: \.self) { i in
                        Button {
                            Task {
                                try? await Utilities.Bookmarks.addBookmark(.init(
                                    created_at: Date().ISO8601Format(),
                                    updated_at: nil,
                                    type: .chapter,
                                    key: String(i.chapter_number),
                                    category: nil,
                                    notes: nil,
                                ))
                                presentAddChapter = false
                            }
                        } label: {
                            HStack {
                                HStack {
                                    Text("Sura \(i.chapter_number)")
                                        .foregroundStyle(.primary)
                                    Text("\(i.getChapterTitle(for: primaryLanguage))")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add a chapter")
        }
    }

    private var addVerseSheet: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(verseSearchResults, id: \.self) { i in
                        Button {
                            Task {
                                try? await Utilities.Bookmarks.addBookmark(.init(
                                    created_at: Date().ISO8601Format(),
                                    updated_at: nil,
                                    type: .verse,
                                    key: String(i.verse_id),
                                    category: nil,
                                    notes: nil,
                                ))
                                presentAddVerse = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                QuranVerseCard(id: i.verse_id, linkToChapter: false, removeLinkToDetails: true, removeFormatting: true, removeBookmarkedIcon: true)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $verseSearchInput, prompt: "Search verse...")
            .onChange(of: verseSearchInput) { _, newValue in
                verseDebounceTask?.cancel()
                let task = DispatchWorkItem {
                    let filtered = AppData.Quran.main.filter { $0.verse_id.localizedCaseInsensitiveContains(newValue) }
                    DispatchQueue.main.async {
                        self.verseSearchResults = Array(filtered.prefix(100))
                    }
                }
                verseDebounceTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: task)
            }
            .onAppear {
                verseSearchResults = AppData.Quran.main.filter { $0.chapter_number == 1 }
            }
            .navigationTitle("Add a verse")
        }
    }

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
                        Spacer()
                    }
                }

                TextField("New or existing category", text: $categoryInput)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.roundedBorder)

                if !Array(Set(bookmarks.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).isEmpty {
                    Text("Suggestions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(Set(bookmarks.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted(), id: \.self) { suggestion in
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

                if (activeBookmark?.category != nil) && !(activeBookmark?.category ?? "").isEmpty {
                    Button(role: .destructive) {
                        Task {
                            if let bookmark = activeBookmark {
                                let updatedBookmark = Types.Bookmarks.Bookmark(
                                    created_at: bookmark.created_at,
                                    updated_at: Date().ISO8601Format(),
                                    type: bookmark.type,
                                    key: bookmark.key,
                                    category: nil,
                                    notes: bookmark.notes,
                                )
                                try? await Utilities.Bookmarks.editBookmark(bookmark, newBookmark: updatedBookmark)
                                presentAddCategory = false
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Remove Category")
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentAddCategory = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let bookmark = activeBookmark {
                                let trimmed = categoryInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                let newCategory = trimmed.isEmpty ? nil : trimmed
                                let updatedBookmark = Types.Bookmarks.Bookmark(
                                    created_at: bookmark.created_at,
                                    updated_at: Date().ISO8601Format(),
                                    type: bookmark.type,
                                    key: bookmark.key,
                                    category: newCategory,
                                    notes: bookmark.notes,
                                )
                                let _ = try? await Utilities.Bookmarks.editBookmark(bookmark, newBookmark: updatedBookmark)
                                presentAddCategory = false
                            }
                        }
                    }
                    .disabled(categoryInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (activeBookmark?.category?.isEmpty ?? true))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        QuranBookmarks()
    }
    .sheet(isPresented: .constant(true)) {
        QuranBookmarks()
    }
    .environmentObject(AppEnvironment.shared)
}
