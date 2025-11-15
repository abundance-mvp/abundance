# DESIGN-009: iOS Networking Layer

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture
**Status**: Approved
**References**: ADR-007 (API Architecture from Stage 2.1), API-CONTRACTS-001

---

## Overview

REST API client for calling Cloud Functions backend endpoints with Firebase Authentication.

---

## API Client Protocol

```swift
import Alamofire
import FirebaseAuth

protocol APIClient {
    func createItem(_ item: CatalogItem) async throws -> CatalogItem
    func getItem(id: String) async throws -> CatalogItem
    func listItems(page: Int, limit: Int) async throws -> [CatalogItem]
    func updateItem(id: String, updates: [String: Any]) async throws -> CatalogItem
    func deleteItem(id: String) async throws
}

class FirebaseAPIClient: APIClient {
    private let baseURL = "https://us-central1-abundance-prod.cloudfunctions.net/api/v1"

    private func getAuthToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.notAuthenticated
        }
        return try await user.getIDToken()
    }

    func createItem(_ item: CatalogItem) async throws -> CatalogItem {
        let token = try await getAuthToken()
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]

        return try await AF.request(
            "\(baseURL)/items",
            method: .post,
            parameters: item,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .serializingDecodable(CatalogItem.self)
        .value
    }

    func listItems(page: Int = 1, limit: Int = 50) async throws -> [CatalogItem] {
        let token = try await getAuthToken()
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        let parameters: [String: Any] = ["page": page, "limit": limit]

        return try await AF.request(
            "\(baseURL)/items",
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .serializingDecodable([CatalogItem].self)
        .value
    }
}

enum APIError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "User not authenticated"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .serverError(let code, let message): return "Server error \(code): \(message)"
        }
    }
}
```

---

## Error Handling

```swift
extension FirebaseAPIClient {
    private func handleError(_ error: AFError) -> APIError {
        if let underlyingError = error.underlyingError {
            return .networkError(underlyingError)
        }
        if let responseCode = error.responseCode {
            return .serverError(responseCode, error.localizedDescription)
        }
        return .networkError(error)
    }
}
```

---

## References

- **API-CONTRACTS-001**: REST endpoint specifications
- **ADR-007**: API Architecture (from Stage 2.1)

---

**Status**: ✅ Approved
