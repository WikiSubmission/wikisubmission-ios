import Defaults

extension Defaults.Keys {
    static let device_token = Key<String?>("device_token", default: nil)

    static let prayer_notifications = Key<Bool>("prayer_notifications", default: false)
    static let fajr_notification = Key<Bool>("fajr_notification", default: true)
    static let dhuhr_notification = Key<Bool>("dhuhr_notification", default: true)
    static let asr_notification = Key<Bool>("asr_notification", default: true)
    static let maghrib_notification = Key<Bool>("maghrib_notification", default: true)
    static let isha_notification = Key<Bool>("isha_notification", default: true)
    static let prayer_time_location = Key<String?>("prayer_time_location", default: nil)
}
