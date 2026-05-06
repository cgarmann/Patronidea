# iOS Adaptation Plan — Schjoldr

Created: April 2026
Approach: Intelligent hybrid — shared where possible, adaptive where it matters,
native-feeling where users notice. Not a full Cupertino rebuild.

---

## Guiding principles

1. One codebase. No forked iOS app.
2. Material 3 is acceptable on iOS. Replace only where the difference is noticeable.
3. Destructive and contextual actions should feel native.
4. Navigation and safe areas must be correct.
5. Brand identity (SpaceGrotesk, cyan/purple, clean light mode) stays intact.
6. Prefer `*.adaptive()` widgets over full platform switches.

---

## Navigation and top bars

**Decision:** Keep Material AppBar. Do not replace with CupertinoNavigationBar.

**Reasoning:**
- Material AppBar with `elevation: 0` and `scrolledUnderElevation: 0.5` looks
  clean and premium on iOS.
- CupertinoNavigationBar has a different title positioning and back button style
  that conflicts with our go_router setup.
- The large-title pattern (scrollable header inside the list) already matches
  iOS norms without requiring a CupertinoSliverNavigationBar.

**Action taken:** No change needed to AppBar.

**Future option (later pass):**
  Implement `CupertinoPageRoute` via go_router `customPageBuilder` for native
  iOS swipe-back gesture and slide transition feel.

---

## Large titles vs Material app bars

**Current pattern in InnovatorDashboard:**
- AppBar is empty (no title shown)
- Large title rendered inside the scrollable content (_DashboardHeader)
- This naturally collapses as the user scrolls — iOS-appropriate behavior

**Assessment:** Already correct for iOS. No change needed.

---

## Sheets, dialogs, menus, and action patterns

**Decision:** Adaptive approach based on action type.

| Pattern | Android | iOS |
|---|---|---|
| Contextual action menu (idea card) | Material BottomSheet | CupertinoActionSheet |
| Destructive confirmation | AlertDialog | showAdaptiveDialog |
| Settings panel | Material BottomSheet | Material BottomSheet (acceptable) |
| Partnership request input | Material BottomSheet | Keep (form-heavy, Material is fine) |

**Implementation:**
- `platform_utils.dart` provides `isIOS` check
- `_showMenu` in IdeaCard uses `showCupertinoModalPopup` on iOS
- Delete confirmation uses `showAdaptiveDialog`
- Settings sheet uses `useSafeArea: true`

---

## Settings UX

**Current:** Bottom sheet with account menu, theme toggle, sign out.

**Assessment:**
- The sheet pattern is perfectly acceptable on iOS — apps like Linear, Notion,
  and many premium apps use modal sheets for account panels.
- No need to replace with a navigation-based settings screen.
- `SwitchListTile.adaptive()` already used — renders Cupertino toggle on iOS.

**Changes made:**
- `useSafeArea: true` on the sheet presentation
- No structural changes

---

## List and card behavior

**Assessment:**
- Custom `_IdeaCard` with `InkWell` — Material ripple. On iOS, InkWell renders
  a highlight instead of a ripple, which is acceptable.
- ListView with animated cards — fine on iOS.
- No `ListTile` issues; padding and touch targets are appropriate.

**Future option:**
- Replace `InkWell` with `GestureDetector` on iOS for cleaner press behavior.
  Low priority — InkWell on iOS is not jarring.

---

## Touch targets and spacing

**Assessment:**
- `IconButton` defaults to 48×48 minimum tap target — meets iOS HIG (44pt min).
- `ElevatedButton` with `minimumSize: Size(double.infinity, 52)` — compliant.
- `ListTile` default height — compliant.
- `FloatingActionButton.extended` — standard, adequate touch area.

**No changes needed.** All interactive elements meet iOS Human Interface Guidelines.

---

## Typography

**Decision:** Keep SpaceGrotesk throughout. No SF Pro substitution.

**Reasoning:**
- Custom fonts are the brand voice. Replacing with SF Pro would make the app
  feel generic and undermine the premium identity.
- SpaceGrotesk renders well on iOS.
- Scale and weight choices (display: 40/700, body: 14/400, label: 11/600) are
  appropriate for both platforms.

---

## Platform-aware widgets — what to use where

| Widget | Verdict | Notes |
|---|---|---|
| `SwitchListTile.adaptive()` | Use everywhere | Already in place |
| `showAdaptiveDialog()` | Use for confirmations | Added to delete flow |
| `CupertinoActionSheet` | Use for contextual menus | Added to idea card menu |
| `CupertinoActivityIndicator` | Optional | `CircularProgressIndicator` is fine |
| `CupertinoPicker` | Future | Category dropdown, later pass |
| `CupertinoPageRoute` | Future | go_router transitions, later pass |
| `CupertinoAlertDialog` | Via showAdaptiveDialog | No direct usage needed |

---

## Where Cupertino IS used

1. `CupertinoActionSheet` + `CupertinoActionSheetAction` — idea card menu on iOS
2. `showCupertinoModalPopup` — wraps action sheet on iOS
3. `CupertinoIcons` — NOT used (Material icons kept for brand consistency)

## Where Material is kept on iOS

1. `AppBar` — clean, adaptive enough
2. `FloatingActionButton` — core interaction, no iOS equivalent
3. `TextFormField` — forms work well on iOS
4. `ElevatedButton`, `OutlinedButton`, `TextButton` — no Cupertino replacement needed
5. `SnackBar` — acceptable on iOS
6. `BottomSheet` (settings, partnership request) — acceptable on iOS
7. `CircularProgressIndicator` — acceptable on iOS

---

## What remains shared (no platform branching)

- Theme system (AppTheme, AppColors)
- All models, services, providers
- Router and navigation logic
- Business logic and Firebase calls
- Animation layer (flutter_animate)
- Typography and color system

---

## What becomes conditional on iOS

- `_showMenu` (IdeaCard): CupertinoActionSheet vs Material BottomSheet
- Delete confirmation: showAdaptiveDialog (renders CupertinoAlertDialog on iOS)
- AppCheck provider: AppCheckDebugProvider / AppAttest vs PlayIntegrity

---

## Later passes (not this session)

1. go_router `customPageBuilder` with `CupertinoPage` for iOS transitions
2. `DropdownButtonFormField` → `CupertinoPicker` in SubmitIdeaScreen on iOS
3. `CircularProgressIndicator` → `.adaptive()` variants
4. Swipe-to-archive gesture on idea cards (works on both platforms)
5. InkWell → GestureDetector on iOS for cleaner press feedback
