# DESIGN-030: Profile & Export View Specification

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/design/DESIGN-028-catalog-view-specification.md
- docs/adr/ADR-010-swiftui-architecture-pattern.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Overview

This document specifies the Profile & Export View for the Abundance iOS app, which provides user account management, app settings, privacy controls, and data export functionality. The view features a glass user info card, settings list with Material backgrounds, and a primary export CTA with format selection. It embodies the Liquid Glass design language with layered depth, spring animations, and complete accessibility support.

**User Journey**: Catalog View → Tap Profile Tab → Profile View → (Optional) Tap Export → Select Format → Share Sheet → Export Complete

**Success Criteria**:
- Profile view loads with < 200ms transition from Catalog
- User info card displays Firebase Auth data (name, email, photo)
- Settings list organized into logical sections with clear hierarchy
- Export flow generates CSV/JSON/PDF with < 2 seconds latency
- Privacy settings clearly communicate data retention policies

---

## Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                         Status Bar                               │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │             [User Info Card - .thickMaterial]            │   │
│  │              ConcentricRectangle, centered               │   │
│  │                                                           │   │
│  │                [Avatar - SF Symbol person.circle]         │   │
│  │                        80pt diameter                      │   │
│  │                                                           │   │
│  │                   "John Appleseed"                        │   │
│  │              20pt, SF Pro Rounded Bold, .primary          │   │
│  │                                                           │   │
│  │                "john@icloud.com"                          │   │
│  │           15pt, SF Pro Rounded Regular, .secondary        │   │
│  │                                                           │   │
│  │              [Subscription Badge - Free/Premium]          │   │
│  │                  Capsule, color-coded                     │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Settings List                          │   │
│  │                 .regularMaterial background               │   │
│  │                                                           │   │
│  │  Account                                                  │   │
│  │    Email                                          →       │   │
│  │    Subscription                                   →       │   │
│  │                                                           │   │
│  │  Preferences                                              │   │
│  │    Appearance                                     →       │   │
│  │    Notifications                                  Toggle  │   │
│  │                                                           │   │
│  │  Privacy                                                  │   │
│  │    Data Retention                                 →       │   │
│  │    Photo Deletion Policy                          →       │   │
│  │                                                           │   │
│  │  Support                                                  │   │
│  │    Help Center                                    →       │   │
│  │    Contact Us                                     →       │   │
│  │                                                           │   │
│  │  About                                                    │   │
│  │    Version                                        1.0.0   │   │
│  │    Licenses                                       →       │   │
│  │    Terms of Service                               →       │   │
│  │    Privacy Policy                                 →       │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│                      [Export Data Button]                        │
│                   Capsule, Bright Blue glow                      │
│                   Primary CTA, bottom 32pt                       │
│                                                                   │
│                  [Floating Tab Bar - Pill Shape]                 │
│              Catalog • Camera • Profile                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### User Info Card

**Purpose**: Display Firebase Auth user data and subscription status

**Specifications**:
- **Shape**: ConcentricRectangle(cornerRadius: 20, inset: 0) [iOS 26+]
- **Fallback**: RoundedRectangle(cornerRadius: 20) [iOS 25]
- **Material**: .thickMaterial
- **Padding**: 24pt all sides (internal content)
- **Margin**: 16pt from screen edges (left/right)
- **Shadow**: Soft shadow (radius 12, y offset 4, opacity 0.1)

**Layout**:
1. **Avatar** (top, centered):
   - SF Symbol "person.circle.fill" (no user photo uploaded)
   - 80pt diameter
   - .secondary vibrancy
   - Circular clip shape

2. **Display Name** (below avatar, 12pt spacing):
   - 20pt SF Pro Rounded Bold (Dynamic Type Title 2)
   - .primary vibrancy
   - From Firebase Auth `displayName` property

3. **Email** (below name, 4pt spacing):
   - 15pt SF Pro Rounded Regular (Dynamic Type Callout)
   - .secondary vibrancy
   - From Firebase Auth `email` property

4. **Subscription Badge** (below email, 12pt spacing):
   - Capsule pill shape
   - Padding: 12pt horizontal, 6pt vertical
   - Color-coded: Mint Green (Free), Bright Blue (Premium)
   - Text: "Free" or "Premium" (12pt SF Pro Rounded Semibold)

