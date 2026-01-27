import SwiftUI
import Defaults

struct QuranSettings_ArabicToggle: View {
    @Default(.arabic) private var arabic
    var body: some View {
        Toggle("Arabic", isOn: $arabic)
    }
}
