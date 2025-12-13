import SwiftUI
import Defaults
import UIKit

#Preview {
    MainView()
}

struct ZikrView: View {
    @StateObject private var vm = ZikrDBViewModel()
    @ObservedObject private var audio = ZikrAudioManager.shared
    @Default(.zikr_favorited_tracks) private var favoritedTracks

    @State private var isRefreshing: Bool = false
    @State private var lastFetchDate: Date? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
            }
            .requiresInternet(reason: "An internet connection is required")
            .toolbar {
                NavigationLink {
                    ZikrFavoritesView()
                } label: {
                    Image(systemName: favoritedTracks.isEmpty ? "heart" : "heart.fill")
                        .foregroundColor(.red)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .overlay(alignment: .center) {
                if isRefreshing && vm.tracks.isEmpty {
                    ProgressView()
                }
            }
            .onAppear {
                if let last = lastFetchDate {
                    if Date().timeIntervalSince(last) > 10 {
                        Task { await performRefresh() }
                    }
                } else {
                    Task { await performRefresh() }
                }
            }
            .onChange(of: favoritedTracks) { _, newFavorites in
                audio.favoriteTrackUrls = newFavorites
            }
            .refreshable {
                await performRefresh()
            }
            .navigationTitle("Zikr")
        }
    }
    
    private func performRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await vm.fetchFromDB()
        updateAudioManager()
        lastFetchDate = Date()
    }
    
    private func updateAudioManager() {
        audio.allTracks = vm.tracks
        audio.favoriteTrackUrls = favoritedTracks
    }

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                if !vm.tracks.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.accent)
                            .font(.caption)
                        Text("The list is frequently updated over time. The copyrights for all materials are retained by the original holders.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.leading)
                }
                
                if vm.tracks.isEmpty && !isRefreshing {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Pull to refresh")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    featuredSection
                    tracksSection
                }
            }
            .padding(.bottom, 200)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.featured.isEmpty {
                HStack {
                    Text("Featured")
                        .font(.title2.bold())
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(vm.featured.sorted { $0.releaseDate > $1.releaseDate }) { t in
                            ZikrFeaturedCard(track: t) {
                                audio.playTrack(track: t, context: .category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 160)
            }
        }
        .padding(.horizontal)
    }

    private var tracksSection: some View {
        VStack(spacing: 8) {
            ForEach(vm.categories.sorted { $1.displayPriority < $0.displayPriority }, id: \.self) { category in
                let tracksInCategory = vm.tracks.filter { $0.category.id == category.id }
                if !tracksInCategory.isEmpty {
                    HStack {
                        Text(category.name).font(.title2.bold())
                        Spacer()
                    }
                    .padding(.horizontal)

                    LazyVStack(spacing: 4) {
                        ForEach(tracksInCategory.sorted { $0.releaseDate > $1.releaseDate }) { track in
                            ZikrTrackRow(
                                track: track,
                                isPlaying: audio.currentTrack?.id == track.id && audio.isPlaying
                            ) {
                                audio.playTrack(track: track, context: .category)
                            }
                            .padding(4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
            }
        }
    }
}

struct ZikrFeaturedCard: View {
    let track: UnifiedTrack
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14).fill(GenerateColorTheme.colors(seed: track.artist.id).card)
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "music.quarternote.3")
                        .padding(.bottom)
                    Text(track.title).font(.headline).lineLimit(2)
                    Text(track.artist.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(width: 260, height: 150)
        }
        .buttonStyle(.plain)
    }
}

struct ZikrTrackRow: View {
    let track: UnifiedTrack
    let isPlaying: Bool
    let action: () -> Void
    
    @Default(.zikr_favorited_tracks) private var favoritedTracks
    
    private var isFavorite: Bool {
        favoritedTracks.contains(track.url)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Main tappable area
            Button(action: action) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(GenerateColorTheme.colors(seed: track.artist.id).art)
                            .frame(width: 56, height: 56)
                        Image(systemName: isPlaying ? "pause.circle.fill" : "music.note")
                            .font(.system(size: 24))
                            .foregroundColor(isPlaying ? .accentColor : .secondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.body)
                            .lineLimit(2)
                        Text(track.artist.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Favorite button - directly toggle Defaults
            Button {
                var fav = Defaults[.zikr_favorited_tracks]
                if fav.contains(track.url) {
                    fav.removeAll { $0 == track.url }
                } else {
                    fav.append(track.url)
                }
                Defaults[.zikr_favorited_tracks] = fav
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .accentColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPlaying ? Color(.accent.opacity(0.1)) : Color(.gray.opacity(0.03)))
                .padding(-4)
        )
    }
}

struct GenerateColorTheme {
    let card: LinearGradient   // gradient used for larger rounded cards
    let art: LinearGradient    // gradient used for artwork / thumbnail backgrounds
    let accent: Color          // accent color for highlights

    static func colors(seed: UUID?) -> GenerateColorTheme {
            // base hue from UUID (0..1)
            let baseHue: Double
            var seedVal: UInt64 = 0
            if let seed = seed {
                let hex = seed.uuidString.replacingOccurrences(of: "-", with: "")
                let prefix = String(hex.prefix(16)) // grab more entropy
                seedVal = UInt64(prefix, radix: 16) ?? 0
                baseHue = Double(seedVal % 360) / 360.0
            } else {
                baseHue = 0.58
                seedVal = 0xDEADBEEF
            }

            // Helper: produce a deterministic offset in [0,1) from seed bits + an index
            func offset(_ idx: Int, spreadDegrees: Double) -> CGFloat {
                // pull different slices of the seedVal for variance
                let shift = UInt64(idx * 8)
                let chunk = UInt32((seedVal >> shift) & 0xFF)
                // map 0..255 -> -spread/2 .. +spread/2 degrees, then to fraction of circle
                let deg = (Double(chunk) / 255.0 - 0.5) * spreadDegrees
                let hue = fmod(baseHue + deg / 360.0 + 1.0, 1.0)
                return CGFloat(hue)
            }

            // Helper: produce saturation/brightness tuned by seed bits
            func sat(_ idx: Int, base: CGFloat, variance: CGFloat) -> CGFloat {
                let chunk = UInt32((seedVal >> UInt64(idx * 7)) & 0x7F) // 0..127
                let frac = CGFloat(chunk) / 127.0
                return min(max(base + (frac - 0.5) * variance, 0.12), 0.98)
            }
            func bright(_ idx: Int, lightBase: CGFloat, darkBase: CGFloat, variance: CGFloat) -> (CGFloat, CGFloat) {
                let chunk = UInt32((seedVal >> UInt64(idx * 9 + 3)) & 0x7F)
                let frac = CGFloat(chunk) / 127.0
                let light = min(max(lightBase + (frac - 0.5) * variance, 0.05), 0.99)
                let dark  = min(max(darkBase  + (frac - 0.5) * variance, 0.05), 0.99)
                return (light, dark)
            }

            // Create dynamic UIColor-backed Color for a hue index with light/dark brightness
            func colorFor(h: CGFloat, s: CGFloat, brightLight: CGFloat, brightDark: CGFloat) -> Color {
                return Color(UIColor { trait in
                    let brightness = (trait.userInterfaceStyle == .dark) ? brightDark : brightLight
                    return UIColor(hue: h, saturation: s, brightness: brightness, alpha: 1)
                })
            }

            // Build multi-stop gradients with distinct stops
            // Card: subtle, slightly desaturated triadic-ish gradient
            let hCard1 = offset(0, spreadDegrees: 30)
            let hCard2 = offset(1, spreadDegrees: 50)
            let hCard3 = offset(2, spreadDegrees: 80)
            let sCard1 = sat(0, base: 0.22, variance: 0.20)
            let sCard2 = sat(1, base: 0.30, variance: 0.28)
            let (cardLight, cardDark) = bright(0, lightBase: 0.97, darkBase: 0.12, variance: 0.12)
            let cardC1 = colorFor(h: hCard1, s: sCard1, brightLight: cardLight, brightDark: cardDark)
            let cardC2 = colorFor(h: hCard2, s: sCard2, brightLight: cardLight * 0.96, brightDark: cardDark * 1.06)
            let cardC3 = colorFor(h: hCard3, s: max(sCard1, sCard2) * 0.85, brightLight: cardLight * 0.92, brightDark: cardDark * 1.12)
            let cardGradient = LinearGradient(
                gradient: Gradient(colors: [cardC1, cardC2, cardC3]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Art: richer, more saturated, higher contrast
            let hArt1 = offset(3, spreadDegrees: 90)
            let hArt2 = offset(4, spreadDegrees: 140)
            let sArt1 = sat(2, base: 0.62, variance: 0.30)
            let sArt2 = sat(3, base: 0.72, variance: 0.22)
            let (artLight, artDark) = bright(1, lightBase: 0.92, darkBase: 0.22, variance: 0.18)
            let artC1 = colorFor(h: hArt1, s: sArt1, brightLight: artLight, brightDark: artDark)
            let artC2 = colorFor(h: hArt2, s: sArt2, brightLight: artLight * 0.96, brightDark: artDark * 1.08)
            let artGradient = LinearGradient(
                gradient: Gradient(colors: [artC1, artC2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Accent: pick a vivid complementary / contrasting hue
            let accentHue = CGFloat(fmod((Double(offset(5, spreadDegrees: 120)) + 0.5), 1.0)) // push ~180deg complementary
            let accentSat = sat(4, base: 0.86, variance: 0.18)
            let (accentLight, accentDark) = bright(2, lightBase: 0.72, darkBase: 0.88, variance: 0.10)
            let accentColor = Color(UIColor { trait in
                let brightness = (trait.userInterfaceStyle == .dark) ? accentDark : accentLight
                return UIColor(hue: accentHue, saturation: accentSat, brightness: brightness, alpha: 1)
            })

            return GenerateColorTheme(card: cardGradient, art: artGradient, accent: accentColor)
        }
}
