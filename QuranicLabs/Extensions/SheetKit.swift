import SwiftUI
import SheetKit
import Clerk

extension SheetKit {
    func presentWithEnvironment<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        self.present {
            content()
                .environmentObject(AppEnvironment.shared)
                .environment(\.clerk, Clerk.shared)
        }
    }
}
