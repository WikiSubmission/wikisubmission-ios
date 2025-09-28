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
                try await Utilities.Supabase.anonClient
                    .from("ws-notifications")
                    .upsert(Types.Supabase.Notifications(
                        platform: "ios",
                        prayer_notifications: Defaults[.prayer_notifications],
                        daily_verse_notifications: Defaults[.random_verse_notifications],
                        daily_chapter_notifications: Defaults[.random_chapter_notifications],
                        device_token: Defaults[.device_token],
                        updated_at: Date().ISO8601Format()
                    ),
                            onConflict: "device_token"
                    )
                    .execute()
            } catch {
                print("Error updating ws-notifications table:", error.localizedDescription)
                throw error
            }
            
            // Prayer times notifications table
            do {
                try await Utilities.Supabase.anonClient
                    .from("ws-notifications-prayer-times")
                    .upsert(Types.Supabase.PrayerTimesNotifications(
                        device_token: deviceToken,
                        fajr: Defaults[.fajr_notification],
                        dhuhr: Defaults[.dhuhr_notification],
                        asr: Defaults[.asr_notification],
                        maghrib: Defaults[.maghrib_notification],
                        isha: Defaults[.isha_notification],
                        location: Defaults[.prayer_time_location],
                        use_midpoint_method_for_asr: Defaults[.use_midpoint_method_for_asr]
                    ),
                            onConflict: "device_token",
                    )
                    .execute()
            } catch {
                print("Error updating ws-notifications-prayer-times table:", error.localizedDescription)
                throw error
            }
            
            // Random verse notifications table
            do {
                try await Utilities.Supabase.anonClient
                    .from("ws-notifications-daily-verse")
                    .upsert(Types.Supabase.DailyVerseNotifications(
                        device_token: deviceToken,
                    ),
                            onConflict: "device_token",
                    )
                    .execute()
            } catch {
                print("Error updating ws-notifications-daily-verse table:", error.localizedDescription)
                throw error
            }
            
            // Random chapter notifications table
            do {
                try await Utilities.Supabase.anonClient
                    .from("ws-notifications-daily-chapter")
                    .upsert(Types.Supabase.DailyChapterNotifications(
                        device_token: deviceToken,
                    ),
                            onConflict: "device_token",
                    )
                    .execute()
            } catch {
                print("Error updating ws-notifications-daily-verse table:", error.localizedDescription)
                throw error
            }
        }
    }
}
