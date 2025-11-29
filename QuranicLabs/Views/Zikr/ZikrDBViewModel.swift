import SwiftUI
import Foundation
import Defaults

@MainActor
class ZikrDBViewModel: ObservableObject {
    @Published var artists: [DBArtist] = []
    @Published var categories: [DBCategory] = []
    @Published var tracks: [UnifiedTrack] = []

    // Cache the decoded DBTrackRow list for featured lookup
    private var vmRows: [DBTrackRow] = []

    // Featured tracks based on the new boolean column
    var featured: [UnifiedTrack] { tracks.filter { track in
        if let row = vmRows.first(where: { $0.id == track.id }) {
            return row.featured ?? false
        }
        return false
    } }

    func refresh() { Task { await fetchFromDB() } }

    func fetchFromDB() async {
        await fetchCategories()
        await fetchArtists()
        await fetchTracks()
    }

    private func fetchCategories() async {
        do {
            let query = Utilities.Supabase.client.from("ws_music_categories").select("*")
            let data = try await query.execute().data
            let decoded = try JSONDecoder().decode([DBCategory].self, from: data)
            categories = decoded.sorted { ($0.name) < ($1.name) }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }

    private func fetchArtists() async {
        do {
            let query = Utilities.Supabase.client.from("ws_music_artists").select("*")
            let data = try await query.execute().data
            let decoded = try JSONDecoder().decode([DBArtist].self, from: data)
            artists = decoded.sorted { $0.name < $1.name }
        } catch {
            print("Failed to fetch artists: \(error)")
        }
    }

    private func fetchTracks() async {
        do {
            let selectStr = "*,artistObj:ws_music_artists(*),categoryObj:ws_music_categories(*)"
            let query = Utilities.Supabase.client.from("ws_music_tracks").select(selectStr)
            let data = try await query.execute().data
            let decoded = try JSONDecoder().decode([DBTrackRow].self, from: data)
            // Cache the decoded rows for featured lookup
            vmRows = decoded
            // Map DBTrackRow + artistObj + categoryObj into UnifiedTrack, filtering out nil artist/category
            tracks = decoded.compactMap { row in
                guard let artist = row.artistObj, let category = row.categoryObj else { return nil }
                return UnifiedTrack(
                    id: row.id,
                    title: row.name,
                    url: row.url,
                    artist: artist,
                    category: category
                )
            }
            sortTracks()
        } catch {
            print("Failed to fetch tracks: \(error)")
        }
    }

    private func sortTracks() { tracks.sort { $0.title < $1.title } }

    func toggleFavorite(track: UnifiedTrack) {
        var fav = Defaults[.zikr_favorited_tracks]
        if fav.contains(track.url) {
            fav.removeAll { $0 == track.url }
        } else {
            fav.append(track.url)
        }
        Defaults[.zikr_favorited_tracks] = fav
    }

    // MARK: - Filtering helpers
    func artistsFiltered(query: String) -> [DBArtist] {
        guard !query.isEmpty else { return artists }
        return artists.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func categoriesFiltered(query: String) -> [DBCategory] {
        guard !query.isEmpty else { return categories }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func featuredTracksFiltered(query: String) -> [UnifiedTrack] {
        var list = featured
        if !query.isEmpty { list = list.filter { $0.title.localizedCaseInsensitiveContains(query) } }
        return list
    }
}

struct DBArtist: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let imageUrl: String?
}

struct DBCategory: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let displayPriority: Int?
}

struct DBTrackRow: Codable, Identifiable {
    let id: UUID
    let name: String
    let url: String
    let releaseDate: String?
    let artist: UUID
    let category: UUID
    let artistObj: DBArtist?
    let categoryObj: DBCategory?
    let featured: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, url
        case releaseDate = "release_date"
        case artist, category
        case artistObj, categoryObj
        case featured
    }
}
