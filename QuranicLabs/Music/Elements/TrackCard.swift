import SwiftUI
import Defaults

struct Music_TrackCard: View {
    let track: MusicTrack
    let isPlaying: Bool
    let onPlay: () -> Void

    @Default(.music_favorites) private var favorites

    private var isFavorite: Bool {
        favorites.contains(track.url)
    }

    private var colorTheme: MusicColorTheme {
        MusicColorTheme.generate(seed: track.artist.id)
    }

    private var isNewRelease: Bool {
        let now = Date()
        guard let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return false }
        return track.releaseDate >= oneWeekAgo && track.releaseDate <= now
    }

    var body: some View {
        HStack(spacing: 12) {
            // Main tappable area
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    artwork
                    trackInfo
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Favorite button
            favoriteButton
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPlaying ? Color.accentColor.opacity(0.16) : Color.gray.opacity(0.05))
        )
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorTheme.artworkGradient)
                .frame(width: 52, height: 52)

            Image(systemName: isPlaying ? "pause.circle.fill" : "music.note")
                .font(.system(size: 22))
                .foregroundColor(isPlaying ? .accentColor : .white.opacity(0.8))
        }
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(track.name)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                if isNewRelease {
                    Text("NEW")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                }
            }

            Text(track.artist.name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Favorite Button

    private var favoriteButton: some View {
        Button {
            toggleFavorite()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : .secondary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }

    private func toggleFavorite() {
        if isFavorite {
            favorites.removeAll { $0 == track.url }
        } else {
            favorites.append(track.url)
        }
    }
}
