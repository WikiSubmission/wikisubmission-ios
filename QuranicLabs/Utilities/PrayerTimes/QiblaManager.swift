import Foundation
import SwiftUI
import CoreLocation

final class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentHeading: Double = 0
    @Published var qiblaDirection: Double = 0
    
    private let locationManager = CLLocationManager()
    
    // Default location
    private let defaultLocation = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
    
    // Cardinal points (fixed on compass)
    let cardinalPoints = [
        CardinalPoint(degrees: 0, label: "N"),
        CardinalPoint(degrees: 90, label: "E"),
        CardinalPoint(degrees: 180, label: "S"),
        CardinalPoint(degrees: 270, label: "W")
    ]
    
    // Computed properties for UI
    var directionDifference: Double {
        let diff = abs(currentHeading - qiblaDirection)
        return min(diff, 360 - diff)
    }
    
    var offsetDirection: OffsetDirection {
        // Determine if currentHeading is clockwise or counterclockwise relative to qiblaDirection
        let diff = currentHeading - qiblaDirection
        let normalizedDiff = (diff + 360).truncatingRemainder(dividingBy: 360)
        if normalizedDiff == 0 {
            return .none
        } else if normalizedDiff < 180 {
            return .clockwise
        } else {
            return .counterclockwise
        }
    }
    
    enum OffsetDirection {
        case clockwise
        case counterclockwise
        case none
    }
    
    var headingColor: Color {
        switch directionDifference {
        case 0..<5: return .green
        case 5..<15: return .orange
        case 15..<30: return .red
        default: return .accent
        }
    }
    
    var statusText: String {
        switch directionDifference {
        case 0..<5: return "Facing the Qibla"
        case 5..<15: return "Close"
        case 15..<30: return "Close"
        default: return "Keep Moving"
        }
    }

    var qiblaDirectionString: String {
        getCompassDirectionString(for: qiblaDirection) ?? "--"
    }
    
    private var lastFeedbackZone: Int? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        
        // Calculate Qibla direction using default location
        qiblaDirection = directionToMecca(userLatitude: defaultLocation.latitude,
                                         userLongitude: defaultLocation.longitude)
    }
    
    func start() {
        // Start compass heading updates (no permission required)
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stop() {
        locationManager.stopUpdatingHeading()
    }
    
    // Qibla calculation method
    private func directionToMecca(userLatitude: Double, userLongitude: Double) -> CLLocationDirection {
        let latDifference = 21.4225241 - userLatitude
        let lonDifference = 39.8261818 - userLongitude
        
        let angle = abs(atan2(lonDifference, latDifference) * 180 / .pi)
        
        return angle
    }
    
    // Helper method to get compass direction string
    func getCompassDirectionString(for heading: CLLocationDirection) -> String? {
        if heading < 0 { return nil }
        
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((heading + 22.5) / 45.0) & 7
        return directions[index]
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self.currentHeading = heading
            
            // Determine feedback zone based on directionDifference
            let diff = self.directionDifference
            let zone: Int
            if diff < 5 {
                zone = 0 // aligned
            } else if diff < 15 {
                zone = 1 // very close
            } else if diff < 30 {
                zone = 2 // close
            } else {
                zone = 3 // far
            }
            
            // Trigger haptic feedback only when entering a closer zone
            if let lastZone = self.lastFeedbackZone {
                if zone < lastZone {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                }
            } else {
                // First time feedback if aligned or very close
                if zone <= 1 {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                }
            }
            
            self.lastFeedbackZone = zone
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

struct CardinalPoint {
    let degrees: Double
    let label: String
}
