import Foundation

extension Types.PrayerTimes {
    struct PrayerTimesResponse: Codable {
        let statusString: String
        let locationString: String
        let country: String
        let countryCode: String
        let city: String
        let region: String
        let localTime: String
        let localTimezone: String
        let localTimezoneId: String
        let coordinates: Coordinates
        let times: [String: String]
        let timesInUTC: [String: String]
        let timesLeft: [String: String]
        let currentPrayer: String
        let upcomingPrayer: String
        let currentPrayerTimeElapsed: String
        let upcomingPrayerTimeLeft: String
        
        struct Coordinates: Codable {
            let latitude: Double
            let longitude: Double
        }

        enum CodingKeys: String, CodingKey {
            case statusString = "status_string"
            case locationString = "location_string"
            case country
            case countryCode = "country_code"
            case city
            case region
            case localTime = "local_time"
            case localTimezone = "local_timezone"
            case localTimezoneId = "local_timezone_id"
            case coordinates
            case times
            case timesInUTC = "times_in_utc"
            case timesLeft = "times_left"
            case currentPrayer = "current_prayer"
            case upcomingPrayer = "upcoming_prayer"
            case currentPrayerTimeElapsed = "current_prayer_time_elapsed"
            case upcomingPrayerTimeLeft = "upcoming_prayer_time_left"
        }
    }
}
