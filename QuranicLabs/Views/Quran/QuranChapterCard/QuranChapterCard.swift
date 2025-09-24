import SwiftUI
import Defaults

struct QuranChapterCard: View {
    var chapter: Int
    
    var displayIndex: String? = nil
    
    var removeBookmarkedIcon = false
    
    var data: Types.Quran.ChapterInfo? {
        AppData.Quran.chapters.first { $0.chapter_number == chapter }
    }
    
    @Default(.primary_language) var primaryLanguage
    
    @Environment(\.colorScheme) var theme
    
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        if let data {
            NavigationLink {
                QuranReaderView(chapter: data.chapter_number)
            } label: {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                if !removeBookmarkedIcon && environment.BookmarkManager.isBookmarked(chapter: chapter) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                        .fontWeight(.ultraLight)
                                }
                                if let displayIndex = displayIndex {
                                    Text(displayIndex)
                                        .font(.footnote)
                                        .padding(8)
                                        .background(Circle().fill(Color.accent.opacity(0.2)))
                                }
                                Text("Sura \(data.chapter_number)")
                                    .foregroundStyle(.accent)
                                    .fontDesign(.serif)
                                Text(data.chapter_title_transliterated)
                                    .foregroundStyle(.secondary)
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text(data.getChapterTitle(for: primaryLanguage))
                                    .foregroundStyle(.primary)
                                    .fontDesign(.serif)
                            }
                        }
                        Spacer()
                        Text("\(data.chapter_verses)")
                            .font(.callout)
                            .fontWeight(.ultraLight)
                            .foregroundStyle(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                            .fontWeight(.ultraLight)
                    }
                    .font(.title2)
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color.secondary.opacity(theme == .dark ? 0.08 : 0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contextMenu {
                    Button {
                        Task {
                            let bookmark = environment.BookmarkManager.get(chapter: chapter)
                            if (bookmark == nil) {
                                await environment.BookmarkManager.addChapter(chapter)
                            } else {
                                await environment.BookmarkManager.remove(bookmarkID: bookmark!.id)
                            }
                        }
                    } label: {
                        let isBookmarked = environment.BookmarkManager.isBookmarked(chapter: chapter)
                        Label(isBookmarked ? "Remove bookmark" : "Bookmark", systemImage: isBookmarked ? "x.circle" : "star")
                            .foregroundStyle(isBookmarked ? .red : .primary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        QuranChapterCard(chapter: 20)
            .environmentObject(AppEnvironment.shared)
    }
}
