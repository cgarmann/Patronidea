# Placeholder Assets

Last updated: April 2026

This document lists every temporary or stub asset in the project,
what is currently in its place, and the exact steps to replace it.

---

## 1. App icon

**Current state:** Flutter default blue launcher icon on all platforms.

**Why deferred:** `flutter_launcher_icons` requires a finished 1024×1024 PNG.
Running it with no `image_path` would overwrite icons with a blank result.

**Config location:** `pubspec.yaml` → `flutter_icons` block (image_path lines commented out).

**Replacement steps (when logo is ready):**

1. Export master icon: 1024×1024 px, PNG, solid brand background `#0A0A0F` (dark),
   no alpha channel (iOS App Store rejects transparent icons).
2. Save to `assets/images/app_icon.png`.
3. In `pubspec.yaml`, uncomment and set:
   ```yaml
   flutter_icons:
     image_path: "assets/images/app_icon.png"
     image_path_ios: "assets/images/app_icon.png"
   ```
4. Run: `dart run flutter_launcher_icons`
5. On macOS, open Xcode → Runner → General → App Icons → verify the icon set populated.

---

## 2. Splash screen image (logo on splash)

**Current state:** Solid brand-color background only — `#F8F9FC` (light) / `#0A0A0F` (dark).
No logo image. This is intentional and looks clean; it is not a broken state.

The branded background has already been applied by running `dart run flutter_native_splash:create`.

**Config location:** `pubspec.yaml` → `flutter_native_splash` block (image lines commented out).

**Replacement steps (when logo is ready):**

1. Export splash logo: PNG, transparent background, ~400px wide recommended.
   Separate light and dark versions if the logo colour needs to adapt.
2. Save to `assets/images/splash_logo.png` (and optionally `splash_logo_dark.png`).
3. In `pubspec.yaml`, uncomment:
   ```yaml
   flutter_native_splash:
     image: assets/images/splash_logo.png
     image_dark: assets/images/splash_logo_dark.png
     android_12:
       image: assets/images/splash_logo.png
   ```
4. Run: `dart run flutter_native_splash:create`
5. On iOS the logo will be centred over the brand-color background automatically.

---

## 3. iOS LaunchScreen.storyboard

**Current state:** Solid `#F8F9FC` background, no logo. Updated in session 4.

This file is the native iOS launch screen shown before Flutter boots.
`flutter_native_splash` manages this file — do **not** edit it manually after running the tool.

---

## 4. Firebase iOS credentials

**Current state:** `lib/firebase_options.dart` contains stub strings:
```
apiKey:  'REPLACE_WITH_IOS_API_KEY'
appId:   'REPLACE_WITH_IOS_APP_ID'
```

**Impact:** The app crashes at `Firebase.initializeApp()` on a real iOS build
until these are replaced with real values from `GoogleService-Info.plist`.

See `ios_prep/references/firebase_ios_setup.md` for the full replacement procedure.

---

## 5. Google Sign-In URL scheme

**Current state:** `ios/Runner/Info.plist` contains:
```xml
<string>REPLACE_WITH_REVERSED_CLIENT_ID</string>
```

**Impact:** Google Sign-In will fail silently on iOS until replaced.

**Replacement:** After downloading `GoogleService-Info.plist` from Firebase Console,
copy the value of `REVERSED_CLIENT_ID` (looks like `com.googleusercontent.apps.XXXX`)
and replace the placeholder string in Info.plist.

---

## 6. Stripe publishable key (iOS)

**Current state:** `ios/Runner/AppDelegate.swift` contains:
```swift
// StripeAPI.defaultPublishableKey = "pk_live_REPLACE_WITH_PUBLISHABLE_KEY"
```

**Impact:** Stripe payment sheet won't initialise on iOS until this is wired up.
The line is commented out intentionally — uncomment and set when ready.
