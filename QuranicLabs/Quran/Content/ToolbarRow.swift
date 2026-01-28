import SwiftUI

struct Quran_Content_ToolbarRow: View {
    @State private var showBookmarks = false

    var body: some View {
        HStack {
            Button {
                showBookmarks = true
            } label: {
                Image(systemName: "bookmark")
            }

            Button {
                Router.shared.push(.randomVerse)
            } label: {
                Image(systemName: "sparkles")
            }

            Quran_Element_QuickSettings()
        }
        .sheet(isPresented: $showBookmarks) {
            Quran_Content_Bookmarks()
        }
    }
}
