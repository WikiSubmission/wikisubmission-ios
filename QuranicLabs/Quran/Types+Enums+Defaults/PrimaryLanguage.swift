import SwiftUI
import Defaults

enum QuranSelectablePrimaryLanguage: String, CaseIterable, Defaults.Serializable, Defaults.PreferRawRepresentable {
    case english, turkish, french, german, bahasa, persian, tamil, swedish, russian, bengali, spanish, urdu
        
    var countryCode: String {
        switch self {
        case .english: return "us"
        case .turkish: return "tr"
        case .french: return "fr"
        case .german: return "de"
        case .bahasa: return "my"
        case .persian: return "ir"
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
        case .persian, .urdu:
            return true
        default:
            return false
        }
    }
}
