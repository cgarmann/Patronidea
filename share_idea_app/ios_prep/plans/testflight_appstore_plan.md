# TestFlight and App Store Plan — Schjoldr

Created: April 2026
Status: Pre-release. iOS project structure complete. Needs Mac to build.

---

## Overview of remaining work

All Dart/Flutter iOS code is complete and clean.
The native iOS project structure (`ios/`) is configured:
- Bundle ID: `com.schjoldr.shareIdea`
- Deployment target: iOS 14.0
- Display name: Schjoldr
- Podfile: ready
- Info.plist: configured (URL scheme placeholder set)

What remains is entirely Mac/Xcode/Apple account work.

---

## Step 1 — First build on Mac (prerequisite for everything else)

**On Mac, from `share_idea_app/`:**

```bash
# 1. Get dependencies
flutter pub get

# 2. Install CocoaPods dependencies
cd ios && pod install && cd ..

# 3. Attempt simulator build (to verify the project compiles)
flutter build ios --simulator --debug

# 4. Run on iOS Simulator
flutter run -d "iPhone 15"
```

**Expected first-run issues to fix:**
- Firebase will initialize but fail to connect (placeholder ios values in firebase_options.dart)
- Google Sign-In will fail (URL scheme placeholder not replaced yet)
- These are expected — fix Firebase config first (Step 2), then retry

**If pod install fails:**
```bash
# Clean and retry
cd ios
pod deintegrate
pod install
```

**If build fails with signing error:**
  - Open `ios/Runner.xcworkspace` in Xcode
  - Runner target → Signing & Capabilities → Team → select your Apple ID
  - Then retry `flutter run`

---

## Step 2 — Firebase iOS setup (REQUIRED before app is functional)

### 2a. Register iOS app in Firebase Console
1. Go to console.firebase.google.com
2. Open project: `share-your-idea-schjoldr`
3. Project Settings (gear icon) → Your apps → Add app → iOS icon
4. Bundle ID: `com.schjoldr.shareIdea`
5. App nickname: `Schjoldr iOS`
6. Skip App Store ID for now
7. Download `GoogleService-Info.plist`

### 2b. Add plist to Xcode (MUST use Xcode, not Finder)
1. Open `ios/Runner.xcworkspace` in Xcode
2. In the project navigator, right-click `Runner/` group
3. "Add Files to Runner..."
4. Select `GoogleService-Info.plist`
5. ✅ Check "Copy items if needed"
6. ✅ Check "Add to targets: Runner"
7. Click Add

### 2c. Update firebase_options.dart
Open `GoogleService-Info.plist` and copy values into `lib/firebase_options.dart`:

| plist key | firebase_options.dart field |
|---|---|
| `API_KEY` | `apiKey` |
| `GOOGLE_APP_ID` | `appId` |
| `BUNDLE_ID` | `iosBundleId` (should match `com.schjoldr.shareIdea`) |
| `GCM_SENDER_ID` | `messagingSenderId` |
| `PROJECT_ID` | `projectId` |
| `STORAGE_BUCKET` | `storageBucket` |

### 2d. Fix Google Sign-In URL scheme in Info.plist
1. Open `GoogleService-Info.plist`
2. Find `REVERSED_CLIENT_ID` value — looks like:
   `com.googleusercontent.apps.1002199718024-xxxxxxxxxxxxxxxxxxxxxxxx`
3. Open `ios/Runner/Info.plist` in a text editor
4. Replace `REPLACE_WITH_REVERSED_CLIENT_ID` with the actual value

---

## Step 3 — Xcode signing setup

### 3a. Automatic signing (recommended for development)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Click `Runner` in project navigator
3. Select `Runner` target → Signing & Capabilities tab
4. Check "Automatically manage signing"
5. Team: select your Apple Developer account
6. Xcode will generate/update provisioning profiles automatically

