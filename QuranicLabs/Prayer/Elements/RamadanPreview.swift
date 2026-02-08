import SwiftUI
import Defaults

struct Prayer_Element_RamadanPreview: View {
    @Default(.prayer_times_location) var prayerTimesLocation
    @Default(.ramadan_cached_data) var cachedData
    @Default(.ramadan_last_fetch) var lastFetch
    @Default(.ramadan_cached_location) var cachedLocation

    @State private var hasFetched = false

    private static let cacheValidityDuration: TimeInterval = 2 * 60 // 2 minutes

    private var shouldFetch: Bool {
        guard let location = prayerTimesLocation else { return false }
        guard let fetchTime = lastFetch,
              let cachedLoc = cachedLocation,
              cachedLoc == location else { return true }
        return Date().timeIntervalSince(fetchTime) >= Self.cacheValidityDuration
    }

    var body: some View {
        Group {
            if let data = cachedData,
               data.current_day >= 0,
               cachedLocation == prayerTimesLocation {
                VStack(spacing: 12) {
                    Group {
                        Text("RAMADAN \(data.year)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .tracking(2)
                        if data.current_day == 26 {
                            Text("TONIGHT IS THE NIGHT OF DESTINY")
                                .font(.title)
                                .bold()
                                .monospaced()
                                .tracking(1.5)
                        } else if data.current_day == 25 {
                            Text("TOMORROW IS THE NIGHT OF DESTINY!")
                                .font(.title)
                                .bold()
                                .monospaced()
                                .tracking(1.5)
                        }
                    }
                    Card(title: "Day: \(data.current_day)", options: .init(
                        subtitle: data.status_string,
                        systemImage: "moon.stars",
                        imageAlignment: .top,
                        style: .secondary,
                        content: AnyView(
                            NavigationLink {
                                Prayer_Element_Ramadan2026()
                            } label: {
                                Label("View Schedule →", systemImage: "calendar")
                            }
                                .buttonStyle(SignatureButtonStyle())
                                .font(.caption)
                        )
                    ))
                }
                .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 32)
        .task {
            if shouldFetch && !hasFetched {
                hasFetched = true
                await fetchRamadanData()
            }
        }
    }

    private func fetchRamadanData() async {
        guard let location = prayerTimesLocation else { return }
        guard let url = URL(string: "https://practices.wikisubmission.org/ramadan/\(location)") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode(RamadanAPIResponse.self, from: data)

            Defaults[.ramadan_cached_data] = decoded
            Defaults[.ramadan_last_fetch] = Date()
            Defaults[.ramadan_cached_location] = location
        } catch {
            // Silent failure - will show nothing if no cache available
        }
    }
}
