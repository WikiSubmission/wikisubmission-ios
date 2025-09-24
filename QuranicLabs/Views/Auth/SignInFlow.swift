import SwiftUI
import Clerk

struct SignInFlow: View {
    var body: some View {
        AuthView()
    }
}

#Preview {
    SignInFlow()
        .environmentObject(AppEnvironment.shared)
}
