import Foundation

extension Date {
    func timeOnly(style: DateFormatter.Style = .short) -> String {
        DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: style)
    }
}
