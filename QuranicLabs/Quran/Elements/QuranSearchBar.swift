import SwiftUI

struct QuranSearchBar: View {
    @ObservedObject private var router = Router.shared
    @Environment(\.colorScheme) private var theme

    var placeholder: String = "Search chapter, verse, or text"
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            if showIcon {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
            }
            Text(placeholder)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            router.selectTab(.quran)
            router.popToRoot(for: .quran)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.openQuranSearchBar = true
            }
        }
    }
}

#Preview {
    VStack {
        QuranSearchBar()
        QuranSearchBar(placeholder: "Chapter, verse, or text")
    }
    .padding()
}
