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
    
    func pushToCenter() -> some View {
        self.modifier(CenterModifier())
    }
    
    func preventHorizontalScroll() -> some View {
        self.modifier(NoHorizontalScrollModifier())
    }
     
    func requiresInternet(reason: String?) -> some View {
        modifier(InternetRequired(reason: reason))
    }

    func removeParentListStyle() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
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

struct CenterModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
            Spacer()
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
