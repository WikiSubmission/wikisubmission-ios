import SwiftUI
import Defaults

struct FootnotesToggle: View {
    @Default(.footnotes) private var footnotes
    var body: some View {
        Toggle("Footnotes", isOn: $footnotes)
    }
}
