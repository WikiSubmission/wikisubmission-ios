import SwiftUI
import Defaults

struct Quran_Content_OptionsRowTwo: View {
    @Binding var searchQuery: QuranQuery

    @State private var showBookmarks = false
    @State private var showHistory = false

    @Default(.sort_chapters_by_revelation_order) private var sortByRevelationOrder

    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var router = Router.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if searchQuery.query.isEmpty {
                    HStack {
                        Button {
                            withAnimation {
                                sortByRevelationOrder.toggle()
                            }
                        } label: {
                            Label(sortByRevelationOrder ? "Revelation Order" : "Standard Order", systemImage: "arrow.up.and.down")
                                .font(DS.Typography.eyebrow)
                        }
                        .buttonStyle(SignatureButtonStyle())
                    }
                }
            }
            .font(.caption)
        }
        .sheet(isPresented: $showBookmarks) {
            Quran_Content_Bookmarks()
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                Quran_Content_ReadingHistory()
            }
        }
    }
}
