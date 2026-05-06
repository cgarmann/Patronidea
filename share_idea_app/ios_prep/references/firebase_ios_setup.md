# Firebase iOS Setup Guide

Complete this once you have access to Firebase Console and a Mac with Xcode.

---

## Prerequisites

- Firebase project `share-your-idea-schjoldr` exists (already created for Android)
- Mac with Xcode installed
- Apple Developer account (needed for signing, not for Simulator testing)

---

## Step 1 — Register the iOS app in Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com) → project `share-your-idea-schjoldr`
2. Project settings → Your apps → Add app → iOS
3. Enter:
   - **iOS bundle ID:** `com.schjoldr.shareIdea`
   - **App nickname:** Schjoldr iOS
   - **App Store ID:** leave blank for now
4. Click Register app
5. Download `GoogleService-Info.plist`
6. Skip the "Add Firebase SDK" step (already in pubspec.yaml)
7. Skip the "Add initialisation code" step (already in main.dart)

---

## Step 2 — Add GoogleService-Info.plist to Xcode

> **Important:** This must be done via Xcode, not Finder drag-and-drop.
> Finder copy will not add the file to the Xcode build target.

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
2. In the Project Navigator (left sidebar), right-click the **Runner** group (yellow folder)
3. Choose **Add Files to "Runner"...**
4. Select `GoogleService-Info.plist` from your Downloads folder
5. In the dialog:
   - ✅ **Copy items if needed**
   - ✅ Target membership: **Runner** checked
6. Click Add
7. Verify the file appears under Runner in the Project Navigator

---

## Step 3 — Update firebase_options.dart

Open `GoogleService-Info.plist` and copy these values into `lib/firebase_options.dart`:

| plist key | firebase_options.dart field |
|---|---|
| `API_KEY` | `apiKey` |
| `GOOGLE_APP_ID` | `appId` |
| `GCM_SENDER_ID` | `messagingSenderId` (already: `1002199718024` — verify it matches) |
| `PROJECT_ID` | `projectId` (already: `share-your-idea-schjoldr` — verify) |
| `STORAGE_BUCKET` | `storageBucket` (already set — verify) |
| `BUNDLE_ID` | `iosBundleId` (already: `com.schjoldr.shareIdea` ✓) |

The iOS options block in `lib/firebase_options.dart`:
```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'PASTE_API_KEY_HERE',
  appId: 'PASTE_GOOGLE_APP_ID_HERE',
  messagingSenderId: '1002199718024',
  projectId: 'share-your-idea-schjoldr',
  storageBucket: 'share-your-idea-schjoldr.firebasestorage.app',
  iosBundleId: 'com.schjoldr.shareIdea',
);
```

---

## Step 4 — Update Google Sign-In URL scheme

1. Open `ios/Runner/Info.plist` in Xcode (or any text editor)
2. Find the URL scheme placeholder:
   ```xml
   <string>REPLACE_WITH_REVERSED_CLIENT_ID</string>
   ```
3. Open `GoogleService-Info.plist`, copy the value of `REVERSED_CLIENT_ID`
   (looks like: `com.googleusercontent.apps.1002199718024-XXXXXXXXXXXX`)
4. Replace the placeholder string with the real value

---

## Step 5 — App Check (debug token for Simulator)

`main.dart` already activates `AppleProvider.debug` for iOS builds.
To allow the Simulator to call Firebase without a real device attestation:

1. Run the app once in the Simulator — App Check will print a debug token to the console
2. Firebase Console → App Check → Apps → Schjoldr iOS → Manage debug tokens
3. Add the token from the console output
4. The Simulator can now call Firestore, Auth, Cloud Functions

> For production: switch `appleProvider` to `AppleProvider.appAttest` in `main.dart`
> and remove this debug token registration. App Attest requires a physical device.

---

## Step 6 — Verify on Simulator

```bash
# First time (from the ios/ directory on Mac):
pod install

# Then run:
cd share_idea_app
flutter run -d "iPhone 15"
```

Expected result:
- Splash screen shows Schjoldr brand background
- Firebase initialises without error
- Email sign-in works
- Google Sign-In opens browser (Simulator) or native sheet (device)

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `GoogleService-Info.plist not found` | File added via Finder not Xcode | Re-add via Xcode Add Files |
| `App Check token invalid` | Debug token not registered | Register in Firebase Console |
| `Google Sign-In: cannotFindAuthView` | REVERSED_CLIENT_ID wrong | Re-copy from plist |
| `FirebaseApp not configured` | plist not in build target | Check target membership in Xcode |
