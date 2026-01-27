import SwiftUI
import Defaults

struct QuranSettings_ReciterPicker: View {
    @Default(.quran_reciter) var quranReciter

    @ObservedObject var audioManager = AudioManager.shared
    
    var body: some View {
        BetterPicker(selection: $quranReciter, previewLabel: "Reciter", previewIcon: "waveform.path") { reciter in
            HStack {
                Text(reciter.displayName)
            }
        }
        .onChange(of: quranReciter) { _, newReciter in
            audioManager.updateReciter(newReciter)
        }
    }
}
