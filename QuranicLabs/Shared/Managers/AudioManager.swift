import AVFoundation
import MediaPlayer
import SwiftData
import Defaults

// MARK: - Defaults Keys

extension Defaults.Keys {
    static let audio_loop_mode = Key<AudioLoopMode>("audio_loop_mode", default: .queue)
}

// MARK: - Audio Types

enum AudioCategory: String {
    case quran
    case music
}

/// Identifies the context/source of the current music queue
enum MusicPlaybackContext: Equatable {
    case featured
    case category(id: UUID)
    case favorites
}

enum AudioLoopMode: String, Codable, CaseIterable, Defaults.Serializable {
    case off = "Off"
    case queue = "Queue"
    case repeatOne = "Repeat"

    var icon: String {
        switch self {
        case .off: return "arrow.right"
        case .queue: return "repeat"
        case .repeatOne: return "repeat.1"
        }
    }

    var displayName: String {
        switch self {
        case .off: return "Play once"
        case .queue: return "Looping queue"
        case .repeatOne: return "Repeating track"
        }
    }
}

struct AudioTrack: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let url: URL
    let metadata: AudioTrackMetadata?

    init(id: String, title: String, subtitle: String, url: URL, metadata: AudioTrackMetadata? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.metadata = metadata
    }

    static func == (lhs: AudioTrack, rhs: AudioTrack) -> Bool {
        lhs.id == rhs.id
    }
}

struct AudioTrackMetadata {
    // Quran metadata
    let chapterNumber: Int?
    let verseNumber: Int?
    let verseIndex: Int?

    // Music metadata
    let colorSeed: UUID?
    let lyrics: String?

    init(chapterNumber: Int? = nil, verseNumber: Int? = nil, verseIndex: Int? = nil, colorSeed: UUID? = nil, lyrics: String? = nil) {
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.verseIndex = verseIndex
        self.colorSeed = colorSeed
        self.lyrics = lyrics
    }
}

// MARK: - Audio Manager

