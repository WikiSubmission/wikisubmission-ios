import Foundation
import SwiftUI
import AudioStreaming
import Combine
import AVFoundation
import MediaPlayer
import AVFAudio
import Defaults

extension Utilities.Quran {
    class QuranAudioManager: ObservableObject, AudioPlayerDelegate {
        static let shared = QuranAudioManager()
        
        @Published var isQueueActive: Bool = false
        @Published var isPlaying: Bool = false
        
        @Published var currentVerse: Types.Quran.Data? = nil
        @Published var queue: [Types.Quran.Data] = []
        @Published var queueCurrentIndex: Int = 0
        
        private var queuedVerses: [URL] = []
        private var queuedVersesCurrentIndex: Int = 0
        
        private var cancellables: Set<AnyCancellable> = []
        private let playerStateChanged = PassthroughSubject<Void, Never>()
                
        lazy var player: AudioPlayer = {
            let player = AudioPlayer()
            player.delegate = self
            player.volume = 0.5
            return player
        }()
        
        func getAudioLink(for verseId: String) -> URL {
            let reciter = UserDefaults.standard.string(forKey: Defaults.Keys.quran_reciter.name) ?? "mishary"
            let urlString = "https://cdn.wikisubmission.org/media/quran-recitations/arabic-\(reciter)/\(verseId.replacingOccurrences(of: ":", with: "-")).mp3"
            
            return URL(string: urlString)!
        }

        @MainActor
        func playVerse(_ verseId: String) {
            if isQueueActive || isPlaying { stopQueue() }
            
            let audioUrl = getAudioLink(for: verseId)
            
            self.player.play(url: audioUrl)
        }
        
        /// Starts playing a queue of verses.
        func playQueue(_ verses: [Types.Quran.Data], startFromVerse: Int? = nil) {
            stopQueue()
            guard !verses.isEmpty else { return }
            queue = verses
            // If chapter 1 or 9, no 0 verse index
            queueCurrentIndex = startFromVerse != nil ? ((verses.first?.chapter_number == 1 || verses.first?.chapter_number == 9) ? ((startFromVerse ?? 1) - 1) : (startFromVerse ?? 1)) : 0
            playCurrentInQueue()
        }

        /// Plays the current verse in the active queue.
        func playCurrentInQueue() {
            guard queue.indices.contains(queueCurrentIndex) else { stopQueue(); return }
            let verse = queue[queueCurrentIndex]
            let url = getAudioLink(for: verse.verse_id)
            self.currentVerse = verse

            UserDefaults.standard.set(verse.verse_id, forKey: Defaults.Keys.last_played_verse.name)
            isQueueActive = true
            self.player.play(url: url)
        }

        /// Advances to the next verse in the queue and plays it.
        func nextInQueue() {
            guard queue.indices.contains(queueCurrentIndex + 1) else { stopQueue(); return }
            queueCurrentIndex += 1
            playCurrentInQueue()
        }

        /// Goes back to the previous verse in the queue and plays it.
        func previousInQueue() {
            guard queueCurrentIndex > 0 else { return }
            queueCurrentIndex -= 1
            playCurrentInQueue()
        }

        /// Stops playing the queue and clears all related state.
        func stopQueue() {
            player.stop()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            isQueueActive = false
            queue = []
            queueCurrentIndex = 0
            currentVerse = nil
        }
        
        /// Pauses queue playback without clearing or resetting state.
        func pauseQueuePlayback() {
            player.pause()
        }
    }
}

extension Utilities.Quran.QuranAudioManager {
    func audioPlayerDidStartPlaying(player: AudioStreaming.AudioPlayer, with entryId: AudioStreaming.AudioEntryId) {
    }
    
    func audioPlayerDidFinishBuffering(player: AudioStreaming.AudioPlayer, with entryId: AudioStreaming.AudioEntryId) {
    }
    
    func audioPlayerStateChanged(player: AudioStreaming.AudioPlayer, with newState: AudioStreaming.AudioPlayerState, previous: AudioStreaming.AudioPlayerState) {
        if newState == .bufferring || newState == .playing {
            self.isPlaying = true
        } else {
            self.isPlaying = false
        }
        
        if !Utilities.System.NetworkMonitor.shared.hasInternet {
            Utilities.System.GlobalAlertManager.shared.showAlert(title: "No Internet Connection", subtitle: "An internet connection is required to play verse audios.", systemImage: "wifi.slash", type: .error, showSettingsButton: false)
            self.stopQueue()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AudioStreaming.AudioPlayer, entryId: AudioStreaming.AudioEntryId, stopReason: AudioStreaming.AudioPlayerStopReason, progress: Double, duration: Double) {
        switch stopReason {
        case .eof:
            if isQueueActive, queue.indices.contains(queueCurrentIndex + 1) {
                nextInQueue()
            } else {
                stopQueue()
            }
            
        case .userAction:
            break
            
        default:
            break
        }
    }
    
    func audioPlayerUnexpectedError(player: AudioStreaming.AudioPlayer, error: AudioStreaming.AudioPlayerError) {
        Utilities.System.GlobalAlertManager.shared.showAlert(title: "Error", subtitle: "\(error.localizedDescription)", systemImage: "waveform.badge.xmark", type: .error, showSettingsButton: false)
    }
    
    func audioPlayerDidCancel(player: AudioStreaming.AudioPlayer, queuedItems: [AudioStreaming.AudioEntryId]) {
    }
    
    func audioPlayerDidReadMetadata(player: AudioStreaming.AudioPlayer, metadata: [String : String]) {
        
    }
}
