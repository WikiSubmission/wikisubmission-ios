import SwiftUI
import Defaults

struct Quran_Element_SearchHistory: View {

    @Binding var searchQuery: QuranQuery

    @Default(.quran_search_history) var quranSearchHistory

    @State private var showReturnHint = false
    @State private var hintTask: Task<Void, Never>?

    private var hasUnsubmittedQuery: Bool {
        !searchQuery.rawInput.isEmpty && searchQuery.query.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            // Return to search hint - only show after delay when query exists but not submitted
            if showReturnHint {
                HStack(spacing: 4) {
                    Text("Press")
                    Image(systemName: "return")
                    Text("to search")
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Search history
            if quranSearchHistory.filter({ $0 != searchQuery.query && !$0.isEmpty }).count > 0 {
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
        .onChange(of: hasUnsubmittedQuery) { _, hasQuery in
            hintTask?.cancel()
            if hasQuery {
                hintTask = Task {
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showReturnHint = true
                        }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showReturnHint = false
                }
            }
        }
    }
}
