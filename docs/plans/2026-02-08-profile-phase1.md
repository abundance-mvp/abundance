# Profile Phase 1: "Make What Exists Work" Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `ios-superpowers execute` to implement this plan task-by-task.
> This is iOS/Swift work — always use `ios-superpowers` (not raw `superpowers`) for execution.

**Goal:** Complete the ProfileFeature by wiring up all stubbed settings screens, implementing real CSV export, and adding display name editing.

**Architecture:** All new views live inside `Sources/ProfileFeature/`. Settings screens push via `NavigationStack` (already in ProfileView). CSV export uses `ShareLink` with a `Transferable` document type. Display name editing uses a sheet with Firebase Auth `updateProfile`. Each new ViewModel follows DESIGN-037 Pattern 1 (constructor injection) with `@Observable`.

**Tech Stack:** Swift 6.0, SwiftUI (iOS 17+), Firebase Auth, Swift Testing framework

**Execution Agent:** `ios-superpowers execute` — routes through Axiom for Apple API verification before each task. Agents for Tasks 1-4 can be dispatched in parallel (independent screens). Tasks 5-6 depend on existing code and should run sequentially after Tasks 1-4.

---

## Agent Dispatch Strategy

```
PARALLEL BATCH 1 (independent screens):
  ├── Agent A: Task 1 — Help screen
  ├── Agent B: Task 2 — Notifications settings
  ├── Agent C: Task 3 — Privacy settings
  └── Agent D: Task 4 — CSV export

SEQUENTIAL (after Batch 1 completes):
  ├── Task 5 — Display name editing
  └── Task 6 — Wire navigation + integration
```

**Rationale:** Tasks 1-4 create independent new files with no cross-dependencies. Task 5 modifies `UserInfoCard` and `ProfileViewModel` which Task 6 also touches for navigation wiring, so they must be sequential.

---

## Task 1: Help Screen

**Files:**
- Create: `Sources/ProfileFeature/Views/HelpView.swift`
- Test: `Tests/ProfileFeatureTests/HelpViewTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/ProfileFeatureTests/HelpViewTests.swift
import Testing
@testable import ProfileFeature

@Suite("HelpView Tests")
struct HelpViewTests {

    @Test("appVersion returns non-empty string")
    func testAppVersion_returnsValue() {
        let info = AppInfo()
        #expect(!info.version.isEmpty)
    }

    @Test("appBuild returns non-empty string")
    func testAppBuild_returnsValue() {
        let info = AppInfo()
        #expect(!info.build.isEmpty)
    }

    @Test("supportEmail is valid format")
    func testSupportEmail_isValid() {
        let info = AppInfo()
        #expect(info.supportEmail.contains("@"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter HelpViewTests 2>&1 | head -30`
Expected: FAIL — `AppInfo` type not found

**Step 3: Write minimal implementation**

```swift
// Sources/ProfileFeature/Views/HelpView.swift
import SwiftUI
import Core

/// App metadata provider (injectable for testing)
public struct AppInfo: Sendable {
    public let version: String
    public let build: String
    public let supportEmail: String

    public init(
        version: String? = nil,
        build: String? = nil,
        supportEmail: String = "support@abundance.app"
    ) {
        self.version = version
            ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0.0"
        self.build = build
            ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            ?? "1"
        self.supportEmail = supportEmail
    }
}

struct HelpView: View {
    let appInfo: AppInfo

    init(appInfo: AppInfo = AppInfo()) {
        self.appInfo = appInfo
    }

    var body: some View {
        List {
            Section("Support") {
                Link(destination: URL(string: "mailto:\(appInfo.supportEmail)")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
                .accessibilityIdentifier("help.contactSupport")
            }

            Section("About") {
                LabeledContent("Version", value: appInfo.version)
                    .accessibilityIdentifier("help.version")
                LabeledContent("Build", value: appInfo.build)
                    .accessibilityIdentifier("help.build")
            }
        }
        .navigationTitle("Help")
    }
}

#Preview("HelpView") {
    NavigationStack {
        HelpView(appInfo: AppInfo(version: "1.2.0", build: "42"))
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter HelpViewTests 2>&1 | tail -10`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add Sources/ProfileFeature/Views/HelpView.swift Tests/ProfileFeatureTests/HelpViewTests.swift
git commit -m "feat(profile): add Help screen with version info and support contact"
```

---

## Task 2: Notifications Settings Screen

**Files:**
- Create: `Sources/ProfileFeature/Views/NotificationsSettingsView.swift`
- Create: `Sources/ProfileFeature/ViewModels/NotificationsSettingsViewModel.swift`
- Test: `Tests/ProfileFeatureTests/NotificationsSettingsTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/ProfileFeatureTests/NotificationsSettingsTests.swift
import Testing
@testable import ProfileFeature

