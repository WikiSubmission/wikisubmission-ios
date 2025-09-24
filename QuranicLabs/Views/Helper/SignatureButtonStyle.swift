import SwiftUI

struct SignatureButtonStyle: ButtonStyle {
    var backgroundColor: Color = Color.accentColor.opacity(0.15)
    var foregroundColor: Color = .accentColor
    var cornerRadius: CGFloat = 24
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor) // accent color for text and icon
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(configuration.isPressed ? 0.7 : 1.0) // subtle pressed effect
    }
}
