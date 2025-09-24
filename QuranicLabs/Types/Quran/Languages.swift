import Defaults

extension Types.Quran {
    enum PrimaryLanguage: String, CaseIterable, Defaults.Serializable, Defaults.PreferRawRepresentable {
        case english, turkish, french, german, bahasa, persian, tamil, swedish, russian

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
            }
        }

        var flag: String {
            countryCode
                .unicodeScalars
                .map { 127397 + $0.value }
                .compactMap { UnicodeScalar($0) }
                .map { String($0) }
                .joined()
        }
    }

    enum SecondaryLanguage: String, CaseIterable, Defaults.Serializable, Defaults.PreferRawRepresentable {
        case none, english, turkish, french, german, bahasa, persian, tamil, swedish, russian

        var countryCode: String? {
            switch self {
            case .none: return nil
            case .english: return "us"
            case .turkish: return "tr"
            case .french: return "fr"
            case .german: return "de"
            case .bahasa: return "my"
            case .persian: return "ir"
            case .tamil: return "in"
            case .swedish: return "se"
            case .russian: return "ru"
            }
        }

        var flag: String {
            guard let code = countryCode else { return "" }
            return code
                .unicodeScalars
                .map { 127397 + $0.value }
                .compactMap { UnicodeScalar($0) }
                .map { String($0) }
                .joined()
        }
    }
}
