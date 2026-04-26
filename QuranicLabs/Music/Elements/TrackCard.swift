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
        guard let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return false }
        return track.releaseDate >= oneWeekAgo && track.releaseDate <= Date()
    }

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: DS.Spacing.md) {
                // Artwork
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorTheme.artworkGradient)

                    Image(systemName: isPlaying ? "waveform" : "music.note")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(width: 48, height: 48)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(track.name)
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Color.fg)
                            .lineLimit(1)

                        if isNewRelease {
                            Text("NEW")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                        }
                    }

                    HStack {
                        Text(track.artist.name)
                            .foregroundStyle(DS.Color.fgMuted)
                        Spacer()
                        Text(track.category.name)
                            .foregroundStyle(DS.Color.fgMuted)
                    }
                    .font(DS.Typography.eyebrowSM)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Favorite
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(isFavorite ? .red : DS.Color.fgMuted.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isPlaying ? Color.accentColor.opacity(0.08) : Color.clear)
    }

    private func toggleFavorite() {
        if isFavorite {
            favorites.removeAll { $0 == track.url }
        } else {
            favorites.append(track.url)
        }
    }
}
