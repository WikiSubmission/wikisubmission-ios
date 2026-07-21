import Defaults

extension Defaults.Keys {
    static let device_token = Key<String?>("device_token", default: nil)
    
    static let notifications = Key<Bool>("notifications", default: true)
    static let prayer_notifications = Key<Bool>("prayer_notifications", default: false)
    static let fajr_notification = Key<Bool>("fajr_notification", default: true)
    static let dhuhr_notification = Key<Bool>("dhuhr_notification", default: true)
    static let asr_notification = Key<Bool>("asr_notification", default: true)
    static let maghrib_notification = Key<Bool>("maghrib_notification", default: true)
    static let isha_notification = Key<Bool>("isha_notification", default: true)
    static let sunrise_notification = Key<Bool>("sunrise_notification", default: true)
    static let prayer_notification_sound = Key<String>("prayer_notification_sound", default: "default")

    static let random_verse_notifications = Key<Bool>("random_verse_notifications", default: true)
    static let daily_reminders_notifications = Key<Bool>("daily_reminders_notifications", default: true)
    static let daily_chapter_notifications = Key<Bool>("daily_chapter_notifications", default: false)
    
    static let daily_chapter = Key<Int?>("daily_chapter", default: nil)
    static let daily_verse = Key<String?>("daily_verse", default: nil)
    
    static let announcement_notifications = Key<Bool>("announcement_notifications", default: true)

    /// Whether the salat countdown Live Activity is enabled.
    static let prayer_live_activity = Key<Bool>("prayer_live_activity", default: false)

    /// Per-activity APNs push token for the current Live Activity window.
    static let live_activity_push_token = Key<String?>("live_activity_push_token", default: nil)

    /// App-wide APNs push-to-start token, letting the server chain prayer
    /// windows without the app opening.
    static let live_activity_push_to_start_token = Key<String?>("live_activity_push_to_start_token", default: nil)
}
