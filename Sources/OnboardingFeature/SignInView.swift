import SwiftUI
import AuthenticationServices
import Core
import CameraFeature

public struct SignInView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingNetworkError = false

    @ScaledMetric(relativeTo: .largeTitle) private var leafIconSize: CGFloat = 80

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

                // Offline indicator at top
                if !networkMonitor.isConnected {
                    offlineWarning
                }

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
            .animation(reduceMotion ? nil : .brandReducedMotion, value: networkMonitor.isConnected)
        }
    }

    // MARK: - Offline Warning

    private var offlineWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.medium))

            Text("No internet connection")
                .font(.subheadline)
        }
        .foregroundStyle(Color.salmon)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            if #available(iOS 26.0, macOS 26.0, *) {
                if !reduceTransparency {
                    Color.salmon.opacity(0.15)
                        .glassEffect(in: Capsule())
                } else {
                    Capsule()
                        .fill(Color.salmon.opacity(0.15))
                }
            } else {
                Capsule()
                    .fill(Color.salmon.opacity(0.15))
            }
        }
        .accessibilityLabel("No internet connection. Sign in requires internet access.")
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        if reduceTransparency {
            Color.backgroundDefault
        } else {
            LinearGradient(
                colors: [
                    Color.peach.opacity(0.3),
                    Color.salmon.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Leaf Icon

    private var leafIcon: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: leafIconSize).leading(.tight))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(Color.softTeal)
            .shadow(color: Color.softTeal.opacity(0.4), radius: 16, x: 0, y: 8)
            .accessibilityHidden(true)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Sign in to Abundance")
                .font(.title.weight(.bold).leading(.tight))
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: errorIcon(for: error))
                    .foregroundStyle(Color.errorColor)

                Text(error.localizedDescription)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.errorColor)
                    .lineLimit(2)
            }

            // Retry button for network errors
            if isNetworkError(error) {
                Button {
                    viewModel.error = nil
                    Task {
                        _ = await networkMonitor.checkConnection()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.medium))
                        Text("Check Connection")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .abundanceCardStyle(cornerRadius: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    private func errorIcon(for error: Error) -> String {
        if isNetworkError(error) {
            return "wifi.exclamationmark"
        }
        return "exclamationmark.triangle.fill"
    }

    private func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain ||
               nsError.code == NSURLErrorNotConnectedToInternet ||
               nsError.code == NSURLErrorTimedOut ||
               nsError.code == NSURLErrorNetworkConnectionLost
    }

    // MARK: - Legal Text

    private var legalText: some View {
        Text("By signing in, you agree to our Terms of Service and Privacy Policy")
            .font(.footnote.leading(.tight))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    SignInView(viewModel: AuthViewModel())
}
