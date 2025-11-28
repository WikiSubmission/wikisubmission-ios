import Foundation
import Defaults

extension Utilities.Notifications {
    static func syncWithDatabase() async throws {
        guard let deviceToken = Defaults[.device_token] else {
            print("Failed to update ws_notifications_ios table: no device token found")
            return
        }
        
        do {
            try await Utilities.Supabase.client
                .schema("internal")
                .from("ws_notifications_ios")
                .upsert(Types.Notifications.Notification(
                    device_token: deviceToken,
                    updated_at: Date().ISO8601Format(),
                    prayer_times_notifications: .init(
                        enabled: Defaults[.prayer_notifications],
                        location: Defaults[.prayer_times_location],
                        fajr: Defaults[.fajr_notification],
                        dhuhr: Defaults[.dhuhr_notification],
                        asr: Defaults[.asr_notification],
                        mahgrib: Defaults[.maghrib_notification],
                        isha: Defaults[.isha_notification],
                        use_midpoint_method_for_asr: Defaults[.use_midpoint_method_for_asr]
                    ),
                    daily_verse_notifications: Defaults[.daily_verse_notifications],
                    daily_chapter_notifications: Defaults[.daily_chapter_notifications]
                ),
                        onConflict: "device_token"
                )
                .setHeader(name: "x-device-token", value: deviceToken)
                .execute()
        } catch {
            print("Error updating ws_notifications_ios table:", error.localizedDescription)
            throw error
        }
    }
}
