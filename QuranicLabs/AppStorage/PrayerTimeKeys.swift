import Defaults

extension Defaults.Keys {
    static let use_midpoint_method_for_asr = Key<Bool>("use_midpoint_method_for_asr", default: false)
    
    static let calculate_qibla_from_north_america = Key<Bool>("calculate_qibla_from_north_america", default: true)
}

extension Defaults {
    static func resetPrayerTimeSettings() {
        Defaults.Keys.use_midpoint_method_for_asr.reset()
    }
}
