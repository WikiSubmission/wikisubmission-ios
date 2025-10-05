import SwiftUI

extension Utilities.System {
    class GlobalAlertManager: ObservableObject {
        static let shared = GlobalAlertManager()
        
        @Published var alert: GlobalAlert? = nil
        
        private init() {}
        
        func showAlert(
            title: String,
            subtitle: String? = nil,
            systemImage: String = "exclamationmark.triangle",
            type: GlobalAlertType,
            showSettingsButton: Bool = false,
            showAppStoreButton: Bool = false
        ) {
            DispatchQueue.main.async {
                self.alert = GlobalAlert(
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage,
                    type: type,
                    showSettingsButton: showSettingsButton,
                    showAppStoreButton: showAppStoreButton
                )
            }
        }
    }

    struct GlobalAlert: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let systemImage: String
        let type: GlobalAlertType
        let showSettingsButton: Bool?
        let showAppStoreButton: Bool?
    }

    enum GlobalAlertType {
        case success
        case error
        case notice
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .notice: return .blue
            }
        }
    }
}
