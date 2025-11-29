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
            let categoriesResult: [DBCategory] = try await Utilities.Supabase.client.from("ws_music_categories").select().execute().value
            categories = categoriesResult.sorted { ($0.displayPriority) > ($1.displayPriority) }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }

    private func fetchArtists() async {
        do {
            let artistsResult: [DBArtist] = try await Utilities.Supabase.client.from("ws_music_artists").select().execute().value
            artists = artistsResult.sorted {
                let p0 = $0.displayPriority ?? 0
                let p1 = $1.displayPriority ?? 0
                if p0 != p1 { return p0 > p1 }
                return $0.name < $1.name
            }
        } catch {
            print("Failed to fetch artists: \(error)")
        }
    }

    private func fetchTracks() async {
        do {
            let selectStr = "*,artistObj:ws_music_artists(*),categoryObj:ws_music_categories(*)"
            let tracksResult: [DBTrackRow] = try await Utilities.Supabase.client.from("ws_music_tracks").select(selectStr).execute().value
            vmRows = tracksResult
            tracks = tracksResult.compactMap { row in
                guard let artist = row.artistObj, let category = row.categoryObj else { return nil }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                guard let parsedDate = formatter.date(from: row.releaseDate ?? "2025-01-01") else { return nil }
                return UnifiedTrack(id: row.id, title: row.name, url: row.url, artist: artist, category: category, releaseDate: parsedDate)
            }
            sortTracks()
        } catch {
            print("Failed to fetch tracks: \(error)")
        }
    }

    private func sortTracks() {
        tracks.sort {
            // Sort by releaseDate descending (newest first), then by title as tiebreaker
            if $0.releaseDate != $1.releaseDate {
                return $0.releaseDate > $1.releaseDate
            }
            return $0.title < $1.title
        }
    }

    func toggleFavorite(track: UnifiedTrack) {
        var fav = Defaults[.zikr_favorited_tracks]
        if fav.contains(track.url) {
            fav.removeAll { $0 == track.url }
        } else {
            fav.append(track.url)
        }
        Defaults[.zikr_favorited_tracks] = fav
    }
}

struct DBArtist: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let imageUrl: String?
    let displayPriority: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case imageUrl = "image_url"
        case displayPriority = "display_priority"
    }
}

struct DBCategory: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let displayPriority: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case displayPriority = "display_priority"
    }
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
