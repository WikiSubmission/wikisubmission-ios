import SwiftUI
import Defaults
import UserNotifications

enum PrayerType {
    case fajr, dhuhr, asr, maghrib, isha, sunrise
}

struct Notifications: View {
    @StateObject private var vm = NotificationsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @Default(.notifications) private var notifications
    @Default(.prayer_notifications) private var prayerNotifications
    @Default(.fajr_notification) private var fajrNotifications
    @Default(.dhuhr_notification) private var dhuhrNotifications
    @Default(.asr_notification) private var asrNotifications
    @Default(.maghrib_notification) private var maghribNotifications
    @Default(.isha_notification) private var ishaNotifications
    @Default(.sunrise_notification) private var sunriseNotifications

    @Default(.daily_verse_notifications) private var dailyVerseNotifications
    @Default(.random_verse_notifications) private var randomVerseNotifications
    @Default(.announcement_notifications) private var announcementNotifications

    @Default(.prompted_for_notifications) private var promptedForNotifications
    @Default(.device_token) private var deviceToken
    
    @State private var testNotificationStatus: TestNotificationStatus = .idle
    
    enum TestNotificationStatus: Equatable {
        case idle
        case sending
        case sent
        case failed(String)
        
        var title: String {
            switch self {
            case .idle, .sending: return "Get a test notification"
            case .sent: return "Test notification sent"
            case .failed(let message): return message
            }
        }
        
        var systemImage: String {
            switch self {
            case .idle: return "bell"
            case .sending: return "progressview"
            case .sent: return "checkmark.circle.fill"
            case .failed: return "x.circle.fill"
            }
        }
        
        var cardStyle: CardStyle {
            switch self {
            case .idle, .sending: return .default
            case .sent: return .secondary
            case .failed: return .error
            }
        }
    }

    var body: some View {
        VStack {
            if let auth = vm.authorization, auth == .authorized {
                notificationAccessGranted
                    .task {
                        Task {
                            try await NotificationManager.shared.sync()
                        }
                    }
            } else {
                notificationAccessPendingOrDenied
            }
        }
        .task {
            vm.refreshAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { vm.refreshAuthorization() }
        }
    }

