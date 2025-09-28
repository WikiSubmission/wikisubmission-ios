import SwiftUI
import Defaults

struct AsrMethodToggle: View {
    @Default(.use_midpoint_method_for_asr) private var useMidPointMethodForAsr
    var body: some View {
        Toggle("Use midpoint method for Asr prayer", isOn: $useMidPointMethodForAsr)
            .onChange(of: useMidPointMethodForAsr) { _, _ in
                Task {
                    try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                }
            }
    }
}