### 3b. Apple Developer account requirements
- Must be enrolled in Apple Developer Program ($99/year)
- Enroll at: developer.apple.com/programs

### 3c. App ID registration
- Xcode auto-registers the App ID (`com.schjoldr.shareIdea`) when you set the team
- Verify in developer.apple.com → Certificates, Identifiers & Profiles → Identifiers

---

## Step 4 — Firebase App Check production setup

Before shipping to TestFlight/App Store:

1. In `lib/main.dart`, change:
   ```dart
   appleProvider: AppleProvider.debug,
   ```
   to:
   ```dart
   appleProvider: AppleProvider.appAttest,
   ```
2. AppAttest requires iOS 14+ physical device — ✅ already set
3. Register App Check in Firebase Console:
   - Firebase Console → App Check → Apps → iOS app → "Get started"
   - Select "App Attest"
4. For development/Simulator testing, keep `AppleProvider.debug` and register
   the debug token in Firebase Console → App Check → Debug tokens

---

## Step 5 — App icon and launch screen

### App icon
Current state: Flutter default placeholder icons are in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Option A — flutter_launcher_icons (recommended):**
```yaml
# Add to pubspec.yaml dev_dependencies:
flutter_launcher_icons: ^0.14.0

# Add configuration:
flutter_icons:
  ios: true
  android: true
  image_path: "assets/images/icon.png"   # 1024x1024 PNG, no alpha channel
  remove_alpha_ios: true
```
```bash
dart run flutter_launcher_icons
```

**Option B — Xcode Asset Catalog:**
- Open `ios/Runner.xcworkspace` in Xcode
- Navigate to `Runner/Assets.xcassets/AppIcon`
- Drag images into each slot (1024×1024 required, others auto-generated)

**Requirements:**
- Master image: 1024×1024 px PNG
- No alpha channel (App Store rejects icons with transparency)
- Background should be the Schjoldr brand color

### Launch screen
Current state: Default white Flutter launch screen (`LaunchScreen.storyboard`)

**Option — flutter_native_splash:**
```yaml
# Add to pubspec.yaml dev_dependencies:
flutter_native_splash: ^2.4.0

# Configuration:
flutter_native_splash:
  color: "#F8F9FC"
  color_dark: "#0A0A0F"
  # Optional: add logo if exists
  # image: assets/images/splash_logo.png
```
```bash
dart run flutter_native_splash:create
```

---

## Step 6 — Version and build number workflow

**Current values in pubspec.yaml:**
```yaml
version: 1.0.0+1
```
Format: `MARKETING_VERSION+BUILD_NUMBER`

**Rules:**
- `MARKETING_VERSION` (e.g. `1.0.0`): user-visible version, shown on App Store
- `BUILD_NUMBER` (e.g. `1`): must increment for every TestFlight/App Store upload
- Apple rejects uploads if build number is not strictly higher than previous

**Increment before each TestFlight upload:**
```yaml
# Example: second upload
version: 1.0.0+2

# Example: first public release
version: 1.0.0+10   # skip numbers during testing to leave room
```

**Build for release:**
```bash
flutter build ipa --release
```
This produces `build/ios/ipa/share_idea_app.ipa`

---

## Step 7 — App Store Connect setup

### 7a. Create app record
1. Go to appstoreconnect.apple.com
2. My Apps → + → New App
3. Platform: iOS
4. Name: Schjoldr
5. Bundle ID: com.schjoldr.shareIdea (select from dropdown after Xcode registers it)
6. SKU: schjoldr-ios-001 (internal reference, not shown to users)

### 7b. App information required
- **App name:** Schjoldr
- **Subtitle** (optional, 30 chars): Private idea management
- **Primary category:** Productivity
- **Secondary category:** Business (optional)
- **Privacy policy URL:** required before submission
- **Age rating:** complete questionnaire (likely 4+)

