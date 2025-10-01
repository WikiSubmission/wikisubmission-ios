extension Types.Notifications {
    struct Notification: Encodable, Decodable {
        let platform: String?
        let device_token: String?
        let user_id: String?
        let prayer_time_notifications: Types.Notifications.NotificationPreferences<Types.Notifications.Customizations.PrayerTimeCustomization>?
        let daily_verse_notifications: Types.Notifications.NotificationPreferences<Types.Notifications.Customizations.NoCustomization>?
        let daily_chapter_notifications: Types.Notifications.NotificationPreferences<Types.Notifications.Customizations.NoCustomization>?
    }
}
