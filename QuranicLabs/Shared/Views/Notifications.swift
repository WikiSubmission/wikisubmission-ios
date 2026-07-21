import SwiftUI
import Defaults
import UserNotifications
import AVFoundation

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
    @Default(.prayer_notification_sound) private var prayerNotificationSound

    @Default(.daily_reminders_notifications) private var dailyRemindersNotifications
    @Default(.random_verse_notifications) private var randomVerseNotifications
    @Default(.announcement_notifications) private var announcementNotifications
    @Default(.prayer_live_activity) private var prayerLiveActivity

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
                    NavigationLink {
                        PrayerNotificationSoundPicker(
                            selection: Binding(
                                get: { prayerNotificationSound },
                                set: { vm.updatePrayerSound($0) }
                            )
                        )
                    } label: {
                        HStack {
                            Label("Notification Sound", systemImage: "speaker.wave.2")
                            Spacer()
                            Text(PrayerNotificationSoundOption.displayName(for: prayerNotificationSound))
                                .foregroundStyle(.secondary)
                        }
                    }
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

            Section(header: Text("LIVE ACTIVITY"), footer: Text("Shows a live countdown to the next prayer on your Lock Screen and Dynamic Island. The color follows the sun through the day.")) {
                Toggle("Prayer Countdown", isOn: Binding(
                    get: { prayerLiveActivity },
                    set: { vm.toggleLiveActivity($0) }
                ))
            }

            Section(header: Text("QURAN REMINDERS"), footer: Text("Daily reminders and daily verses are sent through our notification service once a day.")) {
                Toggle("Daily Verse", isOn: notifications ? Binding(
                    get: { randomVerseNotifications },
                    set: { vm.toggleRandomVerse($0) }
                ) : .constant(randomVerseNotifications))
                Toggle("Daily Reminders", isOn: notifications ? Binding(
                    get: { dailyRemindersNotifications },
                    set: { vm.toggleDailyReminders($0) }
                ) : .constant(dailyRemindersNotifications))
            }
            .disabled(!notifications)

            Section(header: Text("GENERAL"), footer: Text("These are infrequent but may include important community updates or announcements.")) {
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
                                      "category": "DAILY_VERSE"
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

    func toggleDailyReminders(_ enabled: Bool) {
        Defaults[.daily_reminders_notifications] = enabled
        Task { @MainActor in
            try? await notificationManager.sync([.dailyReminders])
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

    /// Toggle the salat countdown Live Activity: persist the preference,
    /// sync the registry, and start or end the Activity immediately.
    func toggleLiveActivity(_ enabled: Bool) {
        Defaults[.prayer_live_activity] = enabled
        Task { @MainActor in
            try? await notificationManager.sync([.liveActivities])
            await SalatLiveActivityManager.shared.ensureActivity()
        }
    }

    func updatePrayerSound(_ value: String) {
        Defaults[.prayer_notification_sound] = value
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

private struct PrayerNotificationSoundPicker: View {
    @Binding var selection: String
    @StateObject private var previewPlayer = PrayerSoundPreviewPlayer()

    var body: some View {
        List {
            ForEach(PrayerNotificationSoundOption.options) { option in
                HStack(spacing: 12) {
                    Button {
                        selection = option.value
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.displayName)
                                    .foregroundStyle(.primary)

                                if option.value == "default" {
                                    Text("Uses the standard notification tone.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if selection == option.value {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if option.fileURL != nil {
                        Button {
                            previewPlayer.toggle(option: option)
                        } label: {
                            Image(systemName: previewPlayer.isPreviewing(option.value) ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                Text(.init("These will take effect immediately for your next prayer notification. For new suggestions, send us an [\(About.contactEmail)](mailto:\(About.contactEmail)) or reach us on [Discord](\(About.developerDiscordLink))."))
                    .font(DS.Typography.eyebrow)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .navigationTitle("Notification Sound")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            previewPlayer.stop()
        }
    }
}

private struct PrayerNotificationSoundOption: Identifiable, Hashable {
    let value: String
    let displayName: String
    let fileURL: URL?

    var id: String { value }

    static var options: [PrayerNotificationSoundOption] {
        let bundlePaths = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
            .filter { URL(fileURLWithPath: $0).lastPathComponent.hasPrefix("call_to_prayer_") }
            .sorted {
                index(for: $0) < index(for: $1)
            }

        return [PrayerNotificationSoundOption(value: "default", displayName: "Default", fileURL: nil)] +
            bundlePaths.map { path in
                let url = URL(fileURLWithPath: path)
                let number = index(for: path)
                return PrayerNotificationSoundOption(
                    value: url.lastPathComponent,
                    displayName: number > 0 ? "Call to Prayer \(number)" : "Call to Prayer",
                    fileURL: url
                )
            }
    }

    static func displayName(for value: String) -> String {
        options.first(where: { $0.value == value })?.displayName ?? "Default"
    }

    private static func index(for path: String) -> Int {
        let filename = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        return Int(filename.replacingOccurrences(of: "call_to_prayer_", with: "")) ?? 0
    }
}

@MainActor
private final class PrayerSoundPreviewPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    @Published private var currentValue: String?
    @Published private var isPlaying = false

    func toggle(option: PrayerNotificationSoundOption) {
        if currentValue == option.value {
            stop()
            return
        }

        guard let fileURL = option.fileURL else {
            stop()
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            currentValue = option.value
            isPlaying = true
            player?.prepareToPlay()
            player?.play()
        } catch {
            stop()
        }
    }

    func isPreviewing(_ value: String) -> Bool {
        currentValue == value && isPlaying
    }

    func stop() {
        player?.stop()
        player = nil
        currentValue = nil
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        currentValue = nil
        isPlaying = false
    }
}