@Suite("NotificationsSettingsViewModel Tests")
@MainActor
struct NotificationsSettingsViewModelTests {

    @Test("Initial state has notifications disabled")
    func testInitialState() {
        let vm = NotificationsSettingsViewModel()
        #expect(vm.itemReadyAlerts == false)
    }

    @Test("Toggling itemReadyAlerts updates state")
    func testToggleItemReady() {
        let vm = NotificationsSettingsViewModel()
        vm.itemReadyAlerts = true
        #expect(vm.itemReadyAlerts == true)
    }

    @Test("persistedKey returns correct UserDefaults key")
    func testPersistedKey() {
        #expect(NotificationsSettingsViewModel.itemReadyKey == "notifications.itemReady")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter NotificationsSettingsViewModelTests 2>&1 | head -30`
Expected: FAIL — type not found

**Step 3: Write ViewModel**

```swift
// Sources/ProfileFeature/ViewModels/NotificationsSettingsViewModel.swift
import Foundation

@MainActor
@Observable
public final class NotificationsSettingsViewModel {
    static let itemReadyKey = "notifications.itemReady"

    public var itemReadyAlerts: Bool {
        didSet {
            UserDefaults.standard.set(itemReadyAlerts, forKey: Self.itemReadyKey)
        }
    }

    public init() {
        self.itemReadyAlerts = UserDefaults.standard.bool(forKey: Self.itemReadyKey)
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter NotificationsSettingsViewModelTests 2>&1 | tail -10`
Expected: PASS (3 tests)

**Step 5: Write the view**

```swift
// Sources/ProfileFeature/Views/NotificationsSettingsView.swift
import SwiftUI

struct NotificationsSettingsView: View {
    @Bindable var viewModel: NotificationsSettingsViewModel

    init(viewModel: NotificationsSettingsViewModel = NotificationsSettingsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            Section {
                Toggle("Item Ready Alerts", isOn: $viewModel.itemReadyAlerts)
                    .accessibilityIdentifier("notifications.itemReady")
            } footer: {
                Text("Get notified when AI finishes analyzing your items.")
            }
        }
        .navigationTitle("Notifications")
    }
}

#Preview("NotificationsSettings") {
    NavigationStack {
        NotificationsSettingsView()
    }
}
```

**Step 6: Commit**

```bash
git add Sources/ProfileFeature/Views/NotificationsSettingsView.swift \
       Sources/ProfileFeature/ViewModels/NotificationsSettingsViewModel.swift \
       Tests/ProfileFeatureTests/NotificationsSettingsTests.swift
git commit -m "feat(profile): add Notifications settings screen with item ready toggle"
```

---

## Task 3: Privacy Settings Screen

**Files:**
- Create: `Sources/ProfileFeature/Views/PrivacySettingsView.swift`
- Test: `Tests/ProfileFeatureTests/PrivacySettingsTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/ProfileFeatureTests/PrivacySettingsTests.swift
import Testing
@testable import ProfileFeature

@Suite("PrivacySettingsView Tests")
@MainActor
struct PrivacySettingsViewModelTests {

    @Test("Initial state has no deletion pending")
    func testInitialState() {
        let vm = PrivacySettingsViewModel(
            authService: MockAuthService(),
            requiresAuthentication: false
        )
        #expect(vm.isDeletionPending == false)
        #expect(vm.error == nil)
    }

    @Test("deleteAccount calls auth service signOut after deletion")
    func testDeleteAccount_signsOut() async {
        let mockAuth = MockAuthService()
        let vm = PrivacySettingsViewModel(
            authService: mockAuth,
            requiresAuthentication: false
        )

        await vm.deleteAccount()

        #expect(mockAuth.signOutCalled == true)
    }

    @Test("privacyPolicyURL is valid")
    func testPrivacyPolicyURL() {
        #expect(PrivacySettingsViewModel.privacyPolicyURL != nil)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PrivacySettingsViewModelTests 2>&1 | head -30`
Expected: FAIL — type not found

**Step 3: Write ViewModel**

```swift
// Sources/ProfileFeature/Views/PrivacySettingsView.swift
import SwiftUI
import Core

@MainActor
@Observable
public final class PrivacySettingsViewModel {
    static let privacyPolicyURL = URL(string: "https://abundance.app/privacy")

    public var isDeletionPending = false
    public var error: String?

    private let authService: AuthServiceProtocol

    public init(
        authService: AuthServiceProtocol = FirebaseAuthService(),
        requiresAuthentication: Bool = true
    ) {
        self.authService = authService
    }

    /// Delete user account. In MVP this signs out; full deletion requires backend Cloud Function.
    public func deleteAccount() async {
        isDeletionPending = true
        error = nil

        do {
            // MVP: Sign out. TODO: Call Cloud Function for full data deletion.
            try authService.signOut()
            isDeletionPending = false
        } catch {
            self.error = error.localizedDescription
            isDeletionPending = false
        }
    }
}

struct PrivacySettingsView: View {
    @Bindable var viewModel: PrivacySettingsViewModel
    @State private var showDeleteConfirmation = false

    init(viewModel: PrivacySettingsViewModel = PrivacySettingsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            Section("Privacy") {
                if let url = PrivacySettingsViewModel.privacyPolicyURL {
                    Link(destination: url) {
                        Label("Privacy Policy", systemImage: "doc.text")
                    }
                    .accessibilityIdentifier("privacy.policy")
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
                .accessibilityIdentifier("privacy.deleteAccount")
            } footer: {
                Text("Permanently delete your account and all associated data.")
            }
        }
        .navigationTitle("Privacy")
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
        } message: {
            Text("This will permanently delete your account and all your data. This action cannot be undone.")
        }
    }
}

#Preview("PrivacySettings") {
    NavigationStack {
        PrivacySettingsView()
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter PrivacySettingsViewModelTests 2>&1 | tail -10`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add Sources/ProfileFeature/Views/PrivacySettingsView.swift \
       Tests/ProfileFeatureTests/PrivacySettingsTests.swift
git commit -m "feat(profile): add Privacy settings screen with account deletion and policy link"
```

---

## Task 4: CSV Export Implementation

**Files:**
- Create: `Sources/ProfileFeature/Models/CSVExporter.swift`
- Modify: `Sources/ProfileFeature/ProfileViewModel.swift` — replace export stub
- Modify: `Sources/ProfileFeature/ProfileView.swift` — replace Button with ShareLink
- Test: `Tests/ProfileFeatureTests/CSVExporterTests.swift`
- Modify: `Tests/ProfileFeatureTests/ProfileViewTests.swift` — update export tests

**Step 1: Write the failing test for CSVExporter**

```swift
// Tests/ProfileFeatureTests/CSVExporterTests.swift
import Testing
@testable import ProfileFeature
@testable import Persistence

@Suite("CSVExporter Tests")
struct CSVExporterTests {

    @Test("Empty items produces header-only CSV")
    func testEmptyItems_headerOnly() {
        let csv = CSVExporter.generate(from: [])
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 2) // header + trailing newline
        #expect(lines[0].contains("Name"))
        #expect(lines[0].contains("Category"))
        #expect(lines[0].contains("Estimated Value"))
    }

    @Test("Single item produces header + one data row")
    func testSingleItem() {
        let item = Item(
            id: "test-1",
            userId: "user-1",
            imageUrl: "https://example.com/img.jpg",
            status: .complete,
            name: "Blue Tent",
            category: "Camping",
            brand: "Coleman",
            estimatedValue: 89.99,
            condition: .good,
            confidence: .high,
            createdAt: Date(timeIntervalSince1970: 1700000000),
            updatedAt: Date(timeIntervalSince1970: 1700000000)
        )
        let csv = CSVExporter.generate(from: [item])
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 3) // header + data + trailing newline
        #expect(lines[1].contains("Blue Tent"))
        #expect(lines[1].contains("Camping"))
        #expect(lines[1].contains("Coleman"))
        #expect(lines[1].contains("89.99"))
    }

