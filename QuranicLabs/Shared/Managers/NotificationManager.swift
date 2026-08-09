import SwiftUI
import Defaults
import UserNotifications

enum NotificationTables: String {
    case user
    case prayerTimes
    case dailyReminders
    case randomVerse
    case announcements
    
    var tableName: String {
        switch self {
        case .user:
            return "ws_push_notifications_users"
        case .prayerTimes:
            return "ws_push_notifications_registry_prayer_times"
        case .dailyReminders:
            return "ws_push_notifications_registry_daily_reminders"
        case .randomVerse:
            return "ws_push_notifications_registry_random_verse"
        case .announcements:
            return "ws_push_notifications_registry_announcements"
        }
    }
}

@MainActor
class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()

    func sync(_ tables: [NotificationTables]? = nil) async throws {
        guard let deviceToken = Defaults[.device_token] else {
            // No stored APNs token yet: re-trigger registration so we obtain one (which
            // calls sync again on success) rather than silently giving up until next launch.
            print("No device token – requesting registration")
            NotificationManager.registerForPushNotificationsIfNeeded()
            return
        }

        do {
        let session = try await SupabaseManager.shared.requireSession()
        let user = session.user

        // Sync user table first (registry tables have foreign key on device_token)
        try await syncPushNotificationUser(
            deviceToken: deviceToken,
            userId: user.id,
            table: .user
        )

        // Then sync registry tables in parallel
        await withTaskGroup(of: Void.self) { group in
            if tables == nil || (tables?.contains(.prayerTimes) == true) {
                group.addTask {
                    do {
                        try await self.syncPushNotificationsRegistryPrayerTimes(
                            deviceToken: deviceToken,
                            userId: user.id,
                            table: .prayerTimes
                        )
                    } catch {
                        print("Notification sync error (prayerTimes): \(error)")
                    }
                }
            }
            if tables == nil || (tables?.contains(.dailyReminders) == true) {
                group.addTask {
                    do {
                        try await self.syncPushNotificationsRegistryDailyReminders(
                            deviceToken: deviceToken,
                            userId: user.id,
                            table: .dailyReminders
                        )
                    } catch {
                        print("Notification sync error (dailyReminders): \(error)")
                    }
                }
            }
            if tables == nil || (tables?.contains(.randomVerse) == true) {
                group.addTask {
                    do {
                        try await self.syncPushNotificationsRegistryRandomVerse(
                            deviceToken: deviceToken,
                            userId: user.id,
                            table: .randomVerse
                        )
                    } catch {
                        print("Notification sync error (randomVerse): \(error)")
                    }
                }
            }
            if tables == nil || (tables?.contains(.announcements) == true) {
                group.addTask {
                    do {
                        try await self.syncPushNotificationsRegistryAnnouncements(
                            deviceToken: deviceToken,
                            userId: user.id,
                            table: .announcements
                        )
                    } catch {
                        print("Notification sync error (announcements): \(error)")
                    }
                }
            }
        }

        Defaults[.last_sync_at] = Date()
        Defaults[.last_sync_error] = nil
        } catch {
            // Record the failure so it is visible in the notifications screen instead of
            // being swallowed by the caller's `try?`.
            Defaults[.last_sync_error] = "\(error)"
            throw error
        }
    }

    /// Syncs only the prayer times registry (plus the parent user row for the FK) and
    /// rethrows on failure, unlike `sync(_:)` which swallows per-table errors. Callers use
    /// the thrown error to decide whether the resolved location was actually persisted.
    func syncPrayerTimesRegistry() async throws {
        guard let deviceToken = Defaults[.device_token] else {
            print("No device token – requesting registration")
            NotificationManager.registerForPushNotificationsIfNeeded()
            return
        }

        let session = try await SupabaseManager.shared.requireSession()
        let user = session.user

        // User row must exist first (registry tables have a foreign key on device_token).
        try await syncPushNotificationUser(
            deviceToken: deviceToken,
            userId: user.id,
            table: .user
        )

        try await syncPushNotificationsRegistryPrayerTimes(
            deviceToken: deviceToken,
            userId: user.id,
            table: .prayerTimes
        )
    }

    static func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    static func registerForPushNotificationsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                Task { @MainActor in
                    if UserDefaults.standard.bool(forKey: Defaults.Keys.prompted_for_notifications.name) {
                        registerForPushNotifications()
                    }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied, .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func syncPushNotificationUser(deviceToken: String, userId: UUID, table: NotificationTables) async throws {
        let payload = PushNotificationsUser(
            user_id: userId,
            updated_at: Date().ISO8601Format(),
            device_token: deviceToken,
            platform: "ios",
            version: About.version,
            enabled: Defaults[.notifications]
        )
        
        try await SupabaseManager.client
            .schema("internal")
            .from(table.tableName)
            .upsert(payload, onConflict: "device_token")
            .execute()
        
        print("Synced ws_push_notifications_users")
    }
    
    private func syncPushNotificationsRegistryPrayerTimes(deviceToken: String, userId: UUID, table: NotificationTables) async throws {
        let payload = PushNotificationsRegistryPrayerTimes(
            user_id: userId,
            updated_at: Date().ISO8601Format(),
            device_token: deviceToken,
            enabled: Defaults[.prayer_notifications],
            location: Defaults[.prayer_times]?.location_string ?? Defaults[.prayer_times_location],
            afternoon_midpoint_method: Defaults[.prayer_times_use_midpoint_method_for_asr],
            notification_sound: Defaults[.prayer_notification_sound],
            dawn: Defaults[.fajr_notification],
            noon: Defaults[.dhuhr_notification],
            afternoon: Defaults[.asr_notification],
            sunset: Defaults[.maghrib_notification],
            night: Defaults[.isha_notification],
            sunrise: Defaults[.sunrise_notification]
        )
        
        try await SupabaseManager.client
            .schema("internal")
            .from(table.tableName)
            .upsert(payload, onConflict: "device_token")
            .execute()
        
        print("Synced ws_push_notifications_registry_prayer_times")
    }
    
    private func syncPushNotificationsRegistryDailyReminders(deviceToken: String, userId: UUID, table: NotificationTables) async throws {
        let payload = PushNotificationsRegistryDailyReminders(
            user_id: userId,
            updated_at: Date().ISO8601Format(),
            device_token: deviceToken,
            enabled: Defaults[.daily_reminders_notifications]
        )
        
        try await SupabaseManager.client
            .schema("internal")
            .from(table.tableName)
            .upsert(payload, onConflict: "device_token")
            .execute()
        
        print("Synced ws_push_notifications_registry_daily_reminders")
    }
    
    private func syncPushNotificationsRegistryRandomVerse(deviceToken: String, userId: UUID, table: NotificationTables) async throws {
        let payload = PushNotificationsRegistryRandomVerse(
            user_id: userId,
            updated_at: Date().ISO8601Format(),
            device_token: deviceToken,
            enabled: Defaults[.random_verse_notifications]
        )
        
        try await SupabaseManager.client
            .schema("internal")
            .from(table.tableName)
            .upsert(payload, onConflict: "device_token")
            .execute()
        
        print("Synced ws_push_notifications_registry_random_verse")
    }
    
    private func syncPushNotificationsRegistryAnnouncements(deviceToken: String, userId: UUID, table: NotificationTables) async throws {
        let payload = PushNotificationsRegistryAnnouncements(
            user_id: userId,
            updated_at: Date().ISO8601Format(),
            device_token: deviceToken,
            enabled: Defaults[.announcement_notifications]
        )
        
        try await SupabaseManager.client
            .schema("internal")
            .from(table.tableName)
            .upsert(payload, onConflict: "device_token")
            .execute()
        
        print("Synced ws_push_notifications_registry_announcements")
    }
}
