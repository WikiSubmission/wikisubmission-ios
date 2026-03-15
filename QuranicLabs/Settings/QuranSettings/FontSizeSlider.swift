import SwiftUI
import Defaults

struct QuranSettings_FontSizeSlider: View {
    @Default(.font_size) var fontSize
    @Default(.arabic_font_size) var arabicFontSize
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sizeRow(
                label: "Translation",
                systemImage: "textformat.size",
                value: $fontSize,
                range: 10...30
            )

            Divider()

            sizeRow(
                label: "Arabic",
                systemImage: "character",
                value: $arabicFontSize,
                range: 12...40
            )
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
    }

    private func sizeRow(label: String, systemImage: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("\(label): \(Int(value.wrappedValue))pt", systemImage: systemImage)
                .font(.subheadline)

            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { newValue in
                    if Int(newValue) != Int(value.wrappedValue) {
                        feedbackGenerator.impactOccurred()
                    }
                    value.wrappedValue = newValue
                }
            ), in: range, step: 1)
            .foregroundStyle(.secondary)
        }
    }
}
