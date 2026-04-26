import SwiftUI
import Defaults

struct Home_QuranSection: View {
    @ObservedObject var router = Router.shared
    @ObservedObject var audioManager = AudioManager.shared

    @State private var showAppendices = false
    @State private var showNotifications = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.sm), count: 3)

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            SectionLabel("THE FINAL TESTAMENT")

            if audioManager.category == .quran, audioManager.isPlaying, let track = audioManager.currentTrack {
                Button {
                    router.selectTab(.quran)
                    router.navigate(to: .chapter(
                        chapterNumber: Int(track.title.split(separator: ":")[0]) ?? 1,
                        scrollToVerseNumber: Int(track.title.split(separator: ":")[1]) ?? 1
                    ))
                } label: {
                    Label("Playing: \(track.title)", systemImage: "waveform")
                        .font(DS.Typography.eyebrow)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SignatureButtonStyle())
            }

            QuranSearchBar()

            LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
                tile(icon: "book.closed", label: "Browse") {
                    router.selectTab(.quran)
                    router.popToRoot(for: .quran)
                }
                tile(icon: "bookmark", label: "Bookmarks") {
                    Router.shared.push(.bookmarks)
                }
                tile(icon: "text.page", label: "Appendices") {
                    showAppendices = true
                }
                tile(icon: "dice", label: "Random") {
                    router.popToRoot(for: .quran)
                    router.navigate(to: .randomVerse)
                }
                tile(icon: "clock.arrow.circlepath", label: "Activity") {
                    Router.shared.push(.readingHistory)
                }
                tile(icon: "bell", label: "Notifications") {
                    showNotifications = true
                }
            }
        }
        .removeParentListStyle()
        .sheet(isPresented: $showAppendices) {
            NavigationStack {
                Appendices()
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
                    .lineLimit(1)
            }
            .foregroundStyle(.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
    }
}
