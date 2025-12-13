import SwiftUI
import Foundation
import AVFoundation
import MediaPlayer
import Defaults

class ZikrAudioManager: ObservableObject {
    static let shared = ZikrAudioManager()

    private var staticNowPlayingInfo: [String: Any] = [:]

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
    private var artworkCache: [UUID: MPMediaItemArtwork] = [:]

    private init() {
        loopMode = Defaults[.zikr_loop_mode]
        playbackContext = Defaults[.zikr_playback_context]
        setupRemoteCommandCenter()
    }
    
    private func setupRemoteCommandCenter() {
            let commandCenter = MPRemoteCommandCenter.shared()
            
            // Play command
            commandCenter.playCommand.isEnabled = true
            commandCenter.playCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                if !self.isPlaying {
                    self.togglePlayPause()
                }
                return .success
            }
            
            // Pause command
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.pauseCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                if self.isPlaying {
                    self.togglePlayPause()
                }
                return .success
            }
            
            // Next track command
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget { [weak self] _ in
                self?.skipToNext()
                return .success
            }
            
            // Previous track command
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget { [weak self] _ in
                self?.skipToPrevious()
                return .success
            }
            
            // Change playback position command
            commandCenter.changePlaybackPositionCommand.isEnabled = true
            commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                guard let self = self,
                      let event = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
                let time = CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                self.player?.seek(to: time)
                self.updateNowPlayingInfo()
                return .success
            }
        }
        
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            staticNowPlayingInfo = [:]
            return
        }

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.artist.name
        info[MPMediaItemPropertyAlbumTitle] = track.category.name

        if let player = player, let duration = player.currentItem?.duration.seconds, duration.isFinite {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        if let cachedArtwork = artworkCache[track.artist.id] {
            info[MPMediaItemPropertyArtwork] = cachedArtwork
        } else if let artwork = generateArtwork(for: track) {
            artworkCache[track.artist.id] = artwork
            info[MPMediaItemPropertyArtwork] = artwork
        }

        staticNowPlayingInfo = info

        // Merge dynamic fields
        var fullInfo = staticNowPlayingInfo
        fullInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0
        fullInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = fullInfo
    }
      
      private func generateArtwork(for track: UnifiedTrack) -> MPMediaItemArtwork? {
          let size = CGSize(width: 512, height: 512)
          
          return MPMediaItemArtwork(boundsSize: size) { _ in
              let renderer = UIGraphicsImageRenderer(size: size)
              return renderer.image { context in
                  // Draw gradient background
                  let colors = [UIColor.systemGray, UIColor.systemGray2]
                  if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                              colors: colors.map { $0.cgColor } as CFArray,
                                              locations: [0.0, 1.0]) {
                      context.cgContext.drawLinearGradient(gradient,
                                                          start: .zero,
                                                          end: CGPoint(x: size.width, y: size.height),
                                                          options: [])
                  }
                  
                  // Draw music note icon
                  let iconSize: CGFloat = 200
                  let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                       y: (size.height - iconSize) / 2,
                                       width: iconSize,
                                       height: iconSize)
                  
                  let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .light)
                  if let musicNote = UIImage(systemName: "music.note", withConfiguration: config) {
                      UIColor.white.withAlphaComponent(0.6).setFill()
                      musicNote.draw(in: iconRect, blendMode: .normal, alpha: 0.6)
                  }
              }
          }
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
           
           // Create new player
           let playerItem = AVPlayerItem(url: url)
           player = AVPlayer(playerItem: playerItem)
           
           // Configure player for remote control
           player?.automaticallyWaitsToMinimizeStalling = true
           player?.allowsExternalPlayback = true
           
           currentTrack = track
           isPlaying = true

           // Set now playing info immediately
           updateNowPlayingInfo()
           
           addPeriodicTimeObserver()
           
           // Start playback
           player?.play()
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
               self?.updateNowPlayingInfo()
           }
           
           print("▶️ Playing: \(track.title) by \(track.artist.name)")
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
        updateNowPlayingInfo()
    }

    func stop() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        updateNowPlayingInfo()
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
                updateNowPlayingInfo()
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
            updateNowPlayingInfo()
            return
        }
        
        // Check if we're more than 3 seconds into the track
        if let currentTime = player?.currentTime().seconds, currentTime > 3.0 {
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
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

        // Update every 1 second to keep elapsed time and playback rate in sync
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            guard let self = self, let player = self.player else { return }

            // Merge dynamic fields into staticNowPlayingInfo
            var info = self.staticNowPlayingInfo
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
            info[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? 1.0 : 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info

            // Track end handling
            if let duration = player.currentItem?.duration.seconds, duration > 0,
               player.currentTime().seconds / duration >= 0.99 {
                switch self.loopMode {
                case .off:
                    player.pause()
                    self.isPlaying = false
                    var info = self.staticNowPlayingInfo
                    info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
