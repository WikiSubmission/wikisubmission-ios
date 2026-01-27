import SwiftUI

struct Home_MusicSection: View {
    @ObservedObject private var music = MusicDataManager.shared
    @ObservedObject private var router = Router.shared
    var body: some View {
        VStack {
            if music.featuredTracks.count > 0 {
                Text("FEATURED TRACKS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .tracking(2)
                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(music.featuredTracks, id: \.self) { track in
                                Music_FeaturedCard(track: track) {
                                    router.selectTab(.music)
                                    router.musicScrollToTrackId = track.id
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button {
                        router.selectTab(.music)
                    } label: {
                        Label("Music →", systemImage: "music.note")
                    }
                    .pushToRight()
                    .buttonStyle(SignatureButtonStyle())
                }
            } else {
                Text("FEATURED TRACKS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .tracking(2)
                Card(title: "Browse Music", options: .action(
                    systemImage: "music.note",
                    imageAlignment: .top,
                    showChevron: true
                ) {
                    router.selectTab(.music)
                })
            }
        }
        .task {
            await music.fetchAll()
        }
    }
}
