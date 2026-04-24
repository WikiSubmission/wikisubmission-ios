import SwiftUI
import SwiftData
import Defaults

struct Onboarding: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var animateIn = false

    @Default(.onboarded) var onboarded

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

                Text("WikiSubmission")
                    .font(DS.Typography.heroMD)
                    .fontWeight(.semibold)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
            }

            Spacer()
            Spacer()

            // Loading or Continue button
            Group {
                Button {
                    onboarded = true
                } label: {
                    Text("Continue")
                        .font(DS.Typography.lede)
                        .fontWeight(.bold)
                        .frame(width: 200, height: 40)
                }
                .buttonStyle(.borderedProminent)
                .transition(.opacity.combined(with: .scale))
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
