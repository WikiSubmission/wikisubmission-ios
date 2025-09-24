import SwiftUI
import Defaults

struct FontSizeSelector: View {
    @Default(.font_size) var fontSize
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Font Size: \(Int(fontSize))pt", systemImage: "textformat.size")
            
            Slider(value: Binding(
                get: { fontSize },
                set: { newValue in
                    // haptic feedback
                    if Int(newValue) != Int(fontSize) {
                        feedbackGenerator.impactOccurred()
                    }
                    fontSize = newValue
                }
            ), in: 10...30, step: 1)
            .foregroundStyle(.secondary)
            .onAppear {
                feedbackGenerator.prepare()
            }
        }
    }
}
