# Building for iOS Device Testing

## Prerequisites

- Xcode Beta (required for Swift 6.0 and iOS 26.1)
- Apple Developer account (free tier sufficient for device testing)
- iPhone 16e with iOS 26.1 (device name: w-16e)
- Firebase project configured (GoogleService-Info.plist in App/)

## Build Steps

### 1. Open Project in Xcode

```bash
open Package.swift
```

### 2. Select Device Target

- In Xcode toolbar, click target selector (next to Run button)
- Select "w-16e" from device list
- If device not listed, connect via USB-C and trust computer on device

### 3. Configure Signing

- Select "AbundanceApp" target in project navigator
- Go to "Signing & Capabilities" tab
- Select your Team from dropdown
- Xcode will automatically create provisioning profile

### 4. Build and Run

Click Run button (⌘R) or:

```bash
xcodebuild -scheme AbundanceApp -destination 'platform=iOS,name=w-16e'
```

### 5. Trust Developer on Device

First time running on w-16e:
- iPhone 16e will show "Untrusted Developer" alert
- Go to Settings → General → VPN & Device Management
- Tap your Apple ID under "Developer App"
- Trust your Apple ID
- Return to app and launch

## Troubleshooting

### "No signing certificate found"
- Ensure Apple ID added in Xcode Preferences → Accounts
- Download manual provisioning profile from developer.apple.com

### "GoogleService-Info.plist not found"
- Ensure file exists at `App/GoogleService-Info.plist`
- Verify it's included in target membership

### "Camera permission denied"
- First launch on w-16e requires camera permission
- If denied, go to Settings → Abundance → Camera → Allow
- iOS 26.1 may require additional Privacy & Security permissions

## Testing Checklist

- [ ] Sign in with Apple works
- [ ] Camera captures photos
- [ ] Vision detects objects
- [ ] Items appear in catalog
- [ ] Tab navigation works
- [ ] Item detail view displays

## Firebase Console Verification

Check Firestore for created items:
https://console.firebase.google.com/project/YOUR_PROJECT/firestore

Check Storage for uploaded images:
https://console.firebase.google.com/project/YOUR_PROJECT/storage
