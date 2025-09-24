import SwiftUI
import SafariServices

struct WebView: UIViewControllerRepresentable {
  let url: URL
  
  func makeUIViewController(context: Context) -> SFSafariViewController {
    return SFSafariViewController(url: url)
  }
  
  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    // Update the view controller if needed
  }
}
