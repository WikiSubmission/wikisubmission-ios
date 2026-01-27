import SwiftUI
import Defaults

struct QuranSettings_FootnotesToggle: View {
    @Default(.footnotes) private var footnotes
    var body: some View {
        Toggle("Footnotes", isOn: $footnotes)
    }
}
