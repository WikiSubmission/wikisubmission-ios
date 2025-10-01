extension Types.Notifications {
    struct NotificationPreferences<T: Codable>: Codable {
        let enabled: Bool
        let customization: T
    }
}