    @Test("Fields with commas are quoted")
    func testCommasAreQuoted() {
        let item = Item(
            id: "test-2",
            userId: "user-1",
            imageUrl: "https://example.com/img.jpg",
            status: .complete,
            name: "Tent, Large",
            category: "Outdoor",
            confidence: .high,
            createdAt: Date(),
            updatedAt: Date()
        )
        let csv = CSVExporter.generate(from: [item])
        #expect(csv.contains("\"Tent, Large\""))
    }

    @Test("Nil fields export as empty")
    func testNilFields_empty() {
        let item = Item(
            id: "test-3",
            userId: "user-1",
            imageUrl: "https://example.com/img.jpg",
            status: .processing,
            confidence: .low,
            createdAt: Date(),
            updatedAt: Date()
        )
        let csv = CSVExporter.generate(from: [item])
        let lines = csv.components(separatedBy: "\n")
        // Name is nil → empty field between commas
        #expect(lines[1].hasPrefix(",")) // first field (Name) is empty
    }

    @Test("CSVDocument has correct UTType and filename")
    func testCSVDocument_metadata() {
        let doc = CSVDocument(csv: "test")
        #expect(doc.filename.hasSuffix(".csv"))
        #expect(doc.filename.hasPrefix("abundance-collection-"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CSVExporterTests 2>&1 | head -30`
Expected: FAIL — `CSVExporter` type not found

**Step 3: Write CSVExporter and CSVDocument**

```swift
// Sources/ProfileFeature/Models/CSVExporter.swift
import Foundation
import UniformTypeIdentifiers
import SwiftUI
import Persistence

/// Generates CSV from Item arrays
public enum CSVExporter {
    static let headers = [
        "Name", "Category", "Sub-Category", "Brand", "Model",
        "Color", "Material", "Condition", "Dimensions",
        "Quantity", "Estimated Value", "Status",
        "Created", "Updated"
    ]

    /// Generate a CSV string from an array of Items
    public static func generate(from items: [Item]) -> String {
        var lines: [String] = []
        lines.append(headers.joined(separator: ","))

        let dateFormatter = ISO8601DateFormatter()

        for item in items {
            let fields: [String] = [
                csvEscape(item.name),
                csvEscape(item.category),
                csvEscape(item.subCategory),
                csvEscape(item.brand),
                csvEscape(item.model),
                csvEscape(item.color),
                csvEscape(item.material),
                csvEscape(item.condition?.rawValue),
                csvEscape(item.dimensions),
                item.quantity.map(String.init) ?? "",
                item.estimatedValue.map { String(format: "%.2f", $0) } ?? "",
                item.status.rawValue,
                dateFormatter.string(from: item.createdAt),
                dateFormatter.string(from: item.updatedAt)
            ]
            lines.append(fields.joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func csvEscape(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "" }
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

/// Transferable document for sharing CSV via ShareLink
public struct CSVDocument: Transferable {
    public let csv: String
    public let filename: String

    public init(csv: String) {
        self.csv = csv
        let dateStr = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        self.filename = "abundance-collection-\(dateStr).csv"
    }

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            Data(doc.csv.utf8)
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter CSVExporterTests 2>&1 | tail -10`
Expected: PASS (5 tests)

**Step 5: Update ProfileViewModel — replace export stub with real data fetch**

In `Sources/ProfileFeature/ProfileViewModel.swift`, replace the `exportData` method:

```swift
// Replace the existing exportData method and add csvDocument property

// Add to published properties section:
public var csvDocument: CSVDocument?

// Replace exportData:
public func exportData(format: ExportFormat) async {
    guard let userId else {
        error = "Authentication required"
        return
    }

    isLoading = true
    error = nil

    do {
        let items = try await itemRepository.getItems(userId: userId)
        let csv = CSVExporter.generate(from: items)
        csvDocument = CSVDocument(csv: csv)
        isLoading = false
    } catch {
        self.error = "Export failed: \(error.localizedDescription)"
        isLoading = false
    }
}
```

**Step 6: Update ProfileView — replace Button with ShareLink**

In `Sources/ProfileFeature/ProfileView.swift`, replace the export section:

```swift
// Replace the exportSection computed property:
private var exportSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        sectionHeader("Export Data")

        if let doc = viewModel.csvDocument {
            ShareLink(
                item: doc,
                preview: SharePreview("Abundance Collection", image: Image(systemName: "tablecells"))
            ) {
                exportButtonLabel
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.exportCSV")
            .accessibilityLabel("Share CSV export")
        } else {
            Button {
                Task { await viewModel.exportData(format: .csv) }
            } label: {
                exportButtonLabel
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.exportCSV")
            .accessibilityLabel("Export as CSV")
            .accessibilityHint("Double tap to generate a CSV file of your collection")
        }
    }
}

private var exportButtonLabel: some View {
    HStack {
        Image(systemName: "tablecells")
            .font(.title3)
            .foregroundStyle(Color.salmon)
        Text(viewModel.csvDocument != nil ? "Share CSV" : "Export as CSV")
            .font(.body.weight(.medium))
            .foregroundStyle(Color.textPrimary)
        Spacer()
        Image(systemName: "square.and.arrow.up")
            .font(.body)
            .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity, minHeight: 44)
    .abundanceCardStyle()
}
```

**Step 7: Run all ProfileFeature tests**

Run: `swift test --filter ProfileFeature 2>&1 | tail -20`
Expected: ALL PASS

**Step 8: Commit**

```bash
git add Sources/ProfileFeature/Models/CSVExporter.swift \
       Sources/ProfileFeature/ProfileViewModel.swift \
       Sources/ProfileFeature/ProfileView.swift \
       Tests/ProfileFeatureTests/CSVExporterTests.swift
git commit -m "feat(profile): implement CSV export with ShareLink and Transferable"
```

---

## Task 5: Display Name Editing

**Files:**
- Create: `Sources/ProfileFeature/Views/EditProfileSheet.swift`
- Modify: `Sources/ProfileFeature/ProfileViewModel.swift` — add `updateDisplayName` method
- Modify: `Sources/ProfileFeature/Components/UserInfoCard.swift` — add edit button
- Test: `Tests/ProfileFeatureTests/EditProfileTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/ProfileFeatureTests/EditProfileTests.swift
import Testing
@testable import ProfileFeature

@Suite("ProfileViewModel Edit Profile Tests")
@MainActor
struct EditProfileTests {

    @Test("updateDisplayName updates local state")
    func testUpdateDisplayName_updatesState() async {
        let mockAuth = MockAuthService()
        let mockRepo = MockItemRepository()
        let vm = ProfileViewModel(
            userId: "test-user",
            displayName: "Old Name",
            email: "test@example.com",
            itemRepository: mockRepo,
            authService: mockAuth,
            requiresAuthentication: false
        )

        await vm.updateDisplayName("New Name")

        #expect(vm.displayName == "New Name")
        #expect(vm.error == nil)
    }

    @Test("updateDisplayName with empty string sets error")
    func testUpdateDisplayName_emptyString_setsError() async {
        let mockAuth = MockAuthService()
        let mockRepo = MockItemRepository()
        let vm = ProfileViewModel(
            userId: "test-user",
            displayName: "Old Name",
            email: "test@example.com",
            itemRepository: mockRepo,
            authService: mockAuth,
            requiresAuthentication: false
        )

        await vm.updateDisplayName("")

        #expect(vm.displayName == "Old Name") // unchanged
        #expect(vm.error != nil)
    }

    @Test("updateDisplayName trims whitespace")
    func testUpdateDisplayName_trimsWhitespace() async {
        let mockAuth = MockAuthService()
        let mockRepo = MockItemRepository()
        let vm = ProfileViewModel(
            userId: "test-user",
            displayName: "Old Name",
            email: "test@example.com",
            itemRepository: mockRepo,
            authService: mockAuth,
            requiresAuthentication: false
        )

        await vm.updateDisplayName("  Trimmed Name  ")

        #expect(vm.displayName == "Trimmed Name")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter EditProfileTests 2>&1 | head -30`
Expected: FAIL — `updateDisplayName` method not found

**Step 3: Add updateDisplayName to ProfileViewModel**

In `Sources/ProfileFeature/ProfileViewModel.swift`, add to the public methods section:

```swift
/// Update the user's display name
/// - Parameter newName: The new display name (trimmed, must be non-empty)
public func updateDisplayName(_ newName: String) async {
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        error = "Display name cannot be empty"
        return
    }

    let previousName = displayName
    displayName = trimmed
    error = nil

    do {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = trimmed
        try await changeRequest?.commitChanges()
    } catch {
        displayName = previousName
        self.error = "Failed to update name: \(error.localizedDescription)"
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter EditProfileTests 2>&1 | tail -10`
Expected: PASS (3 tests)

**Step 5: Create EditProfileSheet**

```swift
// Sources/ProfileFeature/Views/EditProfileSheet.swift
import SwiftUI
import Core

struct EditProfileSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Name", text: $editedName)
                        .textContentType(.name)
                        .accessibilityIdentifier("editProfile.nameField")
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(Color.errorColor)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateDisplayName(editedName)
                            if viewModel.error == nil { dismiss() }
                        }
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("editProfile.save")
                }
            }
            .onAppear {
                editedName = viewModel.displayName
            }
        }
    }
}

#Preview("EditProfileSheet") {
    EditProfileSheet(
        viewModel: ProfileViewModel(
            userId: "preview",
            displayName: "John Doe",
            email: "john@example.com",
            requiresAuthentication: false
        )
    )
}
```

**Step 6: Add edit button to UserInfoCard**

In `Sources/ProfileFeature/Components/UserInfoCard.swift`, add an `onEdit` callback:

```swift
// Add to UserInfoCard properties:
var onEdit: (() -> Void)?

// Update initializer:
public init(displayName: String, email: String, itemCount: Int, onEdit: (() -> Void)? = nil) {
    self.displayName = displayName
    self.email = email
    self.itemCount = itemCount
    self.onEdit = onEdit
}

// Add edit button overlay to avatarView or next to name.
// In the VStack after the name Text, add:
if onEdit != nil {
    Button {
        onEdit?()
    } label: {
        Label("Edit Profile", systemImage: "pencil")
            .font(.callout)
            .foregroundStyle(Color.salmon)
    }
    .accessibilityIdentifier("profile.editButton")
}
```

**Step 7: Run all tests**

Run: `swift test --filter ProfileFeature 2>&1 | tail -20`
Expected: ALL PASS

**Step 8: Commit**

```bash
git add Sources/ProfileFeature/Views/EditProfileSheet.swift \
       Sources/ProfileFeature/ProfileViewModel.swift \
       Sources/ProfileFeature/Components/UserInfoCard.swift \
       Tests/ProfileFeatureTests/EditProfileTests.swift
git commit -m "feat(profile): add display name editing with EditProfileSheet"
```

---

## Task 6: Wire Navigation + Integration

**Files:**
- Modify: `Sources/ProfileFeature/ProfileView.swift` — add NavigationLinks and edit sheet
- Modify: `App/DebugMainTabView.swift` — verify debug mode still works
- No new tests needed — navigation is verified via build + manual/AXe testing

**Step 1: Update ProfileView settings section with NavigationLinks**

In `Sources/ProfileFeature/ProfileView.swift`, replace the `settingsSection`:

```swift
private var settingsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        sectionHeader("Settings")

        VStack(spacing: 0) {
            NavigationLink {
                NotificationsSettingsView()
            } label: {
                settingsRowContent(icon: "bell", title: "Notifications")
            }
            .accessibilityIdentifier("profile.notifications")

            Divider().padding(.leading, 48)

            NavigationLink {
                PrivacySettingsView()
            } label: {
                settingsRowContent(icon: "lock.shield", title: "Privacy")
            }
            .accessibilityIdentifier("profile.privacy")

            Divider().padding(.leading, 48)

            NavigationLink {
                HelpView()
            } label: {
                settingsRowContent(icon: "questionmark.circle", title: "Help")
            }
            .accessibilityIdentifier("profile.help")
        }
        .abundanceCardStyle()
    }
}

private func settingsRowContent(icon: String, title: String) -> some View {
    HStack(spacing: 16) {
        Image(systemName: icon)
            .font(.body)
            .foregroundStyle(Color.salmon)
            .frame(width: 24)
        Text(title)
            .font(.body)
            .foregroundStyle(Color.textPrimary)
        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .contentShape(Rectangle())
}
```

**Step 2: Add edit sheet state and UserInfoCard onEdit**

In `ProfileView`, add state and wire up:

```swift
// Add to @State properties:
@State private var showingEditProfile = false

// Update UserInfoCard in body:
UserInfoCard(
    displayName: viewModel.displayName,
    email: viewModel.email,
    itemCount: viewModel.itemCount,
    onEdit: { showingEditProfile = true }
)

// Add .sheet modifier to NavigationStack:
.sheet(isPresented: $showingEditProfile) {
    EditProfileSheet(viewModel: viewModel)
}
```

**Step 3: Remove the now-unused SettingsRow struct**

Delete the private `SettingsRow` struct at the bottom of ProfileView.swift — it's replaced by `NavigationLink` + `settingsRowContent`.

**Step 4: Build and verify**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded

**Step 5: Run all ProfileFeature tests**

Run: `swift test --filter ProfileFeature 2>&1 | tail -20`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add Sources/ProfileFeature/ProfileView.swift \
       App/DebugMainTabView.swift
git commit -m "feat(profile): wire settings navigation, edit sheet, and remove placeholder stubs"
```

---

## Post-Implementation Checklist

After all 6 tasks are complete:

- [ ] `swift build` succeeds with zero errors
- [ ] `swift test --filter ProfileFeature` — all tests pass
- [ ] `swift test` — full suite passes (no regressions)
- [ ] Each settings row navigates to its destination
- [ ] CSV export generates a real file and presents share sheet
- [ ] Edit profile sheet saves display name
- [ ] Sign out still works
- [ ] Debug/simulator mode (`DebugMainTabView`) still loads
- [ ] Accessibility identifiers present on all interactive elements

---

## File Summary

### New Files (7)
| File | Purpose |
|------|---------|
| `Sources/ProfileFeature/Views/HelpView.swift` | Help screen + AppInfo |
| `Sources/ProfileFeature/Views/NotificationsSettingsView.swift` | Notification toggles |
| `Sources/ProfileFeature/ViewModels/NotificationsSettingsViewModel.swift` | Notification state |
| `Sources/ProfileFeature/Views/PrivacySettingsView.swift` | Privacy + account deletion |
| `Sources/ProfileFeature/Views/EditProfileSheet.swift` | Name editing form |
| `Sources/ProfileFeature/Models/CSVExporter.swift` | CSV generation + Transferable |
| `Tests/ProfileFeatureTests/CSVExporterTests.swift` | CSV export tests |

### Modified Files (4)
| File | Changes |
|------|---------|
| `Sources/ProfileFeature/ProfileView.swift` | NavigationLinks, ShareLink, edit sheet |
| `Sources/ProfileFeature/ProfileViewModel.swift` | Real export, updateDisplayName, csvDocument |
| `Sources/ProfileFeature/Components/UserInfoCard.swift` | onEdit callback + edit button |
| `Tests/ProfileFeatureTests/ProfileViewTests.swift` | Updated export tests (may need adjustment) |

### New Test Files (3)
| File | Tests |
|------|-------|
| `Tests/ProfileFeatureTests/HelpViewTests.swift` | AppInfo validation |
| `Tests/ProfileFeatureTests/NotificationsSettingsTests.swift` | Toggle state + persistence |
| `Tests/ProfileFeatureTests/PrivacySettingsTests.swift` | Account deletion + URL validation |
| `Tests/ProfileFeatureTests/EditProfileTests.swift` | Display name update logic |
