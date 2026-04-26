import SwiftUI
import Defaults

extension Defaults.Keys {
    static let whats_new_last_seen_version = Key<String?>("whats_new_last_seen_version", default: nil)
    static let whats_new_last_seen_at = Key<Date?>("whats_new_last_seen_at", default: nil)
    static let whats_new_auto_presented_version = Key<String?>("whats_new_auto_presented_version", default: nil)
}

#Preview {
    Main()
        .modelContainer(for: [
            QuranChaptersSD.self,
            QuranFootnotesSD.self,
            QuranIndexSD.self,
            QuranSubtitlesSD.self,
            QuranTextSD.self,
            QuranWordByWordSD.self
        ])
}

struct Home: View {

    @ObservedObject var router = Router.shared
    @Environment(\.colorScheme) private var theme
    @State private var appeared = false

    @State private var whatsNewIsPresented = false
    private let whatsNewVersion = "3.17"
    @Default(.whats_new_last_seen_version) private var whatsNewLastSeenVersion
    @Default(.whats_new_last_seen_at) private var whatsNewLastSeenAt
    @Default(.whats_new_auto_presented_version) private var whatsNewAutoPresentedVersion

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .home)) {
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DS.Spacing.section) {
                        titleSection
                            .padding(.horizontal)
                            .overlay(
                                AmbientRibbonsView()
                                    .frame(height: 300)
                                    .mask(
                                        LinearGradient(
                                            stops: [
                                                .init(color: .black, location: 0),
                                                .init(color: .black, location: 0.5),
                                                .init(color: .clear, location: 1)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .allowsHitTesting(false)
                            )
                            .zIndex(1)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)

                        Home_QuranSection()
                            .padding()
                            .background(
                                Color.secondary.opacity(theme == .dark ? 0.10 : 0.06)
                                    .padding(.top, -500)
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        Card(title: "Ask AI", options: .action(
                            subtitle: "Chat about Submission, scripture, or a verse reference.",
                            systemImage: "sparkles",
                            showChevron: true,
                            style: .default
                        ) {
                            router.navigate(to: .ai)
                        })
                        .padding(.horizontal)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)

                        Home_PrayerSection()
                            .padding()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 28)

                        Home_MusicSection()
                            .padding()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 36)

                        VStack(spacing: DS.Spacing.section) {
                            Home_SupportWikiSubmissionSection()
                            Home_FooterSection()
                        }
                        .padding()
                        .background(
                            Color.accent.opacity(theme == .dark ? 0.10 : 0.06)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
                                .padding(.bottom, -500)
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 44)
                    }
                    .frame(width: geo.size.width)
                }
                .contentShape(Rectangle())
                .onAppear {
                    guard !appeared else { return }
                    withAnimation(.easeOut(duration: 0.8)) {
                        appeared = true
                    }
                    autoPresentWhatsNewIfNeeded()
                }
                .sheet(isPresented: $whatsNewIsPresented) {
                    WhatsNew()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .onDisappear {
                            markWhatsNewViewed()
                        }
                }
            }
        }
    }

    private var shouldShowWhatsNewEntry: Bool {
        guard About.version == whatsNewVersion else { return false }
        guard whatsNewLastSeenVersion == whatsNewVersion,
              let lastSeen = whatsNewLastSeenAt else {
            return true
        }
        return Date().timeIntervalSince(lastSeen) < 30 * 24 * 60 * 60
    }

    private func autoPresentWhatsNewIfNeeded() {
        guard About.version == whatsNewVersion else { return }
        guard whatsNewAutoPresentedVersion != whatsNewVersion else { return }

        whatsNewAutoPresentedVersion = whatsNewVersion
        whatsNewIsPresented = true
    }

    private func markWhatsNewViewed() {
        whatsNewLastSeenVersion = whatsNewVersion
        whatsNewLastSeenAt = Date()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<21: return "GOOD EVENING"
        default: return "PEACE BE UPON YOU"
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            VStack(spacing: DS.Spacing.xs) {
                Image("wikisubmission")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .padding(.bottom, 4)
                    .pushToLeft()
                Text(greeting)
                    .font(DS.Typography.eyebrow)
                    .tracking(3)
                    .pushToLeft()
            }
            .foregroundStyle(.secondary)

            if shouldShowWhatsNewEntry {
                Button {
                    whatsNewIsPresented = true
                } label: {
                    Text("WHAT'S NEW →")
                        .font(DS.Typography.eyebrowSM)
                        .tracking(3)
                        .foregroundStyle(.accent)
                }
                .pushToLeft()
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .zIndex(2)
            }

            InAppNoticesBanner()
        }
        .removeParentListStyle()
    }
}

