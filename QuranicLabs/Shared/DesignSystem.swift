import SwiftUI

// MARK: - Spacing & Radius Tokens

enum DS {
    enum Spacing {
        static let xs:      CGFloat = 4
        static let sm:      CGFloat = 8
        static let md:      CGFloat = 12
        static let lg:      CGFloat = 16
        static let xl:      CGFloat = 24
        static let xxl:     CGFloat = 32
        static let section: CGFloat = 48
    }

    enum Radius {
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let pill: CGFloat = 24
    }
}

// MARK: - SectionLabel

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .tracking(2)
    }
}
