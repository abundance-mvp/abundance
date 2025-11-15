# DESIGN-010: iOS Data Persistence

**Created**: 2025-11-08
**Stage**: 2.2 - iOS Client Architecture  
**Status**: Approved

---

## Overview

Local data storage strategy: UserDefaults (app settings), Keychain (secure auth tokens), Firestore local cache (offline catalog).

---

## 1. UserDefaults (App Settings)

```swift
class SettingsService {
    private let defaults = UserDefaults.standard

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    var selectedTheme: String {
        get { defaults.string(forKey: "selectedTheme") ?? "system" }
        set { defaults.set(newValue, forKey: "selectedTheme") }
    }
}
```

---

## 2. Keychain (Secure Storage)

```swift
import Security

class KeychainService {
    func save(_ token: String, for key: String) throws {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    func get(_ key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
```

---

## 3. Firestore Local Cache (Offline Catalog)

```swift
// Enable offline persistence (in AppDelegate or App init)
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings
```

### Benefits:
- Offline reads return cached data
- Writes queue and sync when online
- Automatic cache management (LRU eviction)

---

**Status**: ✅ Approved
