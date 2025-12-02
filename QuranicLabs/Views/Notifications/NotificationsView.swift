import SwiftUI
import Defaults
import UserNotifications

struct NotificationsView: View {
    @State private var authorization: UNAuthorizationStatus? = nil
    @Environment(\.scenePhase) private var scenePhase

    @Default(.device_token) var deviceToken
    @Default(.prompted_for_notifications) var promptedForNotifications
    
    @Default(.prayer_notifications) var prayerNotifications
    @Default(.prayer_times_location) var prayerTimeLocation
    @Default(.fajr_notification) var fajrNotifications
    @Default(.dhuhr_notification) var dhuhrNotifications
    @Default(.asr_notification) var asrNotifications
    @Default(.maghrib_notification) var maghribNotifications
    @Default(.isha_notification) var ishaNotifications
    @Default(.sunrise_notification) var sunriseNotifications

    @Default(.daily_verse_notifications) var dailyVerseNotifications
    @Default(.daily_chapter_notifications) var dailyChapterNotifications
    
    var body: some View {
        NavigationStack {
            VStack {
                if let authorization = authorization {
                    if authorization == .authorized {
                        List {
                            Section(header: Text("PRAYER REMINDERS"), footer: prayerTimeLocation?.count ?? 0 > 0 ?
                                    Label("Prayer reminders are sent generally 10-15 minutes before each enabled prayer.", systemImage: "info.circle") : Label("Add a city on the prayer time section so we can calculate your prayer times (and send reminders).", systemImage: "exclamationmark.triangle")
                            ) {
                                Toggle(isOn: $prayerNotifications) {
                                    Text("Prayer Times")
                                }
                                if prayerNotifications {
                                    NavigationLink {
                                        List {
                                            PrayerNotificationsSection(
                                                fajrNotifications: $fajrNotifications,
                                                dhuhrNotifications: $dhuhrNotifications,
                                                asrNotifications: $asrNotifications,
                                                maghribNotifications: $maghribNotifications,
                                                ishaNotifications: $ishaNotifications,
                                                sunriseNotifications: $sunriseNotifications
                                            )
                                            .navigationTitle("Customize Notifications")
                                            .navigationBarTitleDisplayMode(.inline)
                                        }
                                    } label: {
                                        Text("Customize Prayer Notifications")
                                    }
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
                            
                            QuranNotificationsSection(
                                randomVerseNotifications: $dailyVerseNotifications,
                                randomChapterNotifications: $dailyChapterNotifications
                            )
                            
                            if deviceToken != nil {
                                Section(header: Text("TECHNICAL")) {
                                    NavigationLink {
                                        DeviceTokenView(token: deviceToken!)
                                    } label: {
                                        Label("Device Token", systemImage: "barcode")
                                    }
                                }
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
            .navigationBarTitleDisplayMode(.inline)
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
    @Binding var sunriseNotifications: Bool

    var body: some View {
        Section {
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
            Toggle(isOn: $sunriseNotifications) {
                Text("Sunrise")
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
        .onChange(of: sunriseNotifications) { _, _ in
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
        Section(header: Text("QURAN REMINDERS"), footer: Label("These are sent once a day.", systemImage: "info.circle")) {
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

struct DeviceTokenView: View {
    @State private var reveal = false
    let token: String

    private var masked: String {
        let t = token
        guard t.count > 12 else { return t }
        return "\(t.prefix(6))...\(t.suffix(6))"
    }

    var body: some View {
        Form {
            Section(footer: Text("This token uniquely identifies your device for push notifications. Avoid sharing it publicly.")) {
                HStack {
                    Text(reveal ? token : masked)
                        .font(.system(.footnote, design: .monospaced))
                        .lineLimit(3)
                        .truncationMode(.middle)

                    Spacer()

                    Button(reveal ? "Hide" : "Reveal") {
                        reveal.toggle()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = token
                }
                .buttonStyle(.borderedProminent)
            }
            .textSelection(.enabled)
        }
        .navigationTitle("Device Token")
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AppEnvironment.shared)
}

