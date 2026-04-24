import SwiftUI
import Defaults

struct Music_Content_Favorites: View {
    @ObservedObject var dataManager: MusicDataManager
    @ObservedObject private var audio = AudioManager.shared
    @Default(.music_favorites) private var favoriteUrls
    @Environment(\.dismiss) private var dismiss

    /// Favorite tracks in reverse order (most recently added first)
    private var favoriteTracks: [MusicTrack] {
        dataManager.favoriteTracks(urls: favoriteUrls.reversed())
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Info text
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: audio.loopMode.icon)
                        .foregroundColor(audio.loopMode == .off ? .secondary : .accentColor)
                        .font(.caption)
                    Text(favoritesPlaybackNote)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.bottom, 8)

                if favoriteTracks.isEmpty {
                    emptyState
                } else {
                    ForEach(favoriteTracks) { track in
                        Music_TrackCard(
                            track: track,
                            isPlaying: audio.isPlayingTrack(track)
                        ) {
                            playTrack(track)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 200)
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No favorites yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tap the heart icon on any track to save it here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Playback

    private func playTrack(_ track: MusicTrack) {
        // Play within favorites context
        audio.playMusic(track, queue: favoriteTracks, context: .favorites)
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
