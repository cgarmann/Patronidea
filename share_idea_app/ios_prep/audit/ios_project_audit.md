# iOS Project Readiness Audit

Created: April 2026
Flutter version: 3.32.8 (stable, July 2025)
Dart version: 3.8.1

---

## Summary

The Dart/Flutter codebase is now iOS-safe and mostly iOS-ready.
The project has no `ios/` folder — it cannot be built for iOS yet.
Everything blocking a first iOS build requires macOS + Xcode.

---

## 1. ios/ Folder

**Status: Missing**

The `share_idea_app/` directory contains:
```
android/
assets/
build/
ios_prep/         ← new (documentation only)
lib/
pubspec.lock
pubspec.yaml
```

There is no `ios/` folder. Flutter needs this folder to build for iOS.
It contains the Xcode project, CocoaPods Podfile, and the native Runner app wrapper.

**How to create it (on macOS):**
```bash
cd share_idea_app
flutter create --platforms=ios .
```

This command is safe — it will not overwrite existing files, only add the ios/ folder.
After creation, run `pod install` inside ios/:
```bash
cd ios && pod install
```

---

## 2. pubspec.yaml — iOS compatibility

Flutter 3.32.8 sets minimum iOS to 12.0 by default.

**Dependency iOS requirements:**

| Package | iOS minimum | Notes |
|---|---|---|
| `flutter_stripe: ^10.1.1` | iOS 13.0 | Hard minimum — Stripe SDK requires it |
| `firebase_app_check: ^0.3.0` | iOS 12.0+ | AppAttest requires iOS 14+ |
| `google_sign_in: ^6.2.1` | iOS 12.0+ | URL scheme required in Info.plist |
| `in_app_purchase: ^3.2.0` | iOS 11.0+ | StoreKit, widely supported |
| All other packages | iOS 12.0+ | Pure Dart or widely supported |

**Recommendation:** Set minimum iOS to **14.0** in Podfile.
- Covers AppAttest (App Check production provider)
- Exceeds Stripe's minimum (13.0)
- Covers ~99%+ of active iPhones
- Set in `ios/Podfile`: `platform :ios, '14.0'`

---

## 3. Bundle Identifier

**Status: Not yet set (requires ios/ folder)**

**Recommended value:** `com.schjoldr.shareIdea`

This must be consistent across:
- Xcode project (Runner target → Bundle Identifier)
- Firebase Console (iOS app registration)
- App Store Connect (app record)
- `firebase_options.dart` `iosBundleId` field (set to `com.schjoldr.shareIdea`)

The `iosBundleId` field is already included in the iOS stub in `firebase_options.dart`.

---

## 4. Info.plist

**Status: Not yet created (requires ios/ folder)**

Flutter generates a default Info.plist. The following items must be reviewed/added:

### Required for this app:

```xml
<!-- App display name -->
<key>CFBundleDisplayName</key>
<string>Schjoldr</string>

<!-- Google Sign-In: must match REVERSED_CLIENT_ID from GoogleService-Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>$(REVERSED_CLIENT_ID)</string>
    </array>
  </dict>
</array>

<!-- Stripe: required for payment sheet -->
<key>UIApplicationSupportsIndirectInputEvents</key>
<true/>
```

### Review but likely no action:
- `NSFaceIDUsageDescription` — not using Face ID directly (Firebase handles auth)
- `NSCameraUsageDescription` — not using camera currently
- `NSPhotoLibraryUsageDescription` — not using photo library currently

---

## 5. Firebase iOS configuration

**Status: Not configured**

