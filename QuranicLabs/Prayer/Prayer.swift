import SwiftUI
import Defaults
import UserNotifications

struct Prayer: View {
    @ObservedObject private var router = Router.shared
    @ObservedObject private var manager = PrayerManager.shared
    @ObservedObject private var network = NetworkManager.shared

    @Default(.prayer_times_location) private var prayerTimesLocation
    @Default(.notifications) private var notifications
    @Default(.prayer_notifications) private var prayerNotifications

    @State private var showLocationSearch = false

    private var hasInternet: Bool {
        network.hasInternet
    }

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .prayer)) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    if prayerTimesLocation == nil || prayerTimesLocation?.isEmpty == true {
                        noLocationView
                    } else if let data = manager.prayerData {
                        VStack {
                            // Main prayer times card
                            Prayer_Element_TimeCard(
                                data: data,
                                showLiveData: manager.hasValidLiveData && hasInternet
                            )
                        }
                        
                        VStack(spacing: 4) {
                            // Notifications
                            if !prayerNotifications || !notifications {
                                Card(title: "Notifications", options: .destination(
                                    subtitle: "Get real-time prayer alerts",
                                    systemImage: "bell",
                                    style: .accent
                                ){
                                    Notifications()
                                })
                            } else {
                                Card(title: "Notifications", options: .destination(
                                    systemImage: "bell"
                                ){
                                    Notifications()
                                })
                            }
                            
                            // 30 Day Schedule
                            if !data.schedule.isEmpty {
                                Prayer_Element_PrayerSchedule(schedule: data.schedule)
                            }
                            
                            // Qibla (if applicable)
                            if data.isInNorthAmerica {
                                Card(title: "Qibla", options: .destination(
                                    systemImage: "safari"
                                ){
                                    Prayer_Element_Qibla()
                                })
                            }
                            
                            // Ramadan
                            Card(title: "Ramadan", options: .destination(
                                systemImage: "moon.stars"
                            ){
                                Prayer_Element_Ramadan2026()
                            })
                            
                            // Prayer guide
                            Card(title: "Prayer Guide", options: .destination(
                                systemImage: "questionmark.circle.dashed"
                            ){
                                Prayer_Element_PrayerTutorial()
                            })
                            
                            // Location update
                            Card(title: "Update Location", options: .action(
                                systemImage: "location",
                                showChevron: true,
                                style: .secondary
                            ){
                                showLocationSearch = true
                            })
                            
                            if AudioManager.shared.currentTrack != nil {
                                Color.clear.frame(height: 56)
                            }
                        }
                    } else if manager.state.isLoading {
                        loadingView
                    } else if let error = manager.state.errorMessage {
                        errorView(error)
                    } else {
                        loadingView
                    }
                }
                .padding()
            }
            .navigationTitle("Prayer")
            .toolbar {
                if prayerTimesLocation != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            Button {
                                shareText("https://wikisubmission.org/prayer-times?q=\(Defaults[.prayer_times]?.location_string ?? prayerTimesLocation ?? "" )\(Defaults[.prayer_times_use_midpoint_method_for_asr] == true ? "&asr_adjustment=true" : "")")
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Menu {
                                Button {
                                    showLocationSearch = true
                                } label: {
                                    Label("Change Location", systemImage: "location")
                                }

                                Button(role: .destructive) {
                                    manager.clearData()
                                } label: {
                                    Label("Reset", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showLocationSearch) {
                Prayer_Content_LocationSearch()
                    .presentationDetents([.medium, .large])
            }
            .onDisappear {
                manager.stopAutoRefresh()
            }
            .onAppear {
                if prayerTimesLocation != nil && manager.prayerData == nil && !manager.state.isLoading {
                    Task {
                        await manager.fetchTimes()
                    }
                }
            }
        }
    }

    private var noLocationView: some View {
        Card(
            title: "Add Location",
            options: .action(
                subtitle: "Enter your city to track prayer times.",
                systemImage: "plus.app",
                imageAlignment: .top,
                style: .accent
            ) {
                showLocationSearch = true
            }
        )
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await manager.fetchTimes()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    Prayer()
}
