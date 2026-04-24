import SwiftUI
import SwiftData
import AlertKit

struct Quran_Content_VerseInfo: View {
    @Environment(\.modelContext) private var modelContext
    
    var data: QuranUnified
    
    @State private var versesWithSameRoot: [QuranWordByWordSD]? = nil
    @State private var presentBookmarkSheet = false
    @State private var presentTextSelectorSheet = false
    @ObservedObject private var bookmarkManager = BookmarkManager.shared
    @ObservedObject private var audioManager = AudioManager.shared
    
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
                            HStack {
                                Image(systemName: isBookmarked ? "bookmark.slash" : "bookmark")
                                Text(isBookmarked ? "Remove bookmark" : "Bookmark")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle(tint: .orange))
                        
                        Button {
                            UIPasteboard.general.string = data.formatToText()
                            AlertKitAPI.present(
                                title: "\(data.index.verse_id) Copied",
                                icon: .done,
                                style: .iOS17AppleMusic,
                                haptic: .success
                            )
                        } label: {
                            HStack {
                                Image(systemName: "document.on.document")
                                Text("Copy")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle(tint: .cyan))
                        
                        Button {
                            shareText(data.formatToText())
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle(tint: .accent))
                        
                        Button {
                            presentTextSelectorSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "checklist")
                                Text("Select")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle(tint: .green))
                        
                        Button {
                            audioManager.play(data, modelContext: modelContext)
                        } label: {
                            HStack {
                                Image(systemName: audioManager.isPlaying ? "stop" : "play")
                                Text(audioManager.isPlaying ? "Stop" : "Play")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle(tint: .pink))
                    }
                }
                .removeParentListStyle()
            }
            .font(DS.Typography.eyebrow)
            .sheet(isPresented: $presentBookmarkSheet, content: {
                Quran_Content_Bookmarks()
            })
            .sheet(isPresented: $presentTextSelectorSheet, content: {
                Quran_Element_TextSelector(verse: data)
            })
            
            Section(header: HStack {
                Text("\(data.wordByWord.count) WORDS")
                    .font(DS.Typography.eyebrow)
                    .tracking(2)
                Spacer()
            }) {
                Quran_Element_WordByWordInfo(verse: data)
            }
            
            Section(header: Text("CHAPTER \(data.chapter.chapter_number)")
                .font(DS.Typography.eyebrow)
                .tracking(2)
            ) {
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

