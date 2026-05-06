# Platform Gaps — Missing iOS Infrastructure

Reviewed: April 2026

This file documents everything that is missing or incomplete for iOS support.
Items are grouped by whether they can be done on Windows or require macOS/Xcode.

---

## CRITICAL — App will not build for iOS without these

### 1. No `ios/` Flutter runner folder
**Status:** Missing entirely
**What it is:** Flutter generates an Xcode project (Runner.xcodeproj) and all iOS
native wiring when you run `flutter create --platforms=ios .` or create the
project with iOS enabled from the start.
**How to fix:**
  ```bash
  # On macOS, from share_idea_app/
  flutter create --platforms=ios .
  ```
  This adds ios/ with: Runner.xcodeproj, Runner/, Flutter/, Podfile
**Requires:** macOS + Flutter SDK installed + CocoaPods

### 2. No Firebase iOS config (GoogleService-Info.plist)
**Status:** Missing
**What it is:** Firebase requires a per-platform config file.
Android has `google-services.json`. iOS needs `GoogleService-Info.plist`.
**How to fix:**
  1. Go to Firebase Console → Project Settings → Your apps
  2. Add an iOS app (Bundle ID: e.g. com.schjoldr.shareIdea)
  3. Download GoogleService-Info.plist
  4. In Xcode: drag file into Runner/ group (must be in Xcode, not just in Finder)
**Requires:** Firebase Console access (can be done on any OS) + Xcode for file placement

### 3. firebase_options.dart — iOS case missing (FIXED IN DART)
**Status:** Fixed in Dart — iOS no longer throws UnsupportedError
**Remaining:** The actual iOS FirebaseOptions values (apiKey, appId, etc.)
must come from the Firebase Console after the iOS app is registered.
Current stub will prevent crash but Firebase will not connect on iOS.

### 4. Firebase App Check — iOS provider not configured
**Status:** Fixed in Dart (conditional activation added)
**Remaining:** Choose provider for iOS:
  - Development: `.debug` (AppCheckDebugProvider)
  - Production: `.deviceCheck` or `.appAttest` (iOS 14+)
  - AppAttest is recommended for production (requires iOS 14+)

---

## IMPORTANT — App will build but behave incorrectly without these

### 5. No iOS permissions in Info.plist
**Status:** No Info.plist exists (no ios/ folder)
**Permissions this app will need:**
  - Camera (if profile photos added later)
  - No microphone, location, contacts needed currently
  - Google Sign-In requires URL scheme in Info.plist (REVERSED_CLIENT_ID from
    GoogleService-Info.plist)

### 6. Google Sign-In iOS URL scheme
**Status:** Not configured (requires ios/ folder)
**What it is:** Google Sign-In on iOS requires a custom URL scheme registered
in Info.plist. Without it, Google Sign-In silently fails.
**How to fix (in Info.plist after ios/ created):**
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>$(REVERSED_CLIENT_ID)</string>
      </array>
    </dict>
  </array>
  ```

### 7. Stripe iOS configuration
**Status:** Not configured
**What it is:** flutter_stripe requires iOS-specific setup:
  - Minimum iOS version: 13.0
  - `StripeAPI.defaultPublishableKey` set in AppDelegate or main
  - Payment sheet requires `UIApplicationSupportsIndirectInputEvents = YES` in Info.plist
**How to fix:** Add to AppDelegate.swift after ios/ created

### 8. In-app purchase iOS setup
**Status:** Not configured
**What it is:** `in_app_purchase` plugin works on both platforms but requires:
  - App registered in App Store Connect
  - Subscription products created in App Store Connect
  - StoreKit testing configured in Xcode scheme

---

## NICE TO HAVE — Polish items for later

### 9. App display name
**Status:** Will default to "Runner" without configuration
**How to fix:** Set CFBundleDisplayName in Info.plist to "Schjoldr"
              Or set in Xcode → Runner target → General → Display Name

### 10. App icon (iOS sizes)
**Status:** No iOS app icons exist
**What it is:** iOS requires an AppIcon.appiconset with multiple sizes
  (20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024px)
**How to fix:** Generate from master icon using flutter_launcher_icons package
  or manually in Xcode Asset Catalog

### 11. Launch screen (splash screen)
**Status:** Not configured
**What it is:** iOS shows a launch screen during app startup
**How to fix:** flutter_native_splash package or configure LaunchScreen.storyboard

### 12. Minimum iOS version
**Status:** Not set (will default to Flutter's minimum)
**Recommendation:** Set minimum to iOS 14.0 (supports AppAttest, wide device coverage)
**How to fix:** In Podfile: `platform :ios, '14.0'`

---

## Can be done on Windows (no Mac required)

- [x] firebase_options.dart iOS stub (done)
- [x] main.dart iOS App Check conditional (done)
- [x] Adaptive Dart UI code (done)
- [ ] Register iOS app in Firebase Console (browser-based)
- [ ] Register app in App Store Connect (browser-based, requires Apple Developer account)
- [ ] Generate app icons from master asset

## Requires macOS + Xcode

- [ ] `flutter create --platforms=ios .`
- [ ] GoogleService-Info.plist placement in Xcode
- [ ] Google Sign-In URL scheme in Info.plist
- [ ] Stripe AppDelegate setup
- [ ] Bundle ID configuration
- [ ] Signing team + provisioning profile
- [ ] iOS Simulator testing
- [ ] TestFlight / App Store submission
