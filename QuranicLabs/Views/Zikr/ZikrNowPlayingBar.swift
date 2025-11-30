import SwiftUI
import Defaults
import SheetKit

#Preview {
    MainView()
}

struct ZikrNowPlayingBar: View {
    @ObservedObject var audio: ZikrAudioManager
    @State private var progress: CGFloat = 0.0
    private let progressUpdateInterval: TimeInterval = 0.5

    var body: some View {
        if let track = audio.currentTrack {
            VStack(spacing: 0) {
                Spacer()
                
                Button(action: {
                    SheetKit().presentWithEnvironment {
                        NavigationStack {
                            ZikrNowPlayingSheet(track: track, audio: audio)
                        }
                        .presentationDetents([.medium])
                    }
                }) {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            // Track info
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(GenerateColorTheme.colors(seed: track.artist.id).art)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.secondary)
                                            .padding(8)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(track.artist.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Playback controls
                            HStack(spacing: 12) {
                                Button {
                                    audio.cycleLoopMode()
                                } label: {
                                    Image(systemName: audio.loopMode.icon)
                                        .font(.title3)
                                }
                                
                                Button(action: { audio.togglePlayPause() }) {
                                    Image(systemName: audio.isPlaying && audio.currentTrack?.id == track.id ? "pause.fill" : "play.fill")
                                        .font(.title2)
                                }
                                
                                Button(action: {
                                    audio.stop()
                                    audio.currentTrack = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 2)
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(width: geo.size.width * progress, height: 2)
                                    .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                        }
                        .frame(height: 2)
                        .padding(.horizontal)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 7, y: 3)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 60)
                }
                .buttonStyle(.plain)
                .id(track.id)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: audio.currentTrack != nil)
            .onAppear {
                updateProgress()
            }
            .onReceive(Timer.publish(every: progressUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
                updateProgress()
            }
        }
    }

    private func updateProgress() {
        guard let player = audio.player, let currentItem = player.currentItem else {
            progress = 0
            return
        }
        let duration = currentItem.duration.seconds
        guard duration.isFinite && duration > 0 else {
            progress = 0
            return
        }
        let currentTime = player.currentTime().seconds
        progress = CGFloat(min(max(currentTime / duration, 0), 1))
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
