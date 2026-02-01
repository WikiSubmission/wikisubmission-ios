import SwiftUI
import Defaults

struct QuranSettings_ArabicFontPicker: View {
    @Default(.quran_arabic_font) var arabicFont

    var body: some View {
        NavigationLink {
            ArabicFontPickerContent(selection: $arabicFont)
        } label: {
            HStack {
                Label("Arabic Font", systemImage: "textformat")
                Spacer()
                Text(arabicFont.rawValue)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ArabicFontPickerContent: View {
    @Binding var selection: QuranArabicFont
    @Environment(\.dismiss) private var dismiss

    private let previewText = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"

    var body: some View {
        List {
            Section {
                ForEach(QuranArabicFont.allCases, id: \.self) { font in
                    Button {
                        selection = font
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        HStack {
                            Text(font.rawValue)
                            Spacer()
                            if font == selection {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("PREVIEW") {
                Text(previewText)
                    .font(selection.font(size: 28))
                    .multilineTextAlignment(.center)
                    .pushToCenter()
            }
            .removeParentListStyle()
        }
        .navigationTitle("Arabic Font")
        .navigationBarTitleDisplayMode(.inline)
    }
}
