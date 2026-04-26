import SwiftUI
import Defaults

struct Music: View {
    @StateObject private var dataManager = MusicDataManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var router = Router.shared
    @Default(.music_favorites) private var favoriteUrls

    @State private var scrollProxy: ScrollViewProxy?
    @State private var selectedCategory: UUID?

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .music)) {
            content
                .navigationTitle("Music")
                .requiresInternet(reason: "An internet connection is required to stream music/audio")
                .onAppear {
                    Task {
                        await dataManager.fetchAll()
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
        guard let track = dataManager.tracks.first(where: { $0.id == trackId }) else {
            router.musicScrollToTrackId = nil
            return
        }
        router.musicScrollToTrackId = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let proxy = self.scrollProxy {
                withAnimation { proxy.scrollTo("track-\(trackId)", anchor: .center) }
            }
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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if dataManager.tracks.isEmpty {
            emptyView
        } else {
            mainList
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No tracks available")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
                Text("Pull to refresh")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 100)
        }
        .refreshable { await dataManager.fetchAll() }
    }

    // MARK: - Main List

    private var mainList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DS.Spacing.section) {
                    header

                    // Featured cards
                    if !dataManager.featuredTracks.isEmpty {
                        featuredSection
                    }

                    // Favorites nav link
                    if !favoriteUrls.isEmpty {
                        favoritesLink
                    }

                    // Browse by category + track listing
                    VStack(spacing: DS.Spacing.lg) {
                        browseSection
                        trackListing
                    }
                }
                .padding(.bottom, 200)
            }
            .refreshable { await dataManager.fetchAll() }
            .onAppear { scrollProxy = proxy }
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

    // MARK: - Favorites Link

    private var favoriteTracks: [MusicTrack] {
        dataManager.favoriteTracks(urls: favoriteUrls.reversed())
    }

    private var favoritesLink: some View {
        let previewTracks = Array(favoriteTracks.prefix(4))

        return NavigationLink {
            Music_Content_Favorites(dataManager: dataManager)
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Label("Favorites", systemImage: "music.note")
                    .font(DS.Typography.titleMD)
                    .foregroundStyle(DS.Color.fg)

                Spacer()

                // Stacked artwork previews
                ZStack {
                    ForEach(Array(previewTracks.enumerated()), id: \.element.id) { index, track in
                        let theme = MusicColorTheme.generate(seed: track.artist.id)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.artworkGradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(DS.Color.surface, lineWidth: 2)
                            )
                            .offset(x: CGFloat(index) * 8)
                            .zIndex(Double(previewTracks.count - index))
                    }
                }
                .frame(width: 36 + CGFloat(max(previewTracks.count - 1, 0)) * 8, height: 36)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(DS.Color.rule, lineWidth: DS.Hairline.width)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // MARK: - Featured

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
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
                HStack(spacing: DS.Spacing.md) {
                    ForEach(dataManager.featuredTracks) { track in
                        Music_FeaturedCard(track: track) {
                            audio.playMusic(track, queue: dataManager.featuredTracks, context: .featured)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation {
                                    scrollProxy?.scrollTo("track-\(track.id)", anchor: .center)
                                }
                            }
                        }
                        .id("featured-\(track.id)")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Browse (Category Chips)

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Explore")
                .font(DS.Typography.heroMD)
                .padding(.horizontal)

            FlexStack(horizontalSpacing: 8, verticalSpacing: 8) {
                categoryChip(label: "All", id: nil)

                ForEach(dataManager.tracksByCategory, id: \.category.id) { group in
                    categoryChip(label: group.category.name, id: group.category.id)
                }
            }
            .padding(.horizontal)
        }
    }

    private func categoryChip(label: String, id: UUID?) -> some View {
        let isSelected = selectedCategory == id
        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedCategory = id
            }
        } label: {
            Text(label)
                .font(DS.Typography.eyebrowSM)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? Color.accentColor.opacity(0.15)
                    : Color.secondary.opacity(0.15)
                )
                .foregroundStyle(isSelected ? .accent : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Track Listing

    private var filteredTracks: [MusicTrack] {
        guard let catId = selectedCategory else {
            return dataManager.tracks
        }
        return dataManager.tracks.filter { $0.category.id == catId }
    }

    private var trackListing: some View {
        let tracks = filteredTracks
        let context: MusicPlaybackContext = {
            if let catId = selectedCategory { return .category(id: catId) }
            return .latest
        }()

        return VStack(spacing: 0) {
            LazyVStack(spacing: 0) {
                ForEach(tracks) { track in
                    Music_TrackCard(
                        track: track,
                        isPlaying: audio.isPlayingTrack(track)
                    ) {
                        audio.playMusic(track, queue: tracks, context: context)
                    }
                    .id("track-\(track.id)")

                    if track.id != tracks.last?.id {
                        Divider().padding(.leading, 76)
                    }
                }
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

enum MusicListMode: String, CaseIterable {
    case newReleases = "New Releases"
    case categories = "Categories"
    case favorites = "Favorites"
}

#Preview {
    Music()
}
