import SwiftUI

struct ErrorDetails {
  var title: String
  var message: String
  var icon: String
  var showPermissionSettingsButton: Bool?
  
  static let networkError = ErrorView(details: .init(title: "Network Error", message: "Please ensure you have a working internet connection.", icon: "network.slash"))
}

struct ErrorView: View {
  var details: ErrorDetails
  var body: some View {
    VStack {
      Image(systemName: details.icon)
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
        .padding(.horizontal)
      Text(details.title)
        .font(.title2)
        .fontWeight(.bold)
        .padding()
      Text(.init(details.message))
        .padding(.horizontal)
        .multilineTextAlignment(.center)
      if details.showPermissionSettingsButton != nil {
        Button("OPEN PERMISSION SETTINGS") {
            Utilities.System.openPermissionSettings()
        }
        .buttonStyle(SignatureButtonStyle())
        .padding(.top)
      }
    }
    .multilineTextAlignment(.center)
    .presentationDetents([.medium])
  }
}
