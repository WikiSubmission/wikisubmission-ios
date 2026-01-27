import Foundation
import SwiftUI

extension TimeInterval {
    /// Convert TimeInterval (seconds since 1970) to Date
    var asDate: Date {
        Date(timeIntervalSince1970: self)
    }

    /// Relative formatted date (e.g. "3 days ago")
    func formattedRelative(relativeTo ref: Date = Date(),
                           unitsStyle: RelativeDateTimeFormatter.UnitsStyle = .full) -> String {
        let interval = abs(self.asDate.timeIntervalSince(ref))
        
        if interval < 10 {
            return "just now"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = unitsStyle
        return formatter.localizedString(for: self.asDate, relativeTo: ref)
    }
}
