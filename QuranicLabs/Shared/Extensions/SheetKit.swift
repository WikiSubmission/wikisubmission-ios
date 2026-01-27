import SwiftUI
import SheetKit

extension SheetKit {
    func presentWithEnvironment<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        self.present {
            content()
        }
    }
}
