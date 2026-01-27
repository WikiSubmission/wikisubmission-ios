import SwiftUI
import Defaults

struct Quran_Element_SearchHistory: View {
    
    @Binding var searchQuery: QuranQuery
    
    @Default(.quran_search_history) var quranSearchHistory
    
    var body: some View {
        VStack {
            if quranSearchHistory.filter({ $0 != searchQuery.query }).count > 0 {
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(quranSearchHistory.filter { $0 != searchQuery.query && !$0.isEmpty }, id: \.self) { i in
                                Button {
                                    searchQuery.query = i
                                    searchQuery.rawInput = i
                                } label: {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                            .foregroundStyle(.accent)
                                        Text(i)
                                            .font(.caption2)
                                    }
                                }
                                .buttonStyle(SignatureButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            quranSearchHistory.removeAll { $0 == i }
                                        }
                                    } label: {
                                        Label("Delete Entry", systemImage: "trash")
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                    Button {
                        withAnimation {
                            searchQuery.clearHistory()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.accent)
                            .padding(.trailing, 8)
                    }
                }
            }
        }
    }
}
