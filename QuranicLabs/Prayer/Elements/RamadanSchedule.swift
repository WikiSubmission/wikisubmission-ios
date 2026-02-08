import SwiftUI
import Defaults

extension Defaults.Keys {
    static let ramadan_cached_data = Key<RamadanAPIResponse?>("ramadan_cached_data", default: nil)
    static let ramadan_last_fetch = Key<Date?>("ramadan_last_fetch", default: nil)
    static let ramadan_cached_location = Key<String?>("ramadan_cached_location", default: nil)
}

struct Prayer_Element_Ramadan2026: View {
    @Default(.prayer_times_location) var prayerTimesLocation
    @Default(.prayer_times) var prayerTimes

    @State private var ramadanDataState: RamadanDataState = .loading

    private static let cacheValidityDuration: TimeInterval = 2 * 60 // 2 minutes

    enum RamadanDataState: Equatable {
        case loading
        case loaded(RamadanAPIResponse)
        case failed(String)
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let prayerTimesLocation = prayerTimesLocation, let prayerTimes = prayerTimes {
            ScrollView {
                VStack(spacing: 20) {
                    // Location header
                    HStack {
                        Text(prayerTimesLocation)
                            .font(.headline)
                            .monospaced()
                        Spacer()
                        Image(prayerTimes.country_code.lowercased())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 4)

                    switch ramadanDataState {
                    case .loading:
                        ProgressView()
                            .padding(.top, 40)

                    case .loaded(let ramadanData):
                        if ramadanData.current_day < 0 {
                            VStack(spacing: 16) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("Ramadan has ended")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("See you next year!")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 40)
                        } else {
                            // Current day hero
                            Card(title: "Day: \(ramadanData.current_day)", options: .init(
                                subtitle: ramadanData.status_string,
                                systemImage: "moon.stars",
                                imageAlignment: .top
                            ))

                            // Key dates grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                keyDateCard(
                                    title: "First Day",
                                    date: ramadanData.first_fasting_day,
                                    icon: "sunrise.fill",
                                    color: .orange
                                )
                                keyDateCard(
                                    title: "Last Day",
                                    date: ramadanData.last_fasting_day,
                                    icon: "sunset.fill",
                                    color: .purple
                                )
                                keyDateCard(
                                    title: "Night of Destiny",
                                    date: ramadanData.night_of_destiny,
                                    icon: "sparkles",
                                    color: .yellow
                                )
                                keyDateCard(
                                    title: "Avg. Duration",
                                    date: "~\(ramadanData.average_fasting_duration)",
                                    icon: "clock.fill",
                                    color: .blue
                                )
                            }

                            // Full schedule
                            Prayer_Element_RamadanScheduleTable(
                                schedule: ramadanData.schedule,
                                currentDay: ramadanData.current_day
                            )
                        }

                    case .failed(let errorMessage):
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Ramadan \(String(Calendar.current.component(.year, from: Date())))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if ramadanDataState == .loading {
                    ProgressView()
                }
            }
            .task {
                try? await fetchRamadanData()
            }
        }
    }

    private func keyDateCard(title: String, date: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(formatShortDate(date))
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatShortDate(_ dateString: String) -> String {
        // "Saturday, March 1, 2026" -> "Sat, Mar 1"
        let components = dateString.components(separatedBy: ", ")
        if components.count >= 2 {
            let weekday = String(components[0].prefix(3))
            let monthDay = components[1]
            let parts = monthDay.components(separatedBy: " ")
            if parts.count >= 2 {
                let month = String(parts[0].prefix(3))
                return "\(weekday), \(month) \(parts[1])"
            }
        }
        return dateString
    }
    private func fetchRamadanData() async throws {
        guard let prayerTimesLocation = prayerTimesLocation else {
            self.ramadanDataState = .failed("No location available")
            return
        }

        // Check if we have valid cached data for this location
        if let cachedData = Defaults[.ramadan_cached_data],
           let lastFetch = Defaults[.ramadan_last_fetch],
           let cachedLocation = Defaults[.ramadan_cached_location],
           cachedLocation == prayerTimesLocation,
           Date().timeIntervalSince(lastFetch) < Self.cacheValidityDuration {
            // Use cached data
            withAnimation {
                ramadanDataState = .loaded(cachedData)
            }
            return
        }

        ramadanDataState = .loading

        // [URL]
        var request = URLRequest(url: URL(string: "https://practices.wikisubmission.org/ramadan/\(prayerTimesLocation)")!)

        // [Method]
        request.httpMethod = "GET"

        // [Send]
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let decoded = try JSONDecoder().decode(RamadanAPIResponse.self, from: data)
                        // Cache the response
                        Defaults[.ramadan_cached_data] = decoded
                        Defaults[.ramadan_last_fetch] = Date()
                        Defaults[.ramadan_cached_location] = prayerTimesLocation
                        withAnimation {
                            ramadanDataState = .loaded(decoded)
                        }
                    } catch {
                        withAnimation {
                            ramadanDataState = .failed("Failed to decode response")
                        }
                    }
                } else {
                    withAnimation {
                        ramadanDataState = .failed("Failed: \(httpResponse.statusCode)")
                    }
                }
            } else {
                withAnimation {
                    ramadanDataState = .failed("API Error")
                }
            }
        } catch {
            // On network error, try to use cached data even if stale
            if let cachedData = Defaults[.ramadan_cached_data],
               Defaults[.ramadan_cached_location] == prayerTimesLocation {
                withAnimation {
                    ramadanDataState = .loaded(cachedData)
                }
            } else {
                withAnimation {
                    ramadanDataState = .failed(error.localizedDescription)
                }
            }
        }
    }
}

struct RamadanAPIResponse: Codable, Defaults.Serializable, Equatable {
    let query: String
    let year: String
    let current_day: Int
    let status_string: String
    let average_fasting_duration: String
    let location_string: String
    let first_fasting_day: String
    let last_fasting_day: String
    let night_of_destiny: String
    let begin_last_10_nights: String
    let moon_data: RamadanMoonData
    let schedule: [RamadanDay]
}

struct RamadanMoonData: Codable, Equatable {
    let start: RamadanMoonPhase
    let end: RamadanMoonPhase
}

struct RamadanMoonPhase: Codable, Equatable {
    let new_moon_utc: String
    let new_moon_local: String
    let sunset_local: String
}

struct RamadanDay: Codable, Equatable, Identifiable {
    let day_number: Int
    let day: String
    let dawn: String
    let sunrise: String
    let noon: String
    let afternoon: String
    let sunset: String
    let night: String

    var id: Int { day_number }
}
