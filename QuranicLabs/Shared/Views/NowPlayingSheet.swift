import SwiftUI
import MediaPlayer
import AVKit

struct NowPlayingSheet: View {
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var router = Router.shared
    @Environment(\.dismiss) private var dismiss

    @State private var progress: CGFloat = 0.0
    @State private var isScrubbing = false
    @State private var currentTimeSeconds: Double = 0
    @State private var durationSeconds: Double = 0
    @State private var volume: Float = AVAudioSession.sharedInstance().outputVolume
    @State private var selectedTab: Tab = .nowPlaying

    private let progressUpdateInterval: TimeInterval = 0.25

    enum Tab: String, CaseIterable {
        case nowPlaying = "Now Playing"
        case lyrics = "Lyrics"
        case queue = "Queue"
    }

    private var theme: MusicColorTheme {
        MusicColorTheme.generate(seed: audio.currentTrack?.metadata?.colorSeed)
    }

    private var hasLyrics: Bool {
        audio.category == .music && audio.currentTrack?.metadata?.lyrics != nil
    }

    private var showQueue: Bool {
        audio.loopMode == .queue
    }

    private var availableTabs: [Tab] {
        var tabs: [Tab] = [.nowPlaying]
        if hasLyrics {
            tabs.append(.lyrics)
        }
        if showQueue {
            tabs.append(.queue)
        }
        return tabs
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                background

                VStack(spacing: 0) {
                    // Drag indicator
                    dragIndicator

                    // Tab picker
                    tabPicker

                    // Content
                    TabView(selection: $selectedTab) {
                        nowPlayingContent(geometry: geometry)
                            .tag(Tab.nowPlaying)

                        if hasLyrics {
                            lyricsContent
                                .tag(Tab.lyrics)
                        }

                        if showQueue {
                            queueContent
                                .tag(Tab.queue)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .onAppear {
            updateProgress()
            setupVolumeObserver()
        }
        .onReceive(Timer.publish(every: progressUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
            if !isScrubbing {
                updateProgress()
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        Group {
            if audio.category == .music {
                theme.cardGradient
                    .ignoresSafeArea()
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.1))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Now Playing Content

    private func nowPlayingContent(geometry: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Artwork
                artwork(size: min(geometry.size.width - 80, 320))

                // Track info
                trackInfo

                // Progress
                progressSection

                // Main controls
                mainControls

                // Volume
                volumeSection

                // Secondary controls
                secondaryControls

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - Artwork

    private func artwork(size: CGFloat) -> some View {
        Group {
            switch audio.category {
            case .quran:
                Image("wikisubmission")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            case .music:
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.artworkGradient)

                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.35))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: size, height: size)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(spacing: 6) {
            if let track = audio.currentTrack {
                Text(track.title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(track.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 8) {
            // Scrubber
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.primary.opacity(0.15))

                    // Progress fill
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: max(geo.size.width * progress, 0))
                }
                .frame(height: isScrubbing ? 8 : 6)
                .animation(.easeOut(duration: 0.1), value: isScrubbing)
                .contentShape(Rectangle().inset(by: -20))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let newProgress = min(max(value.location.x / geo.size.width, 0), 1)
                            progress = newProgress
                            currentTimeSeconds = durationSeconds * Double(newProgress)
                        }
                        .onEnded { value in
                            let finalProgress = min(max(value.location.x / geo.size.width, 0), 1)
                            audio.seek(to: Double(finalProgress))
                            isScrubbing = false
                        }
                )
            }
            .frame(height: 8)

            // Time labels
            HStack {
                Text(formatTime(currentTimeSeconds))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)

                Spacer()

                Text("-\(formatTime(durationSeconds - currentTimeSeconds))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Main Controls

    private var mainControls: some View {
        HStack(spacing: 50) {
            // Previous
            Button {
                audio.skipToPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.primary)
            }

            // Play/Pause
            Button {
                audio.togglePlayPause()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.primary)
            }

            // Next
            Button {
                audio.skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Volume Section

    private var volumeSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VolumeSlider()
                .frame(height: 6)
                .frame(maxWidth: .infinity)
                .offset(y: -5)
                .tint(.primary)

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
        }
        .padding(.horizontal)
    }

    // MARK: - Secondary Controls

    private var secondaryControls: some View {
        HStack(spacing: 36) {
            // Loop mode
            Button {
                audio.cycleLoopMode()
            } label: {
                Image(systemName: audio.loopMode.icon)
                    .font(.title3)
                    .foregroundColor(audio.loopMode == .off ? .secondary : .accentColor)
                    .symbolEffect(.bounce, value: audio.loopMode)
            }

            // AirPlay
            AirPlayButton()
                .frame(width: 24, height: 24)

            // Share
            if audio.category == .music, let track = audio.currentTrack {
                Button {
                    shareText("https://wikisubmission.org/music?track=\(track.id.lowercased())")
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .offset(y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lyrics Content

    private var lyricsContent: some View {
        ScrollView(showsIndicators: false) {
            if let lyrics = audio.currentTrack?.metadata?.lyrics {
                VStack(spacing: 24) {
                    // Mini artwork and track info
                    HStack(spacing: 12) {
                        miniArtwork

                        VStack(alignment: .leading, spacing: 2) {
                            if let track = audio.currentTrack {
                                Text(track.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(track.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Lyrics
                    VStack(alignment: .center, spacing: 20) {
                        ForEach(parseLyrics(lyrics)) { section in
                            VStack(spacing: 12) {
                                if let header = section.header {
                                    Text(header)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(1.5)
                                        .padding(.top, 8)
                                }

                                ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                                    Text(line)
                                        .font(.title3)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.primary.opacity(0.9))
                                }
                            }
                        }
                    }
                    .textSelection(.enabled)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 80)
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Queue Content

    private var queueContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Queue header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Up Next")
                                .font(.title2.bold())
                            Text("\(audio.queue.count) tracks")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Loop mode indicator
                        HStack(spacing: 6) {
                            Image(systemName: audio.loopMode.icon)
                                .font(.caption)
                            Text(audio.loopMode.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(audio.loopMode == .off ? .secondary : .accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.primary.opacity(0.1)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // Queue list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(audio.queue.enumerated()), id: \.element.id) { index, track in
                            queueRow(track: track, index: index)
                                .id("queue-\(track.id)")
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .onAppear {
                scrollToCurrentTrack(proxy: proxy)
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .queue {
                    scrollToCurrentTrack(proxy: proxy)
                }
            }
        }
    }

    private func scrollToCurrentTrack(proxy: ScrollViewProxy) {
        if let currentId = audio.currentTrack?.id {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo("queue-\(currentId)", anchor: .center)
                }
            }
        }
    }

    private func queueRow(track: AudioTrack, index: Int) -> some View {
        let isCurrent = track.id == audio.currentTrack?.id

        return Button {
            audio.playTrack(at: index)
            // Scroll to track on Music page
            if audio.category == .music, let uuid = UUID(uuidString: track.id) {
                router.musicScrollToTrackId = uuid
            }
        } label: {
            HStack(spacing: 14) {
                // Index or playing indicator
                Group {
                    if isCurrent && audio.isPlaying {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .symbolEffect(.variableColor.iterative, isActive: true)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 24)

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? .accentColor : .primary)
                        .lineLimit(1)

                    Text(track.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mini Artwork

    private var miniArtwork: some View {
        Group {
            switch audio.category {
            case .quran:
                Image("wikisubmission")
                    .resizable()
                    .scaledToFill()
            case .music:
                ZStack {
                    theme.artworkGradient
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func updateProgress() {
        guard let player = audio.player, let currentItem = player.currentItem else {
            progress = 0
            currentTimeSeconds = 0
            durationSeconds = 0
            return
        }
        let duration = currentItem.duration.seconds
        guard duration.isFinite && duration > 0 else {
            progress = 0
            currentTimeSeconds = 0
            durationSeconds = 0
            return
        }
        let currentTime = player.currentTime().seconds
        progress = CGFloat(min(max(currentTime / duration, 0), 1))
        currentTimeSeconds = currentTime
        durationSeconds = duration
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func setupVolumeObserver() {
        // Initial volume
        volume = AVAudioSession.sharedInstance().outputVolume
    }

    private func parseLyrics(_ raw: String) -> [LyricSection] {
        var sections: [LyricSection] = []
        var currentHeader: String? = nil
        var currentLines: [String] = []

        let lines = raw.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                if !currentLines.isEmpty || currentHeader != nil {
                    sections.append(LyricSection(
                        header: currentHeader,
                        lines: currentLines.filter { !$0.isEmpty }
                    ))
                }
                currentHeader = String(trimmed.dropFirst().dropLast())
                currentLines = []
            } else if !trimmed.isEmpty {
                currentLines.append(trimmed)
            } else if !currentLines.isEmpty {
                currentLines.append("")
            }
        }

        if !currentLines.isEmpty || currentHeader != nil {
            sections.append(LyricSection(
                header: currentHeader,
                lines: currentLines.filter { !$0.isEmpty }
            ))
        }

        return sections
    }
}

// MARK: - Lyric Section

private struct LyricSection: Identifiable {
    let id = UUID()
    let header: String?
    let lines: [String]
}

// MARK: - Volume Slider (using MPVolumeView)

private struct VolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsRouteButton = false

        // Style the slider
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumTrackTintColor = UIColor.label
            slider.maximumTrackTintColor = UIColor.label.withAlphaComponent(0.15)
            slider.thumbTintColor = UIColor.label
        }

        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

// MARK: - AirPlay Button (using AVRoutePickerView)

private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePicker = AVRoutePickerView()
        routePicker.tintColor = UIColor.secondaryLabel
        routePicker.activeTintColor = UIColor.tintColor
        routePicker.prioritizesVideoDevices = false
        return routePicker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

#Preview {
    NowPlayingSheet()
}
