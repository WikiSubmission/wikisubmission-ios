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
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    artwork
                    trackInfo
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            favoriteButton
        }
        .padding(10)
        .background(cardBackground)
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorTheme.artworkGradient)
                .frame(width: 56, height: 56)

            Image(systemName: isPlaying ? "waveform" : "music.note")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(cardBackgroundStyle)
    }

    private var cardBackgroundStyle: AnyShapeStyle {
        if isPlaying {
            return AnyShapeStyle(Color.accentColor.opacity(0.12))
        }

        return AnyShapeStyle(Color.primary.opacity(0.04))
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(track.name)
                    .font(DS.Typography.titleSM)
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
                .font(DS.Typography.caption)
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
