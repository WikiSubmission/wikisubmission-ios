import Defaults

enum QuranReciters: String, CaseIterable, Defaults.Serializable {
    case callum
    case onyx
    case mishary, basit, minshawi

    var speciality: String {
        switch self {
        case .callum: return "Warm male voice"
        case .onyx: return "Deep male voice"
        case .mishary: return "Paced and consistent"
        case .basit: return "Slow and poetic"
        case .minshawi: return "Deep and rhythmic"
        }
    }

    var displayName: String {
        switch self {
        case .callum: return "Callum"
        case .onyx: return "Onyx"
        case .mishary: return "Mishary Alafasy"
        case .basit: return "Abdul Basit"
        case .minshawi: return "Mohamed Minshawi"
        }
    }

    var image: String {
        switch self {
        case .callum: return "callum"
        case .onyx: return "onyx"
        case .mishary: return "mishary"
        case .basit: return "basit"
        case .minshawi: return "minshawi"
        }
    }

    var language: QuranRecitationLanguages {
        switch self {
        case .callum, .onyx: return .english
        default: return .arabic
        }
    }
}

enum QuranRecitationLanguages: String {
    case english, arabic
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "Arabic"
        }
    }
}
