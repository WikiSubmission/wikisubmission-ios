import SwiftUI
import SheetKit

struct ZikrMenu: View {
    let track: UnifiedTrack
       
    var body: some View {
        Menu {
            Button {
                SheetKit().present {
                    WebView(url: URL(string: "\(track.url)")!)
                }
            } label: {
                Label("Download file", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.accent)
        }
    }
}
