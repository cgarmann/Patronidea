# ios_prep — Schjoldr iOS Readiness Workspace

This folder tracks the iOS adaptation work for the Schjoldr Flutter app.
It is not compiled or shipped — it is working documentation for the engineering process.

## What this folder contains

```
ios_prep/
  README.md                          ← this file
  audit/
    ui_audit.md                      ← screen-by-screen iOS compatibility review
    platform_gaps.md                 ← missing iOS infrastructure items
    ios_risks.md                     ← things that could break on iOS
  plans/
    ios_adaptation_plan.md           ← full adaptation strategy
    widget_migration_map.md          ← which widgets to keep, adapt, or replace
    release_readiness_checklist.md   ← what must be done before App Store submission
  references/
    touched_files.md                 ← log of every file changed during this work
    ios_decisions.md                 ← key design/technical decisions and rationale
```

## Current status (April 2026)

- **Platform:** Android only. No `ios/` folder exists.
- **Dart code:** Mostly cross-platform. Two hard iOS blockers fixed (see touched_files.md).
- **UX:** Adaptive action patterns implemented on main screen and settings.
- **Remaining:** ios/ runner requires macOS + Xcode. Firebase iOS config requires Apple setup.

## How to use this folder

- When you make an iOS-related code change, log it in `references/touched_files.md`.
- When you make a design/technical decision, log it in `references/ios_decisions.md`.
- When you finish a checklist item, tick it off in `plans/release_readiness_checklist.md`.
- The audit files are snapshots — update them if the codebase changes significantly.

## What requires macOS / Xcode

See `audit/platform_gaps.md` for the full list.
Short version: creating the ios/ runner, Firebase GoogleService-Info.plist,
Bundle ID, signing, and App Store submission all require macOS.
