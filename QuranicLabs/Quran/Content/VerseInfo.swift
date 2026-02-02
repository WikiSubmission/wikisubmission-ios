import SwiftUI
import SwiftData
import AlertKit

struct Quran_Content_VerseInfo: View {
    @Environment(\.modelContext) private var modelContext
    
    var data: QuranUnified
    
    @State private var versesWithSameRoot: [QuranWordByWordSD]? = nil
    @State private var presentBookmarkSheet = false
    @ObservedObject private var bookmarkManager = BookmarkManager.shared
    
    init(data: QuranUnified) {
        self.data = data
    }
    
    init(verseId: String, context: ModelContext) {
        if let unified = QuranUnified.fetchVerse(byId: verseId, context: context) {
            self.data = unified
        } else {
            self.data = QuranUnified.fetchVerse(byId: "1:1", context: context)!
        }
    }
    
    var isBookmarked: Bool {
        return bookmarkManager.isVerseBookmarked(chapter: data.index.chapter_number, verse: data.index.verse_number)
    }
    
    var body: some View {
        List {
            Section {
                Quran_Element_VerseCard(
                    unified: data,
                    options: .init(
                        unformatted: true,
                        linkToChapterContext: true,
                        disableInteractiveElements: true
                    )
                )
            }
            .id(UUID())
            .removeParentListStyle()
            
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button {
                            withAnimation {
                                if isBookmarked {
                                    bookmarkManager.removeByKey(data.index.verse_id)
                                } else {
                                    bookmarkManager.addVerse(data.index.verse_id)
                                    presentBookmarkSheet = true
                                }
                            }
                        } label: {
                            Label(isBookmarked ? "Remove bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
                                .foregroundStyle(isBookmarked ? .red : .orange)
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
                                .foregroundStyle(.brown)
                        }
                        Button {
                            shareText(data.formatToText())
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .removeParentListStyle()
            }
            .buttonStyle(SignatureButtonStyle())
            .font(.caption)
            .sheet(isPresented: $presentBookmarkSheet, content: {
                Quran_Content_Bookmarks()
            })

            
            Section(header: HStack {
                Text("\(data.wordByWord.count) words")
                Spacer()
                Text("")
            }) {
                Quran_Element_WordByWordInfo(verse: data)
            }
            
            Section("CHAPTER \(data.chapter.chapter_number)") {
                Quran_Element_ChapterInfo(verse: data)
            }
        }
        .navigationTitle(data.index.verse_id)
        .navigationBarTitleDisplayMode(.inline)
        .textSelection(.enabled)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 0) {
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
                    
                    Button {
                        shareText(data.formatToText())
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Quran_Element_QuickSettings()
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for:
            QuranFootnotesSD.self,
            QuranIndexSD.self,
            QuranSubtitlesSD.self,
            QuranTextSD.self,
            QuranWordByWordSD.self,
        configurations: ModelConfiguration()
    )
    
    let context = container.mainContext
    
    let verse = QuranUnified.fetchVerse(byId: "2:20", context: context)
        ?? QuranUnified.fetchVerse(byId: "1:1", context: context)!
    
     NavigationStack {
        Quran_Content_VerseInfo(data: verse)
    }
    .modelContainer(container)
}

