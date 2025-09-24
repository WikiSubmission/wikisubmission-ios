import SwiftUI
import Defaults

struct TransliterationToggle: View {
    @Default(.transliteration) private var transliteration
    var body: some View {
        Toggle("Transliteration", isOn: $transliteration)
    }
}
