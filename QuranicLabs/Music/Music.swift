import SwiftUI
import Defaults

struct Music: View {
    @StateObject private var dataManager = MusicDataManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var router = Router.shared
    @Default(.music_favorites) private var favoriteUrls

    @State private var scrollProxy: ScrollViewProxy?
    @State private var listMode: MusicListMode = .newReleases

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .music)) {
            content
                .navigationTitle("Music")
                .requiresInternet(reason: "An internet connection is required to stream music/audio")
                .onAppear {
                    Task {
                        await dataManager.fetchAll()
                        // After fetch completes, check for pending scroll-to-track
                        handleScrollToTrack(trackId: router.musicScrollToTrackId)
                    }
                }
                .navigationDestination(for: Router.Destination.self) { destination in
                    router.view(for: destination)
                }
                .onChange(of: router.musicScrollToTrackId) { _, trackId in
                    handleScrollToTrack(trackId: trackId)
                }
                .onChange(of: dataManager.tracks) { _, _ in
                    handleScrollToTrack(trackId: router.musicScrollToTrackId)
                }
        }
    }

    private func handleScrollToTrack(trackId: UUID?) {
        guard let trackId else { return }
        guard !dataManager.tracks.isEmpty else { return }

        // Find the track
        guard let track = dataManager.tracks.first(where: { $0.id == trackId }) else {
            router.musicScrollToTrackId = nil
            return
        }

        // Clear immediately to prevent duplicate handling from multiple onChange triggers
        router.musicScrollToTrackId = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Scroll to track if proxy available
            if let proxy = self.scrollProxy {
                withAnimation {
                    proxy.scrollTo("track-\(trackId)", anchor: .center)
                }
            }

            // Only play if not already playing this track (avoid toggle behavior)
            if !self.audio.isPlayingTrack(track) {
                let categoryTracks = self.dataManager.tracks.filter { $0.category.id == track.category.id }
                self.audio.playMusic(track, queue: categoryTracks, context: .category(id: track.category.id))
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if dataManager.isLoading && dataManager.tracks.isEmpty {
            loadingView
        } else if dataManager.tracks.isEmpty {
            emptyView
        } else {
            trackList
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("No tracks available")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Pull to refresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 100)
        }
        .refreshable {
            await dataManager.fetchAll()
        }
    }

    // MARK: - Track List

    private var trackList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    
                    header

                    // Featured section
                    if !dataManager.featuredTracks.isEmpty {
                        featuredSection
                    }

                    // List mode picker
                    listModePicker

                    // Content based on mode
                    switch listMode {
                    case .newReleases:
                        newReleasesSection
                    case .categories:
                        categorySections
                    case .favorites:
                        favoritesSection
                    }
                }
                .padding(.bottom, 200)
            }
            .refreshable {
                await dataManager.fetchAll()
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Label("Glorification and commemoration of God through beautiful recitations and melodies.", systemImage: "music.note")
                .fontWeight(.light)
                .tracking(1.1)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }

    // MARK: - List Mode Picker

    private var recentReleaseCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataManager.tracks.filter { $0.releaseDate >= sevenDaysAgo }.count
    }

    private var listModePicker: some View {
        HStack(spacing: 10) {
            musicPickerButton(.newReleases, label: recentReleaseCount > 0 ? "Latest (\(recentReleaseCount))" : "Latest", icon: recentReleaseCount > 1 ? "sparkles" : "clock")
            musicPickerButton(.categories, label: "All Genres", icon: "square.grid.2x2")
            musicPickerButton(.favorites, label: "Favorites", icon: favoriteUrls.isEmpty ? "heart" : "heart.fill")
        }
        .padding(.horizontal)
        .pushToLeft()
    }

    private func musicPickerButton(_ mode: MusicListMode, label: String, icon: String) -> some View {
        let isSelected = listMode == mode
        let showGlow = mode == .newReleases && recentReleaseCount > 1 && !isSelected

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { listMode = mode }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .symbolEffect(.pulse, isActive: showGlow)
                Text(label)
                    .font(DS.Typography.caption)
            }
            .fontWeight(isSelected ? .bold : .light)
        }
        .buttonStyle(SignatureButtonStyle())
    }

    // MARK: - New Releases Section

    private var newReleasesSection: some View {
        LazyVStack(spacing: 4) {
            ForEach(dataManager.tracks) { track in
                Music_TrackCard(
                    track: track,
                    isPlaying: audio.isPlayingTrack(track)
                ) {
                    audio.playMusic(track, queue: dataManager.tracks, context: .latest)
                }
                .id("track-\(track.id)")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured")
                    .font(DS.Typography.heroMD)

                Spacer()
                
                if audio.isPlayingContext(.featured) {
                    LoopingIndicator()
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(dataManager.featuredTracks) { track in
                        Music_FeaturedCard(track: track) {
                            audio.playMusic(track, queue: dataManager.featuredTracks, context: .featured)
                        }
                        .id("featured-\(track.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Favorites Section

    private var favoriteTracks: [MusicTrack] {
        dataManager.favoriteTracks(urls: favoriteUrls.reversed())
    }

    private var favoritesSection: some View {
        LazyVStack(spacing: 4) {
            if favoriteTracks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No favorites yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Tap the heart icon on any track to save it here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: audio.loopMode.icon)
                        .foregroundColor(audio.loopMode == .off ? .secondary : .accentColor)
                        .font(.caption)
                    Text(favoritesPlaybackNote)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.bottom, 8)

                ForEach(favoriteTracks) { track in
                    Music_TrackCard(
                        track: track,
                        isPlaying: audio.isPlayingTrack(track)
                    ) {
                        audio.playMusic(track, queue: favoriteTracks, context: .favorites)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Category Sections

    private var categorySections: some View {
        ForEach(dataManager.tracksByCategory, id: \.category.id) { group in
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(group.category.name)
                        .font(.title2.bold())

                    if audio.isPlayingContext(.category(id: group.category.id)) {
                        LoopingIndicator()
                    }
                }
                .padding(.horizontal)

                LazyVStack(spacing: 4) {
                    ForEach(group.tracks) { track in
                        Music_TrackCard(
                            track: track,
                            isPlaying: audio.isPlayingTrack(track)
                        ) {
                            audio.playMusic(track, queue: group.tracks, context: .category(id: group.category.id))
                        }
                        .id("track-\(track.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var favoritesPlaybackNote: String {
        switch audio.loopMode {
        case .off:
            return "Favorites will play through once and stop at the end."
        case .queue:
            return "Favorites will keep looping through this list."
        case .repeatOne:
            return "Repeat is on, so the current favorite will replay until you change it."
        }
    }
}

// MARK: - Looping Indicator

private struct LoopingIndicator: View {
    @ObservedObject private var audio = AudioManager.shared
    @State private var isPulsing = false

    private var isLooping: Bool {
        audio.loopMode == .queue || audio.loopMode == .repeatOne
    }

    var body: some View {
        if isLooping {
            Image(systemName: audio.loopMode.icon)
                .font(.caption)
                .foregroundColor(.accentColor)
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .opacity(isPulsing ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear { isPulsing = true }
        }
    }
}

struct FeaturedTracksSection: View {
    let title: String
    let tracks: [MusicTrack]

    /// Optional visual state
    var showsIndicator: Bool = false

    /// Tap handling is injected
    let onSelect: (MusicTrack) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(tracks) { track in
                        Music_FeaturedCard(track: track) {
                            onSelect(track)
                        }
                        .id("featured-\(track.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.title2.bold())

            if showsIndicator {
                LoopingIndicator()
            }
        }
        .padding(.horizontal)
    }
}

enum MusicListMode: String, CaseIterable {
    case newReleases = "New Releases"
    case categories = "Categories"
    case favorites = "Favorites"
}

#Preview {
    Music()
}
