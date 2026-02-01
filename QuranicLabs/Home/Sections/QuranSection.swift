import SwiftUI
import Defaults

struct Home_QuranSection: View {
    @ObservedObject var router = Router.shared
    @Default(.last_read_verse_id) private var lastReadVerseId

    var body: some View {
        VStack {
            Text("QURAN: THE FINAL TESTAMENT")
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(2)
            
            Card(title: "Browse", options: .action (
                systemImage: "book.closed",
                showChevron: true,
                style: .accent
            ) {
                router.selectTab(.quran)
                router.popToRoot(for: .quran)
            })
            
            Card(title: "Search", options: .action(
                systemImage: "magnifyingglass",
                showChevron: true
            ){
                router.selectTab(.quran)
                router.popToRoot(for: .quran)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.openQuranSearchBar = true
                }
            })
            
            Card(title: "Random Verse", options: .action(
                systemImage: "sparkles",
                showChevron: true
            ){
                router.popToRoot(for: .quran)
                router.navigate(to: .randomVerse)
            })
            
            Card(title: "Bookmarks", options: .destination (
                systemImage: "bookmark",
                showChevron: true,
            ){
                Quran_Content_Bookmarks()
            })
            
            Card(title: "Appendices", options: .destination (
                systemImage: "text.page",
                showChevron: true,
            ) {
                Appendices()
            })
            
            if lastReadVerseId != "1:1" {
                Card(title: lastReadVerseId, options: .action (
                    systemImage: "arrow.counterclockwise",
                    showChevron: true,
                    style: .secondary
                ) {
                    router.popToRoot(for: .quran)
                    router.navigate(to: .chapter(chapterNumber: Int(lastReadVerseId.split(separator: ":")[0])!, scrollToVerseNumber: Int(lastReadVerseId.split(separator: ":")[1])!))
                })
            }
        }
        .removeParentListStyle()
    }
}
