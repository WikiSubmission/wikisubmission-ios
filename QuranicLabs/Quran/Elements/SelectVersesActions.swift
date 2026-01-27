import SwiftUI

struct Quran_Element_SelectVersesActions: View {
    var selectMode: QuranSelectMode
    var toolbarMode: Bool = false
    
    @Environment(\.colorScheme) var theme
    
    var body: some View {
        if toolbarMode {
            // Toolbar-friendly layout
            HStack(spacing: 0) {
                Button {
                    let text = selectMode.selection
                        .map { $0.formatToText() }
                        .joined(separator: "\n\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    shareText(text)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            selectMode.reset()
                            selectMode.canSelect = true
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.accent)
                        .offset(y: -2)
                }
            }
        } else {
            // Original floating layout
            ZStack {
                HStack {
                    Button {
                        let text = selectMode.selection
                            .map { $0.formatToText() }
                            .joined(separator: "\n\n")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        shareText(text)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                selectMode.reset()
                                selectMode.canSelect = true
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundStyle(.accent)
                            .fontWeight(.bold)
                            .frame(width: 56, height: 56)
                            .background(theme == .dark ? .white : .black)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
