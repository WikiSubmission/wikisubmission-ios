extension Types.Notifications {
    struct Customizations {
        struct NoCustomization: Encodable, Decodable {}
        
        struct PrayerTimeCustomization: Encodable, Decodable {
            let location: String?
            let fajr: Bool
            let dhuhr: Bool
            let asr: Bool
            let mahgrib: Bool
            let isha: Bool
            let use_midpoint_method_for_asr: Bool
        }
    }
}
