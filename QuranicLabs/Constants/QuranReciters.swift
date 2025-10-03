import Defaults

enum QuranReciters: String, CaseIterable, Defaults.Serializable {
    case mishary, basit, minshawi
        
    var speciality: String {
        switch self {
        case .mishary: return "Paced and consistent"
        case .basit: return "Slow and poetic"
        case .minshawi: return "Deep and rhythmic"
        }
    }

    var displayName: String {
        switch self {
        case .mishary: return "Mishary Alafasy"
        case .basit: return "Abdul Basit"
        case .minshawi: return "Mohamed Minshawi"
        }
    }

    var image: String {
        switch self {
        case .mishary: return "mishary"   // put asset names here
        case .basit: return "basit"
        case .minshawi: return "minshawi"
        }
    }
}
