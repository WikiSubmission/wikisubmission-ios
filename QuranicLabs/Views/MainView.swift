import SwiftUI
import Defaults

struct MainView: View {
    @Default(.onboarded) private var onboarded
    
    var body: some View {
        if onboarded {
            TabsView()
        } else {
            FirstTimeView()
        }
    }
}

#Preview {
    MainView()
}
