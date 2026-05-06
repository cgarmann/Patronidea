# iOS Release Readiness Checklist

Last updated: April 2026 (session 5)
`flutter analyze`: No issues found ✅

---

## A — Dart / Flutter code (COMPLETE on Windows)

- [x] `firebase_options.dart` handles iOS without crashing (stub values)
- [x] `main.dart` App Check conditionally activates iOS provider (debug)
- [x] `lib/core/utils/platform_utils.dart` — isIOS/isAndroid helpers
- [x] Adaptive action sheet on idea card (iOS: CupertinoActionSheet)
- [x] Adaptive confirm dialog (showAdaptiveDialog / AlertDialog.adaptive)
- [x] All `showModalBottomSheet` calls use `useSafeArea: true`
- [x] `context.push()` used for sub-screen navigation (enables iOS swipe-back)
  - submit_idea from dashboard FAB
  - vault idea detail from vault list
- [x] `context.pop()` guarded with `canPop()` on all back buttons
  - submit_idea: `canPop() ? pop() : go('/innovator')` — handles go() arrival from result screen
  - idea_detail: `context.pop()` — always pushed, safe
  - pitch_screen: `canPop() ? pop() : go('/innovator')` — handles cold deep-link arrival
- [x] `auth_provider.dart` — removed `await` from synchronous `currentUser`
- [x] `paywall_screen.dart` — platform-adaptive payment copy (iOS: App Store, Android: Google Play)
- [x] All Dart warnings and infos resolved — codebase is clean
- [ ] Test SpaceGrotesk font loads on iOS device
- [ ] Test keyboard avoidance on SubmitIdeaScreen (text fields + slider)
- [ ] Test keyboard avoidance on PitchScreen
- [ ] Test SnackBar positioning above home indicator
- [ ] Test all touch targets on iPhone 14 screen size
- [ ] Test partnership request sheet on iPhone (keyboard interaction)

---

## B — iOS project setup (COMPLETE on Windows)

- [x] `ios/` Flutter runner project created (`flutter create --platforms=ios .`)
- [x] Bundle ID: `com.schjoldr.shareIdea` (set in Runner.xcodeproj, all 3 configs)
- [x] Deployment target: iOS 14.0 (set in Runner.xcodeproj, all 3 build configs)
- [x] Display name: Schjoldr (CFBundleDisplayName in Info.plist)
- [x] CFBundleName: Schjoldr (CFBundleName in Info.plist)
- [x] iPhone portrait-only orientation (Info.plist)
- [x] iPad all orientations supported (Info.plist)
- [x] UIApplicationSupportsIndirectInputEvents: true (Stripe requirement — present)
- [x] CADisableMinimumFrameDurationOnPhone: true (ProMotion support — present)
- [x] Podfile created with platform ios 14.0 + post-install deployment target hook
- [x] AppDelegate.swift Stripe initialization placeholder added
- [x] Google Sign-In URL scheme placeholder in Info.plist
- [ ] `pod install` on Mac
- [ ] Verify ios/ folder structure builds (open in Xcode)

---

## C — Firebase iOS (needs Firebase Console + Xcode)

- [x] `firebase_options.dart` iOS case ready (no crash, awaiting real values)
- [x] `main.dart` App Check activates `AppleProvider.debug` on iOS
- [ ] Register iOS app in Firebase Console
  - Bundle ID: `com.schjoldr.shareIdea`
  - App nickname: Schjoldr iOS
- [ ] Download `GoogleService-Info.plist`
- [ ] Add `GoogleService-Info.plist` to Xcode Runner target (via Xcode, not Finder)
- [ ] Update `firebase_options.dart` with real iOS values:
  - `apiKey` ← `API_KEY` from plist
  - `appId` ← `GOOGLE_APP_ID` from plist
  - `iosBundleId` ← already set to `com.schjoldr.shareIdea` ✓
- [ ] Switch App Check to `AppleProvider.appAttest` before production build
- [ ] Register App Check debug token in Firebase Console for Simulator testing

---

## D — Google Sign-In (needs GoogleService-Info.plist + Info.plist edit)

