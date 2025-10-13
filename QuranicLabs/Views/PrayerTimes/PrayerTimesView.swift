import SwiftUI
import CoreLocation
import SheetKit
import Defaults

struct PrayerTimesView: View {
    @State private var query = ""
    @State private var results: [Types.PrayerTimes.PrayerTimesLocation] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var presentDeleteConfirmation = false
    @State private var presentSearchbar = false
    @State private var refreshTimer: Timer? = nil
    @State private var geocoder = CLGeocoder()
    
    @Default(.prayer_times) private var prayerTimes
    @Default(.active_tab) private var activeTab
    @Default(.qibla_enabled) private var qibla

    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        NavigationStack {
            ZStack {
                if environment.PrayerTimesManager.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else {
                    VStack {
                        if !results.isEmpty {
                            List(results) { location in
                                Button {
                                    selectLocation(location)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(location.city)
                                                .font(.headline)
                                                .foregroundStyle(.accent)
                                            
                                            if let administrativeArea = location.administrativeArea {
                                                Text(administrativeArea)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if let country = location.country {
                                            Text(country)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.trailing)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .listStyle(.insetGrouped)
                        } else if let prayerData = prayerTimes {
                            ScrollView {
                                LazyVStack(spacing: 32) {
                                    PrayerTimesCard(prayerData: prayerData)
                                        .environmentObject(environment)
                                    
                                    Divider()
                                    
                                    FlexStack {
                                        if qibla {
                                            TinyCard(title: "Qibla", systemImage: "safari.fill") {
                                                QiblaView()
                                            }
                                        }
                                        TinyCard(title: "Notifications", systemImage: "bell.badge.fill") {
                                            NotificationsView()
                                        }
                                        TinyCard(title: "Prayer Guide", systemImage: "info.circle.text.page.fill") {
                                            WebView(url: URL(string: "https://library.wikisubmission.org/file/salat-brochure")!)
                                        }
                                        TinyCardWithAction(title: "Settings", systemImage: "gear.circle.fill") {
                                            activeTab = .settings
                                        }
                                    }
                                    .pushToLeft()
                                    
                                    Button("Remove City") {
                                        presentDeleteConfirmation = true
                                    }
                                    .buttonStyle(SignatureButtonStyle(foregroundColor: .red))
                                }
                                .padding()
                            }
                            .onAppear {
                                presentSearchbar = false
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "location.magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(.accent)
                                
                                VStack(spacing: 4) {
                                    Text("Search for any city to see live prayer times")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding()
                            .padding(.top, 50)
                            .onAppear {
                                if prayerTimes == nil {
                                    presentSearchbar = true
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Prayer Times")
            .navigationBarTitleDisplayMode(.large)
            .scrollIndicators(.hidden)
            .onAppear(perform: setupRefreshTimer)
            .onDisappear(perform: cleanup)
            .searchable(text: $query, isPresented: $presentSearchbar, prompt: "Enter your city")
            .confirmationDialog(
                "Remove this city? You can add it back later.",
                isPresented: $presentDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Group {
                    Button("Delete", role: .destructive) {
                        environment.PrayerTimesManager.removeSavedCity()
                        presentSearchbar = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .onChange(of: query) { oldValue, newValue in
                handleQueryChange(newValue)
            }
        }
    }

    private func setupRefreshTimer() {
        environment.PrayerTimesManager.refresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { _ in
            Task { @MainActor in
                environment.PrayerTimesManager.refresh()
            }
        }
    }

    private func cleanup() {
        invalidateTimer()
        searchTask?.cancel()
        geocoder.cancelGeocode()
    }
    
    private func invalidateTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func handleQueryChange(_ newValue: String) {
        searchTask?.cancel()
        geocoder.cancelGeocode()
        
        guard !newValue.isEmpty else {
            results = []
            return
        }
        
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Reduced debounce time
                if !Task.isCancelled {
                    await searchLocations(for: newValue)
                }
            } catch {
                // Task was cancelled
            }
        }
    }

    private func selectLocation(_ location: Types.PrayerTimes.PrayerTimesLocation) {
        guard environment.NetworkMonitor.hasInternet else {
            Utilities.System.GlobalAlertManager.shared.showAlert(title: "No Internet Connection", subtitle: "An internet connection to load prayer times.", systemImage: "wifi.slash", type: .error)
            return
        }
        
        let locationString = [
            location.city,
            location.administrativeArea,
            location.country
        ].compactMap { $0 }.joined(separator: ", ")
        
        environment.PrayerTimesManager.fetchPrayerTimes(for: locationString)
        
        query = ""
        presentSearchbar = false
    }

    @MainActor
    private func searchLocations(for query: String) async {
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            
            let locations = placemarks.compactMap { placemark -> Types.PrayerTimes.PrayerTimesLocation? in
                guard let coordinate = placemark.location?.coordinate else { return nil }
                
                let city = placemark.locality ?? placemark.name ?? "Unknown"
                
                return Types.PrayerTimes.PrayerTimesLocation(
                    city: city,
                    coordinate: coordinate,
                    country: placemark.country,
                    administrativeArea: placemark.administrativeArea,
                    locality: placemark.locality,
                    countryCode: placemark.isoCountryCode
                )
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                results = locations
            }
            
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
        }
    }
}

struct PrayerTimesCard: View {
    let prayerData: Types.PrayerTimes.PrayerTimesResponse
    @EnvironmentObject private var environment: AppEnvironment
    @Default(.use_midpoint_method_for_asr) private var useMidpointMethodForAsr

    private var hasInternet: Bool { environment.NetworkMonitor.hasInternet }

    // Helper to map PrayerTypes to times property
    private func time(for prayer: Types.PrayerTimes.PrayerTypes) -> String? {
        switch prayer {
        case .fajr: return prayerData.times.fajr
        case .dhuhr: return prayerData.times.dhuhr
        case .asr: return prayerData.times.asr
        case .maghrib: return prayerData.times.maghrib
        case .isha: return prayerData.times.isha
        case .sunrise: return prayerData.times.sunrise
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LargeCardWithoutDestination(
                title: prayerData.location_string,
                image: prayerData.country_code.lowercased()
            )
            VStack(spacing: 8) {
                ForEach(Types.PrayerTimes.PrayerTypes.allCases.filter { $0 != .sunrise }, id: \.self) { prayerName in
                    if let time = time(for: prayerName) {
                        prayerTimeRow(
                            name: prayerName.rawValue,
                            time: time,
                            isCurrentPrayer: prayerName == prayerData.current_prayer,
                            isUpcomingPrayer: prayerName == prayerData.upcoming_prayer,
                            currentPrayerTimeElapsed: prayerData.current_prayer_time_elapsed,
                            upcomingPrayerTimeLeft: prayerData.upcoming_prayer_time_left
                        )
                    }
                }

                // Sunrise section
                Divider()
                    .padding(.vertical, 4)
                sunriseRow(
                    time: prayerData.times.sunrise,
                    isUpcoming: prayerData.upcoming_prayer == .sunrise,
                    upcomingPrayerTimeLeft: prayerData.upcoming_prayer_time_left,
                    isCurrentPrayer: prayerData.current_prayer == .sunrise
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
            VStack(spacing: 4) {
                if !hasInternet {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                        Text("Offline")
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Text(prayerData.local_timezone)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Last updated: \(prayerData.local_time)")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                if (useMidpointMethodForAsr) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Using midpoint method for Asr")
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prayerTimeRow(
        name: String,
        time: String,
        isCurrentPrayer: Bool,
        isUpcomingPrayer: Bool,
        currentPrayerTimeElapsed: String,
        upcomingPrayerTimeLeft: String
    ) -> some View {
        let accentColor: Color = isCurrentPrayer && hasInternet ? .accent : .primary
        let backgroundColor: Color = Color.accent.opacity(isCurrentPrayer && hasInternet ? 0.15 : 0)
        return HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(name.capitalized)
                    .fontWeight(isCurrentPrayer ? .semibold : .regular)
                    .font(.callout)

                if isCurrentPrayer && hasInternet {
                    Label(
                        "\(currentPrayerTimeElapsed) ago",
                        systemImage: "clock"
                    )
                    .font(.callout)
                    .foregroundStyle(currentPrayerTimeElapsed.contains("h") ? .accent : .red)
                }

                if isUpcomingPrayer && hasInternet {
                    Text("in \(upcomingPrayerTimeLeft)")
                        .font(.callout)
                        .foregroundStyle(upcomingPrayerTimeLeft.contains("h") ? .gray : .red)
                }
            }

            Spacer()

            Text(time)
                .fontWeight(isCurrentPrayer ? .semibold : .regular)
        }
        .foregroundColor(accentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }

    private func sunriseRow(
        time: String,
        isUpcoming: Bool,
        upcomingPrayerTimeLeft: String,
        isCurrentPrayer: Bool
    ) -> some View {
        let textColor: Color = .orange
        let backgroundColor: Color = Color.orange.opacity(isCurrentPrayer && hasInternet ? 0.15 : 0)
        return HStack(alignment: .firstTextBaseline) {
            Label("Sunrise", systemImage: "sunrise")
                .font(.callout)

            if isUpcoming && hasInternet {
                Text("in \(upcomingPrayerTimeLeft)")
                    .font(.callout)
                    .foregroundStyle(upcomingPrayerTimeLeft.contains("h") ? .gray : .red)
            }

            Spacer()

            Text(time)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
}

#Preview {
    NavigationStack {
        PrayerTimesView()
            .environmentObject(AppEnvironment.shared)
    }
}
