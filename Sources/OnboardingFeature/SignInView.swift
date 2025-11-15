import SwiftUI
import AuthenticationServices

public struct SignInView: View {
    @StateObject private var viewModel: SignInViewModel = SignInViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Abundance")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Catalog your items with AI-powered insights")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            Task {
                                await viewModel.signInWithApple(credential: credential)
                            }
                        }
                    case .failure(let error):
                        viewModel.handleError(error)
                    }
                }
                .frame(height: 50)
                .signInWithAppleButtonStyle(.black)
            }

            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    SignInView()
}
