import SwiftUI
import Observation
@preconcurrency import FirebaseAuth
import AuthenticationServices
import Persistence

@Observable
@MainActor
public class SignInViewModel {
    public var isAuthenticated: Bool = false
    public var isLoading: Bool = false
    public var error: Error?

    private let keychain: KeychainManager

    public init(keychain: KeychainManager = KeychainManager()) {
        self.keychain = keychain
        checkAuthState()
    }

    /// Check if user is already authenticated
    private func checkAuthState() {
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        }
    }

    /// Sign in with Apple (called after ASAuthorization completes)
    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                throw SignInError.invalidCredential
            }

            // Create Firebase credential from Apple credential
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nil,
                fullName: credential.fullName
            )

            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)

            // Store Firebase ID token in Keychain
            let firebaseToken = try await authResult.user.getIDToken()
            try keychain.save(token: firebaseToken, forKey: "firebaseToken")

            isAuthenticated = true
            error = nil

        } catch {
            self.error = error
            isAuthenticated = false
        }
    }

    /// Sign out
    public func signOut() {
        do {
            try Auth.auth().signOut()
            try? keychain.delete(forKey: "firebaseToken")
            isAuthenticated = false
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Handle error (for testing)
    func handleError(_ error: Error) {
        self.error = error
    }
}

public enum SignInError: Error, LocalizedError {
    case invalidCredential
    case authenticationFailed

    public var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple Sign-In credential"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