Steps required (in order):
1. Go to [Firebase Console](https://console.firebase.google.com) → Project: share-your-idea-schjoldr
2. Project Settings → Your apps → Add app → iOS
3. Enter Bundle ID: `com.schjoldr.shareIdea`
4. Download `GoogleService-Info.plist`
5. In Xcode: drag file into `Runner/` group with "Copy items if needed" checked
   (Do NOT just copy the file in Finder — it must be added via Xcode to be included in the build)
6. Update `firebase_options.dart` with real iOS values:
   - `apiKey` from GoogleService-Info.plist `API_KEY`
   - `appId` from GoogleService-Info.plist `GOOGLE_APP_ID`
   - `messagingSenderId` — same as Android (`1002199718024`)
   - `iosBundleId` — `com.schjoldr.shareIdea`

---

## 6. App Check — iOS

**Status: Code complete (debug provider), production provider pending**

Current code in `main.dart`:
```dart
} else if (defaultTargetPlatform == TargetPlatform.iOS) {
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
  );
}
```

For production, change `AppleProvider.debug` to `AppleProvider.appAttest`.

**AppAttest notes:**
- Requires iOS 14+ device (works on Simulator? No — needs Secure Enclave)
- Register the debug token in Firebase Console:
  Settings → App Check → Apps → iOS app → Manage debug tokens
- Do NOT ship with `AppleProvider.debug` in production

---

## 7. Signing and Team

**Status: Not configured (requires Xcode + Apple Developer account)**

- Enroll at developer.apple.com ($99/year)
- In Xcode: Runner target → Signing & Capabilities → Team
- Xcode can manage signing automatically (recommended)
- Provisioning profiles are generated automatically with auto-signing

---

## 8. App Icon

**Status: Not created**

iOS requires an AppIcon.appiconset with multiple sizes.
The app has no iOS icon assets yet.

**Fastest approach:** Use `flutter_launcher_icons` package:
1. Add to pubspec.yaml dev_dependencies: `flutter_launcher_icons: ^0.14.0`
2. Add icon configuration to pubspec.yaml
3. Run: `flutter pub run flutter_launcher_icons:main`

**Required icon sizes for App Store:**
- 1024×1024 (App Store, no alpha channel)
- 180×180 (iPhone 60pt @3x)
- 120×120 (iPhone 60pt @2x)
- And many others (automatically generated by flutter_launcher_icons)

---

## 9. Launch Screen

**Status: Will default to white/black Flutter splash**

Flutter generates a basic LaunchScreen.storyboard.
For a premium app like Schjoldr, this should show the brand color.

**Approach:** Use `flutter_native_splash` package:
1. Add: `flutter_native_splash: ^2.4.0` to dev_dependencies
2. Configure in pubspec.yaml:
   ```yaml
   flutter_native_splash:
     color: "#F8F9FC"           # light mode bg
     color_dark: "#0A0A0F"     # dark mode bg
     image: assets/images/logo.png   # if logo exists
   ```
3. Run: `dart run flutter_native_splash:create`

---

## 10. Google Sign-In — iOS

**Status: Will fail silently without URL scheme**

The `google_sign_in` package version 6.2.1 supports iOS natively.
However it requires a custom URL scheme in Info.plist to handle the OAuth redirect.

The value comes from `REVERSED_CLIENT_ID` in `GoogleService-Info.plist`.
It looks like: `com.googleusercontent.apps.1002199718024-xxxxxxxx`

This must be added to Info.plist after Firebase iOS app is registered.

---

## 11. Stripe — iOS

**Status: Not integrated (Android also pending)**

`flutter_stripe: ^10.1.1` supports iOS 13+.
iOS setup requires adding to AppDelegate.swift:
```swift
import Flutter
import UIKit
import Stripe

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    StripeAPI.defaultPublishableKey = "pk_live_..."
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 12. What can be done NOW without macOS

| Task | Status |
|---|---|
| firebase_options.dart iOS stub | Done |
| main.dart iOS App Check | Done |
| platform_utils.dart | Done |
| Adaptive action sheet | Done |
| Adaptive confirm dialog | Done |
| useSafeArea on sheets | Done |
| Register iOS app in Firebase Console | Can do (browser) |
| Register app in App Store Connect | Can do (browser, needs Apple Dev account) |
| Prepare app icon master file | Can do |
| Write App Store listing copy | Can do |

## What requires macOS

| Task | Requires |
|---|---|
| `flutter create --platforms=ios .` | macOS + Flutter |
| `pod install` | macOS + CocoaPods |
| Add GoogleService-Info.plist to Xcode | Xcode |
| Configure Info.plist | Text editor (but needs ios/ to exist) |
| Xcode signing setup | Xcode |
| iOS Simulator testing | macOS |
| Physical device testing | macOS + Xcode |
| Archive + TestFlight upload | macOS + Xcode |
| App Store submission | macOS (or App Store Connect web for some steps) |
