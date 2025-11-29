import SwiftUI
import Defaults

struct MainView: View {
    @Default(.onboarded) private var onboarded
    @ObservedObject private var audio = ZikrAudioManager.shared

    var body: some View {
        if onboarded {
            ZStack {
                TabsView()
                QuranNowPlayingBar()
                if audio.currentTrack != nil {
                    ZikrNowPlayingBar(audio: audio)
                }
            }
        } else {
            FirstTimeView()
        }
    }
}

#Preview {
    MainView()
}
