# Profile Switcher Native Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the bottom-sheet profile switcher in ChildHomeView with a native SwiftUI Menu anchored to the avatar button.

**Architecture:** The avatar button becomes a `Menu { } label: { }` when multiple profiles exist. The menu lists profiles (emoji + name, ✅ prefix for active) and an ➕ add action. The `ProfileSwitcherSheet` struct and all related state/sheet plumbing are deleted.

**Tech Stack:** SwiftUI `Menu`, existing `ChildHomeView.swift`

---

### Task 1: Replace avatar button with Menu and delete ProfileSwitcherSheet

**Files:**
- Modify: `ios/Geni/Views/ChildHomeView.swift`

- [ ] **Step 1: Remove `showProfileSwitcher` state and `avatarZoom` namespace**

In the `ChildHomeView` struct properties, remove these two lines:
```swift
// DELETE these lines:
@Namespace private var avatarZoom
@State private var showProfileSwitcher = false
```

Result after removal (properties block):
```swift
struct ChildHomeView: View {
    let viewModel: AppViewModel
    let rewardsNamespace: Namespace.ID
    let settingsNamespace: Namespace.ID
    @State private var showAvatarPicker = false
    @State private var showProfileCreation = false
```

- [ ] **Step 2: Replace the avatar Button with a Menu in `headerSection`**

Find the current avatar button (lines ~74–123). Replace the entire `Button { ... } label: { HStack(...) }` block with a `Menu` that wraps the same label. When `hasMultipleProfiles` is false, keep it as a plain `Button` opening the avatar picker.

Replace this block:
```swift
Button {
    HapticManager.selection()
    if hasMultipleProfiles {
        showProfileSwitcher = true
    } else {
        showAvatarPicker = true
    }
} label: {
    HStack(spacing: 12) {
        Text(avatar.emoji)
            .font(.system(size: 28))
            .frame(width: 56, height: 56)
            .background(.white)
            .overlay(
                Rectangle()
                    .stroke(GeniColor.border, lineWidth: 3)
            )
            .background(
                Rectangle()
                    .fill(GeniColor.border)
                    .offset(x: 3, y: 3)
            )
            .zoomSource(id: "avatar", in: avatarZoom)

        VStack(alignment: .leading, spacing: 2) {
            Text(profile?.nickname ?? "")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)

            HStack(spacing: 4) {
                Text("\(L.s(.level)) \(rewards.level)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
            }
        }

        if hasMultipleProfiles {
            HStack(spacing: 4) {
                Text("🔄")
                    .font(.system(size: 12))
                Text(L.s(.changeProfile))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white)
            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
        }
    }
}
```

With this:
```swift
Group {
    if hasMultipleProfiles {
        Menu {
            ForEach(viewModel.persistence.profiles) { p in
                let isActive = p.id == viewModel.persistence.activeProfileId
                let pAvatar = AvatarOption.find(p.avatarId)
                Button {
                    HapticManager.impact(.medium)
                    viewModel.selectProfile(p)
                } label: {
                    Text((isActive ? "✅ " : "") + pAvatar.emoji + "  " + p.nickname)
                }
            }
            Divider()
            Button {
                HapticManager.selection()
                showProfileCreation = true
            } label: {
                Text("➕  " + L.s(.addProfile))
            }
        } label: {
            avatarLabel(avatar: avatar, profile: profile, rewards: rewards)
        }
    } else {
        Button {
            HapticManager.selection()
            showAvatarPicker = true
        } label: {
            avatarLabel(avatar: avatar, profile: profile, rewards: rewards)
        }
    }
}
```

- [ ] **Step 3: Extract `avatarLabel` as a private helper**

Add this private helper function inside `ChildHomeView` (place it after `headerSection`):
```swift
private func avatarLabel(avatar: AvatarOption, profile: ChildProfile?, rewards: RewardState) -> some View {
    HStack(spacing: 12) {
        Text(avatar.emoji)
            .font(.system(size: 28))
            .frame(width: 56, height: 56)
            .background(.white)
            .overlay(
                Rectangle()
                    .stroke(GeniColor.border, lineWidth: 3)
            )
            .background(
                Rectangle()
                    .fill(GeniColor.border)
                    .offset(x: 3, y: 3)
            )

        VStack(alignment: .leading, spacing: 2) {
            Text(profile?.nickname ?? "")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)

            Text("\(L.s(.level)) \(rewards.level)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.black)
        }

        if hasMultipleProfiles {
            HStack(spacing: 4) {
                Text("🔄")
                    .font(.system(size: 12))
                Text(L.s(.changeProfile))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white)
            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
        }
    }
}
```