**SwiftUI Implementation**:
```swift
struct UserInfoCard: View {
    let user: User // Firebase Auth User
    let subscriptionTier: SubscriptionTier
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            // Display Name
            Text(user.displayName ?? "User")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Email
            Text(user.email ?? "No email")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)

            // Subscription Badge
            SubscriptionBadge(tier: subscriptionTier)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            if reduceTransparency {
                Color.backgroundDefault
            } else {
                if #available(iOS 26, *) {
                    ConcentricRectangle(cornerRadius: 20, inset: 0)
                        .fill(.thickMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thickMaterial)
                }
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(user.displayName ?? "User"), \(user.email ?? "No email"), \(subscriptionTier.rawValue) subscription")
    }
}

struct SubscriptionBadge: View {
    let tier: SubscriptionTier

    var color: Color {
        tier == .premium ? Color.brandBrightBlue : Color.brandMintGreen
    }

    var body: some View {
        Text(tier.rawValue)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color, in: Capsule())
            .shadow(color: color.opacity(0.3), radius: 4)
    }
}

enum SubscriptionTier: String {
    case free = "Free"
    case premium = "Premium"
}
```

**Accessibility**:
- VoiceOver: "[User name], [email], [tier] subscription. Card."
- Dynamic Type: Text scales, avatar size fixed
- Reduce Transparency: Replace .thickMaterial with opaque `backgroundDefault`

---

### Settings List

**Purpose**: Organized list of app settings, privacy controls, and support links

**Specifications**:
- **Background**: .regularMaterial
- **Shape**: RoundedRectangle(cornerRadius: 16)
- **Margin**: 16pt from screen edges
- **Padding**: 16pt all sides (internal)
- **Row Height**: Minimum 44pt (iOS HIG tap target)
- **Dividers**: 1pt, .tertiary color, between sections

**Sections**:
1. **Account**: Email, Subscription tier, Manage subscription
2. **Preferences**: Appearance (theme), Notifications toggle
3. **Privacy**: Data retention, Photo deletion policy
4. **Support**: Help center, Contact us
5. **About**: Version, Licenses, Terms, Privacy Policy

**SwiftUI Implementation**:
```swift
struct SettingsList: View {
    @Binding var notificationsEnabled: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 0) {
            // Account Section
            SettingsSection(title: "Account") {
                SettingsRow(label: "Email", value: "john@icloud.com", action: {})
                SettingsRow(label: "Subscription", value: "Free", action: {})
            }

            Divider().background(.tertiary)

            // Preferences Section
            SettingsSection(title: "Preferences") {
                SettingsRow(label: "Appearance", value: "System", action: {})
                SettingsToggleRow(label: "Notifications", isOn: $notificationsEnabled)
            }

            Divider().background(.tertiary)

            // Privacy Section
            SettingsSection(title: "Privacy") {
                SettingsRow(label: "Data Retention", value: "30 days", action: {})
                SettingsRow(label: "Photo Deletion Policy", value: "After cropping", action: {})
            }

            Divider().background(.tertiary)

            // Support Section
            SettingsSection(title: "Support") {
                SettingsRow(label: "Help Center", action: {})
                SettingsRow(label: "Contact Us", action: {})
            }

            Divider().background(.tertiary)

            // About Section
            SettingsSection(title: "About") {
                SettingsRow(label: "Version", value: "1.0.0")
                SettingsRow(label: "Licenses", action: {})
                SettingsRow(label: "Terms of Service", action: {})
                SettingsRow(label: "Privacy Policy", action: {})
            }
        }
        .padding(16)
        .background {
            if reduceTransparency {
                Color.backgroundDefault.opacity(0.95)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.top, 12)

            content
        }
    }
}

struct SettingsRow: View {
    let label: String
    var value: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
        }
        .disabled(action == nil)
        .accessibilityAddTraits(action != nil ? [.isButton] : [])
    }
}

struct SettingsToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 12)
    }
}
```

**Navigation**:
- Rows with `action` closure: Navigate to detail screen or show sheet
- Rows with `value` only: Display-only (e.g., Version number)
- Toggle rows: Inline state change with sensory feedback

**Accessibility**:
- VoiceOver: "Account. Heading. Email, john@icloud.com, button. Subscription, Free, button."
- Dynamic Type: Text scales, row heights adjust
- Reduce Transparency: Replace .regularMaterial with opaque `backgroundDefault` with 5% black tint

---

### Export Data Button

**Purpose**: Primary CTA to trigger data export flow with format selection

