import SwiftUI
import Clerk

struct SignIn: View {
    @Environment(\.clerk) var clerk
    @State private var authIsPresented = false
    
    var removeFormatting = false
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image("book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: CGFloat(24)))
                    
                    Text("WikiSubmission")
                        .fontDesign(.serif)
                        .font(.title2)
                    
                    Spacer()
                    
                    if clerk.user != nil {
                        UserButton()
                            .frame(width: 24, height: 24)
                    } else {
                        Button {
                            authIsPresented = true
                        } label: {
                            Text("Sign In")
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                        }
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                .padding(.vertical, removeFormatting ? 0 : 12)
                .padding(.horizontal, removeFormatting ? 0 : 24)
                .background(Color.accentColor.opacity(removeFormatting ? 0 : 0.05))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .sheet(isPresented: $authIsPresented) {
                    SignInFlow()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppEnvironment.shared)
    }
}
