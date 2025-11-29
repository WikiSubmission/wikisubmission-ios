import Defaults

extension Defaults.Keys {
    static let zikr_favorited_tracks = Key<[String]>("zikr_favorited_tracks", default: [])
    static let zikr_loop_mode = Key<LoopMode>("zikr_loop_mode", default: .context)
    static let zikr_playback_context = Key<PlaybackContext>("zikr_playback_context", default: .allTracks)
}