**Specifications**:
- **Type**: PrimaryButton (from component library)
- **Title**: "Export Data"
- **Icon**: SF Symbol "square.and.arrow.up" (leading)
- **Position**: Bottom of screen, above tab bar, 32pt spacing
- **Margin**: 40pt from screen edges (left/right)

**Action**: Opens action sheet with format selection (CSV, JSON, PDF)

**SwiftUI Implementation**:
```swift
struct ExportDataButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))

                Text("Export Data")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background {
                Capsule()
                    .fill(.thinMaterial)
                    .shadow(color: Color.brandBrightBlue.opacity(0.5), radius: 12, x: 0, y: 4)
            }
            .overlay {
                Capsule()
                    .stroke(Color.brandBrightBlue, lineWidth: 2)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.brandSnappy, value: isPressed)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .padding(.horizontal, 40)
        .accessibilityLabel("Export Data")
        .accessibilityHint("Opens export format selection")
    }
}
```

---

### Export Format Selection Sheet

**Purpose**: Allow user to choose export format (CSV, JSON, PDF)

**Specifications**:
- **Presentation**: Action Sheet (.confirmationDialog)
- **Title**: "Choose Export Format"
- **Message**: "Select the format for your catalog export"
- **Options**:
  1. **CSV** - "Spreadsheet (CSV)" - Opens in Numbers/Excel
  2. **JSON** - "Developer Format (JSON)" - Raw data for programmers
  3. **PDF** - "Printable Document (PDF)" - Formatted catalog report
  4. **Cancel** - Dismiss without exporting

**SwiftUI Implementation**:
```swift
.confirmationDialog(
    "Choose Export Format",
    isPresented: $showExportSheet,
    titleVisibility: .visible
) {
    Button("Spreadsheet (CSV)") {
        Task {
            await viewModel.exportData(format: .csv)
        }
    }

    Button("Developer Format (JSON)") {
        Task {
            await viewModel.exportData(format: .json)
        }
    }

    Button("Printable Document (PDF)") {
        Task {
            await viewModel.exportData(format: .pdf)
        }
    }

    Button("Cancel", role: .cancel) {}
} message: {
    Text("Select the format for your catalog export")
}
```

---

### Export Progress Overlay

**Purpose**: Display progress indicator while export file is being generated

**Specifications**:
- **Background**: .ultraThickMaterial fullscreen overlay
- **Content**:
  - ProgressView (spinning indicator)
  - "Generating export..." (15pt SF Pro Rounded Regular, .secondary vibrancy)
  - Progress percentage (if available): "45%" (17pt SF Pro Rounded Semibold, .primary vibrancy)

**SwiftUI Implementation**:
```swift
struct ExportProgressOverlay: View {
    let progress: Double? // 0.0 to 1.0, nil = indeterminate

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                }

                Text("Generating export...")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        }
    }
}
```

**Timing**: Appears when export starts, dismisses when complete (< 2 seconds typical)

---

### Share Sheet (UIActivityViewController)

**Purpose**: System share sheet to export file via AirDrop, Mail, Files, etc.

**Specifications**:
- **Trigger**: After export file generated successfully
- **Items**: File URL (temporary directory)
- **Excluded Activities**: None (all sharing methods allowed)

**SwiftUI Implementation**:
```swift
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Usage:
.sheet(isPresented: $showShareSheet) {
    ActivityViewController(activityItems: [exportFileURL])
}
```

**Cleanup**: Delete temporary export file after share sheet dismissed

---

## State Management

### ProfileViewModel

**MVVM Pattern** (ADR-010):

```swift
import SwiftUI
import FirebaseAuth
import Combine

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var user: User?
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var notificationsEnabled: Bool = false
    @Published var exportStatus: ExportStatus = .idle
    @Published var exportFileURL: URL?
    @Published var error: ProfileError?

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let exportService: ExportServiceProtocol

    // MARK: - Computed Properties

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    // MARK: - Initialization

    init(
        authService: AuthServiceProtocol = FirebaseAuthService(),
        exportService: ExportServiceProtocol = CatalogExportService()
    ) {
        self.authService = authService
        self.exportService = exportService
        loadUser()
        loadNotificationSettings()
    }

    // MARK: - User Management

    func loadUser() {
        user = authService.currentUser
        // Load subscription tier from Firestore or RevenueCat
    }

    func signOut() async {
        do {
            try await authService.signOut()
            // Navigate to Onboarding
        } catch {
            self.error = .signOutFailed(error)
        }
    }

    // MARK: - Export

    func exportData(format: ExportFormat) async {
        exportStatus = .generating
        defer { exportStatus = .idle }

        do {
            let fileURL = try await exportService.exportCatalog(format: format)
            exportFileURL = fileURL
            exportStatus = .complete
        } catch {
            self.error = .exportFailed(error)
            exportStatus = .failed
        }
    }

    // MARK: - Notifications

    func loadNotificationSettings() {
        // Load from UserDefaults or UNUserNotificationCenter
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    func toggleNotifications() {
        notificationsEnabled.toggle()
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")

        if notificationsEnabled {
            // Request notification permission if not granted
        } else {
            // Disable notifications
        }
    }
}

enum ExportStatus {
    case idle
    case generating
    case complete
    case failed
}

enum ExportFormat {
    case csv
    case json
    case pdf
}

enum ProfileError: Error, LocalizedError {
    case signOutFailed(Error)
    case exportFailed(Error)

    var errorDescription: String? {
        switch self {
        case .signOutFailed(let error):
            return "Failed to sign out: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        }
    }
}
```

