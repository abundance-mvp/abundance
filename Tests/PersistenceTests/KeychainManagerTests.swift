import Testing
@testable import Persistence

@Suite("KeychainManager Tests")
struct KeychainManagerTests {

    @Test("Save and retrieve token from Keychain")
    func testSaveAndRetrieveToken() async throws {
        let keychain = KeychainManager()
        let testToken = "test-firebase-token-123"

        // Save token
        try keychain.save(token: testToken, forKey: "firebaseToken")

        // Retrieve token
        let retrievedToken = try keychain.retrieve(forKey: "firebaseToken")

        #expect(retrievedToken == testToken)
    }

    @Test("Delete token from Keychain")
    func testDeleteToken() async throws {
        let keychain = KeychainManager()
        let testToken = "test-token-to-delete"

        // Save then delete
        try keychain.save(token: testToken, forKey: "tempToken")
        try keychain.delete(forKey: "tempToken")

        // Should throw error when retrieving deleted token
        #expect(throws: KeychainError.self) {
            _ = try keychain.retrieve(forKey: "tempToken")
        }
    }
}
