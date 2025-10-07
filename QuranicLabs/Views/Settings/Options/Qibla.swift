import SwiftUI
import Defaults

struct QiblaToggle: View {
    @Default(.qibla_enabled) private var qibla
    var body: some View {
        Toggle("Qibla Finder", isOn: $qibla)
            .onChange(of: qibla) { _, enabled in
                if enabled == true {
                    Utilities.System.GlobalAlertManager.shared.showAlert(title: "Qibla Disclaimer", subtitle: "It's been enabled, but may be inaccurate for certain locations, especially outside of North America.\n\nWe're working to fix this, but may take some time. [Here](https://apps.apple.com/us/app/the-qiblah/id552231045) is an alternative application.", systemImage: "exclamationmark.triangle", type: .notice)
                }
            }
    }
}
