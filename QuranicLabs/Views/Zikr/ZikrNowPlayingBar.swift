import SwiftUI
import Defaults

struct ZikrNowPlayingBar: View {
    @ObservedObject var audioManager = ZikrAudioManager.shared
    @Default(.active_tab) private var activeTab
    var body: some View {
        VStack {
            Spacer()
            if let currentTrack = audioManager.currentTrack,
               let currentArtist = audioManager.currentArtist {
                HStack(spacing: 16) {
                    Button {
                        if activeTab != .zikr {
                            activeTab = .zikr
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentTrack.split(separator: ".")[0])
                                .font(.headline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(currentArtist.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    HStack(spacing: 4) {
                        Button(action: {
                            audioManager.togglePlayPause()
                        }) {
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        Button(action: {
                            audioManager.stop()
                        }) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        Button(action: {
                            audioManager.isLooping.toggle()
                        }) {
                            Image(systemName: audioManager.isLooping ? "repeat.1" : "repeat.badge.xmark")
                                .font(.title2)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 7, y: 3)
                .padding(.horizontal)
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: audioManager.isPlaying)
            }
        }
    }
}
