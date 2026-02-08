import SwiftUI

struct NowPlayingBar: View {
    @ObservedObject private var audio = AudioManager.shared
    @State private var progress: CGFloat = 0.0
    @State private var isScrubbing: Bool = false
    @State private var currentTimeSeconds: Double = 0
    @State private var durationSeconds: Double = 0
    @State private var showNowPlayingSheet: Bool = false
    private let progressUpdateInterval: TimeInterval = 0.5

    var body: some View {
        if let track = audio.currentTrack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Main content row
                    HStack(spacing: 12) {
                        // Artwork + Track info (tappable)
                        HStack(spacing: 12) {
                            artwork
                            trackInfo(track: track)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showNowPlayingSheet = true
                        }

                        // Controls
                        controls(track: track)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 10)
                .padding(.bottom, 56)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: audio.currentTrack != nil)
            .onAppear {
                updateProgress()
            }
            .onReceive(Timer.publish(every: progressUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
                updateProgress()
            }
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Track Info

    private func trackInfo(track: AudioTrack) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(track.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(timeString)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    private func controls(track: AudioTrack) -> some View {
        HStack(spacing: 16) {
            // Play/Pause
            Button { audio.togglePlayPause() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }

            // Next
            Button { audio.skipToNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.callout)
            }

            // Dismiss
            Button { audio.dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scrubber

    private var scrubber: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track background
                Rectangle()
                    .fill(Color.primary.opacity(0.08))

                // Progress fill
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: max(geo.size.width * progress, 0))
            }
            .frame(height: 3)
        }
        .frame(height: 3)
    }

    // MARK: - Helpers

    private var timeString: String {
        let current = formatTime(currentTimeSeconds)
        let total = formatTime(durationSeconds)
        return "\(current) / \(total)"
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Progress Update

    private func updateProgress() {
        guard !isScrubbing else { return }
        guard let player = audio.player, let currentItem = player.currentItem else {
            progress = 0
            currentTimeSeconds = 0
            durationSeconds = 0
            return
        }
        let duration = currentItem.duration.seconds
        guard duration.isFinite && duration > 0 else {
            progress = 0
            currentTimeSeconds = 0
            durationSeconds = 0
            return
        }
        let currentTime = player.currentTime().seconds
        progress = CGFloat(min(max(currentTime / duration, 0), 1))
        currentTimeSeconds = currentTime
        durationSeconds = duration
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        NowPlayingBar()
    }
}
