import SwiftUI
import Defaults

struct Music_Content_Favorites: View {
    @ObservedObject var dataManager: MusicDataManager
    @ObservedObject private var audio = AudioManager.shared
    @Default(.music_favorites) private var favoriteUrls

    private var favoriteTracks: [MusicTrack] {
        dataManager.favoriteTracks(urls: favoriteUrls.reversed())
    }

    var body: some View {
        Group {
            if favoriteTracks.isEmpty {
                emptyState
            } else {
                trackList
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Track List

    private var trackList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Playback note
                HStack {
                    Label(favoritesPlaybackNote, systemImage: audio.loopMode.icon)
                        .font(DS.Typography.caption)
                        .foregroundStyle(audio.loopMode == .off ? Color.secondary : Color.accentColor)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, DS.Spacing.lg)

                LazyVStack(spacing: 0) {
                    ForEach(favoriteTracks) { track in
                        Music_TrackCard(
                            track: track,
                            isPlaying: audio.isPlayingTrack(track)
                        ) {
                            audio.playMusic(track, queue: favoriteTracks, context: .favorites)
                        }

                        if track.id != favoriteTracks.last?.id {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
            }
            .padding(.bottom, 200)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Favorites Yet")
                .font(DS.Typography.titleLG)
            Text("Tap the heart on any track to save it here.")
                .font(DS.Typography.bodySM)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var favoritesPlaybackNote: String {
        switch audio.loopMode {
        case .off:
            return "Favorites will play through once and stop at the end."
        case .queue:
            return "Favorites will keep looping through this list."
        case .repeatOne:
            return "Repeat is on, so the current favorite will replay until you change it."
        }
    }
}
