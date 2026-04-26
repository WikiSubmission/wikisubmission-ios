import SwiftUI

struct Home_FooterSection: View {
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image("wikisubmission")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding(.bottom, 4)
            
            HStack {
                Button {
                    openURL(URL(string: "https://wikisubmission.org")!)
                } label: {
                    Text("WIKISUBMISSION.ORG")
                        .font(DS.Typography.eyebrow)
                        .fontWeight(.light)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .pushToCenter()
                }
                .buttonStyle(.plain)
            }
         
            Text("Version \(About.version)")
                .font(DS.Typography.eyebrow)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .pushToCenter()
        }
    }
}
