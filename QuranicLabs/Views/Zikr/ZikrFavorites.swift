import SwiftUI
import Defaults

struct ZikrFavoritesView: View {
    @ObservedObject private var audio = ZikrAudioManager.shared
    @Default(.zikr_favorited_tracks) private var favoritedTracks
    @Environment(\.dismiss) private var dismiss
    
    // Simply filter allTracks by favorites - no VM needed
    private var favoriteTracks: [UnifiedTrack] {
        guard !favoritedTracks.isEmpty else { return [] }
        
        let filtered = audio.allTracks.filter { favoritedTracks.contains($0.url) }
        
        // Sort by index in favoritedTracks (reverse = latest first)
        return filtered.sorted { track1, track2 in
            let index1 = favoritedTracks.firstIndex(of: track1.url) ?? 0
            let index2 = favoritedTracks.firstIndex(of: track2.url) ?? 0
            return index1 > index2
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        Label("Click the heart beside any track to add it as a favorite. The app will use this list as your loop queue if you play them from here.", systemImage: "info.circle")
                            .font(.caption)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                            .pushToLeft()
                        ForEach(favoriteTracks) { track in
                            ZikrTrackRow(
                                track: track,
                                isPlaying: audio.currentTrack?.id == track.id && audio.isPlaying
                            ) {
                                audio.playTrack(track: track, context: .favorites)
                            }
                            .padding(4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 200)
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
