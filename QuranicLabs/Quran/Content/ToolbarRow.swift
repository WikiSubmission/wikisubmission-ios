import SwiftUI

struct Quran_Content_ToolbarRow: View {
    var body: some View {
        HStack(spacing: 0) {
            NavigationLink {
                Quran_Content_Bookmarks()
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
    }
}
