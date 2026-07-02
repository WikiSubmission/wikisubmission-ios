import SwiftUI
import Defaults
import Combine

/// Manages prayer times data fetching, caching, and auto-refresh.
@MainActor
class PrayerManager: ObservableObject {

    static let shared = PrayerManager()

    @Published private(set) var state: PrayerLoadingState = .idle
    @Published private(set) var prayerData: PrayerAPIResponse?
    @Published private(set) var hasValidLiveData: Bool = false

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let refreshInterval: TimeInterval = 45

    private var hasInternet: Bool {
        NetworkManager.shared.hasInternet
    }

    private init() {
        loadCachedData()
        observeNetworkChanges()
    }

    /// Fetch prayer times for the current saved location
    func fetchTimes() async {
        guard let location = Defaults[.prayer_times_location] else {
            return
        }
        await fetchTimes(for: location)
    }

    /// Fetch prayer times for a specific location
    func fetchTimes(for location: String) async {
        guard hasInternet else {
            loadCachedData()
            hasValidLiveData = false
            return
        }

        state = .loading

        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? location

        var components = URLComponents(string: "https://practices.wikisubmission.org/prayer-times/\(encodedLocation.lowercased())")!
        components.queryItems = [
            URLQueryItem(name: "include_schedule", value: "true"),
            URLQueryItem(name: "client", value: "ios")
        ]

        if Defaults[.prayer_times_use_midpoint_method_for_asr] {
            components.queryItems?.append(URLQueryItem(name: "asr_adjustment", value: "true"))
        }

        guard let url = components.url else {
            state = .error("Invalid URL")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                state = .error("Invalid response")
                return
            }

            guard httpResponse.statusCode == 200 else {
                state = .error("Server error (\(httpResponse.statusCode))")
                return
            }

            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let decoded = try decoder.decode(PrayerAPIResponse.self, from: data)

            prayerData = decoded
            Defaults[.prayer_times] = decoded
            Defaults[.prayer_times_last_fetch] = Date()
            Defaults[.prayer_times_location] = decoded.location_string
            hasValidLiveData = true
            state = .loaded

            // [Keep the push notification registry in step with the resolved location.]
            // The server sends prayer notifications purely from the registry's `location`
            // column, so if the resolved location changes (city change, or a normalized
            // string from the API) the registry must be re-synced or the server keeps
            // notifying for the previous location. Only mark as registered on a successful
            // write, so a failed sync is retried automatically on the next fetch.
            await syncRegisteredLocationIfChanged()

        } catch let decodingError as DecodingError {
            print("PrayerManager: Decoding error - \(decodingError)")
            state = .error("Failed to parse prayer times")
            loadCachedData()
        } catch {
            print("PrayerManager: Network error - \(error.localizedDescription)")
            state = .error("Network error")
            loadCachedData()
        }
    }

    /// Re-syncs the prayer times registry when the resolved location differs from the
    /// value last written to the server. The registered marker is only advanced on a
    /// successful write, so a transient failure is retried on the next successful fetch
    /// rather than silently stranding a stale location on the server.
    private func syncRegisteredLocationIfChanged() async {
        guard Defaults[.prayer_notifications] else { return }

        let resolvedLocation = Defaults[.prayer_times]?.location_string ?? Defaults[.prayer_times_location]
        guard let resolvedLocation, resolvedLocation != Defaults[.prayer_times_registered_location] else {
            return
        }

        do {
            try await NotificationManager.shared.syncPrayerTimesRegistry()
            Defaults[.prayer_times_registered_location] = resolvedLocation
        } catch {
            // Leave the registered marker unchanged so the next fetch retries the sync.
            print("PrayerManager: failed to sync prayer location '\(resolvedLocation)' to registry, will retry: \(error.localizedDescription)")
        }
    }

    /// Start auto-refresh timer (called when view appears)
    func startAutoRefresh() {
        stopAutoRefresh()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchTimes()
            }
        }
    }

    /// Stop auto-refresh timer (call when view disappears)
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Clear all prayer data and reset state
    func clearData() {
        stopAutoRefresh()
        prayerData = nil
        hasValidLiveData = false
        state = .idle
        Defaults.resetPrayerPreferences()
    }

    /// Set a new location and fetch times
    func setLocation(_ location: String) async {
        Defaults[.prayer_times_location] = location
        await fetchTimes(for: location)
    }

    private func loadCachedData() {
        if let cached = Defaults[.prayer_times] {
            prayerData = cached
            state = .loaded
            // Cached data doesn't have valid live timing info
            hasValidLiveData = false
        }
    }

    private func observeNetworkChanges() {
        NetworkManager.shared.$hasInternet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasInternet in
                guard let self else { return }
                if hasInternet && self.prayerData != nil {
                    // Network restored - refresh data
                    Task {
                        await self.fetchTimes()
                    }
                } else if !hasInternet {
                    // Lost network - mark live data as invalid
                    self.hasValidLiveData = false
                }
            }
            .store(in: &cancellables)
    }
}
