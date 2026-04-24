import SwiftUI

struct Quran_Element_SelectVersesTrigger: View {
    var selectMode: QuranSelectMode
    @Environment(\.colorScheme) var theme

    private let toolbarMode: Bool

    init(selectMode: QuranSelectMode, toolbarContext: Bool = false) {
        self.selectMode = selectMode
        self.toolbarMode = toolbarContext
    }

    var body: some View {
        if toolbarMode {
            toolbarButton
        } else {
            floatingButton
        }
    }

    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if selectMode.selection.count > 0 {
                    Quran_Element_SelectVersesActions(selectMode: selectMode, toolbarMode: toolbarMode)
                }

                Button {
                    toggleSelectMode()
                } label: {
                    Image(systemName: selectMode.isActive ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(theme == .dark ? Color.secondary : Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbarButton: some View {
        Button {
            toggleSelectMode()
        } label: {
            Image(systemName: selectMode.isActive ? "checkmark.circle.fill" : "checklist")
        }
    }

    private func toggleSelectMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectMode.isActive.toggle()
                if !selectMode.isActive {
                    selectMode.selection.removeAll()
                }
            }
    }
}
