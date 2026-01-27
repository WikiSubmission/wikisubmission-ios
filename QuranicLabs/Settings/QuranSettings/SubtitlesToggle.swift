import SwiftUI
import Defaults

struct QuranSettings_SubtitlesToggle: View {
    @Default(.subtitles) private var subtitles
    var body: some View {
        Toggle("Subtitles", isOn: $subtitles)
    }
}
