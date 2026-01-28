import SwiftUI

struct Quran_Content_ToolbarRow: View {
    var body: some View {
        HStack {
            Button {
                Router.shared.push(.randomVerse)
            } label: {
                Image(systemName: "sparkles")
            }

            Quran_Element_QuickSettings()
        }
    }
}
