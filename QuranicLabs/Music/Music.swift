import SwiftUI
import Defaults

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
    case categories = "Categories"
    case newReleases = "New Releases"
}

struct Music: View {
    @StateObject private var dataManager = MusicDataManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var router = Router.shared
    @Default(.music_favorites) private var favoriteUrls

    @State private var showFavorites = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var listMode: MusicListMode = .categories

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .music)) {
            content
                .navigationTitle("Music")
                .requiresInternet(reason: "An internet connection is required to stream music/audio")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        favoritesButton
                    }
                }
                .sheet(isPresented: $showFavorites) {
                    NavigationStack {
                        Music_Content_Favorites(dataManager: dataManager)
                    }
                }
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

    // MARK: - Favorites Button

    private var favoritesButton: some View {
        Button {
            showFavorites = true
        } label: {
            Image(systemName: favoriteUrls.isEmpty ? "heart" : "heart.fill")
                .foregroundColor(.red)
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
                    // Disclaimer
                    header

                    // Featured section
                    if !dataManager.featuredTracks.isEmpty {
                        featuredSection
                    }

                    // List mode picker
                    listModePicker

                    // Content based on mode
                    switch listMode {
                    case .categories:
                        categorySections
                    case .newReleases:
                        newReleasesSection
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

    // MARK: - List Mode Picker

    private var recentReleaseCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataManager.tracks.filter { $0.releaseDate >= sevenDaysAgo }.count
    }

    private var listModePicker: some View {
        HStack(spacing: 10) {
            musicPickerButton(.categories, label: "All Genres", icon: "square.grid.2x2")
            musicPickerButton(.newReleases, label: recentReleaseCount > 0 ? "New (\(recentReleaseCount))" : "New", icon: recentReleaseCount > 1 ? "sparkles" : "clock")
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
                    .font(.subheadline.weight(.medium))
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
                    audio.playMusic(track, queue: dataManager.tracks, context: .category(id: track.category.id))
                }
                .id("track-\(track.id)")
            }
        }
        .padding(.horizontal)
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

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Featured")
                    .font(.title2.bold())

                if audio.isPlayingContext(.featured) {
                    LoopingIndicator()
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(dataManager.featuredTracks) { track in
                        Music_FeaturedCard(track: track) {
                            router.musicScrollToTrackId = track.id
                        }
                        .id("featured-\(track.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
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

#Preview {
    Music()
}
