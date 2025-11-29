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
        VStack(spacing: 0) {
            Spacer()

            Button(action: {
                guard let track = audio.currentTrack else { return }
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        ZikrNowPlayingSheet(track: track, audio: audio)
                    }
                    .presentationDetents([.medium])
                }
            }) {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 36, height: 4)
                        .padding(.top, 6)
                        .padding(.bottom, 8)

                    if let track = audio.currentTrack {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(GenerateColorTheme.colors(seed: track.artist.id).art)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.secondary)
                                        .padding(12)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(track.artist.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                            
                            HStack(spacing: 4) {
                                Button {
                                    audio.cycleLoopMode()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: audio.loopMode.icon)
                                    }
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(12)
                                }

                                Button(action: { audio.togglePlayPause() }) {
                                    Image(systemName: audio.isPlaying && audio.currentTrack?.id == track.id ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.accentColor)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(action: {
                                    audio.stop()
                                    audio.currentTrack = nil
                                    audio.currentTrack = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.red)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 56)
                        .id(track.id)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 2)
                                    .cornerRadius(1)
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(width: geo.size.width * progress, height: 2)
                                    .cornerRadius(1)
                                    .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                        }
                        .frame(height: 2)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                }
                .background(
                    VisualEffectBlur()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -1)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 60)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            updateProgress()
        }
        .onReceive(Timer.publish(every: progressUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
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
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
