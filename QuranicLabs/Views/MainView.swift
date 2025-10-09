import SwiftUI
import Defaults

struct MainView: View {
    @Default(.onboarded) private var onboarded
    
    var body: some View {
        if onboarded {
            ZStack {
                TabsView()
                QuranNowPlayingBar()
                ZikrNowPlayingBar()
            }
        } else {
            FirstTimeView()
        }
    }
}

#Preview {
    MainView()
}
