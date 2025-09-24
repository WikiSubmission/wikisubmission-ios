import SwiftUI
import CoreLocation
import SheetKit

struct PrayerTimesView: View {
    @State private var query = ""
    @State private var results: [Types.PrayerTimes.PrayerTimesLocation] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var presentDeleteConfirmation = false
    @State private var presentSearchbar = false
    @State private var refreshTimer: Timer? = nil
    @State private var geocoder = CLGeocoder()

    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        NavigationStack {
            ZStack {
                if environment.PrayerTimesManager.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Prayer Times")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: setupRefreshTimer)
            .onDisappear(perform: cleanup)
            .searchable(text: $query, isPresented: $presentSearchbar, prompt: "Enter your city")
            .confirmationDialog(
                "Remove this city? You can add it back later.",
                isPresented: $presentDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteConfirmationButtons
            }
            .onChange(of: query) { oldValue, newValue in
                handleQueryChange(newValue)
            }
        }
    }
}

private extension PrayerTimesView {
    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading prayer times...")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }

    var contentView: some View {
        VStack {
            if !results.isEmpty {
                locationsList
            } else if let prayerData = environment.PrayerTimesManager.prayerTimesData {
                prayerTimesScrollView(for: prayerData)
            } else {
                PlaceholderView()
                    .padding(.top, 50)
                Spacer()
            }
        }
    }

    var locationsList: some View {
        List(results) { location in
            locationRow(for: location)
        }
        .listStyle(.insetGrouped)
    }

    func locationRow(for location: Types.PrayerTimes.PrayerTimesLocation) -> some View {
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

    func prayerTimesScrollView(for prayerData: Types.PrayerTimes.PrayerTimesResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                PrayerTimesCard(prayerData: prayerData)
                
                Divider()
                
                FlexStack {
                    TinyCard(title: "Qibla", systemImage: "safari.fill") {
                        QiblaView()
                    }
                    TinyCard(title: "Prayer Guide", systemImage: "info.circle.text.page.fill") {
                        WebView(url: URL(string: "https://library.wikisubmission.org/file/salat-brochure")!)
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
    }

    var deleteConfirmationButtons: some View {
        Group {
            Button("Delete", role: .destructive) {
                environment.PrayerTimesManager.removeSavedCity()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private extension PrayerTimesView {
    func setupRefreshTimer() {
        environment.PrayerTimesManager.refresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { _ in
            Task { @MainActor in
                environment.PrayerTimesManager.refresh()
            }
        }
    }

    func cleanup() {
        invalidateTimer()
        searchTask?.cancel()
        geocoder.cancelGeocode()
    }
    
    func invalidateTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func handleQueryChange(_ newValue: String) {
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

    func selectLocation(_ location: Types.PrayerTimes.PrayerTimesLocation) {
        guard environment.NetworkMonitor.hasInternet else {
            presentNetworkError()
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
    
    func presentNetworkError() {
        SheetKit().presentWithEnvironment {
            InternetRequiredContent(reason: "An internet connection is required to fetch prayer times.")
        }
    }

    @MainActor
    func searchLocations(for query: String) async {
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
            // Handle error appropriately
        }
    }
}

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.accent)
                .symbolEffect(.pulse.wholeSymbol, options: .repeating)
            
            VStack(spacing: 4) {
                Text("Find Your Prayer Times")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Search for your city to see prayer times")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

struct PrayerTimesCard: View {
    let prayerData: Types.PrayerTimes.PrayerTimesResponse
    @EnvironmentObject private var environment: AppEnvironment
    
    private let prayerNames = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Location header
            LargeCardWithoutDestination(
                title: prayerData.locationString,
                image: prayerData.countryCode.lowercased()
            )
            
            // Prayer times list
            VStack(spacing: 8) {
                ForEach(prayerNames, id: \.self) { prayerName in
                    if let time = prayerData.times[prayerName] {
                        prayerTimeRow(
                            name: prayerName,
                            time: time,
                            isCurrentPrayer: prayerName == prayerData.currentPrayer,
                            isUpcomingPrayer: prayerName == prayerData.upcomingPrayer
                        )
                    }
                }
                
                // Sunrise time (if available)
                if let sunriseTime = prayerData.times["sunrise"] {
                    Divider()
                        .padding(.vertical, 4)
                    
                    sunriseRow(
                        time: sunriseTime,
                        isUpcoming: prayerData.upcomingPrayer == "sunrise"
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
            
            // Status and metadata
            statusSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func prayerTimeRow(name: String, time: String, isCurrentPrayer: Bool, isUpcomingPrayer: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(name.capitalized)
                    .fontWeight(isCurrentPrayer ? .semibold : .regular)
                    .font(.callout)
                
                if isCurrentPrayer && environment.NetworkMonitor.hasInternet {
                    Label(
                        "\(prayerData.currentPrayerTimeElapsed) ago",
                        systemImage: "clock"
                    )
                    .font(.callout)
                    .foregroundStyle(prayerData.currentPrayerTimeElapsed.contains("h") ? .gray : .red)
                }
                
                if isUpcomingPrayer && environment.NetworkMonitor.hasInternet {
                    Text("in \(prayerData.upcomingPrayerTimeLeft)")
                        .font(.callout)
                        .foregroundStyle(prayerData.upcomingPrayerTimeLeft.contains("h") ? .gray : .red)
                }
            }
            
            Spacer()
            
            Text(time)
                .fontWeight(isCurrentPrayer ? .semibold : .regular)
        }
        .foregroundStyle(isCurrentPrayer && environment.NetworkMonitor.hasInternet ? .accent : .primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accent.opacity(isCurrentPrayer && environment.NetworkMonitor.hasInternet ? 0.15 : 0))
        )
    }
    
    private func sunriseRow(time: String, isUpcoming: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label("Sunrise", systemImage: "sunrise")
                .font(.callout)
            
            if isUpcoming && environment.NetworkMonitor.hasInternet {
                Text("in \(prayerData.upcomingPrayerTimeLeft)")
                    .font(.callout)
                    .foregroundStyle(prayerData.upcomingPrayerTimeLeft.contains("h") ? .gray : .red)
            }
            
            Spacer()
            
            Text(time)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(prayerData.currentPrayer == "sunrise" && environment.NetworkMonitor.hasInternet ? 0.15 : 0))
        )
    }
    
    private var statusSection: some View {
        VStack(spacing: 4) {
            if !environment.NetworkMonitor.hasInternet {
                Label("Offline", systemImage: "wifi.slash")
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Text(prayerData.localTimezone)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("Last updated: \(prayerData.localTime)")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption)
    }
}

#Preview {
    NavigationStack {
        PrayerTimesView()
            .environmentObject(AppEnvironment.shared)
    }
}
