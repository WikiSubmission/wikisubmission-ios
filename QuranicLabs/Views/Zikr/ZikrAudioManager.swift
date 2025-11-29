import SwiftUI
import Foundation
import AVFoundation
import Defaults

class ZikrAudioManager: ObservableObject {
    static let shared = ZikrAudioManager()

    @Published var isPlaying: Bool = false
    @Published var currentTrack: UnifiedTrack? = nil
    @Published var loopMode: LoopMode = Defaults[.zikr_loop_mode] {
        didSet {
            Defaults[.zikr_loop_mode] = loopMode
        }
    }
    @Published var playbackContext: PlaybackContext = Defaults[.zikr_playback_context] {
        didSet {
            Defaults[.zikr_playback_context] = playbackContext
        }
    }
    
    var allTracks: [UnifiedTrack] = []
    var favoriteTrackUrls: [String] = []

    var player: AVPlayer?
    private var timeObserverToken: Any?

    private init() {
        loopMode = Defaults[.zikr_loop_mode]
        playbackContext = Defaults[.zikr_playback_context]
    }
    
    private func getCurrentQueue() -> [UnifiedTrack] {
        guard let current = currentTrack else { return [] }
        
        switch playbackContext {
        case .allTracks:
            return allTracks
        case .category:
            return allTracks.filter { $0.category.id == current.category.id }
        case .favorites:
            return allTracks.filter { favoriteTrackUrls.contains($0.url) }
        }
    }

    func playTrack(track: UnifiedTrack, context: PlaybackContext? = nil) {
        if let context = context {
            playbackContext = context
        }
        
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }

        guard let url = URL(string: track.url) else { return }

        // Don't call stop() - just clean up the old player
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        
        player = AVPlayer(url: url)
        player?.play()

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
        // Keep currentTrack for UI - don't clear it
        // currentTrack = nil
    }
    
    func skipToNext() {
        // If repeat one, just restart current track
        if loopMode == .repeatOne, let current = currentTrack {
            playTrack(track: current)
            return
        }
        
        let queue = getCurrentQueue()
        guard !queue.isEmpty, let current = currentTrack else { return }
        
        if let currentIndex = queue.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (currentIndex + 1) % queue.count
            
            // If loop is off and we're at the end, pause but keep track visible
            if loopMode == .off && nextIndex == 0 {
                player?.pause()
                isPlaying = false
                return
            }
            
            playTrack(track: queue[nextIndex])
        }
    }
    
    func skipToPrevious() {
        // If repeat one, just restart current track
        if loopMode == .repeatOne {
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
            return
        }
        
        // Check if we're more than 3 seconds into the track
        if let currentTime = player?.currentTime().seconds, currentTime > 3.0 {
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
            return
        }
        
        let queue = getCurrentQueue()
        guard !queue.isEmpty, let current = currentTrack else { return }
        
        if let currentIndex = queue.firstIndex(where: { $0.id == current.id }) {
            let previousIndex = currentIndex == 0 ? queue.count - 1 : currentIndex - 1
            playTrack(track: queue[previousIndex])
        }
    }
    
    func cycleLoopMode() {
        switch loopMode {
        case .off:
            loopMode = .context
        case .context:
            loopMode = .repeatOne
        case .repeatOne:
            loopMode = .off
        }
    }

    private func addPeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            guard let duration = player.currentItem?.duration.seconds, duration > 0 else { return }
            let progress = time.seconds / duration
            
            // When track ends
            if progress >= 0.99 {
                switch self.loopMode {
                case .off:
                    // Pause at end but keep track visible
                    player.pause()
                    self.isPlaying = false
                case .context:
                    self.skipToNext()
                case .repeatOne:
                    player.seek(to: .zero)
                    player.play()
                }
            }
        }
    }
    
    func getCurrentQueuePublic() -> [UnifiedTrack] {
        guard let current = currentTrack else { return [] }
        
        switch playbackContext {
        case .allTracks:
            return allTracks
        case .category:
            return allTracks.filter { $0.category.id == current.category.id }
        case .favorites:
            return allTracks.filter { favoriteTrackUrls.contains($0.url) }
        }
    }
}
