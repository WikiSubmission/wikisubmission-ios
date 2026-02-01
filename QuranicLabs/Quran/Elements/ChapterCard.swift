import SwiftUI
import Defaults

struct Quran_Element_ChapterCard: View {
    let chapter: QuranChapters
    var highlightPhrase = ""
    var hideBookmarkStatus = false

    @Default(.quran_primary_language) private var primaryLanguage
    
    @ObservedObject private var bookmarkManager = BookmarkManager.shared
    @ObservedObject private var router = Router.shared
    
    @State private var presentBookmarkSheet = false
    
    @Environment(\.dismiss) var dismiss

    private var isBookmarked: Bool {
        bookmarkManager.isChapterBookmarked(chapter.chapter_number)
    }

    var body: some View {
        Button {
            dismiss()
            router.popToRoot(for: .quran)
            router.navigate(to: .chapter(chapterNumber: chapter.chapter_number))
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text("Chapter \(chapter.chapter_number)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .fontDesign(.serif)
                        if hideBookmarkStatus != true && bookmarkManager.isChapterBookmarked(chapter.chapter_number) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        Text("\(chapter.chapter_verses)")
                            .foregroundStyle(.accent)
                            .font(.subheadline)
                    }
                    HStack {
                        if highlightPhrase.isEmpty {
                            Text("\(chapter.getTitleInUserLanguage(primaryLanguage))")
                                .background(Color.secondary.opacity(0.09).padding(-4))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            ConditionalHighlight(
                                text: chapter.getTitleInUserLanguage(primaryLanguage),
                                query: highlightPhrase
                            )
                            .background(Color.secondary.opacity(0.09).padding(-4))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Spacer()
                        Text("\(chapter.title_transliterated)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding()
            .background(Color.secondary.opacity(0.07).clipShape(RoundedRectangle(cornerRadius: 8)))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                if isBookmarked {
                    bookmarkManager.removeByKey(String(chapter.chapter_number))
                } else {
                    bookmarkManager.addChapter(chapter.chapter_number)
                    presentBookmarkSheet = true
                }
            } label: {
                Label(
                    isBookmarked ? "Remove Bookmark" : "Bookmark",
                    systemImage: isBookmarked ? "bookmark.slash" : "bookmark"
                )
            }

            Button {
                shareText("Chapter \(chapter.chapter_number): \(chapter.title_english)")
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .sheet(isPresented: $presentBookmarkSheet) {
            Quran_Content_Bookmarks()
        }
    }
}
