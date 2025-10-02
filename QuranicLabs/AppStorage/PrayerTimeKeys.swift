import Defaults

extension Defaults.Keys {
    static let use_midpoint_method_for_asr = Key<Bool>("use_midpoint_method_for_asr", default: false)
}

extension Defaults {
    static func resetPrayerTimeSettings() {
        Defaults.Keys.use_midpoint_method_for_asr.reset()
    }
}