    private var notificationAccessGranted: some View {
        List {
            if !notifications {
                Section(footer: Text("All notifications are currently turned off. Your preferences are preserved.")) {
                    Button {
                        vm.toggleAllNotifications(true)
                    } label: {
                        Label("Turn on notifications", systemImage: "bell.badge")
                    }
                }
            }

            Section(header: Text("PRAYER REMINDERS"), footer: Text("Reminders are sent 10 minutes before each enabled prayer.")) {
                if notifications && prayerNotifications {
                    Toggle("Dawn", isOn: Binding(
                        get: { fajrNotifications },
                        set: { vm.togglePrayer(.fajr, enabled: $0) }
                    ))
                    Toggle("Noon", isOn: Binding(
                        get: { dhuhrNotifications },
                        set: { vm.togglePrayer(.dhuhr, enabled: $0) }
                    ))
                    Toggle("Afternoon", isOn: Binding(
                        get: { asrNotifications },
                        set: { vm.togglePrayer(.asr, enabled: $0) }
                    ))
                    Toggle("Sunset", isOn: Binding(
                        get: { maghribNotifications },
                        set: { vm.togglePrayer(.maghrib, enabled: $0) }
                    ))
                    Toggle("Night", isOn: Binding(
                        get: { ishaNotifications },
                        set: { vm.togglePrayer(.isha, enabled: $0) }
                    ))
                    Toggle("Sunrise", isOn: Binding(
                        get: { sunriseNotifications },
                        set: { vm.togglePrayer(.sunrise, enabled: $0) }
                    ))
                    Button(role: .destructive) {
                        vm.togglePrayerNotifications(false)
                    } label: {
                        Label("Turn off prayer reminders", systemImage: "bell.slash")
                            .foregroundStyle(.red)
                    }
                } else if notifications {
                    Toggle("Prayer Times", isOn: Binding(
                        get: { prayerNotifications },
                        set: { vm.togglePrayerNotifications($0) }
                    ))
                } else {
                    Toggle("Fajr", isOn: .constant(fajrNotifications))
                    Toggle("Dhuhr", isOn: .constant(dhuhrNotifications))
                    Toggle("Asr", isOn: .constant(asrNotifications))
                    Toggle("Maghrib", isOn: .constant(maghribNotifications))
                    Toggle("Isha", isOn: .constant(ishaNotifications))
                    Toggle("Sunrise", isOn: .constant(sunriseNotifications))
                }
            }
            .disabled(!notifications)

            Section(header: Text("QURAN REMINDERS"), footer: Text("Random verses are sent every once in a while.")) {
                Toggle("Random Verse", isOn: notifications ? Binding(
                    get: { randomVerseNotifications },
                    set: { vm.toggleRandomVerse($0) }
                ) : .constant(randomVerseNotifications))
                Toggle("Daily Verse", isOn: notifications ? Binding(
                    get: { dailyVerseNotifications },
                    set: { vm.toggleDailyVerse($0) }
                ) : .constant(dailyVerseNotifications))
            }
            .disabled(!notifications)

            Section(header: Text("GENERAL"), footer: Text("These are infrequent but may include important updates or announcements.")) {
                Toggle("Announcements", isOn: notifications ? Binding(
                    get: { announcementNotifications },
                    set: { vm.toggleAnnouncements($0) }
                ) : .constant(announcementNotifications))
            }
            .disabled(!notifications)

            if notifications {
                Button(role: .destructive) {
                    vm.toggleAllNotifications(false)
                } label: {
                    Label("Turn off all notifications", systemImage: "bell.slash")
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text("DEVICE TOKEN")) {
                Text("\(deviceToken ?? "--")")
                    .font(.caption2)
                    .fontWeight(.light)
                    .monospaced()
                    .textSelection(.enabled)
            }
            
            
            if notifications {
                Section {
                    Card(title: testNotificationStatus.title, options: .action(
                        systemImage: testNotificationStatus.systemImage,
                        style: testNotificationStatus.cardStyle
                    ) {
                        if testNotificationStatus == .idle {
                            Task {
                                withAnimation {
                                    testNotificationStatus = .sending
                                }
                                
                                guard NetworkManager.shared.hasInternet else {
                                    withAnimation {
                                        testNotificationStatus = .failed("Internet connection required")
                                    }
                                    return
                                }
                                
                                guard let authToken = try? await SupabaseManager.shared.requireSession().accessToken else {
                                    withAnimation {
                                        testNotificationStatus = .failed("Failed: missing auth token")
                                    }
                                    return
                                }
                                
                                guard let deviceToken = deviceToken else {
                                    withAnimation {
                                        testNotificationStatus = .failed("Missing device token")
                                    }
                                    return
                                }
                                
                                // [URL]
                                var request = URLRequest(url: URL(string: "https://push-notifications.wikisubmission.org/send-notification")!)
                                
                                // [Method]
                                request.httpMethod = "POST"
                                
                                // [Headers]
                                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                
                                // [Body]
                                let requestBody: [String: String] = [
                                      "device_token": deviceToken,
                                      "platform": "ios",
                                      "category": "RANDOM_VERSE"
                                ]
                                request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
                                
                                // [Send]
                                do {
                                    let (_, response) = try await URLSession.shared.data(for: request)
                                    if let httpResponse = response as? HTTPURLResponse {
                                        if httpResponse.statusCode == 200 {
                                            withAnimation {
                                                testNotificationStatus = .sent
                                            }
                                        } else {
                                            withAnimation {
                                                testNotificationStatus = .failed("Failed: \(httpResponse.statusCode)")
                                            }
                                        }
                                    } else {
                                        withAnimation {
                                            testNotificationStatus = .failed("API Error")
                                        }
                                    }
                                } catch {
                                    withAnimation {
                                        testNotificationStatus = .failed(error.localizedDescription)
                                    }
                                }
                            }
                        }
                    })
                    .removeParentListStyle()
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var notificationAccessPendingOrDenied: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.accent)

            if vm.authorization == .notDetermined {
                Button {
                    promptedForNotifications = true
                    NotificationManager.registerForPushNotifications()
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
                    .onDisappear {
                        Task { @MainActor in
                            if vm.authorization == .authorized {
                                vm.alertNotificationsEnabled()
                                try? await NotificationManager.shared.sync()
                            }
                        }
                    }
            } else {
                Button {
                    DispatchQueue.main.async {
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: nil)
                        }
                    }
                } label: {
                    Text("Open Permission Settings")
                }
                .buttonStyle(SignatureButtonStyle())

                Text("Missing access. Please grant the app notification permissions")
                    .font(.footnote)
                    .fontWeight(.light)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var authorization: UNAuthorizationStatus? = nil

    private let notificationManager = NotificationManager.shared

    func refreshAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorization = settings.authorizationStatus
            }
        }
    }

    func togglePrayer(_ type: PrayerType, enabled: Bool) {
        switch type {
        case .fajr: Defaults[.fajr_notification] = enabled
        case .dhuhr: Defaults[.dhuhr_notification] = enabled
        case .asr: Defaults[.asr_notification] = enabled
        case .maghrib: Defaults[.maghrib_notification] = enabled
        case .isha: Defaults[.isha_notification] = enabled
        case .sunrise: Defaults[.sunrise_notification] = enabled
        }
        Task { @MainActor in
            try? await notificationManager.sync([.prayerTimes])
        }
    }

    func toggleDailyVerse(_ enabled: Bool) {
        Defaults[.daily_verse_notifications] = enabled
        Task { @MainActor in
            try? await notificationManager.sync([.dailyVerse])
        }
    }

    func toggleRandomVerse(_ enabled: Bool) {
        Defaults[.random_verse_notifications] = enabled
        Task { @MainActor in
            try? await notificationManager.sync([.randomVerse])
        }
    }

    func toggleAnnouncements(_ enabled: Bool) {
        Defaults[.announcement_notifications] = enabled
        Task { @MainActor in
            try? await notificationManager.sync([.announcements])
        }
    }

    func togglePrayerNotifications(_ enabled: Bool) {
        Defaults[.prayer_notifications] = enabled
        Task { @MainActor in
            try? await notificationManager.sync([.prayerTimes])
        }
    }
    
    func toggleAllNotifications(_ enabled: Bool) {
        Defaults[.notifications] = enabled
        Task { @MainActor in
            try? await notificationManager.sync()
        }
    }

    func alertNotificationsEnabled() {
        let content = UNMutableNotificationContent()
        content.title = "All set!"
        content.body = "Notifications are now enabled. You can adjust what you need in the app!"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
