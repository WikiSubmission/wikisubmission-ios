import SwiftUI
import Defaults

struct QuranSettings_WordByWordToggle: View {
    @Default(.word_by_word) private var wordByWord
    @Default(.arabic) private var arabic

    var body: some View {
        Toggle("Word by word", isOn: $wordByWord)
            .onChange(of: wordByWord) { _, on in
                if on && !arabic {
                    arabic = true
                }
            }
    }
}
