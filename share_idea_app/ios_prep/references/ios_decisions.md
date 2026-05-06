# iOS Design & Technical Decisions

Created: April 2026
Purpose: Log key decisions made during iOS adaptation so future engineers
understand the reasoning and don't reverse choices without context.

---

## D1 — Keep Material AppBar, do not use CupertinoNavigationBar

**Decision:** AppBar stays Material on iOS.
**Date:** 2026-04-26
**Reasoning:**
  - Material AppBar with zero elevation looks clean and premium on iOS.
  - CupertinoNavigationBar conflicts with go_router's navigation model and
    has different title sizing and back button behavior.
  - The "large title" pattern is implemented as a scrollable header inside
    the list body (_DashboardHeader), which naturally matches iOS norms
    without requiring CupertinoSliverNavigationBar.
  - Changing AppBar would require forking every screen that uses MainScaffold.
**Revisit if:** User testing shows iOS users are confused by navigation.

---

## D2 — CupertinoActionSheet for idea card contextual menus on iOS

**Decision:** Idea card overflow menu uses CupertinoActionSheet on iOS,
Material BottomSheet on Android.
**Date:** 2026-04-26
**Reasoning:**
  - Contextual menus with destructive actions (Archive, Delete) feel most
    natural as action sheets on iOS — this is the dominant iOS pattern
    (used by Files, Notes, Reminders, etc.).
  - A Material BottomSheet with ListTile items works but feels un-iOS-like
    at this specific interaction point.
  - Action sheets make the destructive action (Delete) visually prominent
    with red color, matching iOS convention.
  - This is the highest-impact single UX change for iOS feel.

---

## D3 — showAdaptiveDialog for delete confirmation

**Decision:** Replace `showDialog` + `AlertDialog` with `showAdaptiveDialog`.
**Date:** 2026-04-26
**Reasoning:**
  - `showAdaptiveDialog` renders `CupertinoAlertDialog` on iOS and
    `AlertDialog` on Android automatically.
  - Zero extra code. Correct behavior on both platforms.
  - CupertinoAlertDialog is the iOS-native confirmation pattern.

---

## D4 — Keep SpaceGrotesk font on iOS, no SF Pro substitution

**Decision:** SpaceGrotesk is the brand font on all platforms.
**Date:** 2026-04-26
**Reasoning:**
  - Brand identity. The premium, structured feeling of Schjoldr comes
    partly from the typography. SF Pro would make it look generic.
  - Flutter handles font embedding via pubspec.yaml — this works on iOS.
  - Accepted risk: if font fails to load on an edge case iOS version,
    the system fallback is SF Pro, which is still readable.

---

## D5 — Keep Material forms (TextFormField) on iOS

**Decision:** Do not replace TextFormField with CupertinoTextField.
**Date:** 2026-04-26
**Reasoning:**
  - Material TextFormField renders acceptably on iOS.
  - CupertinoTextField has different styling APIs, different validation
    patterns, and would require rewriting all form screens.
  - The investment is not worth the visual delta for this app.
  - Custom border styling via InputDecorationTheme looks good on iOS.
**Revisit if:** Design audit after device testing shows it looks poor.

---

## D6 — useSafeArea: true on all bottom sheets

**Decision:** All `showModalBottomSheet` calls use `useSafeArea: true`.
**Date:** 2026-04-26
**Reasoning:**
  - iPhone home indicator (34px bar at the bottom) overlaps sheet content
    without this flag.
  - The settings sheet sign-out button was the most at-risk item.
  - Low risk change — Android ignores the flag when there is no home indicator.

---

## D7 — Bundle Identifier recommendation

**Decision:** Use `com.schjoldr.shareIdea` as Bundle ID.
**Date:** 2026-04-26
**Status:** Pending — must be confirmed and set when ios/ folder is created.
**Reasoning:**
  - Follows reverse domain convention.
  - Matches the project identity (Schjoldr company, shareIdea product).
  - Must match exactly between: Xcode project, Firebase Console,
    App Store Connect, and GoogleService-Info.plist.
**Alternative:** `com.schjoldr.app` if simpler is preferred.

---

## D8 — Minimum iOS version: 14.0

**Decision:** Target iOS 14.0 as minimum supported version.
**Date:** 2026-04-26
**Reasoning:**
  - Firebase AppAttest (recommended App Check provider) requires iOS 14+.
  - iOS 14 covers ~99% of active iPhone users (as of 2025 data).
  - Flutter's current minimum is iOS 12, but 14 is the practical choice
    for AppAttest and modern API access.
  - Dropping to 13 saves almost no users and complicates App Check setup.

