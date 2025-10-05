import SwiftUI
import Defaults

extension Utilities.Quran {
    
    struct QueryParser {
        @MainActor
        static func parse(_ input: String) -> Types.Quran.ParsedQuery {
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !trimmed.isEmpty else {
                return .invalid
            }

            // MARK: - Chapter only (e.g., "1")
            if let chapterOnly = trimmed.range(of: #"^(\d+)$"#, options: .regularExpression) {
                if let _ = Int(trimmed[chapterOnly]) {
                    return .chapter
                }
            }

            // MARK: - Single verse (e.g., "1:1")
            if let verseMatch = trimmed.range(of: #"^(\d+)[:\s]+(\d+)$"#, options: .regularExpression) {
                let parts = trimmed[verseMatch].split { ": ".contains($0) }.compactMap { Int($0) }
                if parts.count == 2 {
                    return .verse
                }
            }

            // MARK: - Verse range (e.g., "1:1-5")
            if let rangeMatch = trimmed.range(of: #"^(\d+)[:\s]+(\d+)[-\s]+(\d+)$"#, options: .regularExpression) {
                let parts = trimmed[rangeMatch].split { ": -".contains($0) }.compactMap { Int($0) }
                if parts.count == 3 {
                    return .verseRange
                }
            }

            // MARK: - Multiple verses (e.g., "1:1, 2:3, 10:1-2")
            /// TODO

            switch trimmed {
            default:
                return .search
            }
        }
    }
}
