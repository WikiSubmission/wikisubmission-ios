import SwiftUI
import SheetKit

struct QuranBookmarks: View {
    @EnvironmentObject private var environment: AppEnvironment

    @State private var presentNoteInput = false
    @State private var noteInput = ""

    @State private var presentCategoryInput = false
    @State private var categoryInput = ""

    @State private var activeBookmark: Types.Supabase.Bookmarks?
    @State private var bookmarkToRemove: Types.Supabase.Bookmarks?

    @State private var showDeleteBookmarkConfirmation = false
    @State private var showDeleteAllBookmarksConfirmation = false

    @State private var selectedCategory: String? = nil
    @FocusState private var isCategoryFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                if environment.BookmarkManager.bookmarks.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 16) {
                        topToolbar
                        bookmarkList
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { mainToolbar }
            .task { await environment.BookmarkManager.refresh() }
            .alert("Bookmark Note", isPresented: $presentNoteInput) { noteAlertButtons } message: { Text("Add or edit your note") }
            .sheet(isPresented: $presentCategoryInput) { categorySheet }
            .confirmationDialog("Are you sure you want to remove this bookmark?", isPresented: $showDeleteBookmarkConfirmation, titleVisibility: .visible) { deleteBookmarkDialog }
            .confirmationDialog("Are you sure you want to remove all bookmarks?", isPresented: $showDeleteAllBookmarksConfirmation, titleVisibility: .visible) { deleteAllBookmarksDialog }
        }
    }

    // MARK: - Components

    private var emptyState: some View {
        Text("You have no bookmarks yet. Click on any chapter or verse to add them here.")
            .padding()
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var filteredBookmarks: [Types.Supabase.Bookmarks] {
        let filtered: [Types.Supabase.Bookmarks]
        if let category = selectedCategory {
            filtered = environment.BookmarkManager.bookmarks.filter { $0.category == category }
        } else {
            filtered = environment.BookmarkManager.bookmarks
        }
        
        // Sort by most recent first (descending)
        return filtered.sorted { $0.created_at > $1.created_at }
    }

    private var topToolbar: some View {
        BookmarkSyncStatusView()
            .pushToRight()
    }

    private var bookmarkList: some View {
        ForEach(filteredBookmarks, id: \.id) { bookmark in
            VStack(alignment: .leading, spacing: 4) {
                bookmarkHeader(bookmark)
                bookmarkContent(bookmark)
                bookmarkActions(bookmark)
            }
            .padding(.bottom, 8)
        }
    }

    private func bookmarkHeader(_ bookmark: Types.Supabase.Bookmarks) -> some View {
        HStack {
            if let note = bookmark.note, !note.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(.secondary)
                    Text(note)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 2)
                }
            }

            if let category = bookmark.category, !category.isEmpty {
                Spacer()
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "circle.grid.2x2.topleft.checkmark.filled")
                    Text(category)
                        .padding(.bottom, 2)
                        .fontDesign(.serif)
                }
                .foregroundStyle(.orange)
            }
        }
    }

    private func bookmarkContent(_ bookmark: Types.Supabase.Bookmarks) -> some View {
        Group {
            if let chapter = bookmark.chapter_number {
                QuranChapterCard(chapter: chapter, removeBookmarkedIcon: true)
            } else if let verseID = bookmark.verse_id {
                QuranVerseCard(id: verseID, linkToChapter: true, removeBookmarkedIcon: true)
            }
        }
    }

    private func bookmarkActions(_ bookmark: Types.Supabase.Bookmarks) -> some View {
        HStack {
            Text("\(bookmark.created_at.formattedRelative())")
            Spacer()
            
            // Add/Edit Category
            Button {
                activeBookmark = bookmark
                categoryInput = bookmark.category ?? ""
                presentCategoryInput = true
            } label: {
                Text(bookmark.category?.isEmpty == false ? "Edit category" : "Add category")
                    .foregroundStyle(.accent)
            }
            
            // Note
            Button {
                activeBookmark = bookmark
                noteInput = bookmark.note ?? ""
                presentNoteInput = true
            } label: {
                Text(bookmark.note?.isEmpty == false ? "Edit note" : "Add note")
                    .foregroundStyle(.accent)
            }
            
            // Delete bookmark
            Button {
                bookmarkToRemove = bookmark
                showDeleteBookmarkConfirmation = true
            } label: {
                Text("Delete")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
        .fontWeight(.light)
        .foregroundStyle(.secondary)
        .padding(.top, 2)
    }

    private var mainToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 0) {
                filterMenu
                Menu {
                    Button {
                        showDeleteAllBookmarksConfirmation = true
                    } label: {
                        Label("Delete all bookmarks", systemImage: "delete.left")
                    }
                    .foregroundStyle(.red)

                    QuranMenu()
                } label: {
                    Label("", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    private var filterMenu: some View {
        VStack {
            if !environment.BookmarkManager.uniqueCategories.isEmpty {
                Menu {
                    Button {
                        withAnimation { selectedCategory = nil }
                    } label: {
                        HStack {
                            Text("All Categories")
                            if selectedCategory == nil { Spacer(); Image(systemName: "checkmark") }
                        }
                    }

                    ForEach(environment.BookmarkManager.uniqueCategories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack {
                                Text(category)
                                if selectedCategory == category { Spacer(); Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    Label("Filter: \(selectedCategory ?? "All Categories")", systemImage: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var noteAlertButtons: some View {
        Group {
            TextField("Note", text: $noteInput)
            Button("Save") {
                if let bookmark = activeBookmark {
                    Task { await environment.BookmarkManager.addNote(bookmarkID: bookmark.id, note: noteInput) }
                }
            }
            .disabled(noteInput.isEmpty && (activeBookmark?.note?.isEmpty ?? true))
            Button("Cancel", role: .cancel) {}
        }
    }

    private var categorySheet: some View {
        NavigationStack {
            VStack {
                TextField("Create a new category", text: $categoryInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .padding(.leading, 8)
                    .padding(.vertical, 4)
                    .fontWeight(.light)
                    .focused($isCategoryFieldFocused)
                    .padding()
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            isCategoryFieldFocused = true
                        }
                    }

                if !environment.BookmarkManager.uniqueCategories.isEmpty {
                    List {
                        Section("Existing") {
                            ForEach(environment.BookmarkManager.uniqueCategories, id: \.self) { category in
                                Button {
                                    categoryInput = category
                                } label: {
                                    HStack {
                                        Text(category)
                                        Spacer()
                                        if categoryInput == category {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Save / Cancel / Remove buttons
                HStack {
                    Button("Cancel", role: .cancel) { presentCategoryInput = false }
                    Spacer()
                    if let bookmark = activeBookmark, let category = bookmark.category, !category.isEmpty {
                        Button("Remove") {
                            Task {
                                await environment.BookmarkManager.removeCategory(bookmarkID: bookmark.id)
                                presentCategoryInput = false
                            }
                        }
                        .foregroundStyle(.red)
                    }
                    Button("Save") {
                        if let bookmark = activeBookmark {
                            Task { await environment.BookmarkManager.addCategory(bookmarkID: bookmark.id, category: categoryInput) }
                        }
                        presentCategoryInput = false
                    }
                    .disabled(categoryInput.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
        }
    }

    private var deleteBookmarkDialog: some View {
        Group {
            Button("Delete", role: .destructive) {
                if let bookmark = bookmarkToRemove {
                    Task { await environment.BookmarkManager.remove(bookmarkID: bookmark.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var deleteAllBookmarksDialog: some View {
        Group {
            Button("Delete All", role: .destructive) {
                Task { await environment.BookmarkManager.clearAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct BookmarkSyncStatusView: View {
    @ObservedObject private var bookmarks = Utilities.Quran.BookmarkManager.shared
    @ObservedObject var networkMonitor = Utilities.System.NetworkMonitor.shared
    
    @State private var presentSignInFlow = false

    @Environment(\.clerk) var clerk
    
    var body: some View {
        HStack(spacing: 4) {
            switch bookmarks.syncStatus {
            case .synced:
                if bookmarks.isOnline {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Synced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.accent)
                    Text("Local bookmarks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .syncing:
                ProgressView()
                    .scaleEffect(0.7)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            case .pendingOffline:
                if !networkMonitor.hasInternet {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.accent)
                    Text("Offline")
                        .font(.caption)
                        .foregroundColor(.accent)
                }
            
            case .pendingSignIn:
                Button {
                    presentSignInFlow = true
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.accent)
                    Text("Sign In to sync")
                        .font(.caption)
                        .foregroundColor(.accent)
                }
                
            case .failed:
                Button("Retry Sync") {
                    Task {
                        await bookmarks.forceSyncWithServer()
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $presentSignInFlow) {
            SignInFlow()
        }
    }
}

#Preview {
    QuranBookmarks()
        .environmentObject(AppEnvironment.shared)
}
