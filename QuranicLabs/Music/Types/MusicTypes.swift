import Foundation

// MARK: - Domain Models

struct MusicTrack: Identifiable, Hashable {
    let id: UUID
    let name: String
    let url: String
    let artist: MusicArtist
    let category: MusicCategory
    let releaseDate: Date
    let isFeatured: Bool
    let lyrics: String?
}

struct MusicArtist: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let imageUrl: String
    let displayPriority: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case imageUrl = "image_url"
        case displayPriority = "display_priority"
    }
}

struct MusicCategory: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let displayPriority: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case displayPriority = "display_priority"
    }
}

// MARK: - Database Row (for Supabase decoding)

struct MusicTrackRow: Codable, Identifiable {
    let id: UUID
    let name: String
    let url: String
    let releaseDate: String
    let artist: UUID
    let category: UUID
    let featured: Bool
    let lyrics: String?

    // Joined relations
    let artistObj: MusicArtist?
    let categoryObj: MusicCategory?

    enum CodingKeys: String, CodingKey {
        case id, name, url, lyrics
        case releaseDate = "release_date"
        case artist, category, featured
        case artistObj, categoryObj
    }
}