---

## SwiftUI Implementation Pattern

### ProfileView (Main View)

```swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var showExportSheet = false
    @State private var showShareSheet = false

    init(
        authService: AuthServiceProtocol = FirebaseAuthService(),
        exportService: ExportServiceProtocol = CatalogExportService()
    ) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            authService: authService,
            exportService: exportService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Info Card
                    if let user = viewModel.user {
                        UserInfoCard(user: user, subscriptionTier: viewModel.subscriptionTier)
                            .padding(.top, 16)
                    }

                    // Settings List
                    SettingsList(notificationsEnabled: $viewModel.notificationsEnabled)

                    // Export Button
                    ExportDataButton {
                        showExportSheet = true
                    }
                    .padding(.bottom, 80) // Space for tab bar
                }
            }
            .background(Color.backgroundDefault.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Choose Export Format",
                isPresented: $showExportSheet,
                titleVisibility: .visible
            ) {
                Button("Spreadsheet (CSV)") {
                    Task {
                        await viewModel.exportData(format: .csv)
                    }
                }

                Button("Developer Format (JSON)") {
                    Task {
                        await viewModel.exportData(format: .json)
                    }
                }

                Button("Printable Document (PDF)") {
                    Task {
                        await viewModel.exportData(format: .pdf)
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select the format for your catalog export")
            }
            .overlay {
                if viewModel.exportStatus == .generating {
                    ExportProgressOverlay(progress: nil)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let fileURL = viewModel.exportFileURL {
                    ActivityViewController(activityItems: [fileURL])
                }
            }
            .onChange(of: viewModel.exportStatus) { _, newStatus in
                if newStatus == .complete {
                    showShareSheet = true
                }
            }
            .alert(error: $viewModel.error)
        }
    }
}
```

---

## Export File Generation

### CSV Format

**Structure**:
```csv
Name,Category,Location,Estimated Value,Color,Material,Condition,AI Confidence
Camping Tent,Camping Gear,Garage,89.00,Green,Nylon,Good,0.87
Power Drill,Tools,Garage,45.00,Black,Metal,Excellent,0.92
```

**Implementation**:
```swift
func generateCSV(items: [CatalogItem]) -> String {
    var csv = "Name,Category,Location,Estimated Value,Color,Material,Condition,AI Confidence\n"

    for item in items {
        let row = [
            item.name,
            item.category,
            item.location ?? "",
            String(format: "%.2f", item.estimatedValue ?? 0.0),
            item.color ?? "",
            item.material ?? "",
            item.condition ?? "",
            String(format: "%.2f", item.aiConfidence ?? 0.0)
        ].joined(separator: ",")

        csv += row + "\n"
    }

    return csv
}
```

---

### JSON Format

**Structure**:
```json
{
  "exportDate": "2025-11-10T14:30:00Z",
  "totalItems": 42,
  "items": [
    {
      "id": "abc123",
      "name": "Camping Tent",
      "category": "Camping Gear",
      "location": "Garage",
      "estimatedValue": 89.00,
      "color": "Green",
      "material": "Nylon",
      "condition": "Good",
      "aiConfidence": 0.87,
      "imageURL": "https://firebasestorage.googleapis.com/..."
    }
  ]
}
```

**Implementation**:
```swift
func generateJSON(items: [CatalogItem]) throws -> Data {
    let export = CatalogExport(
        exportDate: Date(),
        totalItems: items.count,
        items: items
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    return try encoder.encode(export)
}

struct CatalogExport: Codable {
    let exportDate: Date
    let totalItems: Int
    let items: [CatalogItem]
}
```

