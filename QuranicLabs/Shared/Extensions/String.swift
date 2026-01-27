import Foundation

extension String {
    func capitalizeFirstLetter() -> String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
    
    func formattedRelativeDate() -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: self) else {
            return self
        }
        let interval = date.timeIntervalSince1970
        return interval.formattedRelative()
    }
}

