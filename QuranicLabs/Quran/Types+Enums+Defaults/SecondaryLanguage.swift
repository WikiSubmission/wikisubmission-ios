import SwiftUI
import Defaults

enum QuranSelectableSecondaryLanguage: String, CaseIterable, Defaults.Serializable, Defaults.PreferRawRepresentable {
    case none
    case english, turkish, french, german, bahasa, persian, persian_new, tamil, swedish, russian, bengali, spanish, urdu
    
    var displayText: String {
        switch self {
        case .persian_new: return "Persian (Alternative)"
        default: return self.rawValue.capitalizeFirstLetter()
        }
    }
    
    var countryCode: String? {
        switch self {
        case .none: return nil
        case .english: return "us"
        case .turkish: return "tr"
        case .french: return "fr"
        case .german: return "de"
        case .bahasa: return "my"
        case .persian: return "ir"
        case .persian_new: return "ir"
        case .tamil: return "in"
        case .swedish: return "se"
        case .russian: return "ru"
        case .bengali: return "bd"
        case .spanish: return "es"
        case .urdu: return "pk"
        }
    }
    
    var isRightToLeft: Bool {
        switch self {
        case .persian, .persian_new, .urdu:
            return true
        default:
            return false
        }
    }
}
