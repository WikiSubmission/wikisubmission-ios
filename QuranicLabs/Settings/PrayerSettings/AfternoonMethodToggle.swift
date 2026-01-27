import SwiftUI
import Defaults

struct PrayerSettings_AfternoonMethodToggle: View {
    @Default(.prayer_times_use_midpoint_method_for_asr) private var afternoonMethod
    var body: some View {
        Toggle("Afternoon: use midpoint method", isOn: $afternoonMethod)
    }
}
