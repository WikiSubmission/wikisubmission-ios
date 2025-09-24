import SwiftUI
import Defaults

struct FirstTimeView: View {
    @State private var animateIn = false
    @Default(.onboarded) var onboarded

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image("book")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .scaleEffect(animateIn ? 1 : 0.8) // scale from smaller
                .opacity(animateIn ? 1 : 0) // fade in
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)

            VStack {
                Text("Submission App")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20) // slide up
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
                
                Text("Access the Final Testament")
                    .italic()
                    .foregroundStyle(.secondary)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 30) // slide up
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
            }

            Spacer()

            Button {
                onboarded = true
            } label: {
                Text("Enter")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(width: 200, height: 40)
            }
            .buttonStyle(.borderedProminent)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 40) // slide up slower
            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
            
            Spacer()
        }
        .padding()
        .onAppear {
            animateIn = true
        }
    }
}
#Preview {
    FirstTimeView()
}
