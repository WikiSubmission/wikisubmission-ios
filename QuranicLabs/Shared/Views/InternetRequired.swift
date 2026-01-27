import SwiftUI

struct InternetRequired: ViewModifier {

    @ObservedObject var networkMonitor = NetworkManager.shared

    var reason: String?
    func body(content: Content) -> some View {
        Group {
            if networkMonitor.hasInternet {
                content
            } else {
                InternetRequiredContent(reason: reason)
            }
        }
    }
}

struct InternetRequiredContent: View {
    var reason: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            
            Text(reason ?? "This feature requires an internet connection.")
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
