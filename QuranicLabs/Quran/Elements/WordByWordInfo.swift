import SwiftUI

struct Quran_Element_WordByWordInfo: View {
    var verse: QuranUnified

    @ObservedObject private var router = Router.shared

    var body: some View {
        Section {
            ForEach(verse.wordByWord, id: \.self) { w in
                Button {
                    router.push(.wordInfo(
                        chapterNumber: verse.index.chapter_number,
                        verseNumber: verse.index.verse_number,
                        wordIndex: w.word_index
                    ))
                } label: {
                    HStack {
                        Text("**\(w.word_index).** \(w.english)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(w.arabic)")
                            .multilineTextAlignment(.leading)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
