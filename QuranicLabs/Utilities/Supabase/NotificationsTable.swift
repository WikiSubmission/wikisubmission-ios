import Foundation
import PostgREST
import Defaults

extension Utilities.Supabase {
    struct NotificationsTable {
        static func syncWithServer() async throws {
            guard let deviceToken = Defaults[.device_token] else {
                print("Failed to update notifications: no device token found")
                return
            }
            
            // Notifications table
            do {
                try await Utilities.Supabase.client
                    .from("ws-notifications")
                    .upsert(Types.Supabase.Notifications(
                        platform: "ios",
                        prayer_notifications: Defaults[.prayer_notifications],
                        device_token: Defaults[.device_token],
                        updated_at: Date().ISO8601Format()
                    ),
                            onConflict: "device_token"
                    )
                    .execute()
            } catch {
                print("Error updating notifications", error.localizedDescription)
                throw error
            }
            
            // Prayer times notifications table
            do {
                try await Utilities.Supabase.client
                    .from("ws-notifications-prayer-times")
                    .upsert(Types.Supabase.PrayerTimesNotifications(
                        device_token: deviceToken,
                        fajr: Defaults[.fajr_notification],
                        dhuhr: Defaults[.dhuhr_notification],
                        asr: Defaults[.asr_notification],
                        maghrib: Defaults[.maghrib_notification],
                        isha: Defaults[.isha_notification],
                        location: Defaults[.prayer_time_location]),
                            onConflict: "device_token"
                    )
                    .execute()
            } catch {
                print("Error updating prayer time notifications", error.localizedDescription)
                throw error
            }
        }
    }
}