- [x] URL scheme slot prepared in Info.plist (placeholder: `REPLACE_WITH_REVERSED_CLIENT_ID`)
- [ ] Replace placeholder with real `REVERSED_CLIENT_ID` from GoogleService-Info.plist
- [ ] Test Google Sign-In on Simulator
- [ ] Test Google Sign-In on physical device

---

## E — Payments (needs App Store Connect + Mac)

- [ ] Register app in App Store Connect
- [ ] Create subscription products (monthly $19.99, annual $149.99)
- [ ] Enable in-app purchases capability in Xcode (Runner → Signing & Capabilities)
- [ ] Update `AppDelegate.swift` with Stripe publishable key (placeholder ready)
- [ ] Test StoreKit in Xcode Simulator with StoreKit configuration file
- [ ] Test Stripe payment sheet on Simulator

---

## F — App identity and assets (needs Mac)

- [x] Bundle Identifier: `com.schjoldr.shareIdea` ✓
- [x] Display name: Schjoldr ✓
- [ ] App icon: 1024×1024 master PNG needed (no alpha, brand background)
  - `flutter_launcher_icons: ^0.14.1` already in dev_dependencies ✓
  - Steps: add PNG to `assets/images/app_icon.png`, uncomment `image_path` in pubspec, run `dart run flutter_launcher_icons`
  - See `ios_prep/references/placeholder_assets.md`
- [x] Launch screen brand colors applied — `#F8F9FC` (light) / `#0A0A0F` (dark)
  - `flutter_native_splash: ^2.4.0` added to dev_dependencies ✓
  - `dart run flutter_native_splash:create` run — iOS + Android splash updated ✓
  - Logo image deferred; solid color splash is the current shipped state
- [ ] Set version and build number in pubspec.yaml before each upload

---

## G — Signing and provisioning (needs Apple Developer account)

- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Runner target → Signing & Capabilities → Team → select account
- [ ] Enable "Automatically manage signing"
- [ ] Verify code signing: Product → Archive

---

## H — Testing (needs Mac + iOS device/Simulator)

- [ ] First build: `flutter build ios --simulator --debug`
- [ ] Run on Simulator: `flutter run -d "iPhone 15"`
- [ ] Test all screens — light mode and dark mode
- [ ] Test on small screen (iPhone SE, 4.7")
- [ ] Test on iPhone 14 Pro (Dynamic Island)
- [ ] Test safe areas on all sheets and dialogs
- [ ] Test swipe-back gesture on sub-screens (submit idea, vault detail)
- [ ] Test Firebase auth flow (email + Google Sign-In)
- [ ] Test action sheet (idea card → ⋮ menu on iOS)
- [ ] Test delete confirmation dialog (Cupertino style)
- [ ] Test settings sheet with home indicator
- [ ] TestFlight beta test (internal testers first)

---

## I — App Store submission (needs Apple account + screenshots)

- [ ] Create app listing in App Store Connect
- [ ] Prepare screenshots (6.7", 6.1" minimum)
  - Dashboard — My Ideas (light + dark)
  - Submit idea screen
  - Idea result screen
  - The Vault (if Patron flow ready)
- [ ] Write privacy policy (URL required before submission)
- [ ] Complete privacy nutrition label
- [ ] Set age rating
- [ ] Submit for review

---

## Progress summary

**Section A — Dart/Flutter code:** 14/18 done (4 added this session; 4 remain, require device testing)
**Section B — iOS project:** 14/16 done (2 require Mac: pod install, Xcode verify)
**Section C — Firebase:** 2/8 done
**Section D — Google Sign-In:** 1/4 done
**Section E — Payments:** 0/5 done
**Section F — Assets:** 3/6 done (launch screen color ✓, icon still needs logo PNG)
**Section G — Signing:** 0/4 done
**Section H — Testing:** 0/12 done
**Section I — App Store:** 0/9 done

---

## Android smoke-check result (April 2026)

`flutter analyze` ✅ · `flutter test` ✅ · `flutter build apk --debug` ✅
APK: `build/app/outputs/flutter-apk/app-debug.apk` · 226 MB · 35.8s build time
**No Android regressions from iOS prep work.**
