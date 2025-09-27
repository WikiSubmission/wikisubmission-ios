import SwiftUI
import Defaults
import UserNotifications

struct NotificationsView: View {
    @State private var authorization: UNAuthorizationStatus? = nil
    
    @Default(.prompted_for_notifications) var promptedForNotifications
    @Default(.prayer_notifications) var prayerNotifications
    @Default(.fajr_notification) var fajrNotifications
    @Default(.dhuhr_notification) var dhuhrNotifications
    @Default(.asr_notification) var asrNotifications
    @Default(.maghrib_notification) var maghribNotifications
    @Default(.isha_notification) var ishaNotifications
    
    @Default(.device_token) var deviceToken
    @Default(.prayer_time_location) var prayerTimeLocation
    
    var body: some View {
        NavigationStack {
            VStack {
                if let authorization = authorization {
                    if authorization == .authorized {
                        List {
                            Section("ENABLE NOTIFICATIONS") {
                                Toggle(isOn: $prayerNotifications) {
                                    Text("Prayer Times")
                                }
                            }
                            
                            if prayerNotifications {
                                Section("PRAYERS") {
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
                                .onChange(of: prayerNotifications) { _, newValue in
                                    Task {
                                        try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                                    }
                                }
                                .onChange(of: fajrNotifications) { _, newValue in
                                    Task {
                                        try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                                    }
                                }
                                .onChange(of: dhuhrNotifications) { _, newValue in
                                    Task {
                                        try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                                    }
                                }
                                .onChange(of: asrNotifications) { _, newValue in
                                    Task {
                                        try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                                    }
                                }
                                .onChange(of: maghribNotifications) { _, newValue in
                                    Task {
                                        try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                                    }
                                }
                                .onChange(of: ishaNotifications) { _, newValue in
                                    Task {
                                        try? await Utilities.Supabase.NotificationsTable.syncWithServer()
                                    }
                                }
                            }
                            
                            Button {
                                let content = UNMutableNotificationContent()
                                content.title = "Test Notification"
                                content.body = "This is just a test."
                                
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                                
                                UNUserNotificationCenter.current().add(request)
                            } label: {
                                Label("Send Test Notification", systemImage: "bell.fill")
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
        }
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings() { settings in
                self.authorization = settings.authorizationStatus
            }
            
            Task {
                try? await Utilities.Supabase.NotificationsTable.syncWithServer()
            }
        }
    }
}

#Preview {
    NotificationsView()
}
