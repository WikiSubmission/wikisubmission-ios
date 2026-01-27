import SwiftUI
import Network

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var hasInternet: Bool = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkManager")
    
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
