import SwiftUI

struct ConditionalNavigationLink<Content: View, Destination: View>: View {
    let isActive: Bool
    let destination: Destination
    let content: () -> Content
    
    init(
        isActive: Bool,
        destination: Destination,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isActive = isActive
        self.destination = destination
        self.content = content
    }
    
    var body: some View {
        if isActive {
            NavigationLink(destination: destination) {
                content()
            }
            .buttonStyle(.plain)
        } else {
            content()
        }
    }
}
