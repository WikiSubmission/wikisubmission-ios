import SwiftUI
import Defaults

struct UnifiedTrack: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let url: String
    let artist: DBArtist
    let category: DBCategory
    let releaseDate: Date
}

enum PlaybackContext: String, Codable, CaseIterable, Defaults.Serializable {
    case allTracks = "All Tracks"
    case category = "Category"
    case favorites = "Favorites"
    
    var icon: String {
        switch self {
        case .allTracks: return "music.note.list"
        case .category: return "square.grid.2x2"
        case .favorites: return "heart.fill"
        }
    }
    
    func displayState(loopMode: LoopMode) -> String {
        switch loopMode {
        case .off:
            return "Loop off"
        case .context:
            switch self {
            case .allTracks: return "Queue"
            case .category: return "Queue"
            case .favorites: return "Queue"
            }
        case .repeatOne:
            return "Repeating track"
        }
    }
}

enum LoopMode: String, Codable, CaseIterable, Defaults.Serializable {
    case off = "Loop Off"
    case context = "Loop Queue"
    case repeatOne = "Repeat Track"
    
    var icon: String {
        switch self {
        case .off: return "arrow.right"
        case .context: return "repeat"
        case .repeatOne: return "repeat.1"
        }
    }
}
