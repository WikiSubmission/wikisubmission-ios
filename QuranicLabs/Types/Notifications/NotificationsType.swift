extension Types.Notifications {
    struct Notification: Encodable, Decodable {
        let device_token: String?
        let updated_at: String?
        let prayer_times_notifications: Types.Notifications.PrayerTimesSettings
        let daily_verse_notifications: Bool
        let daily_chapter_notifications: Bool
        let announcement_notifications: Bool
    }
    
    struct PrayerTimesSettings: Encodable, Decodable {
        let enabled: Bool
        let location: String?
        let fajr: Bool
        let dhuhr: Bool
        let asr: Bool
        let mahgrib: Bool
        let isha: Bool
        let sunrise: Bool
        let use_midpoint_method_for_asr: Bool
    }
}
