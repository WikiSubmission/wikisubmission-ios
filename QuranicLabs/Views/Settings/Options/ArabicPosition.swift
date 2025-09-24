import SwiftUI
import Defaults

struct ArabicPositionToggle: View {
    @Default(.arabic_on_side) private var arabicOnSide
    var body: some View {
        Toggle("Arabic On Side", isOn: $arabicOnSide)
    }
}
