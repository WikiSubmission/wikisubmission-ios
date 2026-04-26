import SwiftUI
import MediaPlayer
import AVKit

struct NowPlayingSheet: View {
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var router = Router.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var progress: CGFloat = 0.0
    @State private var isScrubbing = false
    @State private var currentTimeSeconds: Double = 0
    @State private var durationSeconds: Double = 0
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
        audio.category == .music && audio.queueCount > 1
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
        }
        .onReceive(Timer.publish(every: progressUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
            if !isScrubbing {
                updateProgress()
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            DS.Color.bg
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.accentColor.opacity(colorScheme == .dark ? 0.18 : 0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
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
                        .font(selectedTab == tab ? DS.Typography.label : DS.Typography.caption)
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
        let compactHeight = geometry.size.height < 760
        let artworkSize = min(
            geometry.size.width - (compactHeight ? 152 : 112),
            compactHeight ? 182 : 232,
            geometry.size.height * (compactHeight ? 0.22 : 0.28)
        )

        return VStack(spacing: compactHeight ? 14 : 20) {
            Spacer(minLength: compactHeight ? 4 : 12)
            artwork(size: artworkSize)
            trackInfo
            progressSection
            mainControls(compact: compactHeight)

            VStack(spacing: compactHeight ? 10 : 14) {
                volumeSection
                secondaryControls
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in }
            )

            Spacer(minLength: compactHeight ? 10 : 20)
        }
        .padding(.horizontal, compactHeight ? 20 : 24)
        .padding(.top, compactHeight ? 8 : 14)
        .padding(.bottom, 20)
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
                HStack(spacing: 6) {
                    Text(track.subtitle)
                        .font(DS.Typography.eyebrow)
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let categoryName = track.metadata?.categoryName {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(categoryName)
                            .font(DS.Typography.eyebrow)
                            .tracking(1.5)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Text(track.title)
                    .font(DS.Typography.heroMD)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
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
                        .fill(progressFill)
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
                    .font(DS.Typography.eyebrowSM)
                    .monospacedDigit()
                    .foregroundColor(.secondary)

                Spacer()

                Text("-\(formatTime(durationSeconds - currentTimeSeconds))")
                    .font(DS.Typography.eyebrowSM)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Main Controls

    private func mainControls(compact: Bool) -> some View {
        HStack(spacing: compact ? 36 : 50) {
            Button {
                audio.skipToPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: compact ? 24 : 30))
                    .foregroundColor(.primary)
            }
            .disabled(!audio.hasPreviousTrack)
            .opacity(audio.hasPreviousTrack ? 1 : 0.35)

            Button {
                audio.togglePlayPause()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: compact ? 58 : 68))
                    .foregroundColor(.accentColor)
            }

            Button {
                audio.skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: compact ? 24 : 30))
                    .foregroundColor(.primary)
            }
            .disabled(!audio.hasNextTrack)
            .opacity(audio.hasNextTrack ? 1 : 0.35)
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
            Button {
                audio.cycleLoopMode()
            } label: {
                controlBadge(
                    title: audio.loopMode.displayName,
                    symbol: audio.loopMode.icon,
                    tint: audio.loopMode == .off ? .secondary : .accentColor
                )
            }
            .buttonStyle(.plain)

            AirPlayButton()
                .frame(width: 24, height: 24)
                .frame(minWidth: 54)

            if audio.category == .music, let track = audio.currentTrack {
                Button {
                    shareText("https://wikisubmission.org/music?track=\(track.id.lowercased())")
                } label: {
                    controlBadge(
                        title: "Share",
                        symbol: "square.and.arrow.up",
                        tint: .secondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
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
                                    .font(DS.Typography.titleSM)
                                    .lineLimit(1)
                                Text(track.subtitle)
                                    .font(DS.Typography.caption)
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
                                        .font(DS.Typography.eyebrow)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(1.5)
                                        .padding(.top, 8)
                                }

                                ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                                    Text(line)
                                        .font(DS.Typography.titleMD)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Up Next")
                            .font(DS.Typography.titleLG)
                        Text("\(audio.queue.count) tracks • \(audio.queueSourceLabel)")
                            .font(DS.Typography.caption)
                            .foregroundColor(.secondary)
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
                        .font(isCurrent ? DS.Typography.label : DS.Typography.bodySM)
                        .foregroundColor(isCurrent ? .accentColor : .primary)
                        .lineLimit(1)

                    Text(track.subtitle)
                        .font(DS.Typography.caption)
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

    private var progressFill: LinearGradient {
        LinearGradient(colors: [.accentColor, .accentColor], startPoint: .leading, endPoint: .trailing)
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

    private func metaPill(_ text: String, systemImage: String, accented: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(text)
                .font(DS.Typography.eyebrowSM)
        }
        .foregroundStyle(accented ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.08))
        )
    }

    private func controlBadge(title: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: title == "Loop" ? audio.loopMode.rawValue : symbol)

            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 54)
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
