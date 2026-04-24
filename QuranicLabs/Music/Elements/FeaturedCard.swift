import SwiftUI

struct Music_FeaturedCard: View {
    let track: MusicTrack
    let onPlay: () -> Void

    private var colorTheme: MusicColorTheme {
        MusicColorTheme.generate(seed: track.artist.id)
    }

    private var isNewRelease: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let releaseDay = calendar.startOfDay(for: track.releaseDate)

        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return false
        }

        return releaseDay >= oneWeekAgo && releaseDay <= today
    }

    var body: some View {
        Button(action: onPlay) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorTheme.cardGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "music.quarternote.3")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    HStack(spacing: 6) {
                        Text(track.name)
                            .font(DS.Typography.titleMD)
                            .lineLimit(2)
                            .foregroundColor(.primary)

                        if isNewRelease {
                            Text("NEW")
                                .font(DS.Typography.caption)
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
                .padding()
            }
            .frame(width: 240, height: 140)
        }
        .buttonStyle(.plain)
    }
}
