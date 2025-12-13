import Defaults

extension Defaults.Keys {
    static let device_token = Key<String?>("device_token", default: nil)
    
    static let prayer_notifications = Key<Bool>("prayer_notifications", default: false)
    static let fajr_notification = Key<Bool>("fajr_notification", default: true)
    static let dhuhr_notification = Key<Bool>("dhuhr_notification", default: true)
    static let asr_notification = Key<Bool>("asr_notification", default: true)
    static let maghrib_notification = Key<Bool>("maghrib_notification", default: true)
    static let isha_notification = Key<Bool>("isha_notification", default: true)
    static let sunrise_notification = Key<Bool>("sunrise_notification", default: true)

    static let daily_verse_notifications = Key<Bool>("daily_verse_notifications", default: false)
    static let daily_chapter_notifications = Key<Bool>("daily_chapter_notifications", default: false)
    
    static let daily_chapter = Key<Int?>("daily_chapter", default: nil)
    static let daily_verse = Key<String?>("daily_verse", default: nil)
    
    static let announcement_notifications = Key<Bool>("announcement_notifications", default: true)
}
