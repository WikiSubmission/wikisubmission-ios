import SwiftUI
import Defaults

struct Quran_Content_OptionsRow: View {
    @Binding var searchQuery: QuranQuery
    
    @Default(.sort_chapters_by_revelation_order) private var sortByRevelationOrder

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
                        }
                        .buttonStyle(SignatureButtonStyle())
                    }
                }
            }
            .font(.caption)
        }
    }
}
