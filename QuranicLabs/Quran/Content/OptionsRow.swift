import SwiftUI
import Defaults

struct Quran_Content_OptionsRow: View {
    @Binding var searchQuery: QuranQuery

    @State private var showBookmarks = false

    @Default(.sort_chapters_by_revelation_order) private var sortByRevelationOrder
    @Default(.last_read_verse_id) private var lastReadVerseId

    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var router = Router.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if audioManager.category == .quran, audioManager.isPlaying, let track = audioManager.currentTrack {
                    Button {
                        router.selectTab(.quran)
                        router.navigate(to: .chapter(chapterNumber: Int(track.title.split(separator: ":")[0]) ?? 1, scrollToVerseNumber: Int(track.title.split(separator: ":")[1]) ?? 1))
                    } label: {
                        Label("Playing: \(track.title) →", systemImage: "waveform")
                    }
                    .font(.caption)
                    .buttonStyle(SignatureButtonStyle())
                }
                
                if searchQuery.query.isEmpty {
                    HStack {
                        Button {
                            withAnimation {
                                sortByRevelationOrder.toggle()
                            }
                        } label: {
                            Label(sortByRevelationOrder ? "Revelation Order" : "Standard Order", systemImage: "arrow.up.and.down")
                        }
                        .buttonStyle(SignatureButtonStyle())
                    }
                }
                
                Button {
                    showBookmarks = true
                } label: {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                .buttonStyle(SignatureButtonStyle())
                
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
                    .font(.caption)
                    .buttonStyle(SignatureButtonStyle())
                    .pushToRight()
                }
            }
            .font(.caption)
        }
        .sheet(isPresented: $showBookmarks) {
            Quran_Content_Bookmarks()
        }
    }
}
