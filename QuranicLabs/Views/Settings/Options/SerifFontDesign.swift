import SwiftUI
import Defaults

struct UseSerifFontDesignToggle: View {
    @Default(.use_serif_font_design) private var useSerifFontDesign
    var body: some View {
        Toggle("Use Serif Font", isOn: $useSerifFontDesign)
    }
}
