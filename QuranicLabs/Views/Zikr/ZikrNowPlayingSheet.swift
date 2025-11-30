import SwiftUI
import Defaults
import AVFoundation

struct ZikrNowPlayingSheet: View {
    let track: UnifiedTrack
    @ObservedObject var audio: ZikrAudioManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var progress: CGFloat = 0.0
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0.0
    @State private var showQueue = false
    private let progressUpdateInterval: TimeInterval = 0.5
    
    @StateObject private var vm = ZikrDBViewModel()
    
    // Use currentTrack from audio manager, fallback to initial track
    private var displayTrack: UnifiedTrack {
        audio.currentTrack ?? track
    }
    
    @Default(.zikr_favorited_tracks) private var favoritedTracks
    private var isFavorite: Bool {
        favoritedTracks.contains(track.url)
    }
    
    // Get current time and duration for display
    private var currentTime: String {
        guard let player = audio.player else { return "0:00" }
        let time = player.currentTime().seconds
        return formatTime(time)
    }
    
    private var duration: String {
        guard let player = audio.player,
              let currentItem = player.currentItem else { return "0:00" }
        let time = currentItem.duration.seconds
        guard time.isFinite && time > 0 else { return "0:00" }
        return formatTime(time)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Artwork - use displayTrack
                RoundedRectangle(cornerRadius: 16)
                    .fill(GenerateColorTheme.colors(seed: displayTrack.artist.id).art)
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                            .padding(60)
                    )
                    .id(displayTrack.id)

                // Track info - use displayTrack
                VStack(spacing: 4) {
                    Text(displayTrack.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                    Text(displayTrack.artist.name)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, 40)
                    
                    // Context indicator - tappable to show queue
                    if audio.loopMode == .context {
                        Button {
                            showQueue.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: audio.playbackContext.icon)
                                Text(audio.playbackContext.displayState(loopMode: audio.loopMode))
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                        .id("\(audio.playbackContext.rawValue)-\(audio.loopMode.rawValue)")
                    }
                }
                .id(displayTrack.id)
                
                // Progress bar with time labels and drag gesture
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: geo.size.width * (isDragging ? dragProgress : progress), height: 4)
                                .cornerRadius(2)
                                .animation(isDragging ? nil : .easeInOut(duration: 0.3), value: progress)
                            
                            // Draggable thumb
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: isDragging ? 12 : 0, height: isDragging ? 12 : 0)
                                .offset(x: geo.size.width * (isDragging ? dragProgress : progress) - (isDragging ? 6 : 0))
                                .animation(.easeInOut(duration: 0.15), value: isDragging)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newProgress = min(max(value.location.x / geo.size.width, 0), 1)
                                    dragProgress = newProgress
                                }
                                .onEnded { value in
                                    let finalProgress = min(max(value.location.x / geo.size.width, 0), 1)
                                    seekToProgress(finalProgress)
                                    isDragging = false
                                }
                        )
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    
                    // Time labels
                    HStack {
                        Text(currentTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                        Spacer()
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 40)
                }

                // Playback controls
                HStack(spacing: 40) {
                    Button {
                        audio.skipToPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                    }

                    Button {
                        audio.togglePlayPause()
                    } label: {
                        Image(systemName: audio.isPlaying && audio.currentTrack?.id == displayTrack.id ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.accentColor)
                    }
                    .id("\(audio.isPlaying)-\(displayTrack.id)")

                    Button {
                        audio.skipToNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                    }
                }
                
                HStack(spacing: 16) {
                    Button {
                        audio.cycleLoopMode()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: audio.loopMode.icon)
                            Text(audio.loopMode.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .id(audio.loopMode.rawValue)

                    Button {
                        vm.toggleFavorite(track: track)
                    } label: {
                        Label(isFavorite ? "Remove favorite" : "Add to favorites", systemImage: isFavorite ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(isFavorite ? .red : .orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .toolbar {
                ZikrMenu(track: displayTrack)
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showQueue) {
                QueueView(audio: audio)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                if audio.currentTrack?.id != track.id {
                    audio.playTrack(track: track)
                }
            }
            .onReceive(Timer.publish(every: progressUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
                guard !isDragging else { return }
                updateProgress()
            }
        }
    }
    
    private func updateProgress() {
        guard let player = audio.player, let currentItem = player.currentItem else {
            progress = 0
            return
        }
        let duration = currentItem.duration.seconds
        guard duration.isFinite && duration > 0 else {
            progress = 0
            return
        }
        let currentTime = player.currentTime().seconds
        progress = CGFloat(min(max(currentTime / duration, 0), 1))
    }
    
    private func seekToProgress(_ newProgress: CGFloat) {
        guard let player = audio.player,
              let currentItem = player.currentItem else { return }
        
        let duration = currentItem.duration.seconds
        guard duration.isFinite && duration > 0 else { return }
        
        let targetTime = duration * Double(newProgress)
        let cmTime = CMTime(seconds: targetTime, preferredTimescale: 600)
        
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            self.updateProgress()
        }
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        guard timeInSeconds.isFinite && timeInSeconds >= 0 else { return "0:00" }
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct QueueView: View {
    @ObservedObject var audio: ZikrAudioManager
    @Environment(\.dismiss) private var dismiss
    
    // Create a unique ID that changes when relevant state changes
    private var stateId: String {
        "\(audio.playbackContext.rawValue)-\(audio.loopMode.rawValue)-\(audio.currentTrack?.id.uuidString ?? "")"
    }
    
    private var currentQueue: [UnifiedTrack] {
        audio.getCurrentQueuePublic()
    }
    
    private var currentIndex: Int? {
        guard let current = audio.currentTrack else { return nil }
        return currentQueue.firstIndex(where: { $0.id == current.id })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if currentQueue.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No tracks in queue")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        // Queue header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: audio.playbackContext.icon)
                                Text(audio.playbackContext.rawValue)
                                Spacer()
                                Text("\(currentQueue.count) tracks")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            
                            // Loop mode display - always visible, updates with state
                            HStack(spacing: 6) {
                                Image(systemName: audio.loopMode.icon)
                                Text(audio.playbackContext.displayState(loopMode: audio.loopMode))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            .id(stateId) // Force update when state changes
                        }
                        
                        Divider()
                        
                        // Queue items
                        ForEach(Array(currentQueue.enumerated()), id: \.element.id) { index, track in
                            let isCurrentTrack = track.id == audio.currentTrack?.id
                            
                            Button {
                                audio.playTrack(track: track)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    // Position indicator or now playing icon
                                    if isCurrentTrack {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                            .frame(width: 24)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                    }
                                    
                                    // Artwork
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(GenerateColorTheme.colors(seed: track.artist.id).art)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        )
                                    
                                    // Track info
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .font(.body)
                                            .foregroundColor(isCurrentTrack ? .accentColor : .primary)
                                            .lineLimit(1)
                                        Text(track.artist.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Current track indicator
                                    if isCurrentTrack && audio.isPlaying {
                                        Image(systemName: "waveform")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(isCurrentTrack ? Color.accentColor.opacity(0.1) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            
                            if index < currentQueue.count - 1 {
                                Divider()
                                    .padding(.leading, 80)
                            }
                        }
                    }
                }
                .id(stateId) // Force entire view update when state changes
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
