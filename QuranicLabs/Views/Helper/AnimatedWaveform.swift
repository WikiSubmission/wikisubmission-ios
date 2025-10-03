import SwiftUI

struct AnimatedWaveform: View {
  @State private var animationAmount = 0.0
  var body: some View {
    Image(systemName: "waveform")
      .resizable()
      .scaledToFit()
      .foregroundStyle(.blue)
      .frame(width: 20, height: 20)
      .opacity(2 - animationAmount)
      .animation(
        .easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true),
        value: animationAmount
      )
      .onAppear {
        animationAmount = 2
      }
  }
}
