import SwiftUI
import Defaults
import SheetKit

struct QuranChapterCard: View {
    var chapter: Int
    
    var displayIndex: String? = nil
    
    var removeBookmarkedIcon = false
    
    var displayOnly = false
    
    var data: Types.Quran.ChapterInfo? {
        AppData.Quran.chapters.first { $0.chapter_number == chapter }
    }
    
    @Default(.primary_language) var primaryLanguage
    
    @Environment(\.colorScheme) var theme
        
    @Default(.bookmarks) private var bookmarks

    var body: some View {
        if let data {
            ConditionalNavigationLink(
                isActive: displayOnly == false,
                destination: QuranReaderView(chapter: data.chapter_number)
            ) {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                if !removeBookmarkedIcon && bookmarks.contains(where: { $0.key == String(data.chapter_number) }) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                        .fontWeight(.ultraLight)
                                }
                                if let displayIndex = displayIndex {
                                    Text(displayIndex)
                                        .font(.footnote)
                                        .foregroundStyle(theme == .dark ? .white : .black)
                                        .padding(8)
                                        .background(Circle().fill(Color.accent.opacity(0.3)))
                                }
                                Text("Sura \(data.chapter_number)")
                                    .foregroundStyle(.accent)
                                    .fontDesign(.serif)
                                Text(data.chapter_title_transliterated)
                                    .foregroundStyle(theme == .dark ? .white : .black)
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text(data.getChapterTitle(for: primaryLanguage))
                                    .foregroundStyle(theme == .dark ? .white : .black)
                                    .fontDesign(.serif)
                            }
                        }
                        Spacer()
                        Text("\(data.chapter_verses)")
                            .font(.callout)
                            .fontWeight(.ultraLight)
                            .foregroundStyle(.gray)
                        if !displayOnly {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                                .fontWeight(.ultraLight)
                        }
                    }
                    .font(.title2)
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(theme == .dark ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .contextMenu {
                    Button {
                        Task {
                            if let bookmark = bookmarks.first(where: {
                                $0.key == String(chapter)
                            }) {
                                try? await Utilities.Bookmarks.removeBookmark(bookmark)
                            } else {
                                try? await Utilities.Bookmarks.addBookmark(.init(
                                    created_at: Date().ISO8601Format(),
                                    updated_at: nil,
                                    type: .chapter,
                                    key: String(chapter),
                                    category: nil,
                                    notes: nil,
                                ))
                                
                                SheetKit().presentWithEnvironment {
                                    QuranBookmarks()
                                }
                            }
                        }
                    } label: {
                        let isBookmarked = bookmarks.contains(where: { $0.key == String(data.chapter_number) })
                        Label(isBookmarked ? "Remove bookmark" : "Bookmark", systemImage: isBookmarked ? "x.circle" : "star")
                            .foregroundStyle(isBookmarked ? .red : .primary)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        QuranChapterCard(chapter: 20)
            .environmentObject(AppEnvironment.shared)
    }
}
