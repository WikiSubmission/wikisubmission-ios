import SwiftUI
import Defaults
import UserNotifications

struct NotificationsView: View {
    @State private var authorization: UNAuthorizationStatus? = nil
    @Environment(\.scenePhase) private var scenePhase

    @Default(.device_token) var deviceToken
    @Default(.prompted_for_notifications) var promptedForNotifications
    
    @Default(.prayer_notifications) var prayerNotifications
    @Default(.prayer_time_location) var prayerTimeLocation
    @Default(.fajr_notification) var fajrNotifications
    @Default(.dhuhr_notification) var dhuhrNotifications
    @Default(.asr_notification) var asrNotifications
    @Default(.maghrib_notification) var maghribNotifications
    @Default(.isha_notification) var ishaNotifications
    
    @Default(.random_verse_notifications) var randomVerseNotifications
    @Default(.random_chapter_notifications) var randomChapterNotifications
    
    var body: some View {
        NavigationStack {
            VStack {
                if let authorization = authorization {
                    if authorization == .authorized {
                        List {
                            Section(header: Text("ENABLE NOTIFICATIONS"), footer: prayerTimeLocation?.count ?? 0 > 0 ? nil : Label("Add a city on the prayer time section so we can calculate your prayer times (and send reminders).", systemImage: "exclamationmark.triangle")) {
                                Toggle(isOn: $prayerNotifications) {
                                    Text("Prayer Times")
                                }
                            }
                            .onChange(of: prayerNotifications) { _, newState in
                                Task {
                                    try? await Utilities.Notifications.syncWithDatabase()
                                }
                                if newState == true {
                                    alertNotificationsEnabled()
                                }
                            }
                            
                            if prayerNotifications {
                                PrayerNotificationsSection(
                                    fajrNotifications: $fajrNotifications,
                                    dhuhrNotifications: $dhuhrNotifications,
                                    asrNotifications: $asrNotifications,
                                    maghribNotifications: $maghribNotifications,
                                    ishaNotifications: $ishaNotifications
                                )
                            }
                            
                            QuranNotificationsSection(
                                randomVerseNotifications: $randomVerseNotifications,
                                randomChapterNotifications: $randomChapterNotifications
                            )
                            
                            Button {
                                guard let token = deviceToken, !token.isEmpty else { return }
                                guard let url = URL(string: "https://notifications.wikisubmission.org/random-verse") else { return }
                                var request = URLRequest(url: url)
                                request.httpMethod = "POST"
                                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                let body: [String: String] = ["device_token": token]
                                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                                let task = URLSession.shared.dataTask(with: request) { _, _, _ in }
                                task.resume()
                            } label: {
                                Text("Send Test Notification")
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else if authorization == .denied {
                        ErrorView(details: .init(title: "Notifications Denied", message: "You can enable it through your phone settings", icon: "bell.slash", showPermissionSettingsButton: true))
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "bell")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.accent)
                            Button {
                                promptedForNotifications = true
                                Utilities.System.registerForPushNotifications()
                            } label: {
                                Text("Grant Permissions")
                            }
                            .buttonStyle(SignatureButtonStyle())
                            
                            Text("To send you notifications, grant the app the required permissions.")
                                .font(.footnote)
                                .fontWeight(.light)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Notifications")
            .toolbarTitleDisplayMode(.large)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshAuthorization()
            }
        }
        .task {
            refreshAuthorization()
            try? await Utilities.Notifications.syncWithDatabase()
        }
    }
    
    private func refreshAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorization = settings.authorizationStatus
                if settings.authorizationStatus == .authorized {
                    Task {
                        try? await Utilities.Notifications.syncWithDatabase()
                    }
                }
            }
        }
    }
    
    private func alertNotificationsEnabled() {
        let content = UNMutableNotificationContent()
        content.title = "All set!"
        content.body = "Notifications are now enabled. You can adjust what you need in the app!"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

private struct PrayerNotificationsSection: View {
    @Binding var fajrNotifications: Bool
    @Binding var dhuhrNotifications: Bool
    @Binding var asrNotifications: Bool
    @Binding var maghribNotifications: Bool
    @Binding var ishaNotifications: Bool
    
    var body: some View {
        Section(header: Text("PRAYER REMINDERS"), footer: Text("Prayer reminders are sent 10 minutes before each enabled prayer.")) {
            Toggle(isOn: $fajrNotifications) {
                Text("Fajr")
            }
            Toggle(isOn: $dhuhrNotifications) {
                Text("Dhuhr")
            }
            Toggle(isOn: $asrNotifications) {
                Text("Asr")
            }
            Toggle(isOn: $maghribNotifications) {
                Text("Maghrib")
            }
            Toggle(isOn: $ishaNotifications) {
                Text("Isha")
            }
        }
        .onChange(of: fajrNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
        .onChange(of: dhuhrNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
        .onChange(of: asrNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
        .onChange(of: maghribNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
        .onChange(of: ishaNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
    }
}

private struct QuranNotificationsSection: View {
    @Binding var randomVerseNotifications: Bool
    @Binding var randomChapterNotifications: Bool
    
    var body: some View {
        Section(header: Text("QURAN REMINDERS"), footer: Text("These are sent once a day.")) {
            Toggle(isOn: $randomChapterNotifications) {
                Text("Daily Chapter")
            }
            Toggle(isOn: $randomVerseNotifications) {
                Text("Daily Verse")
            }
        }
        .onChange(of: randomVerseNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
        .onChange(of: randomChapterNotifications) { _, _ in
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
    }
}

#Preview {
    NotificationsView()
}
