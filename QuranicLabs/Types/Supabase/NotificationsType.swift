import Foundation

extension Types.Supabase {
    struct Notifications: Encodable, Decodable {
        let platform: String
        let prayer_notifications: Bool?
        let device_token: String?
        let updated_at: String?
    }
    
    struct PrayerTimesNotifications: Encodable, Decodable {
        let device_token: String?
        let fajr: Bool?
        let dhuhr: Bool?
        let asr: Bool?
        let maghrib: Bool?
        let isha: Bool?
        let location: String?
    }
}