### 7c. App description (for App Store listing)
Draft (refine before submission):
```
Schjoldr is a private-first idea management app for serious builders.

Save your ideas securely, organize them by status, and track them through 
our Smart Engine — which scores each idea for originality and flags 
similarities before they go anywhere.

Your ideas stay private until you decide to share them. No view counts. 
No public feeds. Just you, your ideas, and the tools to develop them.

Features:
• Private idea vault — submit, organize, and track your ideas
• Smart Engine — AI-powered originality scoring and duplicate detection
• Archive and restore ideas at any time
• The Vault — browse verified ideas from other innovators (Patron access)
• Partnership pitches — connect directly with innovators you believe in

Schjoldr is built for people who take their ideas seriously.
```

### 7d. Screenshots required
- iPhone 6.7" display (iPhone 15 Pro Max): minimum 3 screenshots
- iPhone 6.1" display (iPhone 15): optional but recommended
- iPad 12.9" (3rd gen+): required only if iPad is supported

**Screenshots to capture:**
1. Dashboard — My Ideas list (light mode)
2. Dashboard — My Ideas list (dark mode)
3. Submit idea screen
4. Idea result screen (active/approved state)
5. The Vault (if Patron flow is ready)

**Tool:** Take screenshots from iOS Simulator:
```bash
# Launch simulator
flutter run -d "iPhone 15 Pro Max"
# Use simulator menu: File → Save Screen
```

---

## Step 8 — TestFlight upload

```bash
# Build IPA
flutter build ipa --release

# Upload via Transporter app (Mac App Store) or xcrun altool:
xcrun altool --upload-app -f build/ios/ipa/share_idea_app.ipa \
  -u "your-apple-id@email.com" -p "@keychain:altool"

# Or use Xcode: Product → Archive → Distribute App → TestFlight
```

**After upload:**
1. Wait for Apple processing (5–30 minutes)
2. App Store Connect → TestFlight → Builds → select build
3. Add internal testers (up to 100, no review needed)
4. Add external testers (requires TestFlight review, 1–2 days)

---

## What Claude completed

- [x] ios/ Flutter runner project generated
- [x] Bundle ID set to `com.schjoldr.shareIdea`
- [x] Deployment target set to iOS 14.0
- [x] Display name set to "Schjoldr"
- [x] iPhone locked to portrait orientation
- [x] Podfile created with correct iOS 14.0 platform
- [x] Info.plist configured with URL scheme placeholder
- [x] firebase_options.dart has iOS case (no crash)
- [x] main.dart App Check activates iOS provider
- [x] Adaptive action sheets on iOS (CupertinoActionSheet)
- [x] Adaptive confirm dialog (showAdaptiveDialog)
- [x] Settings sheet uses useSafeArea: true

## What still needs a human

- [ ] `pod install` on Mac
- [ ] GoogleService-Info.plist from Firebase Console
- [ ] Replace URL scheme placeholder in Info.plist
- [ ] Xcode signing team setup
- [ ] App icon design (1024×1024 master)
- [ ] Launch screen brand color configuration
- [ ] First simulator build and smoke test
- [ ] Firebase App Check debug token registration
- [ ] App Store Connect app record creation
- [ ] Privacy policy URL
- [ ] App Store screenshots
- [ ] TestFlight upload

## What requires Apple account access

- Apple Developer Program enrollment ($99/year)
- Xcode signing (team ID)
- App ID registration
- App Store Connect app record
- TestFlight
- Distribution provisioning profile
- App Store submission

---

## Next 5 actions in order

1. **On Mac:** `flutter pub get` → `cd ios && pod install`
2. **Firebase Console:** Register iOS app → download `GoogleService-Info.plist`
3. **In Xcode:** Add `GoogleService-Info.plist` to Runner target → update `firebase_options.dart` → update URL scheme in Info.plist
4. **In Xcode:** Set signing team → run on Simulator → verify auth flow
5. **App Store Connect:** Create app record → add description → prepare screenshots
