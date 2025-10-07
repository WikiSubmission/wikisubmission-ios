import SwiftUI

struct GlobalAlertView: View {
    let alert: Utilities.System.GlobalAlert
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: alert.systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(alert.type.color)
                
                Text(alert.title)
                    .font(.title)
                    .bold()
                
                if let subtitle = alert.subtitle {
                    Text(.init(subtitle))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                if alert.showSettingsButton ?? false {
                    Button {
                        Utilities.System.openPermissionSettings()
                    } label: {
                        Text("Open Settings")
                    }
                    .buttonStyle(SignatureButtonStyle())
                }
                
                if alert.showAppStoreButton ?? false {
                    Button {
                        UIApplication.shared.open(URL(string: Info.appStoreURL)!)
                    } label: {
                        Text("Open App Store")
                    }
                    .buttonStyle(SignatureButtonStyle())
                }
            }
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        Text("Some View")
    }
    .sheet(isPresented: .constant(true)) {
        GlobalAlertView(alert: .init(
            title: "No Internet",
            subtitle: "An internet connection is required to use this feature.",
            systemImage: "wifi.exclamationmark",
            type: .success,
            showSettingsButton: false,
            showAppStoreButton: false
        ))
    }
}
