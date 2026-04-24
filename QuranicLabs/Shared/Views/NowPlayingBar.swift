import SwiftUI

struct NowPlayingBar: View {
    @ObservedObject private var audio = AudioManager.shared
    @Environment(\.colorScheme) private var theme
    @State private var showNowPlayingSheet: Bool = false

    var body: some View {
        if let track = audio.currentTrack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            artwork
                            trackInfo(track: track)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showNowPlayingSheet = true
                        }

                        controls
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(barBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(theme == .dark ? 0.24 : 0.10), radius: 16, y: 6)
                .padding(.horizontal, 10)
                .padding(.bottom, 52)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: audio.currentTrack != nil)
            .sheet(isPresented: $showNowPlayingSheet) {
                NowPlayingSheet()
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Artwork

    private var artwork: some View {
        Group {
            switch audio.category {
            case .quran:
                Image("wikisubmission")
                    .resizable()
                    .scaledToFill()
            case .music:
                let colorSeed = audio.currentTrack?.metadata?.colorSeed
                let theme = MusicColorTheme.generate(seed: colorSeed)
                ZStack {
                    theme.artworkGradient
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Track Info

    private func trackInfo(track: AudioTrack) -> some View {
        Text(track.title)
            .font(DS.Typography.titleSM)
            .foregroundStyle(.primary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                audio.togglePlayPause()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)

            if audio.hasNextTrack {
                Button {
                    audio.skipToNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.caption)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            Button {
                audio.dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    private var barBackground: some View {
        DS.Color.surface.opacity(theme == .dark ? 0.96 : 0.94)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        NowPlayingBar()
    }
}
