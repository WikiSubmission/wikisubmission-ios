import SwiftUI

struct InternetRequired: ViewModifier {

    @ObservedObject var networkMonitor = Utilities.System.NetworkMonitor.shared

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
            
            Button {
                Utilities.System.openPermissionSettings()
            } label: {
                Text("Open Settings")
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
            }
            .background(Color.accent.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            Text(reason ?? "This feature requires an internet connection.")
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        InternetRequiredContent()
    }
}
