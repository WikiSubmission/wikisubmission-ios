import SwiftUI
import Defaults

struct ArabicToggle: View {
    @Default(.arabic) private var arabic
    var body: some View {
        Toggle("Arabic", isOn: $arabic)
    }
}
