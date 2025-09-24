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
                                HStack {
                                    Button {
                                        
                                        if environment.NetworkMonitor.hasInternet {
                                            environment.PrayerTimesManager.fetchPrayerTimes(for: "\(location.city), \(location.administrativeArea ?? ""), \(location.country ?? "")")
                                            query = ""
                                            presentSearchbar = false
                                        } else {
                                            SheetKit().presentWithEnvironment {
                                                ErrorDetails.networkError
                                            }
                                        }
                                        
                                    } label: {
                                        HStack {
                                            Text("\(location.city)\(location.administrativeArea != nil ? ", \(location.administrativeArea ?? "")" : "")")
                                                .font(.headline)
                                                .foregroundStyle(.accent)
                                            Spacer()
                                            if let country = location.country {
                                                Text(country)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .listStyle(.insetGrouped)
                        } else if let prayerData = environment.PrayerTimesManager.prayerTimesData {
                            ScrollView {
                                VStack(spacing: 32) {
                                    PrayerTimesCard(prayerData: prayerData)
                                    
                                    Button {
                                        presentDeleteConfirmation = true
                                    } label: {
                                        Text("Remove City")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding()
                            }
                        } else {
                            PlaceholderView()
                                .padding(.top, 50)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Prayer Times")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                environment.PrayerTimesManager.refresh()
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { _ in
                    Task {
                        await MainActor.run {
                            environment.PrayerTimesManager.refresh()
                        }
                    }
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
            .searchable(text: $query, isPresented: $presentSearchbar, prompt: "Enter your city")
            .confirmationDialog("Remove this city? You can add it back later.", isPresented: $presentDeleteConfirmation, titleVisibility: .visible) {
                Group {
                    Button("Delete", role: .destructive) {
                        environment.PrayerTimesManager.removeSavedCity()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                if newValue.isEmpty {
                    results = []
                } else {
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        if !Task.isCancelled {
                            searchLocations(for: newValue)
                        }
                    }
                }
            }
        }
    }
}

struct PrayerTimesCard: View {
    let prayerData: Types.PrayerTimes.PrayerTimesResponse
    @EnvironmentObject private var environment: AppEnvironment
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LargeCardWithoutDestination(title: prayerData.locationString, image: prayerData.countryCode.lowercased())
                
                VStack(spacing: 12) {
                    ForEach(["fajr","dhuhr","asr","maghrib","isha"], id: \.self) { key in
                        if let time = prayerData.times[key] {
                            HStack {
                                Text(key.capitalized)
                                if key == prayerData.currentPrayer && environment.NetworkMonitor.hasInternet {
                                    Image(systemName: "clock")
                                    Text("\(prayerData.currentPrayerTimeElapsed) ago")
                                        .foregroundStyle(.secondary)
                                        .fontWeight(.light)
                                }
                                if key == prayerData.upcomingPrayer && environment.NetworkMonitor.hasInternet {
                                    Text("in \(prayerData.upcomingPrayerTimeLeft)")
                                        .foregroundStyle(prayerData.upcomingPrayerTimeLeft.contains("h") ? .gray : .red)
                                        .fontWeight(.light)
                                }
                                Spacer()
                                Text(time)
                            }
                            .foregroundStyle(key == prayerData.currentPrayer && environment.NetworkMonitor.hasInternet ? .accent : .primary)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.accent.opacity(key == prayerData.currentPrayer && environment.NetworkMonitor.hasInternet ? 0.15 : 0))
                                    .padding(-6)
                            )
                        }
                    }
                    if let sunriseTime = prayerData.times["sunrise"] {
                        Divider()
                        HStack {
                            Image(systemName: "sunrise")
                            Text("Sunrise")
                            if prayerData.upcomingPrayer == "sunrise" && environment.NetworkMonitor.hasInternet {
                                Text("in \(prayerData.upcomingPrayerTimeLeft)")
                                    .foregroundStyle(prayerData.upcomingPrayerTimeLeft.contains("h") ? .gray : .red)
                                    .fontWeight(.light)
                            }
                            Spacer()
                            Text("\(sunriseTime)")
                        }
                        .foregroundStyle(.orange)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.orange.opacity(prayerData.currentPrayer == "sunrise" && environment.NetworkMonitor.hasInternet ? 0.15 : 0))
                                .padding(-6)
                        )
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                
                VStack(spacing: 4) {
                    if !environment.NetworkMonitor.hasInternet {
                        Label("Offline", systemImage: "wifi.slash")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                            .pushToRight()
                    }
                    
                    Text(prayerData.localTimezone)
                        .foregroundStyle(.secondary)
                        .pushToRight()
                    
                    Text("Last updated: \(prayerData.localTime)")
                        .foregroundStyle(.secondary)
                        .pushToRight()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .foregroundStyle(.accent)
            Text("Search for your city to see prayer times.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

extension PrayerTimesView {
    func searchLocations(for query: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            if let error = error {
                print("Geocoding error:", error)
                return
            }
            withAnimation {
                results = placemarks?.compactMap { placemark -> Types.PrayerTimes.PrayerTimesLocation? in
                    guard let coordinate = placemark.location?.coordinate else { return nil }
                    let name = placemark.name ?? placemark.locality ?? "Unknown"
                    return Types.PrayerTimes.PrayerTimesLocation(
                        city: name,
                        coordinate: coordinate,
                        country: placemark.country,
                        administrativeArea: placemark.administrativeArea,
                        locality: placemark.locality,
                        countryCode: placemark.isoCountryCode
                    )
                } ?? []
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PrayerTimesView()
}
