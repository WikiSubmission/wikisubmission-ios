import SwiftUI
import Defaults

enum QuranArabicFont: String, CaseIterable, Defaults.Serializable {
    case system = "System"
    case amiriQuran = "Amiri Quran"

    var fontName: String? {
        switch self {
        case .system:
            return nil
        case .amiriQuran:
            return "AmiriQuran-Regular"
        }
    }

    /// Size adjustment to normalize visual size across fonts
    var sizeAdjustment: CGFloat {
        switch self {
        case .system:
            return 0
        case .amiriQuran:
            return 0
        }
    }

    /// Line spacing for compact Arabic view
    var lineSpacing: CGFloat {
        switch self {
        case .system:
            return 20
        case .amiriQuran:
            return 20
        }
    }

    func font(size: CGFloat) -> Font {
        let adjustedSize = size + sizeAdjustment
        if let fontName {
            return .custom(fontName, size: adjustedSize)
        }
        return .system(size: adjustedSize)
    }
}
