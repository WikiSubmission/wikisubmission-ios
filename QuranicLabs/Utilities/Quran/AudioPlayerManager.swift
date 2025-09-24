import Foundation
import SwiftUI
import AudioStreaming
import Combine
import AVFoundation
import MediaPlayer
import AVFAudio

extension Utilities.Quran {
    class AudioPlayerManager: ObservableObject, AudioPlayerDelegate {
        static let shared = AudioPlayerManager()
        
        @Published var currentVerseId: String? = nil
        @Published var isQueueActive: Bool = false
        @Published var isPlaying: Bool = false
        
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
        
        func getAudioLink(for verseId: String) async -> URL? {
            let reciter = UserDefaults.standard.string(forKey: "quran_reciter") ?? "mishary"
            let urlString = "https://quran.wikisubmission.org/recitations/\(verseId)"

            guard let url = URL(string: urlString) else { return nil }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
                   let audioUrlString = json[reciter],
                   let audioUrl = URL(string: audioUrlString) {
                    return audioUrl
                } else {
                    print("Error: No audio URL found for reciter \(reciter)")
                    return nil
                }
            } catch {
                print("Error fetching audio link:", error)
                return nil
            }
        }

        @MainActor
        func playVerse(_ verseId: String) {
            Task {
                if let audioUrl = await getAudioLink(for: verseId) {
                    print("Playing \(audioUrl)")
                    self.player.play(url: audioUrl)
                    self.currentVerseId = verseId
                } else {
                    print("Failed to get audio URL for verse \(verseId)")
                }
            }
        }
    }
}

extension Utilities.Quran.AudioPlayerManager {
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
    }
    
    func audioPlayerDidFinishPlaying(player: AudioStreaming.AudioPlayer, entryId: AudioStreaming.AudioEntryId, stopReason: AudioStreaming.AudioPlayerStopReason, progress: Double, duration: Double) {
    }
    
    func audioPlayerUnexpectedError(player: AudioStreaming.AudioPlayer, error: AudioStreaming.AudioPlayerError) {
    }
    
    func audioPlayerDidCancel(player: AudioStreaming.AudioPlayer, queuedItems: [AudioStreaming.AudioEntryId]) {
    }
    
    func audioPlayerDidReadMetadata(player: AudioStreaming.AudioPlayer, metadata: [String : String]) {
        
    }
}
