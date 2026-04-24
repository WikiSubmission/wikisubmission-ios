import SwiftUI

struct QuranSettings_PreviewVerse: View {
    @State private var isExpanded = false
    @Environment(\.modelContext) var modelContext
    @ObservedObject private var quranDataManager = QuranDataManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    Label("Preview Verse", systemImage: "eye")
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded && quranDataManager.isReady,
               let verse = QuranUnified.fetchVerse(byId: "2:20", context: modelContext) {
                Quran_Element_VerseCard(
                    unified: verse,
                    options: .init(
                        unformatted: true,
                        disableInteractiveElements: true,
                        hideBookmarkStatus: true
                    )
                )
                .padding(.top, 12)
            }
        }
    }
}
