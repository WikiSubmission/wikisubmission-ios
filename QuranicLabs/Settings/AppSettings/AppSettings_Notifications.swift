import SwiftUI

struct AppSettings_Notifications: View {
    var body: some View {
        NavigationLink {
            Notifications()
        } label: {
            Label("Notifications", systemImage: "bell")
        }
    }
}
