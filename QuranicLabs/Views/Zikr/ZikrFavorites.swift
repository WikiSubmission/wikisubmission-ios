import SwiftUI
import Defaults

struct ZikrFavoritesView: View {
    @StateObject private var vm = ZikrDBViewModel()
    @ObservedObject private var audio = ZikrAudioManager.shared
    @Default(.zikr_favorited_tracks) private var favoritedTracks
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = true
    
    private var favoriteTracks: [UnifiedTrack] {
        // Use audio.allTracks if vm.tracks is still empty (loading)
        let tracks = vm.tracks.isEmpty ? audio.allTracks : vm.tracks
        return tracks.filter { favoritedTracks.contains($0.url) }
    }
    
    private var shouldShowEmptyState: Bool {
        // Only show empty state if not loading AND no favorites
        !isLoading && favoriteTracks.isEmpty && !favoritedTracks.isEmpty
    }
    
    private var shouldShowNoFavoritesMessage: Bool {
        // Show "no favorites yet" only if definitely no favorites selected
        !isLoading && favoritedTracks.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading && audio.allTracks.isEmpty {
                    // Loading state
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if shouldShowNoFavoritesMessage {
                    // No favorites selected at all
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Favorites Yet")
                            .font(.title2.bold())
                        Text("Tap the heart icon on any track to add it to your favorites")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(spacing: 4) {
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
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
            .task {
                // If audio manager already has tracks, use those immediately
                if !audio.allTracks.isEmpty && vm.tracks.isEmpty {
                    isLoading = false
                }
                
                await vm.fetchFromDB()
                audio.allTracks = vm.tracks
                audio.favoriteTrackUrls = favoritedTracks
                isLoading = false
            }
            .onChange(of: favoritedTracks) { _, newFavorites in
                audio.favoriteTrackUrls = newFavorites
            }
        }
    }
}
