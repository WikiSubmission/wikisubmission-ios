import SwiftUI

struct DataLoading: View {
    var statusText: String
    var title: String = "WikiSubmission"

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Spacer()

            VStack(spacing: 12) {
                Image("wikisubmission")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)

                Text(title)
                    .font(DS.Typography.heroMD)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
            }

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                ProgressView()
                Text(statusText)
                    .font(DS.Typography.eyebrow)
                    .foregroundStyle(.secondary)
            }
            .opacity(animateIn ? 1 : 0)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animateIn = true
            }
        }
    }
}
