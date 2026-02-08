import SwiftUI

struct SignatureButtonStyle: ButtonStyle {
    var tint: Color = .accentColor
    var cornerRadius: CGFloat = 24
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(tint)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
