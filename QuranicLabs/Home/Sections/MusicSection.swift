import SwiftUI

struct Home_MusicSection: View {
    @ObservedObject private var music = MusicDataManager.shared
    @ObservedObject private var router = Router.shared

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            SectionLabel("FEATURED TRACKS")

            if music.featuredTracks.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.lg - 2) {
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
                        .font(DS.Typography.eyebrow)
                }
                .pushToRight()
                .buttonStyle(SignatureButtonStyle())
            } else {
                Card(title: "Browse Music", options: .action(
                    systemImage: "music.note",
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
