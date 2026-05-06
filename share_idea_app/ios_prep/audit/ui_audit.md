# UI Audit — iOS Compatibility Review

Reviewed: April 2026
Scope: All screens in lib/screens/

---

## Summary verdict

| Screen | iOS-ready? | Notes |
|---|---|---|
| GatewayScreen | Good | Hero gradient, role cards — fine on iOS |
| LoginScreen | Good | Material TextFormField works on iOS |
| RegisterScreen | Good | Same as login |
| InnovatorDashboard | Fixed | Action sheet + delete dialog now adaptive |
| SubmitIdeaScreen | Acceptable | Dropdown, slider, text fields — Material works |
| IdeaResultScreen | Good | Display-only, no platform-specific patterns |
| TheVaultScreen | Acceptable | Shimmer + horizontal tabs — fine |
| IdeaDetailScreen | Acceptable | No destructive actions, low risk |
| PaywallScreen | Acceptable | Display + CTA buttons — fine |
| PitchScreen | Acceptable | Forms and status display — fine |
| MainScaffold | Fixed | Settings sheet now uses adaptive switch + useSafeArea |
| DevMenuScreen | Low priority | Internal tool, not shipped |

---

## Screen-by-screen notes

### GatewayScreen
- Full-screen gradient hero with role selection cards
- Uses GestureDetector, AnimatedContainer — cross-platform
- No iOS concerns

### LoginScreen / RegisterScreen
- Material TextFormField — renders acceptably on iOS
- Google Sign-In button uses Material styling — cosmetically different but functional
- Password visibility toggle is a standard IconButton — fine
- No Cupertino replacement needed here; forms on iOS do not need to be Cupertino

### InnovatorDashboard (FIXED)
- Was: `showModalBottomSheet` for idea card menu with custom shape
- Was: `AlertDialog` for delete confirmation
- Now: adaptive action sheet using `showCupertinoModalPopup` on iOS,
        `showModalBottomSheet` on Android
- Now: `showAdaptiveDialog` for delete confirmation
- The large-title header pattern (_DashboardHeader) already matches iOS norms —
  it scrolls with content, gives breathing room to the AppBar

### SubmitIdeaScreen
- DropdownButtonFormField for category — functional on iOS but not native-feeling
- Price slider: Material Slider — acceptable, no Cupertino Slider needed
- Character count feedback is inline text — fine
- Future: consider CupertinoPicker for category selection on iOS (later pass)

### IdeaResultScreen
- Three display states (active / needsReview / rejected)
- Pure content display with icons and text
- No interactive patterns that need adapting

### TheVaultScreen
- Horizontal scrollable category filters — custom chips, not TabBar
- Shimmer loading — cross-platform
- No destructive actions
- Acceptable as-is

### IdeaDetailScreen
- Metrics row (icons + text)
- Purchase button: ElevatedButton — fine
- "Request Partnership" shows a modal with a text field
- The modal uses showModalBottomSheet — acceptable on iOS
- Future: adaptive sheet if needed

### PaywallScreen
- Monthly/Yearly toggle: Material choice chip or custom toggle
- "Start Patron Access" ElevatedButton
- No destructive actions
- Acceptable as-is

### PitchScreen
- Status banner, form fields, action buttons
- TextFormField for pitch body + email
- Decline button uses AppColors.error styling — fine
- No sheet or dialog pattern used

### MainScaffold / Settings Sheet (FIXED)
- Was: `showModalBottomSheet` without useSafeArea, custom rounding
- Now: `showModalBottomSheet` with `useSafeArea: true` + `isScrollControlled: false`
- SwitchListTile.adaptive already used — renders Cupertino switch on iOS
- Sign out in destructive TextButton style — appropriate

---

## Patterns used across the app that are iOS-acceptable

- `SafeArea` wrapping — correct on both platforms
- `FloatingActionButton.extended` — Material FAB, visible on iOS, no native equivalent needed
- `SnackBar` with `SnackBarBehavior.floating` — works on iOS
- `CircularProgressIndicator` — visible on iOS; CupertinoActivityIndicator is optional
- `go_router` page transitions — Material slide, acceptable on iOS

## Patterns that could be improved in a later pass

- `DropdownButtonFormField` → `CupertinoPicker` on iOS for category selection
- `CircularProgressIndicator` → `CupertinoActivityIndicator.adaptive()` everywhere
- Page transitions → `CupertinoPageRoute` via go_router customPageBuilder (optional)
- `SnackBar` → `CupertinoPopupSurface` toast (optional, complex)