---

## D9 — Firebase App Check: debug provider for iOS development

**Decision:** Use `AppCheckDebugProvider` for iOS in debug builds.
**Date:** 2026-04-26
**Reasoning:**
  - AppAttest does not work in the iOS Simulator — it requires a physical
    device with Secure Enclave.
  - The debug provider allows Simulator and development device testing.
  - Platform check (`kDebugMode` or build flag) gates which provider is used.
  - Production builds should use AppAttest.
**Note:** The debug token must be registered in Firebase Console.

---

## D10 — FloatingActionButton kept on iOS

**Decision:** FAB for "New Idea" stays as-is on iOS.
**Date:** 2026-04-26
**Reasoning:**
  - The FAB is a core product interaction (primary CTA).
  - There is no iOS-native equivalent that would be better.
  - Many cross-platform apps (Notion, Linear) use FABs on iOS without user confusion.
  - Replacing it would require a new bottom bar or navigation redesign,
    which is out of scope for this pass.

---

## D11 — iPhone portrait-only orientation

**Decision:** iPhone is locked to portrait. iPad supports all orientations.
**Date:** 2026-04-26
**Reasoning:**
  - Schjoldr is an idea management tool — all core flows (submit, review, archive)
    are vertical content lists. Landscape adds no value on a phone.
  - Locking to portrait prevents unexpected layout bugs in landscape.
  - iPad users may want landscape for reading longer idea bodies — kept enabled.
  - Set in `ios/Runner/Info.plist` via `UISupportedInterfaceOrientations` (portrait only).

---

## D12 — flutter create --platforms=ios on Windows

**Decision:** Used `flutter create --platforms=ios .` on Windows to generate the ios/ folder.
**Date:** 2026-04-26
**Reasoning:**
  - Flutter SDK on Windows can generate the iOS project file structure.
  - The generated files are identical to what macOS would generate.
  - CocoaPods (`pod install`) and actual builds still require macOS.
  - This approach maximises what can be done before Mac access.
  - The generated project was immediately configured (bundle ID, deployment target,
    Info.plist, Podfile) so it is ready for `pod install` on Mac.

---

## D13 — Podfile written manually, not generated by pod init

**Decision:** `ios/Podfile` was written manually using the standard Flutter iOS Podfile template.
**Date:** 2026-04-26
**Reasoning:**
  - `pod init` was not available (Windows, no CocoaPods).
  - The Flutter iOS Podfile is well-documented and stable — the manual version is
    identical to what Flutter's tooling would generate on macOS.
  - Post-install hook explicitly sets `IPHONEOS_DEPLOYMENT_TARGET = '14.0'` on all
    pods to ensure CocoaPods-managed dependencies also respect the minimum version.
  - This prevents common "pod deployment target lower than app" build warnings.

---

## D14 — URL scheme placeholder in Info.plist

**Decision:** Added a `REPLACE_WITH_REVERSED_CLIENT_ID` placeholder for the Google Sign-In URL scheme.
**Date:** 2026-04-26
**Reasoning:**
  - The actual REVERSED_CLIENT_ID comes from `GoogleService-Info.plist`, which
    requires Firebase Console registration of the iOS app first.
  - Adding a visible placeholder ensures the step is not forgotten.
  - An app without this URL scheme will fail silently on Google Sign-In — a
    notoriously easy-to-miss iOS gotcha.
  - The placeholder string is intentionally invalid so it will not accidentally
    match a real URL scheme.
**Action required:** Replace with actual REVERSED_CLIENT_ID from GoogleService-Info.plist.

---

## D15 — Platform-adaptive payment provider copy in PaywallScreen

**Decision:** Use `isIOS` guard to show "App Store" on iOS and "Google Play" on Android.
**Date:** 2026-04-26
**Reasoning:**
  - Apple App Store guidelines prohibit referencing competitor platforms.
  - The paywall disclaimer ("Secure payment via ...") and the placeholder SnackBar
    both contained Android-only text that would appear verbatim on iOS.
  - The fix is a runtime platform check — same widget, different string.
  - The actual payment integration (StoreKit vs Google Play Billing) is still a
    TODO; only the user-visible strings were made platform-correct.
**Files changed:** `lib/screens/patron/paywall_screen.dart`
