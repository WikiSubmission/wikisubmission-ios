import SwiftUI
import CoreLocation

struct Prayer_Content_LocationSearch: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = PrayerManager.shared

    @State private var query = ""
    @State private var searchResults: [GeocodedLocation] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?
    @State private var debounceTask: Task<Void, Never>?
    @State private var searchBarIsPresented = false
    @FocusState private var searchBarIsFocused

    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Enter Location")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .searchable(text: $query, isPresented: $searchBarIsPresented, prompt: "Search city or region")
                .focused($searchBarIsFocused)
                .onChange(of: query) { _, newValue in
                    handleQueryChange(newValue)
                }
        }
        .onAppear {
            searchBarIsFocused = true
            searchBarIsPresented = true
        }
        .onDisappear {
            Task {
                try? await NotificationManager.shared.sync()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isSearching {
            loadingView
        } else if let error = errorMessage {
            errorView(error)
        } else if searchResults.isEmpty {
            emptyStateView
        } else {
            resultsList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await performSearch(query)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSearched ? "location.slash" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            if hasSearched {
                Text("No Results Found")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Enter Your City or Region")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Start typing to search for locations")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults.indices, id: \.self) { index in
                    locationRow(for: index)
                        .padding()
                }
            }
        }
    }

    @ViewBuilder
    private func locationRow(for index: Int) -> some View {
        let location = searchResults[index]
        Card(title: "\(location.displayString)", options: .action (
            subtitle: location.country != nil ? location.country! : nil,
            image: location.countryCode != nil ? location.countryCode!.lowercased() : nil,
            imageAlignment: .top,
            showChevron: true
        ) {
            selectLocation(location)
        })

        if index < searchResults.count - 1 {
            Divider()
                .padding(.leading, 56)
        }
    }

    // MARK: - Actions

    private func handleQueryChange(_ newValue: String) {
        debounceTask?.cancel()
        errorMessage = nil
        hasSearched = false

        guard newValue.count >= 2 else {
            searchResults = []
            return
        }

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(newValue)
        }
    }

    @MainActor
    private func performSearch(_ searchQuery: String) async {
        isSearching = true
        errorMessage = nil

        do {
            let placemarks = try await geocoder.geocodeAddressString(searchQuery)

            var locations: [GeocodedLocation] = []
            for placemark in placemarks {
                guard let coordinate = placemark.location?.coordinate else { continue }
                let city = placemark.locality ?? placemark.name ?? "Unknown"
                let location = GeocodedLocation(
                    city: city,
                    administrativeArea: placemark.administrativeArea,
                    country: placemark.country,
                    countryCode: placemark.isoCountryCode,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                locations.append(location)
            }

            // Remove duplicates
            var seen = Set<String>()
            let uniqueLocations = locations.filter { location in
                let key = "\(location.displayString)-\(location.country ?? "")"
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                searchResults = uniqueLocations
            }

        } catch {
            errorMessage = "Unable to search locations. Check your connection."
            searchResults = []
        }

        hasSearched = true
        isSearching = false
    }

    private func selectLocation(_ location: GeocodedLocation) {
        Task {
            await manager.setLocation(location.queryString)
            dismiss()
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(String(unicodeScalar))
            }
        }
        return emoji
    }
}
