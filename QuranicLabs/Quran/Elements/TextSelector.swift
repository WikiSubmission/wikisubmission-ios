import SwiftUI
import AlertKit

struct Quran_Element_TextSelector: View {
    let verse: QuranUnified
    @State private var text: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    init(verse: QuranUnified) {
        self.verse = verse
        self._text = State(initialValue: verse.formatToText())
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.body)
                .padding()
                .navigationTitle(verse.index.verse_id)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFocused = true
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            UIPasteboard.general.string = text
                            AlertKitAPI.present(
                                title: "Copied",
                                icon: .done,
                                style: .iOS17AppleMusic,
                                haptic: .success
                            )
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
        }
    }
}
