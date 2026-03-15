import SwiftUI
import Defaults

struct Home_QuranSection: View {
    @ObservedObject var router = Router.shared
    @ObservedObject var audioManager = AudioManager.shared
    @Default(.last_read_verse_id) private var lastReadVerseId

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            SectionLabel("THE FINAL TESTAMENT")

            if audioManager.category == .quran, audioManager.isPlaying, let track = audioManager.currentTrack {
                Button {
                    router.selectTab(.quran)
                    router.navigate(to: .chapter(
                        chapterNumber: Int(track.title.split(separator: ":")[0]) ?? 1,
                        scrollToVerseNumber: Int(track.title.split(separator: ":")[1]) ?? 1
                    ))
                } label: {
                    Label("Playing: \(track.title) →", systemImage: "waveform")
                }
                .font(.caption)
                .buttonStyle(SignatureButtonStyle())
            }

            QuranSearchBar()

            Card(title: "Browse", options: .action(
                systemImage: "book.closed",
                showChevron: true
            ) {
                router.selectTab(.quran)
                router.popToRoot(for: .quran)
            })

            Card(title: "Bookmarks", options: .destination(
                systemImage: "bookmark",
                showChevron: true
            ) {
                Quran_Content_Bookmarks()
            })

            Card(title: "Appendices", options: .destination(
                systemImage: "text.page",
                showChevron: true
            ) {
                Appendices()
            })

            HStack {
                Spacer()
                Button {
                    router.popToRoot(for: .quran)
                    router.navigate(to: .chapter(
                        chapterNumber: Int(lastReadVerseId.split(separator: ":")[0])!,
                        scrollToVerseNumber: Int(lastReadVerseId.split(separator: ":")[1])!
                    ))
                } label: {
                    Label("Random", systemImage: "sparkles")
                }
                if lastReadVerseId != "1:1" {
                    Button {
                        router.popToRoot(for: .quran)
                        router.navigate(to: .chapter(
                            chapterNumber: Int(lastReadVerseId.split(separator: ":")[0])!,
                            scrollToVerseNumber: Int(lastReadVerseId.split(separator: ":")[1])!
                        ))
                    } label: {
                        Label("\(lastReadVerseId) →", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .font(.caption)
            .buttonStyle(SignatureButtonStyle())
        }
        .removeParentListStyle()
    }
}
