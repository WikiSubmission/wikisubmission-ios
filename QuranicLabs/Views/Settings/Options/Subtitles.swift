import SwiftUI
import Defaults

struct SubtitlesToggle: View {
    @Default(.subtitles) private var subtitles
    var body: some View {
        Toggle("Subtitles", isOn: $subtitles)
    }
}
