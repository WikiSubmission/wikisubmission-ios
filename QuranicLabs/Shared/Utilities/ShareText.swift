import Foundation
import SwiftUI

func shareText(_ text: String) {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else { return }

    let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)

    // Find the topmost presented view controller to present from
    var topController = rootViewController
    while let presented = topController.presentedViewController {
        topController = presented
    }

    topController.present(activityViewController, animated: true)
}
