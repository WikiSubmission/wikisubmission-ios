import AVFoundation
import SwiftUI
import Defaults

extension Defaults.Keys {
    static let zikr_cached_index = Key<[Artist]?>("zikr_cached_index", default: nil)
    static let zikr_favorited_tracks = Key<[String]>("zikr_favorited_tracks", default: [])
    static let zikr_cached_index_timestamp = Key<Date?>("zikr_cached_index_timestamp", default: nil)
}

struct ZikrView: View {
    @StateObject private var vm = ZikrViewModel()
    @ObservedObject private var audioManager = ZikrAudioManager.shared

    private func handleTrackTap(artist: Artist, track: Artist.Track) {
        // if the same track is playing, toggle pause
        if audioManager.currentTrack == track.title {
            if audioManager.isPlaying {
                ZikrAudioManager.shared.togglePlayPause()
            } else {
                ZikrAudioManager.shared.playTrack(artist: artist.id, track: track.title)
            }
        } else {
            // if a new track is tapped, stop current and start new one
            ZikrAudioManager.shared.stop()
            ZikrAudioManager.shared.playTrack(artist: artist.id, track: track.title)
        }
    }

    private var headerInfo: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "info.circle")
                .foregroundStyle(.accent)
                .font(.caption)
            Text("The list is frequently updated over time. The copyrights for all materials are retained by the original holders.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var favoriteTracksSection: some View {
        let favoriteTracks = vm.artists.flatMap { artist in
            artist.tracks.filter { $0.favoritedAt != nil }
        }
        return Group {
            if !favoriteTracks.isEmpty {
                LazyVStack(alignment: .leading, spacing: 8) {
                    Section(header:
                        HStack {
                            Image(systemName: "music.note")
                                .font(.title3)
                            Text("Favorites")
                                .font(.title)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.accent)
                    ) {
                        VStack {
                            ForEach(favoriteTracks) { track in
                                if let artist = vm.artists.first(where: { $0.tracks.contains(where: { $0.id == track.id }) }) {
                                    TrackItem(
                                        artistObject: artist,
                                        trackObject: track,
                                        isPlaying: audioManager.currentTrack == track.title && audioManager.isPlaying,
                                        action: { handleTrackTap(artist: artist, track: track) },
                                        vm: vm,
                                        showArtist: true
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var artistLists: some View {
        ForEach(vm.artists) { artist in
            LazyVStack(alignment: .leading, spacing: 8, pinnedViews: .sectionHeaders) {
                Section(header:
                    Text("\(artist.id.capitalized)")
                        .font(.title)
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                        .pushToLeft()
                ) {
                    VStack {
                        ForEach(artist.tracks) { track in
                            TrackItem(
                                artistObject: artist,
                                trackObject: track,
                                isPlaying: audioManager.currentTrack == track.title && audioManager.isPlaying,
                                action: { handleTrackTap(artist: artist, track: track) },
                                vm: vm,
                                showArtist: false
                            )
                        }
                    }
                }
            }
        }
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { _ in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                headerInfo
                                favoriteTracksSection
                                artistLists
                            }
                            .padding()
                            .padding(.bottom, audioManager.currentTrack != nil ? 64 : 0)
                        }
                    }
                }
//                ZikrNowPlayingBar(audioManager: audioManager)
            }
            .navigationTitle("Zikr")
            .task { await vm.fetchMediaIndex() }
        }
    }
}

struct TrackItem: View {
    let artistObject: Artist
    let trackObject: Artist.Track
    let isPlaying: Bool
    let action: () -> Void
    @ObservedObject var vm: ZikrViewModel
    var showArtist: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: isPlaying ? [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.4)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.15)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(isPlaying ? .secondary : .accentColor)
                        .font(.system(size: 20, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(trackObject.title.split(separator: ".")[0])
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .truncationMode(.tail)
                    }
                    if showArtist {
                        Text(artistObject.id.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                Spacer()
                Button {
                    vm.toggleFavorite(track: trackObject)
                } label: {
                    HStack {
                        Image(systemName: trackObject.favoritedAt != nil ? "heart.fill" : "heart")
                            .foregroundColor(trackObject.favoritedAt != nil ? .red : .gray)
                            .font(.title3)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.accent.opacity(isPlaying ? 0.17 : 0.08).padding(-8))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .contextMenu {
            Button {
                vm.toggleFavorite(track: trackObject)
            } label: {
                Label("Favorite", systemImage: trackObject.favoritedAt != nil ? "heart.fill" : "heart")
            }
        }
    }
}

struct Artist: Identifiable, Codable, Defaults.Serializable {
    let id: String
    var tracks: [Track]
    
    struct Track: Identifiable, Codable, Defaults.Serializable {
        var id: UUID = UUID()
        let title: String
        let url: String
        var favoritedAt: Date?
    }
}

class ZikrViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    
    init() {
        Utilities.Quran.QuranAudioManager.shared.player.stop()
        mergeFavorites()
    }
    
    private func buildTracks(for artistKey: String, trackList: [String]) -> [Artist.Track] {
        var trackObjects: [Artist.Track] = []
        
        for trackName in trackList {
            let trackURL = "\(Info.cdnEndpoint)/media/zikr/\(artistKey)/\(trackName)"
            let isFavorited = Defaults[.zikr_favorited_tracks].contains(trackURL)
            let favoritedAt = isFavorited ? Date() : nil
            
            let track = Artist.Track(title: trackName, url: trackURL, favoritedAt: favoritedAt)
            trackObjects.append(track)
        }
        
        return trackObjects.sorted(by: { $0.title < $1.title })
    }
    
    @MainActor
    func fetchMediaIndex() async {
        isLoading = true
        defer { isLoading = false }
        
        if let cached = Defaults[.zikr_cached_index],
           let timestamp = Defaults[.zikr_cached_index_timestamp],
           Date().timeIntervalSince(timestamp) < 60 {
            self.artists = cached
            mergeFavorites()
            return
        }
        
        guard let url = URL(string: "\(Info.cdnEndpoint)/index.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let media = json["media"] as? [String: Any],
                  let zikr = media["zikr"] as? [String: Any] else {
                return
            }
            
            var tempArtists: [Artist] = []
            
            for (artistKey, tracks) in zikr {
                if artistKey.starts(with: ".") { continue }
                
                if let trackList = tracks as? [String] {
                    let trackObjects = buildTracks(for: artistKey, trackList: trackList)
                    
                    let artist = Artist(id: artistKey, tracks: trackObjects)
                    tempArtists.append(artist)
                }
            }
            
            self.artists = tempArtists.sorted(by: { $0.id < $1.id })
            Defaults[.zikr_cached_index] = self.artists
            Defaults[.zikr_cached_index_timestamp] = Date()
        } catch {
            print("Zikr: failed to fetch or decode: \(error)")
        }
    }
    
    private func mergeFavorites() {
        let favoriteTrackURLs = Defaults[.zikr_favorited_tracks]
        for i in artists.indices {
            for j in artists[i].tracks.indices {
                let trackURL = artists[i].tracks[j].url
                let isFavorited = favoriteTrackURLs.contains(trackURL)
                artists[i].tracks[j].favoritedAt = isFavorited ? Date() : nil
            }
        }
    }
    
    func toggleFavorite(track: Artist.Track) {
        var favoriteTrackURLs = Defaults[.zikr_favorited_tracks]
        if favoriteTrackURLs.contains(track.url) {
            favoriteTrackURLs.removeAll(where: { $0 == track.url })
        } else {
            favoriteTrackURLs.append(track.url)
        }
        Defaults[.zikr_favorited_tracks] = favoriteTrackURLs
        mergeFavorites()
    }
}

class ZikrAudioManager: ObservableObject {
    static let shared = ZikrAudioManager()
    
    @Published var isPlaying: Bool = false
    @Published var currentTrack: String? = nil
    @Published var currentArtist: String? = nil
    @Published var isLooping: Bool = true
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    
    private init() {}
    
    func playTrack(artist: String, track: String) {
        guard Utilities.System.NetworkMonitor.shared.hasInternet else {
            Utilities.System.GlobalAlertManager.shared.showAlert(title: "No Internet Connection", subtitle: "An internet connection is required to play zikr audios.", systemImage: "wifi.slash", type: .error)
            return
        }
        
        if currentTrack == track && isPlaying {
            togglePlayPause()
            return
        }
        
        guard let url = URL(string: "\(Info.cdnEndpoint)/media/zikr/\(artist)/\(track)") else { return }
        
        stop()
        
        player = AVPlayer(url: url)
        player?.play()
        currentArtist = artist
        currentTrack = track
        isPlaying = true
        
        addPeriodicTimeObserver()
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func stop() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentTrack = nil
        currentArtist = nil
    }
    
    private func addPeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard self != nil else { return }
            guard let duration = player.currentItem?.duration.seconds, duration > 0 else {
                return
            }
            let progress = time.seconds / duration
            if progress >= 1.0 {
                if self?.isLooping == true {
                    player.seek(to: .zero)
                    player.play()
                }
            }
        }
    }
}

#Preview {
    ZikrView()
}
