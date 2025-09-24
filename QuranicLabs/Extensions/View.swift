import SwiftUI
import Network
import Combine

extension View {
    @ViewBuilder
    func conditionalContextMenu(remove: Bool, @ViewBuilder content: () -> some View) -> some View {
        if remove {
            self
        } else {
            self.contextMenu { content() }
        }
    }
        
    func pushToLeft() -> some View {
        self.modifier(HLeadingModifier())
    }
    
    func pushToRight() -> some View {
        self.modifier(HTrailingModifier())
    }
    
    func preventHorizontalScroll() -> some View {
        self.modifier(NoHorizontalScrollModifier())
    }
    
    func requiresSignIn(reason: String? = nil) -> some View {
        modifier(SignInRequired(reason: reason))
    }
     
    func requiresInternet() -> some View {
        modifier(InternetRequired())
    }
}

struct HLeadingModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
        }
    }
}

struct HTrailingModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
        }
    }
}

struct NoHorizontalScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
    }
}
