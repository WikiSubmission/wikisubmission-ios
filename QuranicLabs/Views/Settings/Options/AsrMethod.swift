import SwiftUI
import Defaults

struct AsrMethodToggle: View {
    @Default(.use_midpoint_method_for_asr) private var use_midpoint_method_for_asr
    var body: some View {
        Toggle("Use midpoint method for Asr prayer", isOn: $use_midpoint_method_for_asr)
    }
}
