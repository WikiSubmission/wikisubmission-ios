import SwiftUI
import Defaults

struct Quran_Element_ChapterCard: View {
    let chapter: QuranChapters
    var highlightPhrase = ""
    var hideBookmarkStatus = false
    var revelationOrderIndex: Int? = nil

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
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Sura \(chapter.chapter_number)")
                        .font(DS.Typography.eyebrow)
                        .foregroundStyle(.accent)

                    Spacer(minLength: 0)

                    if hideBookmarkStatus != true && bookmarkManager.isChapterBookmarked(chapter.chapter_number) {
                        Image(systemName: "star.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("\(chapter.chapter_verses)")
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.accent.opacity(0.4))
                }

                Spacer(minLength: 8)

                if highlightPhrase.isEmpty {
                    Text(chapter.getTitleInUserLanguage(primaryLanguage))
                        .font(DS.Typography.titleSM)
                        .lineLimit(2)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    ConditionalHighlight(
                        text: chapter.getTitleInUserLanguage(primaryLanguage),
                        query: highlightPhrase
                    )
                    .lineLimit(2)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(chapter.title_transliterated)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .font(DS.Typography.eyebrow)

                    Spacer(minLength: 0)

                    if let revelationOrderIndex {
                        Text("#\(revelationOrderIndex)")
                            .foregroundStyle(.accent)
                            .font(DS.Typography.eyebrowSM)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.07))
            )
            .contentShape(RoundedRectangle(cornerRadius: 24))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