@MainActor
class AudioManager: ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published State

    @Published var isPlaying: Bool = false
    @Published var currentTrack: AudioTrack?
    @Published var queue: [AudioTrack] = []
    @Published var currentIndex: Int = 0
    @Published var category: AudioCategory = .quran
    @Published var loopMode: AudioLoopMode = Defaults[.audio_loop_mode] {
        didSet {
            Defaults[.audio_loop_mode] = loopMode
        }
    }

    /// For music: tracks which category/context the current queue belongs to
    @Published var currentMusicContext: MusicPlaybackContext?

    // MARK: - Player

    var player: AVPlayer?
    private var timeObserverToken: Any?
    private var staticNowPlayingInfo: [String: Any] = [:]
    private var quranArtwork: MPMediaItemArtwork?
    private var musicArtwork: MPMediaItemArtwork?

    // MARK: - Init

    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
        generateArtwork()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }
    }

    // MARK: - Remote Command Center (System Controls)

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }

        // Pause
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }

        // Next track
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipToNext()
            return .success
        }

        // Previous track
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipToPrevious()
            return .success
        }

        // Seek
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

    // MARK: - Now Playing Info (Control Center)

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            staticNowPlayingInfo = [:]
            return
        }

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.subtitle
        info[MPMediaItemPropertyAlbumTitle] = category == .quran ? "Quran" : "Music"

        if let player = player, let duration = player.currentItem?.duration.seconds, duration.isFinite {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        // Use category-specific artwork
        let artwork = category == .quran ? quranArtwork : musicArtwork
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }

        staticNowPlayingInfo = info

        // Merge dynamic fields
        var fullInfo = staticNowPlayingInfo
        fullInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0
        fullInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = fullInfo
    }

    private func generateArtwork() {
        let size = CGSize(width: 512, height: 512)

        // Quran artwork - wikisubmission logo
        quranArtwork = MPMediaItemArtwork(boundsSize: size) { _ in
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { _ in
                if let image = UIImage(named: "wikisubmission") {
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
            }
        }

        // Music artwork - silver gradient with music note
        musicArtwork = MPMediaItemArtwork(boundsSize: size) { _ in
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { context in
                // Silver gradient background
                let colors = [
                    UIColor(white: 0.75, alpha: 1.0),
                    UIColor(white: 0.55, alpha: 1.0)
                ]
                if let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors.map { $0.cgColor } as CFArray,
                    locations: [0.0, 1.0]
                ) {
                    context.cgContext.drawLinearGradient(
                        gradient,
                        start: .zero,
                        end: CGPoint(x: size.width, y: size.height),
                        options: []
                    )
                }

                // Music note icon
                let config = UIImage.SymbolConfiguration(pointSize: 180, weight: .regular)
                if let noteImage = UIImage(systemName: "music.note", withConfiguration: config) {
                    let tintedImage = noteImage.withTintColor(.white, renderingMode: .alwaysOriginal)
                    let noteSize = tintedImage.size
                    let noteOrigin = CGPoint(
                        x: (size.width - noteSize.width) / 2,
                        y: (size.height - noteSize.height) / 2
                    )
                    tintedImage.draw(at: noteOrigin)
                }
            }
        }
    }

    // MARK: - Periodic Time Observer

    private func addPeriodicTimeObserver() {
        removeTimeObserver()
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let player = self.player else { return }

                // Update control center with current position
                var info = self.staticNowPlayingInfo
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
                info[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? 1.0 : 0.0
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info

                // Handle track end
                if let duration = player.currentItem?.duration.seconds,
                   duration > 0,
                   player.currentTime().seconds / duration >= 0.99 {
                    self.handleTrackEnd()
                }
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func handleTrackEnd() {
        switch loopMode {
        case .off:
            // Play through queue once, stop at end
            if currentIndex < queue.count - 1 {
                skipToNext()
            } else {
                player?.pause()
                isPlaying = false
                updateNowPlayingInfo()
            }
        case .queue:
            // Loop through queue
            skipToNext()
        case .repeatOne:
            // Repeat current track
            player?.seek(to: .zero)
            player?.play()
        }
    }

    // MARK: - Playback Controls

    func play(_ verse: QuranUnified, modelContext: ModelContext) {
        category = .quran
        queue = []

        // Build queue from chapter
        let chapterVerses = QuranUnified.fetchChapter(verse.index.chapter_number, context: modelContext)

        for v in chapterVerses {
            let trackUrl = URL(string: "https://cdn.wikisubmission.org/media/quran-recitations/arabic-\(Defaults[.quran_reciter])/\(v.index.chapter_number)-\(v.index.verse_number).mp3")!
            let track = AudioTrack(
                id: v.index.verse_id,
                title: v.index.verse_id,
                subtitle: Defaults[.quran_reciter].displayName,
                url: trackUrl,
                metadata: AudioTrackMetadata(
                    chapterNumber: v.index.chapter_number,
                    verseNumber: v.index.verse_number,
                    verseIndex: v.index.verse_index
                )
            )
            queue.append(track)
        }

        // Find starting index
        if let startIndex = queue.firstIndex(where: { $0.title == verse.index.verse_id }) {
            playTrack(at: startIndex)
        }
    }

    func playTrack(at index: Int) {
        guard index >= 0 && index < queue.count else { return }

        let track = queue[index]

        // If same track, toggle play/pause
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }

        // Clean up old player
        removeTimeObserver()
        player?.pause()

        // Create new player
        let playerItem = AVPlayerItem(url: track.url)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true

        currentTrack = track
        currentIndex = index
        isPlaying = true

        // Update control center
        updateNowPlayingInfo()
        addPeriodicTimeObserver()

        // Start playback
        player?.play()

        // Update now playing info after a short delay to get duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.updateNowPlayingInfo()
        }
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

    func skipToNext() {
        if loopMode == .repeatOne, let _ = currentTrack {
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            return
        }

        guard !queue.isEmpty else { return }

        let nextIndex = (currentIndex + 1) % queue.count

        // If loop is off and we wrapped around, stop
        if loopMode == .off && nextIndex == 0 {
            player?.pause()
            isPlaying = false
            updateNowPlayingInfo()
            return
        }

        playTrack(at: nextIndex)
    }

    func skipToPrevious() {
        if loopMode == .repeatOne {
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            return
        }

        // If more than 3 seconds in, restart current track
        if let currentTime = player?.currentTime().seconds, currentTime > 3.0 {
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            return
        }

        guard !queue.isEmpty else { return }

        let previousIndex = currentIndex == 0 ? queue.count - 1 : currentIndex - 1
        playTrack(at: previousIndex)
    }

    func stop() {
        removeTimeObserver()
        player?.pause()
        player = nil
        isPlaying = false
        currentTrack = nil
        queue = []
        currentIndex = 0
        updateNowPlayingInfo()
    }

    func dismiss() {
        removeTimeObserver()
        player?.pause()
        player = nil
        isPlaying = false
        currentTrack = nil
        updateNowPlayingInfo()
    }

    func cycleLoopMode() {
        switch loopMode {
        case .off:
            loopMode = .queue
        case .queue:
            loopMode = .repeatOne
        case .repeatOne:
            loopMode = .off
        }
    }

    // MARK: - Seek

    func seek(to percentage: Double) {
        guard let player = player,
              let duration = player.currentItem?.duration.seconds,
              duration.isFinite else { return }

        let targetTime = duration * percentage
        let time = CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time)
        updateNowPlayingInfo()
    }

    // MARK: - Music Playback

    /// Play a music track with a given queue context
    func playMusic(_ track: MusicTrack, queue: [MusicTrack], context: MusicPlaybackContext) {
        category = .music
        currentMusicContext = context

        // Build queue from provided tracks, including metadata for artwork and lyrics
        self.queue = queue.map { musicTrack in
            AudioTrack(
                id: musicTrack.id.uuidString,
                title: musicTrack.name,
                subtitle: musicTrack.artist.name,
                url: URL(string: musicTrack.url)!,
                metadata: AudioTrackMetadata(
                    colorSeed: musicTrack.artist.id,
                    lyrics: musicTrack.lyrics
                )
            )
        }

        // Find and play the selected track
        if let index = self.queue.firstIndex(where: { $0.id == track.id.uuidString }) {
            playTrack(at: index)
        }
    }

    /// Check if a specific music track is currently playing
    func isPlayingTrack(_ track: MusicTrack) -> Bool {
        currentTrack?.id == track.id.uuidString && isPlaying
    }

    /// Check if the current queue is from a specific context
    func isPlayingContext(_ context: MusicPlaybackContext) -> Bool {
        category == .music && currentMusicContext == context && currentTrack != nil
    }

    // MARK: - Reciter Change

    func updateReciter(_ reciter: QuranReciters) {
        guard category == .quran, !queue.isEmpty else { return }

        // Rebuild queue with new reciter URLs
        queue = queue.map { track in
            guard let metadata = track.metadata,
                  let chapterNumber = metadata.chapterNumber,
                  let verseNumber = metadata.verseNumber else { return track }

            let newUrl = URL(string: "https://cdn.wikisubmission.org/media/quran-recitations/arabic-\(reciter)/\(chapterNumber)-\(verseNumber).mp3")!
            return AudioTrack(
                id: track.id,
                title: track.title,
                subtitle: reciter.displayName,
                url: newUrl,
                metadata: track.metadata
            )
        }

        // Update current track and restart playback if playing
        if let current = currentTrack,
           let updatedTrack = queue.first(where: { $0.id == current.id }) {
            currentTrack = updatedTrack

            let wasPlaying = isPlaying
            let currentTime = player?.currentTime()

            // Create new player with updated URL
            removeTimeObserver()
            player?.pause()

            let playerItem = AVPlayerItem(url: updatedTrack.url)
            player = AVPlayer(playerItem: playerItem)
            player?.automaticallyWaitsToMinimizeStalling = true

            // Seek to previous position if available
            if let time = currentTime {
                player?.seek(to: time)
            }

            if wasPlaying {
                player?.play()
            }

            updateNowPlayingInfo()
            addPeriodicTimeObserver()
        }
    }
}
