import SwiftUI

/// Manages fetching music data from Supabase.
/// Fetches fresh data on each view appearance.
@MainActor
class MusicDataManager: ObservableObject {
    
    static let shared = MusicDataManager()

    @Published private(set) var artists: [MusicArtist] = []
    @Published private(set) var categories: [MusicCategory] = []
    @Published private(set) var tracks: [MusicTrack] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    private var lastSuccessfulFetch: Date?

    /// Featured tracks sorted by release date (newest first)
    var featuredTracks: [MusicTrack] {
        tracks
            .filter { $0.isFeatured }
            .sorted { $0.releaseDate > $1.releaseDate }
    }

    /// Tracks grouped by category, sorted by display priority
    var tracksByCategory: [(category: MusicCategory, tracks: [MusicTrack])] {
        categories
            .sorted { $0.displayPriority > $1.displayPriority }
            .compactMap { category in
                let categoryTracks = tracks
                    .filter { $0.category.id == category.id }
                    .sorted { $0.releaseDate > $1.releaseDate }

                guard !categoryTracks.isEmpty else { return nil }
                return (category: category, tracks: categoryTracks)
            }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Fetches all music data from Supabase.
    func fetchAll() async {
        if let lastFetch = lastSuccessfulFetch,
           Date().timeIntervalSince(lastFetch) < 60 {
            return
        }

        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedTracks = try await fetchTracks()

            // Extract unique categories from tracks
            var uniqueCategories: [UUID: MusicCategory] = [:]
            for track in fetchedTracks {
                uniqueCategories[track.category.id] = track.category
            }

            // Update state
            self.tracks = fetchedTracks
            self.categories = Array(uniqueCategories.values)
            self.lastSuccessfulFetch = Date()

            print("MusicDataManager: Loaded \(fetchedTracks.count) tracks")

        } catch {
            self.error = error
            print("MusicDataManager: Failed to fetch - \(error.localizedDescription)")
        }
    }

    private func fetchTracks() async throws -> [MusicTrack] {
        let selectQuery = "*,artistObj:ws_music_artists(*),categoryObj:ws_music_categories(*)"

        let rows: [MusicTrackRow] = try await SupabaseManager.client
            .from("ws_music_tracks")
            .select(selectQuery)
            .execute()
            .value

        // Transform rows to domain models
        return rows.compactMap { row -> MusicTrack? in
            guard let artist = row.artistObj,
                  let category = row.categoryObj,
                  let releaseDate = Self.dateFormatter.date(from: row.releaseDate)
            else { return nil }

            return MusicTrack(
                id: row.id,
                name: row.name,
                url: row.url,
                artist: artist,
                category: category,
                releaseDate: releaseDate,
                isFeatured: row.featured,
                lyrics: row.lyrics
            )
        }
        .sorted { $0.releaseDate > $1.releaseDate }
    }

    /// Find a track by its URL
    func track(forUrl url: String) -> MusicTrack? {
        tracks.first { $0.url == url }
    }

    /// Get tracks for a list of favorite URLs, preserving order
    func favoriteTracks(urls: [String]) -> [MusicTrack] {
        urls.compactMap { url in
            tracks.first { $0.url == url }
        }
    }
}
