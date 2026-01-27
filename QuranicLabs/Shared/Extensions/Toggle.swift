import SwiftUI

extension Toggle where Label == Text {
    init(_ title: String, isOn: Binding<Bool>, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let feedback = UIImpactFeedbackGenerator(style: feedbackStyle)
        let binding = Binding<Bool>(
            get: { isOn.wrappedValue },
            set: { newValue in
                if newValue != isOn.wrappedValue {
                    feedback.impactOccurred()
                }
                isOn.wrappedValue = newValue
            }
        )
        self.init(isOn: binding) {
            Text(title)
        }
    }
}
