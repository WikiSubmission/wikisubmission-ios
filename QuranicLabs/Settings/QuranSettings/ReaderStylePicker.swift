import SwiftUI
import Defaults

struct QuranSettings_ReaderStylePicker: View {
    @Default(.quran_reader_style) var quranReaderStyle

    var body: some View {
        Picker("Reading Style", selection: $quranReaderStyle) {
            ForEach(QuranReadingStyle.allCases, id: \.self) { style in
                Image(systemName: style.systemImage).tag(style)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct QuranSettings_ReaderStyle: View {
    @Default(.quran_reader_style) var quranReaderStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("READING STYLE: \(quranReaderStyle.rawValue.uppercased())")
                .font(DS.Typography.eyebrowSM)
                .tracking(1.5)
                .foregroundStyle(.secondary)

            QuranSettings_ReaderStylePicker()
        }
    }
}
