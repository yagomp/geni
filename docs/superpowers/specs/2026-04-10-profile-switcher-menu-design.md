# Profile Switcher: Native Menu Design

**Date:** 2026-04-10
**Status:** Approved

## Problem

The current profile switcher in `ChildHomeView` uses a `.sheet()` (bottom drawer) when a kid taps their avatar in the top-left. Two specific problems:

- The slide-up animation feels un-native and jarring
- The partial-screen drawer pattern is confusing for kids — they don't have the mental model of "tap outside to dismiss"

## Solution

Replace the sheet with a native SwiftUI `Menu` anchored directly to the avatar button. Tapping the avatar shows a floating context menu. No slide-up, no partial coverage, no dismiss gesture required.

## Menu Structure

```
✅ Emma          ← active profile (checkmark prefix)
🦁 Lucas
🐼 Sofia
────────────────
➕  Add profile
```

- Each profile: `[✅ if active][avatar emoji]  [nickname]`
- Inactive profiles: `[avatar emoji]  [nickname]`
- Divider separating profiles from the add action
- Add action: `➕  Add profile`
- Pure emoji, no SF Symbols

## Files Changed

### `ChildHomeView.swift`

- **Remove** `@State private var showProfileSwitcher`
- **Remove** `.sheet(isPresented: $showProfileSwitcher) { ProfileSwitcherSheet(...) }` modifier
- **Remove** `.zoomSource(id: "avatar", in: avatarZoom)` from the avatar button (no sheet to zoom into)
- **Replace** the avatar `Button { ... } label: { ... }` with `Menu { ... } label: { ... }` keeping the existing label content identical
- **Delete** `ProfileSwitcherSheet` struct (bottom of `ChildHomeView.swift`)

### `ContentView.swift`

No changes needed.

## What Stays the Same

- Avatar button label appearance (emoji, name, level, "🔄 change profile" badge) — unchanged
- Single-profile path (still opens `AvatarPickerSheet` directly) — unchanged
- `onAddProfile` callback path — same logic, triggered from menu item instead of sheet button
- Haptic feedback on selection

## Behaviour

- Tap avatar → native iOS context menu floats up anchored to button
- Tap profile → `onSelect(profile)` called, menu dismisses automatically
- Tap ➕ → `onAddProfile()` called
- Tap anywhere else → menu dismisses, nothing happens
- No extra state, no sheet lifecycle to manage
