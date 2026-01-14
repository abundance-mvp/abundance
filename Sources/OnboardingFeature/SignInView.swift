import SwiftUI
import AuthenticationServices
import Core

public struct SignInView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Brand gradient background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Leaf icon with brand mint green
                leafIcon

                // Title
                titleSection

                Spacer()

                // Sign in button section
                signInSection

                // Legal text
                legalText
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        if reduceTransparency {
            Color.backgroundDefault
        } else {
            LinearGradient(
                colors: [
                    Color.brandMintGreen.opacity(0.3),
                    Color.brandBrightBlue.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Leaf Icon

    private var leafIcon: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 80))
            .foregroundStyle(Color.brandMintGreen)
            .shadow(color: Color.brandMintGreen.opacity(0.4), radius: 16, x: 0, y: 8)
            .accessibilityHidden(true)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Sign in to Abundance")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Your catalog syncs across devices")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Sign In Section

    @ViewBuilder
    private var signInSection: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
                .accessibilityLabel("Signing in")
        } else {
            VStack(spacing: 16) {
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
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)

                if let error = viewModel.error {
                    errorView(error: error)
                }
            }
        }
    }

    // MARK: - Error View

    private func errorView(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.errorColor)

            Text(error.localizedDescription)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.errorColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.backgroundDefault)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    // MARK: - Legal Text

    private var legalText: some View {
        Text("By signing in, you agree to our Terms of Service and Privacy Policy")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    SignInView(viewModel: AuthViewModel())
}
