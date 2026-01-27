import SwiftUI
import Defaults

struct Prayer_Element_Ramadan2026: View {
    @Default(.prayer_times_location) var prayerTimesLocation
    @Default(.prayer_times) var prayerTimes
    
    @State private var ramadanDataState: RamadanDataState = .loading
    
    enum RamadanDataState: Equatable {
        case loading
        case loaded(RamadanAPIResponse)
        case failed(String)
    }
    
    var body: some View {
        if let prayerTimesLocation = prayerTimesLocation, let prayerTimes = prayerTimes {
            VStack {
                ScrollView {
                    Card(title: "\(prayerTimesLocation)", options: .init(
                        image: prayerTimes.country_code.lowercased()
                    ))
                    
                    switch ramadanDataState {
                    case .loading:
                        EmptyView()

                    case .loaded(let ramadanData):
                        Card(title: "Day: 0", options: .init(
                            subtitle: ramadanData.status_string,
                            systemImage: "moon.stars",
                            imageAlignment: .top,
                            style: .secondary
                        ))
                        
                        Card(title: "First Day", options: .init(
                            subtitle: "**\(ramadanData.first_fasting_day)**",
                            systemImage: "sunrise",
                            style: .accent
                        ))
                        
                        Card(title: "Night of Destiny", options: .init(
                            subtitle: "**\(ramadanData.night_of_destiny)**",
                            systemImage: "sparkles",
                            style: .accent
                        ))
                        
                        Card(title: "Last Day", options: .init(
                            subtitle: "**\(ramadanData.last_fasting_day)**",
                            systemImage: "sunset",
                            style: .accent
                        ))
                        
                        Card(title: "Average Fast Duration", options: .init(
                            subtitle: "**~\(ramadanData.average_fasting_duration)**",
                            systemImage: "clock",
                            style: .accent
                        ))
                    case .failed(let errorMessage):
                        Card(title: errorMessage, options: .init(
                            systemImage: "x.circle",
                            style: .error
                        ))
                    }
                }
                .padding()
            }
            .navigationTitle("Ramadan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if ramadanDataState == .loading {
                    ProgressView()
                }
            }
            .task {
                Task {
                    try? await fetchRamadanData()
                }
            }
        }
    }
    private func fetchRamadanData() async throws {
        
        ramadanDataState = .loading
        
        guard let prayerTimesLocation = prayerTimesLocation else {
            self.ramadanDataState = .failed("No location available")
            return
        }
        
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
            withAnimation {
                ramadanDataState = .failed(error.localizedDescription)
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
//
//// MARK: - View
//
//struct Prayer_Element_RamadanSchedule: View {
//    @Default(.prayerLocation) private var prayerLocation
//    @Default(.ramadanData) private var ramadanData
//    @Default(.ramadanLocationUsed) private var ramadanLocationUsed
//
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        content
//            .onAppear {
//                checkAndFetch()
//            }
//            .onChange(of: prayerLocation) { _, newLocation in
//                handleLocationChange(newLocation)
//            }
//    }
//
//    @ViewBuilder
//    private var content: some View {
//        if let data = ramadanData {
//            ramadanCard(data)
//        } else if isLoading {
//            loadingView
//        } else {
//            Color.clear
//                .frame(height: 0)
//        }
//    }
//
//    // MARK: - Main Card
//
//    private func ramadanCard(_ data: RamadanAPIResponse) -> some View {
//        let title = "Ramadan: Day \(data.current_day)"
//
//        return Card(title: title, options: .destination(
//            subtitle: data.status_string,
//            systemImage: "moon.stars",
//            imageAlignment: .top
//        ) {
//            ramadanDetailView(data)
//        })
//    }
//
//    // MARK: - Detail View
//
//    private func ramadanDetailView(_ data: RamadanAPIResponse) -> some View {
//        ScrollView {
//            VStack(spacing: 16) {
//                // Summary cards
//                summarySection(data.summary)
//
//                // Schedule section
//                scheduleSection(data.schedule, currentDay: data.current_day)
//            }
//            .padding()
//        }
//        .navigationTitle("Ramadan \(data.year)")
//        #if os(iOS)
//        .navigationBarTitleDisplayMode(.inline)
//        #endif
//    }
//
//    // MARK: - Summary Section
//
//    private func summarySection(_ summary: RamadanSummary) -> some View {
//        VStack(spacing: 12) {
//            Text("\(Defaults[.prayerTimes]?.location_string ?? "")")
//                .font(.caption)
//                .monospaced()
//                .foregroundStyle(.secondary)
//            
//            Card(title: "First Fasting Day", options: .init(
//                subtitle: summary.first_fasting_day,
//                systemImage: "sunrise",
//                imageAlignment: .top
//            ))
//            
//            Card(title: "Night of Destiny", options: .action(
//                subtitle: summary.night_of_destiny,
//                systemImage: "sparkles",
//                imageAlignment: .top,
//                style: .accent
//            ) {
//                Router.shared.selectTab(.quran)
//                Router.shared.navigate(to: .chapter(chapterNumber: 97))
//            })
//
//            Card(title: "Last Fasting Day", options: .init(
//                subtitle: summary.last_fasting_day,
//                systemImage: "sunset",
//                imageAlignment: .top
//            ))
//        }
//    }
//
//    // MARK: - Schedule Section
//
//    private func scheduleSection(_ schedule: [RamadanDay], currentDay: Int) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("30-DAY SCHEDULE")
//                .font(.caption)
//                .fontWeight(.semibold)
//                .foregroundStyle(.secondary)
//                .padding(.top, 8)
//
//            // Table header
//            scheduleHeader
//
//            // Schedule rows
//            LazyVStack(spacing: 0) {
//                ForEach(schedule) { day in
//                    VStack(spacing: 0) {
//                        scheduleRow(day, isCurrent: day.day_number == currentDay)
//                        if day.day_number < schedule.count {
//                            Divider()
//                        }
//                    }
//                }
//            }
//            .background(
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color.secondary.opacity(0.03))
//            )
//        }
//    }
//
//    private var scheduleHeader: some View {
//        HStack(spacing: 0) {
//            Text("DAY")
//                .frame(width: 50, alignment: .leading)
//            Text("DAWN")
//                .frame(maxWidth: .infinity)
//            Text("NOON")
//                .frame(maxWidth: .infinity)
//            Text("AFT")
//                .frame(maxWidth: .infinity)
//            Text("SUN")
//                .frame(maxWidth: .infinity)
//            Text("NIGHT")
//                .frame(maxWidth: .infinity)
//        }
//        .font(.caption2)
//        .fontWeight(.semibold)
//        .foregroundStyle(.secondary)
//        .padding(.horizontal, 8)
//        .padding(.vertical, 6)
//    }
//
//    private func scheduleRow(_ day: RamadanDay, isCurrent: Bool) -> some View {
//        HStack(spacing: 0) {
//            // Day number + date
//            VStack(alignment: .leading, spacing: 0) {
//                Text(day.day.prefix(7))
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
//            }
//            .frame(width: 50, alignment: .leading)
//
//            // Prayer times
//            Text(formatTime(day.dawn))
//                .frame(maxWidth: .infinity)
//            Text(formatTime(day.noon))
//                .frame(maxWidth: .infinity)
//            Text(formatTime(day.afternoon))
//                .frame(maxWidth: .infinity)
//            Text(formatTime(day.sunset))
//                .frame(maxWidth: .infinity)
//            Text(formatTime(day.night))
//                .frame(maxWidth: .infinity)
//        }
//        .font(.caption)
//        .monospaced()
//        .padding(.horizontal, 8)
//        .padding(.vertical, 8)
//        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
//    }
//
//    private func formatTime(_ time: String) -> String {
//        // Remove AM/PM for density: "5:18 AM" -> "5:18"
//        time.replacingOccurrences(of: " AM", with: "").replacingOccurrences(of: " PM", with: "")
//    }
//
//    // MARK: - Loading View
//
//    private var loadingView: some View {
//        HStack {
//            ProgressView()
//        }
//        .padding()
//    }
//
//    // MARK: - Data Fetching
//
//    private func checkAndFetch() {
//        guard let location = prayerLocation else {
//            clearData()
//            return
//        }
//
//        // If we have data for a different location, clear it
//        if let usedLocation = ramadanLocationUsed, usedLocation != location {
//            clearData()
//        }
//
//        // Fetch if we don't have data
//        if ramadanData == nil {
//            print("RamadanSchedule: Fetching...")
//            Task {
//                await fetchRamadanData(for: location)
//            }
//        }
//    }
//
//    private func handleLocationChange(_ newLocation: String?) {
//        if newLocation == nil {
//            clearData()
//        } else if newLocation != ramadanLocationUsed {
//            clearData()
//            if let location = newLocation {
//                Task {
//                    await fetchRamadanData(for: location)
//                }
//            }
//        }
//    }
//
//    private func clearData() {
//        ramadanData = nil
//        ramadanLocationUsed = nil
//    }
//
//    @MainActor
//    private func fetchRamadanData(for location: String) async {
//        guard !isLoading else {
//            print("RamadanSchedule: Already loading, skipping fetch")
//            return
//        }
//
//        isLoading = true
//        errorMessage = nil
//
//        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? location
//        let urlString = "https://practices.wikisubmission.org/ramadan/\(encodedLocation.lowercased())"
//        print("RamadanSchedule: Fetching from \(urlString)")
//
//        guard let url = URL(string: urlString) else {
//            print("RamadanSchedule: Invalid URL")
//            errorMessage = "Invalid URL"
//            isLoading = false
//            return
//        }
//
//        do {
//            let (data, response) = try await URLSession.shared.data(from: url)
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("RamadanSchedule: Invalid response type")
//                errorMessage = "Server error"
//                isLoading = false
//                return
//            }
//
//            print("RamadanSchedule: Response status code: \(httpResponse.statusCode)")
//
//            guard httpResponse.statusCode == 200 else {
//                errorMessage = "Server error (\(httpResponse.statusCode))"
//                isLoading = false
//                return
//            }
//
//            let decoded = try JSONDecoder().decode(RamadanAPIResponse.self, from: data)
//            print("RamadanSchedule: Successfully decoded response")
//            ramadanData = decoded
//            ramadanLocationUsed = location
//
//        } catch {
//            print("RamadanSchedule: Error fetching data - \(error)")
//            errorMessage = "Failed to load"
//        }
//
//        isLoading = false
//    }
//}
