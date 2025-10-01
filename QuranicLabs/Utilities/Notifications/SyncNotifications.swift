import Defaults
import Clerk

extension Utilities.Notifications {
    static func syncWithDatabase() async throws {
        guard let deviceToken = Defaults[.device_token] else {
            print("Failed to update ws-notifications table: no device token found")
            return
        }
        
        do {
            try await Utilities.Supabase.anonClient
                .from("ws-notifications")
                .upsert(Types.Notifications.Notification(
                    platform: "ios",
                    device_token: deviceToken,
                    user_id: Clerk.shared.user?.id ?? nil,
                    prayer_time_notifications: .init(
                        enabled: Defaults[.prayer_notifications],
                        customization: .init(
                            location: Defaults[.prayer_time_location],
                            fajr: Defaults[.fajr_notification],
                            dhuhr: Defaults[.dhuhr_notification],
                            asr: Defaults[.asr_notification],
                            mahgrib: Defaults[.maghrib_notification],
                            isha: Defaults[.isha_notification],
                            use_midpoint_method_for_asr: Defaults[.use_midpoint_method_for_asr]
                        )
                    ),
                    daily_verse_notifications: .init(
                        enabled: Defaults[.random_verse_notifications],
                        customization: .init()
                    ),
                    daily_chapter_notifications: .init(
                        enabled: Defaults[.random_chapter_notifications],
                        customization: .init()
                    )
                ),
                        onConflict: "device_token"
                )
                .execute()
        } catch {
            print("Error updating ws-notifications table:", error.localizedDescription)
            throw error
        }
    }
}
