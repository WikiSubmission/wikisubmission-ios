import SwiftUI
import Clerk

struct SignInRequired: ViewModifier {
    @Environment(\.clerk) var clerk

    var reason: String?
    func body(content: Content) -> some View {
        Group {
            if clerk.user != nil {
                content
            } else {
                SignInRequiredContent(reason: reason)
            }
        }
    }
}

struct SignInRequiredContent: View {
    @State private var authIsPresented = false
    var reason: String?
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            
            Button {
                authIsPresented = true
            } label: {
                Text("Sign In")
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
            }
            .background(Color.accent.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            Text(reason ?? "A WikiSubmission ID is required to access this resource.")
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .sheet(isPresented: $authIsPresented) {
            NavigationStack {
                SignInFlow()
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        SignInRequiredContent()
            .environmentObject(AppEnvironment.shared)
    }
}
