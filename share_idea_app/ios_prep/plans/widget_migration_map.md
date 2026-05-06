# Widget Migration Map

Created: April 2026
Purpose: Track every widget that needs attention for iOS, with its status.

Format: Widget → Keep / Adapt / Replace / Future

---

## Navigation

| Widget | Status | Decision |
|---|---|---|
| `MaterialApp.router` | Keep | Renders fine on iOS |
| `AppBar` | Keep | Clean, no elevation, works on iOS |
| `GoRouter` transitions | Future | Add `CupertinoPage` via customPageBuilder later |
| `Navigator.pop()` | Keep | Standard, cross-platform |
| `context.go()` | Keep | go_router, cross-platform |

---

## Scaffold and layout

| Widget | Status | Decision |
|---|---|---|
| `Scaffold` | Keep | Core, cross-platform |
| `SafeArea` | Keep | Already used, correct behavior |
| `MediaQuery` | Keep | Cross-platform responsive |
| `ListView.builder` | Keep | Fine on iOS |
| `Column`, `Row`, `Expanded` | Keep | Layout primitives |
| `Padding`, `SizedBox` | Keep | Layout spacing |
| `GestureDetector` | Keep | Works on iOS |

---

## Dialogs, sheets, and menus

| Widget | Status | Decision |
|---|---|---|
| `showModalBottomSheet` (settings) | Keep | Acceptable on iOS, useSafeArea fixed |
| `showModalBottomSheet` (idea menu) | Adapted | iOS uses `showCupertinoModalPopup` instead |
| `CupertinoActionSheet` | Added | Used for idea card contextual menu on iOS |
| `CupertinoActionSheetAction` | Added | Actions within the Cupertino sheet |
| `showDialog` (delete confirm) | Replaced | Now uses `showAdaptiveDialog` |
| `AlertDialog` (delete confirm) | Replaced | `showAdaptiveDialog` renders Cupertino on iOS |
| `showModalBottomSheet` (pitch request) | Keep | Form-heavy, Material is acceptable |

---

## Controls and inputs

| Widget | Status | Decision |
|---|---|---|
| `SwitchListTile.adaptive()` | Keep | Already adaptive, renders Cupertino on iOS |
| `TextFormField` | Keep | Works on iOS |
| `ElevatedButton` | Keep | Fine on iOS, 52px height exceeds HIG minimum |
| `OutlinedButton` | Keep | Fine on iOS |
| `TextButton` | Keep | Fine on iOS |
| `IconButton` | Keep | 48px tap target, compliant |
| `Slider` | Keep | Material Slider on iOS is acceptable |
| `DropdownButtonFormField` | Future | Consider `CupertinoPicker` on iOS (later pass) |
| `Checkbox`, `Radio` | Keep (unused currently) | `.adaptive()` available if needed |

---

## Feedback and loading

| Widget | Status | Decision |
|---|---|---|
| `CircularProgressIndicator` | Keep | Acceptable on iOS |
| `SnackBar` (floating) | Keep | Works on iOS |
| `Shimmer` | Keep | Third-party, cross-platform |
| `flutter_animate` animations | Keep | Pure Dart, cross-platform |

---

## Display and content

| Widget | Status | Decision |
|---|---|---|
| `Card` | Keep | Clean with Material 3 styling |
| `InkWell` | Keep (Future) | Renders highlight on iOS (not ripple) — acceptable now |
| `ListTile` | Keep | Standard, works on iOS |
| `Divider` | Keep | Fine on iOS |
| `Text` | Keep | SpaceGrotesk font, cross-platform |
| `Icon` (Material Icons) | Keep | Brand decision |
| `AnimatedContainer` | Keep | Pure Dart, cross-platform |
| `Chip` / filter tabs | Keep | Custom implementation, cross-platform |

---

## Platform-specific additions (new)

| Widget | Platform | Purpose |
|---|---|---|
| `CupertinoActionSheet` | iOS only | Contextual menu for idea cards |
| `CupertinoActionSheetAction` | iOS only | Individual actions in sheet |
| `showCupertinoModalPopup` | iOS only | Presents the action sheet |
| `showAdaptiveDialog` | Both | Renders correctly on each platform |

---

## Widgets to add in future passes

| Widget | Platform | Purpose | Priority |
|---|---|---|---|
| `CupertinoPicker` | iOS | Category selection in Submit screen | Medium |
| `CupertinoActivityIndicator` | iOS | Replace loading spinner | Low |
| `CupertinoPageRoute` via go_router | iOS | Native page transitions | Low |
| Custom swipe actions | Both | Swipe-to-archive on idea cards | Medium |