- [ ] **Step 4: Remove the ProfileSwitcher sheet modifier**

In `body`, remove the entire `.sheet(isPresented: $showProfileSwitcher)` block:
```swift
// DELETE this entire block:
.sheet(isPresented: $showProfileSwitcher) {
    ProfileSwitcherSheet(
        profiles: viewModel.persistence.profiles,
        activeProfileId: viewModel.persistence.activeProfileId,
        onSelect: { profile in
            showProfileSwitcher = false
            if profile.id != viewModel.persistence.activeProfileId {
                viewModel.selectProfile(profile)
            }
        },
        onAddProfile: {
            showProfileSwitcher = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showProfileCreation = true
            }
        }
    )
    .zoomDestination(id: "avatar", in: avatarZoom)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
}
```

Also remove the `.zoomDestination` from the AvatarPickerSheet (no longer needed for a sheet that doesn't come from the same button):
```swift
// BEFORE:
.sheet(isPresented: $showAvatarPicker) {
    AvatarPickerSheet(viewModel: viewModel)
        .zoomDestination(id: "avatar", in: avatarZoom)
}

// AFTER:
.sheet(isPresented: $showAvatarPicker) {
    AvatarPickerSheet(viewModel: viewModel)
}
```

- [ ] **Step 5: Delete the `ProfileSwitcherSheet` struct**

Remove the entire `ProfileSwitcherSheet` struct from the bottom of `ChildHomeView.swift` (approximately lines 680–769):
```swift
// DELETE this entire struct:
struct ProfileSwitcherSheet: View {
    // ... everything through the closing }
}
```

- [ ] **Step 6: Build and verify**

```bash
xcodebuild build \
  -scheme "Geni" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -project ios/Geni.xcodeproj \
  2>&1 | grep -E "(error:|warning:|BUILD)"
```

Expected: `** BUILD SUCCEEDED **` with no errors.

- [ ] **Step 7: Commit**

```bash
git add ios/Geni/Views/ChildHomeView.swift
git commit -m "feat: replace profile switcher sheet with native Menu"
```

---

### Task 2: Build, bump, and ship to TestFlight

**Files:**
- Modify: `ios/Geni.xcodeproj/project.pbxproj` (via asc cli)

- [ ] **Step 1: Bump build number**

```bash
asc xcode version bump --type build --project-dir ./ios
```

Expected output: `{"bumpType":"build","oldBuild":"63","newBuild":"64",...}`

- [ ] **Step 2: Archive**

```bash
xcodebuild clean archive \
  -scheme "Geni" \
  -configuration Release \
  -archivePath /tmp/Geni.xcarchive \
  -destination "generic/platform=iOS" \
  -project ios/Geni.xcodeproj \
  2>&1 | tail -5
```

Expected: `** ARCHIVE SUCCEEDED **`

- [ ] **Step 3: Export IPA**

```bash
xcodebuild -exportArchive \
  -archivePath /tmp/Geni.xcarchive \
  -exportPath /tmp/GeniExport \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  2>&1 | tail -5
```

Expected: `** EXPORT SUCCEEDED **`

- [ ] **Step 4: Upload to App Store Connect**

```bash
asc builds upload --app "6761134405" --ipa "/tmp/GeniExport/Geni.ipa"
```

Expected: `"uploaded":true`

- [ ] **Step 5: Commit build bump**

```bash
git add ios/Geni.xcodeproj/project.pbxproj
git commit -m "chore: bump build number to 64"
```

- [ ] **Step 6: Distribute to TestFlight groups**

```bash
asc publish testflight \
  --app "6761134405" \
  --build-number "64" \
  --group "54cdccda-6414-48c6-9480-ce1190a1f16c,44685ebf-4db5-46a7-bc53-9e79bef9e296" \
  --notify
```

- [ ] **Step 7: Push to GitHub**

```bash
git push origin main
```
