import Network
import SwiftUI

extension Utilities.System {
    class NetworkMonitor: ObservableObject {
        static let shared = NetworkMonitor()
        
        @Published var hasInternet: Bool = true
        private let monitor = NWPathMonitor()
        private let queue = DispatchQueue(label: "NetworkMonitor")
        
        private init() {
            monitor.pathUpdateHandler = { path in
                DispatchQueue.main.async {
                    self.hasInternet = path.status == .satisfied
                }
            }
            monitor.start(queue: queue)
        }
        
        func checkConnectivity() {
            // Trigger immediate check
            hasInternet = monitor.currentPath.status == .satisfied
        }
    }
}
