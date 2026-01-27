import Foundation
import Defaults

extension Defaults.Keys {
    /// Cached prayer times API response
    static let prayer_times = Key<PrayerAPIResponse?>("prayer_times", default: nil)

    /// User's saved location string for prayer times lookup
    static let prayer_times_location = Key<String?>("prayer_times_location", default: nil)

    /// Last successful fetch timestamp (for cache validation)
    static let prayer_times_last_fetch = Key<Date?>("prayer_times_last_fetch", default: nil)

    /// Use midpoint method for Asr calculation
    static let prayer_times_use_midpoint_method_for_asr = Key<Bool>("use_midpoint_method_for_asr", default: false)
}

extension Defaults {
    /// Reset all prayer-related preferences
    static func resetPrayerPreferences() {
        Defaults.Keys.prayer_times.reset()
        Defaults.Keys.prayer_times_location.reset()
        Defaults.Keys.prayer_times_last_fetch.reset()
        Defaults.Keys.prayer_times_use_midpoint_method_for_asr.reset()
    }
}
