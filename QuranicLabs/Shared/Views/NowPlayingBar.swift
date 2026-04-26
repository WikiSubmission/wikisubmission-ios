import SwiftUI
import Defaults

struct NowPlayingBar: View {
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject private var router = Router.shared
    @Environment(\.colorScheme) private var theme
    @Default(.active_tab) private var activeTab
    @State private var showNowPlayingSheet = false
    @State private var showLoopMenu = false
    @State private var keyboardVisible = false

    /// Collapse to just the artwork ring when in contexts that need more space
    private var shouldCollapse: Bool {
        // AI chat is pushed onto the quran path
        if activeTab == .quran && !router.quranPath.isEmpty {
            return true
        }
        return false
    }

    var body: some View {
        if let track = audio.currentTrack {
            VStack(spacing: 0) {
                Spacer()

                HStack {
                    if shouldCollapse {
                        collapsedPill
                        Spacer()
                    } else {
                        Spacer()
                        expandedCapsule(track: track)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 56)
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: audio.currentTrack != nil)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: shouldCollapse)
            .opacity(keyboardVisible ? 0 : 1)
            .sheet(isPresented: $showNowPlayingSheet) {
                NowPlayingSheet()
                    .presentationDragIndicator(.hidden)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeOut(duration: 0.15)) { keyboardVisible = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.15)) { keyboardVisible = false }
            }
        }
    }

    // MARK: - Expanded Capsule

    private func expandedCapsule(track: AudioTrack) -> some View {
        HStack(spacing: 0) {
            // Artwork + title + spacer -> opens sheet
            HStack(spacing: 8) {
                NowPlayingArtworkRing(audio: audio)

                Text(track.title)
                    .font(DS.Typography.label)
                    .foregroundStyle(DS.Color.fg)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Controls
            HStack(spacing: 4) {
                loopMenu

                controlButton(icon: "backward.fill", size: 12) {
                    audio.skipToPrevious()
                }

                controlButton(icon: audio.isPlaying ? "pause.fill" : "play.fill", size: 14) {
                    audio.togglePlayPause()
                }

                controlButton(icon: "forward.fill", size: 12) {
                    audio.skipToNext()
                }
                .opacity(audio.hasNextTrack ? 1 : 0.3)

                controlButton(icon: "xmark", size: 10) {
                    audio.dismiss()
                }
                .opacity(0.5)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .frame(height: 44)
        .background(
            Capsule()
                .fill(DS.Color.surface.opacity(theme == .dark ? 0.95 : 0.92))
        )
        .overlay(
            Capsule()
                .stroke(DS.Color.rule.opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(theme == .dark ? 0.35 : 0.1), radius: 12, y: 4)
        .contentShape(Capsule())
        .onTapGesture { showNowPlayingSheet = true }
    }

    // MARK: - Collapsed Pill (leading side)

    private var collapsedPill: some View {
        Button {
            showNowPlayingSheet = true
        } label: {
            NowPlayingArtworkRing(audio: audio)
                .padding(4)
                .background(
                    Capsule()
                        .fill(DS.Color.surface.opacity(theme == .dark ? 0.95 : 0.92))
                )
                .overlay(
                    Capsule()
                        .stroke(DS.Color.rule.opacity(0.4), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(theme == .dark ? 0.35 : 0.1), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .leading)),
            removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .leading))
        ))
    }

    // MARK: - Loop Menu

    private var loopMenu: some View {
        Button {
            showLoopMenu = true
        } label: {
            Image(systemName: audio.loopMode.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(audio.loopMode == .off ? DS.Color.fgMuted : Color.accentColor)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showLoopMenu, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(AudioLoopMode.allCases, id: \.self) { mode in
                    let isSelected = audio.loopMode == mode
                    Button {
                        audio.loopMode = mode
                        showLoopMenu = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: .medium))
                            Text(mode.actionText)
                                .font(DS.Typography.eyebrowSM)
                        }
                        .foregroundStyle(isSelected ? .white : DS.Color.fg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            isSelected
                            ? Capsule().fill(Color.accentColor)
                            : Capsule().fill(Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Control Button

    private func controlButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(DS.Color.fg)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Artwork Ring (isolated to avoid progress updates re-rendering parent)

private struct NowPlayingArtworkRing: View {
    let audio: AudioManager
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?

    private let size: CGFloat = 28
    private let ringWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: ringWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            artworkContent
                .frame(width: size - ringWidth * 2 - 2, height: size - ringWidth * 2 - 2)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var artworkContent: some View {
        Group {
            switch audio.category {
            case .quran:
                Image("wikisubmission")
                    .resizable()
                    .scaledToFill()
            case .music:
                let colorSeed = audio.currentTrack?.metadata?.colorSeed
                let colorTheme = MusicColorTheme.generate(seed: colorSeed)
                ZStack {
                    colorTheme.artworkGradient
                    Image(systemName: "music.note")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in updateProgress() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateProgress() {
        guard let player = audio.player,
              let duration = player.currentItem?.duration.seconds,
              duration.isFinite && duration > 0 else {
            progress = 0
            return
        }
        let current = player.currentTime().seconds
        progress = CGFloat(min(max(current / duration, 0), 1))
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        NowPlayingBar()
    }
}
