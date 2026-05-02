import SwiftUI

struct Music_FeaturedCard: View {
    let track: MusicTrack
    let onPlay: () -> Void

    @ObservedObject private var audio = AudioManager.shared

    private var colorTheme: MusicColorTheme {
        MusicColorTheme.generate(seed: track.artist.id)
    }

    private var isPlaying: Bool {
        audio.isPlayingTrack(track)
    }

    var body: some View {
        Button(action: onPlay) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(colorTheme.cardGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: isPlaying ? "waveform" : "music.quarternote.3")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)

                    Text(track.name)
                        .font(DS.Typography.titleMD)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(track.artist.name)
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.secondary)
                }
                .padding(DS.Spacing.lg)
            }
            .frame(width: 220, height: 140)
        }
        .buttonStyle(.plain)
    }
}
