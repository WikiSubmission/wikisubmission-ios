import SwiftUI
import Defaults

struct QuranSettings_TransliterationToggle: View {
    @Default(.transliteration) private var transliteration
    var body: some View {
        Toggle("Transliteration", isOn: $transliteration)
    }
}
