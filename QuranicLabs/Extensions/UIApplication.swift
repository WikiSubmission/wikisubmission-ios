import SwiftUI

extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        if let nav = baseVC as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = baseVC?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return baseVC
    }
}