---

### PDF Format

**Structure**: Formatted catalog report with item photos, metadata table, and summary statistics

**Implementation**: Uses PDFKit to generate multi-page PDF

```swift
func generatePDF(items: [CatalogItem]) -> Data {
    let pdfMetaData = [
        kCGPDFContextCreator: "Abundance iOS",
        kCGPDFContextTitle: "Catalog Export"
    ]

    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]

    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size

    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

    let data = renderer.pdfData { context in
        // Cover page
        context.beginPage()
        drawCoverPage(pageRect: pageRect, itemCount: items.count)

        // Item pages
        for item in items {
            context.beginPage()
            drawItemPage(pageRect: pageRect, item: item)
        }
    }

    return data
}
```

---

## Animations

### User Info Card Entrance

- Fade in with brandDefault spring (0.4s response)
- Scale from 0.9 → 1.0 with brandBouncy spring

### Settings List Entrance

- Slide up from bottom with brandDefault spring (0.5s delay)

### Export Button Press

- Scale to 0.95 with brandSnappy spring (0.1s)
- Glow expands on press

### Export Progress Overlay

- Fade in with brandGentle spring (0.3s)
- Progress percentage updates with brandSnappy spring

---

## Accessibility

### VoiceOver

- **User info card**: "[User name], [email], [tier] subscription. Card."
- **Settings sections**: "Account. Heading. Email, john@icloud.com, button."
- **Export button**: "Export Data. Button. Opens export format selection."
- **Export sheet**: "Choose Export Format. Spreadsheet CSV, button. Developer Format JSON, button."

### Dynamic Type

- All text scales from `.xSmall` to `.xxxLarge`
- Settings rows adjust height to fit scaled text
- Export button maintains minimum 44pt height

### Reduce Transparency

- Replace all materials with opaque `backgroundDefault` (#FCFCFF)
- User info card: Add 5% black tint
- Settings list: Add 10% black tint

### Reduce Motion

- Disable spring animations, use instant fades
- Export progress overlay: Instant appearance

---

## Testing Checklist

### Functional Tests

- [ ] User info card displays Firebase Auth data (name, email)
- [ ] Subscription badge color-coded correctly (Free = Mint Green, Premium = Bright Blue)
- [ ] Settings list organized into 5 sections (Account, Preferences, Privacy, Support, About)
- [ ] Notifications toggle persists to UserDefaults
- [ ] Export button opens format selection action sheet
- [ ] CSV export generates valid comma-separated file
- [ ] JSON export generates valid JSON with ISO 8601 dates
- [ ] PDF export generates multi-page document with items
- [ ] Share sheet opens with export file URL
- [ ] Temporary export file deleted after sharing

### Accessibility Tests

- [ ] VoiceOver announces all elements with descriptive labels
- [ ] All text scales with Dynamic Type (XS to XXXL)
- [ ] Reduce Transparency replaces materials with opaque backgrounds
- [ ] Reduce Motion disables spring animations
- [ ] All buttons have minimum 44pt tap target
- [ ] Settings rows keyboard-navigable

### Brand Compliance

- [ ] User info card uses ConcentricRectangle on iOS 26, RoundedRectangle on iOS 25
- [ ] Subscription badge uses Mint Green (Free) or Bright Blue (Premium)
- [ ] Export button uses Bright Blue (#4381DF) glow with 12pt radius
- [ ] All animations use brand spring presets (brandSnappy, brandDefault, brandGentle)
- [ ] Typography uses SF Pro Rounded at specified weights

### Performance Tests

- [ ] Export generation completes in < 2 seconds for 100 items
- [ ] CSV export tested with 1000+ items (no memory issues)
- [ ] PDF generation handles large item photos without crashes
- [ ] Share sheet presents without lag

---

## References

- **Architecture**: docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- **Component Library**: docs/design/DESIGN-031-swiftui-component-library.md
- **Color System**: docs/design/DESIGN-032-color-system-design-tokens.md
- **Animation Presets**: docs/design/DESIGN-034-animation-motion-specifications.md
- **Catalog View**: docs/design/DESIGN-028-catalog-view-specification.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial profile & export view specification | iOS UI/UX Designer |

---

**Status**: ✅ **APPROVED**

**Implementation Ready**: Profile & Export view specified with Firebase Auth integration, settings list, CSV/JSON/PDF export, share sheet, and complete accessibility support.
