import SwiftUI
import Defaults

struct Prayer_Element_TimeCard: View {
    let data: PrayerAPIResponse
    let showLiveData: Bool

    @Default(.prayer_times_location) private var prayerTimesLocation
    @Default(.prayer_times_use_midpoint_method_for_asr) private var useMidpointAsr
    @State private var locationSheetIsPresented = false
    @ObservedObject var manager = PrayerManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Location header
            locationHeader

            // Prayer times list
            timesSection

            // Footer info
            footerSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $locationSheetIsPresented) {
            Prayer_Content_LocationSearch()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            if prayerTimesLocation != nil {
                Task {
                    await manager.fetchTimes()
                }
                manager.startAutoRefresh()
            }
        }
        .onDisappear {
            manager.stopAutoRefresh()
        }
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        Card(title: "\(data.location_string)", options: .action (
            image: data.country_code.lowercased()
        ) {
            locationSheetIsPresented = true
        })
    }

    // MARK: - Times Section

    private var timesSection: some View {
        VStack(spacing: 2) {
            // Primary prayers (excluding sunrise)
            ForEach(PrayerName.primaryPrayers, id: \.self) { prayer in
                Prayer_Element_TimeRow(
                    prayer: prayer,
                    time: data.times[prayer],
                    isCurrent: prayer == data.current_prayer,
                    isUpcoming: prayer == data.upcoming_prayer,
                    elapsed: data.current_prayer_time_elapsed,
                    timeLeft: data.upcoming_prayer_time_left,
                    showLiveData: showLiveData
                )
            }

            // Sunrise divider and row
            Divider()
                .padding(.vertical, 4)

            Prayer_Element_TimeRow(
                prayer: .sunrise,
                time: data.times.sunrise,
                isCurrent: data.current_prayer == .sunrise,
                isUpcoming: data.upcoming_prayer == .sunrise,
                elapsed: data.current_prayer_time_elapsed,
                timeLeft: data.upcoming_prayer_time_left,
                showLiveData: showLiveData
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.09))
        )
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 4) {
            // Offline indicator
            if !showLiveData {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                    Text("Offline")
                }
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Timezone
            Text(data.local_timezone)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Last updated
            Text("Last updated: \(data.local_time)")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Asr method notice
            if useMidpointAsr {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("Using midpoint method for Afternoon")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.system(size: 10))
        .monospaced()
    }
}
