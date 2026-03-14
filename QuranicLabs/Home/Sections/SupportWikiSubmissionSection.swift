import SwiftUI
import StoreKit

struct Home_SupportWikiSubmissionSection: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            SectionLabel("SUPPORT WIKISUBMISSION")

            Card(title: "Review the App", options: .action(
                systemImage: "star",
                showChevron: true
            ) {
                if let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    AppStore.requestReview(in: scene)
                } else {
                    openURL(URL(string: About.appStoreURL)!)
                }
            })

            Card(title: "Share the App", options: .action(
                systemImage: "square.and.arrow.up",
                showChevron: true
            ) {
                shareText(About.appStoreURL)
            })

            Card(title: "Donate", options: .action(
                systemImage: "heart",
                showChevron: true
            ) {
                openURL(URL(string: "https://wikisubmission.org/donate")!)
            })

            Text("Donations are external and do not unlock any in-app features or content. WikiSubmission is a registered 501(c)3 nonprofit.")
                .font(.system(size: 11))
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .padding(.top, DS.Spacing.xs)
        }
    }
}