struct WhatsNew: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("What’s New")
                        .font(DS.Typography.heroMD)
                    Text("Here are a list of updates in this version (\(About.version)):")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: DS.Spacing.md) {
                    whatsNewCard(
                        title: "Activity log and insights",
                        subtitle: "A new structured activity timeline tracks your reading sessions with lifecycle events, and insights surfaces streaks, charts, and chapter breakdowns.",
                        systemImage: "chart.bar.xaxis.ascending"
                    )
                    whatsNewCard(
                        title: "Refreshed music experience",
                        subtitle: "Browse by category, featured cards, a dedicated favorites page, and genre labels on every track.",
                        systemImage: "music.note"
                    )
                    whatsNewCard(
                        title: "AI chat (limited early preview)",
                        subtitle: "Ask broader questions across the app. Early preview.",
                        systemImage: "sparkles"
                    )
                    whatsNewCard(
                        title: "English Quran recitation",
                        subtitle: "Our first English recitation, Onyx, is now available as the default Quran voice.",
                        systemImage: "waveform"
                    )
                    whatsNewCard(
                        title: "Daily reminders and prayer sounds",
                        subtitle: "Daily reminder notifications are on by default. You can also choose a call to prayer sound for prayer alerts.",
                        systemImage: "bell.badge"
                    )
                    whatsNewCard(
                        title: "Refined design",
                        subtitle: "An editorial visual theme with custom typography across the app.",
                        systemImage: "paintpalette"
                    )
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 1)
                        .padding(.vertical, DS.Spacing.xs)
                    discordFooter
                    Image("wikisubmission")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }

    private func whatsNewCard(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 38, height: 38)

                Image(systemName: systemImage)
                    .foregroundStyle(.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DS.Typography.label)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(DS.Typography.bodySM)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Color.surface)
        )
    }

    private var discordFooter: some View {
        Link(destination: URL(string: About.developerDiscordLink)!) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                HStack(alignment: .top, spacing: DS.Spacing.md) {
                    Image("discord")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Join our Discord")
                            .font(DS.Typography.label)
                            .foregroundStyle(.primary)

                        Text("We're working 24/7 to improve this app for you. Your feedback is welcome!")
                            .font(DS.Typography.eyebrowSM)
                            .foregroundStyle(.secondary)
                    }
                }

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)

                HStack {
                    Spacer()

                    HStack(spacing: 6) {
                        Text("Open")
                            .font(DS.Typography.eyebrow)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.accent)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ambient Ribbons

private struct Ribbon: Identifiable {
    let id = UUID()
    let hueShift: Double
    let width: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double
    let rotationStart: Double
    let rotationEnd: Double
    let scaleRange: (CGFloat, CGFloat)
    let xAnchor: CGFloat
    let yAnchor: CGFloat
}

private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.15),
            control1: CGPoint(x: w * 0.08, y: h * 0.1),
            control2: CGPoint(x: w * 0.25, y: h * 0.0)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.7),
            control1: CGPoint(x: w * 0.45, y: h * 0.3),
            control2: CGPoint(x: w * 0.5, y: h * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.4),
            control1: CGPoint(x: w * 0.8, y: h * 0.55),
            control2: CGPoint(x: w * 0.92, y: h * 0.2)
        )
        return path
    }
}

private struct AmbientRibbonsView: View {
    @State private var phase = false
    @State private var dragOffset: CGSize = .zero
    @State private var touchPoint: CGPoint? = nil

    private let ribbons: [Ribbon] = (0..<5).map { i in
        Ribbon(
            hueShift: Double(i) * 0.07,
            width: CGFloat.random(in: 1.5...3),
            opacity: Double.random(in: 0.1...0.2),
            duration: Double.random(in: 14...22),
            delay: Double(i) * 0.4,
            rotationStart: Double.random(in: -4...0),
            rotationEnd: Double.random(in: 0...4),
            scaleRange: (0.97, 1.03),
            xAnchor: CGFloat.random(in: 0.3...0.7),
            yAnchor: CGFloat.random(in: 0.3...0.7)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let dragMagnitude = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
            let interactivity = min(dragMagnitude / 120, 1.0)

            ForEach(Array(ribbons.enumerated()), id: \.element.id) { i, r in
                let parallax = CGFloat(i + 1) / CGFloat(ribbons.count + 1)
                let boostedOpacity = r.opacity + (0.4 * interactivity * Double(parallax))
                let boostedWidth = r.width + (2.0 * interactivity * parallax)

                RibbonShape()
                    .stroke(
                        .accent.opacity(boostedOpacity),
                        style: StrokeStyle(lineWidth: boostedWidth, lineCap: .round)
                    )
                    .frame(width: geo.size.width * 1.8, height: geo.size.height * 0.7)
                    .rotationEffect(
                        .degrees(phase ? r.rotationEnd : r.rotationStart),
                        anchor: UnitPoint(x: r.xAnchor, y: r.yAnchor)
                    )
                    .scaleEffect(
                        x: 1.0,
                        y: phase ? r.scaleRange.1 : r.scaleRange.0
                    )
                    .offset(
                        x: -geo.size.width * 0.2 + dragOffset.width * parallax,
                        y: (phase ? geo.size.height * 0.01 : -geo.size.height * 0.01) + dragOffset.height * parallax
                    )
                    .animation(
                        .easeInOut(duration: r.duration)
                        .repeatForever(autoreverses: true)
                        .delay(r.delay),
                        value: phase
                    )
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.55), value: dragOffset)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    touchPoint = value.location
                    dragOffset = CGSize(
                        width: value.translation.width * 0.4,
                        height: value.translation.height * 0.4
                    )
                }
                .onEnded { _ in
                    touchPoint = nil
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.4)) {
                        dragOffset = .zero
                    }
                }
        )
        .onAppear { phase = true }
    }
}
