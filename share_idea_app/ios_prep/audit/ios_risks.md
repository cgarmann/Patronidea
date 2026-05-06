# iOS Risks — Things That Could Break or Surprise

Reviewed: April 2026

Risks are rated: HIGH / MEDIUM / LOW

---

## HIGH — Will definitely break without attention

### R1: UnsupportedError in firebase_options.dart
**Risk:** App crashes immediately on any non-Android platform
**Status:** FIXED — iOS stub added, no longer throws
**Residual risk:** iOS will not actually connect to Firebase until real iOS
FirebaseOptions are added after the iOS app is registered

### R2: Google Sign-In silently fails on iOS without URL scheme
**Risk:** Tapping "Sign in with Google" does nothing or shows an error
**Root cause:** iOS Google Sign-In requires a REVERSED_CLIENT_ID URL scheme in Info.plist
**Mitigation:** Document clearly; implement when ios/ folder exists
**Status:** Not fixed — requires ios/ and GoogleService-Info.plist first

### R3: Stripe payment sheet may not present on iOS
**Risk:** `flutter_stripe` needs iOS-specific initialization in AppDelegate
**Root cause:** Stripe's iOS SDK hooks into the AppDelegate lifecycle
**Mitigation:** Add Stripe setup to AppDelegate.swift when ios/ created
**Status:** Not fixed — Stripe not yet integrated anyway (pending)

---

## MEDIUM — Will degrade experience but not crash

### R4: SpaceGrotesk font on iOS
**Risk:** Font may fail to load if iOS font embedding is not configured in Info.plist
**Details:** Flutter handles font embedding via pubspec.yaml assets, which is
cross-platform. However, some iOS versions are stricter about font file validity.
**Mitigation:** Test on device. Fallback is system font (SF Pro), which looks
different from the brand intent.
**Status:** Low action needed now — Flutter font loading is usually reliable

### R5: SystemUiOverlayStyle — status bar on iOS
**Risk:** Status bar styling behaves differently on iOS
**Details:** iOS respects `statusBarBrightness` not `statusBarColor`. The current
theme sets `statusBarColor: Colors.transparent` which is Android-specific.
On iOS the relevant property is the brightness of the status bar icons.
The current code sets `SystemUiOverlayStyle.light` (dark theme) and
`SystemUiOverlayStyle.dark` (light theme) — this IS correct for iOS icon color.
**Mitigation:** Already handled correctly. No action needed.
**Status:** Low risk

### R6: Modal bottom sheet safe area on iOS
**Risk:** Sheet content may be obscured by the iPhone home indicator (bottom notch)
**Details:** Without `useSafeArea: true`, the bottom 34px (home indicator area)
is not padded, and the last item in the sheet can be under the bar.
**Status:** FIXED — `useSafeArea: true` added to settings sheet

### R7: Keyboard avoiding behavior differences
**Risk:** iOS and Android handle keyboard avoidance differently
**Details:** `Scaffold` with `resizeToAvoidBottomInset: true` (default) resizes
the body when the keyboard appears. On iOS this can cause layout jumps, especially
on screens with Sliders or content near the bottom.
**Affected screens:** SubmitIdeaScreen (text fields + slider at bottom), PitchScreen
**Mitigation:** Test on device. May need `SingleChildScrollView` adjustments.
**Status:** Document only — fix when testing on device

### R8: SnackBar overlap with home indicator
**Risk:** Floating SnackBar may appear at the very bottom and be partially covered
by the iOS home indicator gesture area
**Details:** `SnackBarBehavior.floating` should auto-respect SafeArea in
recent Flutter versions, but can still sit too low.
**Mitigation:** Test on device. May need `margin` override.
**Status:** Document only

---

## LOW — Minor visual differences, not breaking

### R9: Material icons appearance on iOS
**Risk:** Material Icons font renders fine on iOS but may look slightly different
from SF Symbols that users expect in native iOS apps
**Details:** Schjoldr's design intent is premium Material, not a native iOS clone.
This is a deliberate choice, not a bug.
**Mitigation:** Accept as design decision

### R10: FloatingActionButton on iOS
**Risk:** iOS users are less familiar with FABs — they are a Material design pattern
**Details:** The FAB for "New Idea" is a core interaction. This is a known tradeoff.
**Mitigation:** Accept. FABs are common in cross-platform apps on iOS.
Could be revisited if user research suggests confusion.

### R11: ElevatedButton minimum size
**Risk:** Buttons have `minimumSize: Size(double.infinity, 52)` — full-width, 52px tall
**Details:** This renders fine on iOS. iOS HIG recommends 44pt minimum touch targets.
52px is compliant and generous.
**Mitigation:** No action needed

### R12: go_router page transitions
**Risk:** Default Material slide transitions instead of iOS right-to-left native slide
**Details:** go_router uses Material page transitions by default. On iOS, this creates
a subtle "not quite native" feel, especially when navigating back.
**Mitigation:** Can be addressed with `customPageBuilder` in go_router using
`CupertinoPage` — medium effort, aesthetic improvement only.
**Status:** Document for future pass

---

## Risk summary

| ID | Description | Status | Priority |
|---|---|---|---|
| R1 | UnsupportedError crash | FIXED | - |
| R2 | Google Sign-In URL scheme | Pending Xcode | HIGH |
| R3 | Stripe iOS AppDelegate | Pending Xcode | HIGH |
| R4 | SpaceGrotesk font | Test on device | MEDIUM |
| R5 | SystemUiOverlayStyle | Already correct | LOW |
| R6 | Sheet safe area | FIXED | - |
| R7 | Keyboard avoiding | Test on device | MEDIUM |
| R8 | SnackBar home indicator | Test on device | LOW |
| R9 | Material icons | Accept (design) | LOW |
| R10 | FAB on iOS | Accept (design) | LOW |
| R11 | Button sizes | Compliant | NONE |
| R12 | Page transitions | Future pass | LOW |
