import Foundation
import Defaults

// MARK: - API Response

struct PrayerAPIResponse: Codable, Defaults.Serializable, Equatable {
    let status_string: String
    let location_string: String
    let country: String
    let country_code: String
    let city: String
    let region: String
    let local_time: String
    let local_timezone: String
    let local_timezone_id: String
    let coordinates: PrayerCoordinates
    let times: PrayerTimes
    let times_left: PrayerTimes
    let current_prayer: PrayerName
    let upcoming_prayer: PrayerName
    let current_prayer_time_elapsed: String
    let upcoming_prayer_time_left: String
    let schedule: [PrayerScheduleDay]
}

extension PrayerAPIResponse {

    /// Infer whether the user is located in North America
    var isInNorthAmerica: Bool {
        let northAmericaCountryCodes: Set<String> = [
            "US", "CA", "MX", // Core
            "GT", "BZ", "SV", "HN", "NI", "CR", "PA", // Central America
            "BS", "CU", "JM", "HT", "DO", "TT", "BB", "GD", "LC", "VC", "AG", "KN", "DM" // Caribbean
        ]

        if northAmericaCountryCodes.contains(country_code.uppercased()) {
            return true
        }

        // Fallback: geographic bounds (very coarse, but safe)
        let lat = coordinates.latitude
        let lon = coordinates.longitude

        return lat >= 5 && lat <= 83 && lon >= -170 && lon <= -50
    }
}

struct PrayerCoordinates: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct PrayerTimes: Codable, Equatable {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let sunrise: String

    /// Get time for a specific prayer
    subscript(_ prayer: PrayerName) -> String {
        switch prayer {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        case .sunrise: return sunrise
        }
    }
}

struct PrayerScheduleDay: Codable, Equatable, Identifiable {
    let date: Date
    let day: String
    let times: PrayerTimes

    var id: Date { date }
}

enum PrayerName: String, Codable, CaseIterable, Equatable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case sunrise

    /// Display name with capitalization
    var displayName: String {
        rawValue.capitalized
    }
    
    /// English translation
    var englishName: String {
        switch self {
        case .fajr:
            return "Dawn"
        case .dhuhr:
            return "Noon"
        case .asr:
            return "Afternoon"
        case .maghrib:
            return "Sunset"
        case .isha:
            return "Night"
        case .sunrise:
            return "Sunrise"
        }
    }

    /// SF Symbol for this prayer
    var symbol: String {
        switch self {
        case .fajr: return "moon.stars"
        case .sunrise: return "sunrise"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.haze"
        case .maghrib: return "sunset"
        case .isha: return "moon"
        }
    }

    /// Primary prayers (excluding sunrise)
    static var primaryPrayers: [PrayerName] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }

    /// All prayers in order
    static var orderedPrayers: [PrayerName] {
        [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
    }
}

struct GeocodedLocation: Identifiable, Equatable {
    let id = UUID()
    let city: String
    let administrativeArea: String?
    let country: String?
    var countryCode: String?
    let latitude: Double
    let longitude: Double

    /// Formatted display string for the location
    var displayString: String {
        var parts = [city]
        if let area = administrativeArea {
            parts.append(area)
        }
        return parts.joined(separator: ", ")
    }

    /// Full location string for API query
    var queryString: String {
        var parts = [city]
        if let area = administrativeArea {
            parts.append(area)
        }
        if let country = country {
            parts.append(country)
        }
        return parts.joined(separator: ",")
    }

    static func == (lhs: GeocodedLocation, rhs: GeocodedLocation) -> Bool {
        lhs.city == rhs.city &&
        lhs.administrativeArea == rhs.administrativeArea &&
        lhs.country == rhs.country &&
        abs(lhs.latitude - rhs.latitude) < 0.0001 &&
        abs(lhs.longitude - rhs.longitude) < 0.0001
    }
}

enum PrayerLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}
