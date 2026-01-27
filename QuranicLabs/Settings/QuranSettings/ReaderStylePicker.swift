import SwiftUI
import Defaults

struct QuranSettings_ReaderStyle: View {
    @Default(.quran_reader_style) var quranReaderStyle
    
    var body: some View {
        BetterPicker(selection: $quranReaderStyle, previewLabel: "Reader Style", previewIcon: "character.book.closed") { style in
            HStack {
                Image(systemName: style.systemImage)
                Text(style.rawValue)
            }
        }
    }
}
