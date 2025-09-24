import SwiftUI
import Defaults
import SheetKit

struct QuranReaderView: View {
    var chapter: Int
    var scrollToVerseID: String? = nil
    
    @State private var data: [Types.Quran.Data] = []
    
    @EnvironmentObject private var environment: AppEnvironment
    
    @Default(.primary_language) private var primaryLanguage

    var body: some View {
        VStack {
            if data.count > 0 {
                chapterHeader
                verseList
            } else {
                ProgressView()
            }
        }
        .padding(.horizontal, 12)
        .onAppear {
            Task {
                DispatchQueue.main.async {
                    self.data = AppData.Quran.versesByChapter[chapter] ?? []
                }
            }
        }
        .toolbar {
            toolbar
        }
    }
    
    private var chapterHeader: some View {
        VStack {
            Text("SURA \(chapter)")
                .font(.title)
                .fontWeight(.ultraLight)
                .foregroundStyle(.secondary)
                .pushToLeft()
            
            HStack {
                Text("\(data.first!.getChapterTitle(for: primaryLanguage)) · \(data.first!.chapter_title_arabic)")
                    .pushToLeft()
                Text("\(data.first!.chapter_verses) verses")
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.ultraLight)
            .foregroundStyle(.primary)
        }
        .padding()
        .background(Color.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .fontDesign(.serif)
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
    
    private var verseList: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    Color.clear.frame(height: 0).id("top")
                    VStack {
                        ForEach(data, id: \.verse_id) { verse in
                            QuranVerseCard(id: verse.verse_id, isScrolledTo: scrollToVerseID == verse.verse_id ? true : false)
                        }
                    }
                }
                .onAppear {
                    Task {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let scrollToVerseID = scrollToVerseID {
                                withAnimation {
                                    proxy.scrollTo(scrollToVerseID, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack(alignment: .center, spacing: 0) {
            // Share button
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
                let isBookmarked = environment.BookmarkManager.isBookmarked(chapter: data.first?.chapter_number)
                Label("", systemImage: isBookmarked ? "star.fill" : "star")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(isBookmarked ? .yellow : .accent)
            }
            
            // Share button
            Button {
                SheetKit().presentWithEnvironment {
                    QuranShareVerses(data: data)
                }
            } label: {
                Label("", systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
            }
            
            // Settings button
            QuranMenu()
        }
    }
}

#Preview {
    NavigationStack {
        QuranReaderView(chapter: 19)
            .environmentObject(AppEnvironment.shared)
    }
}
