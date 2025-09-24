import Foundation
import SwiftUI

extension QuranReaderView {
    /// Creates a QuranReaderView starting at a random chapter
    static func randomChapter() -> QuranReaderView {
        if let randomChapter = AppData.Quran.versesByChapter.keys.randomElement() {
            return QuranReaderView(chapter: randomChapter)
        } else {
            return QuranReaderView(chapter: 1)
        }
    }

    /// Creates a QuranReaderView starting at a random verse
    static func randomVerse() -> QuranReaderView {
        if let randomVerse = AppData.Quran.main.randomElement() {
            return QuranReaderView(chapter: randomVerse.chapter_number,
                                   scrollToVerseID: randomVerse.verse_id)
        } else {
            return QuranReaderView(chapter: 1)
        }
    }
}
