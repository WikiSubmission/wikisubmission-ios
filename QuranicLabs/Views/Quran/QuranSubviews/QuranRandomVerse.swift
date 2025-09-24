import SwiftUI

struct QuranRandomVerse: View {
    @State private var randomVerse: Types.Quran.Data? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if let randomVerse = randomVerse {
                    QuranReaderView(chapter: randomVerse.chapter_number, scrollToVerseID: randomVerse.verse_id)
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            Task {
                DispatchQueue.main.async {
                    self.randomVerse = AppData.Quran.main.randomElement()
                }
            }
        }
    }
}

#Preview {
    QuranRandomVerse()
        .environmentObject(Utilities.Quran.BookmarkManager.shared)
}
