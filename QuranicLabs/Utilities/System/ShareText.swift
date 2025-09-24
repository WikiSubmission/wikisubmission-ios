import Foundation
import SwiftUI

extension Utilities.System {
    static func shareText(_ text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        windowScene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}
