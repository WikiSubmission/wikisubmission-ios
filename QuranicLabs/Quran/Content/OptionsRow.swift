import SwiftUI
import Defaults

struct Quran_Content_OptionsRow: View {
    @Binding var searchQuery: QuranQuery

    @State private var showBookmarks = false
    @State private var showHistory = false
    @State private var showNotifications = false

    @Default(.sort_chapters_by_revelation_order) private var sortByRevelationOrder

    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var router = Router.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.sm), count: 4)

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            // Now playing banner (spans full width when active)
            if audioManager.category == .quran, audioManager.isPlaying, let track = audioManager.currentTrack {
                Button {
                    router.selectTab(.quran)
                    router.navigate(to: .chapter(chapterNumber: Int(track.title.split(separator: ":")[0]) ?? 1, scrollToVerseNumber: Int(track.title.split(separator: ":")[1]) ?? 1))
                } label: {
                    Label("Playing: \(track.title)", systemImage: "waveform")
                        .font(DS.Typography.eyebrow)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SignatureButtonStyle())
            }

            // Icon grid
            LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
                tile(icon: "sparkles", label: "AI Chat") {
                    router.navigate(to: .ai)
                }
                tile(icon: "bookmark", label: "Bookmarks") {
                    showBookmarks = true
                }
                tile(icon: "dice", label: "Random") {
                    Router.shared.push(.randomVerse)
                }
                tile(icon: "clock.arrow.circlepath", label: "History") {
                    showHistory = true
                }
                tile(icon: "chart.bar.xaxis.ascending", label: "Insights") {
                    Router.shared.push(.insights)
                }
                tile(icon: "bell", label: "Alerts") {
                    showNotifications = true
                }
                tile(icon: "gearshape", label: "Settings") {
                    Router.shared.push(.settings)
                }
            }
        }
        .sheet(isPresented: $showBookmarks) {
            Quran_Content_Bookmarks()
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                Quran_Content_ReadingHistory()
            }
        }
        .sheet(isPresented: $showNotifications) {
            NavigationStack {
                Notifications()
            }
        }
    }

    private func tile(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(height: 24)
                Text(label)
                    .font(DS.Typography.eyebrowSM)
            }
            .foregroundStyle(.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
    }
}
