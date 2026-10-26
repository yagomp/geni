# Open Source Geni — Design Spec

**Date:** 2026-04-06  
**Author:** Yago Martinez  
**License:** MIT  
**Goal:** Make the Geni iOS app + marketing site fully open source — transparent, contributor-ready, and useful as a reference project.

---

## Context

Geni is a published iOS reading/learning app for kids (App Store ID: 6761134405). The repo is currently private on GitHub. The goal is to open source it for three reasons: transparency, community contributions, and as a reference for other developers. The app has zero external dependencies (pure SwiftUI + native Apple frameworks), making it a clean codebase to share.

---

## Approach

**Standard open source setup (Option B):** Security cleanup + LICENSE + README + CONTRIBUTING + issue templates + Code of Conduct. No CI for now — can be added later.

---

## Section 1: Security Cleanup

**Files to remove from working tree and add to `.gitignore`:**
- `.asc/config.json` — contains App Store Connect API key ID and issuer ID
- `ios/profiles/*.mobileprovision` — provisioning profile
- `ios/ExportOptions.plist` — contains Apple Team ID (`ZBRDR5Q455`)
- `.wrangler/` — Cloudflare Workers local state

**Git history:** Check if `.asc/config.json` was ever committed. If yes, purge with `git filter-repo --path .asc/config.json --invert-paths`.

**`.gitignore` additions:**
```
# App Store Connect
.asc/config.json

# Signing
ios/profiles/*.mobileprovision
ios/ExportOptions.plist

# Cloudflare
.wrangler/
```

---

## Section 2: LICENSE

Create `LICENSE` at repo root:
- Type: MIT
- Copyright: `Copyright 2026 Yago Martinez`

---

## Section 3: README.md

Location: repo root  
Sections:
1. App name + one-line description + App Store badge
2. **What is Geni?** — reading/learning app for kids
3. **Features** — key feature list
4. **Privacy** — zero-backend, all local storage (CloudKit/iCloud), no custom servers
5. **Tech stack** — SwiftUI, CloudKit, Speech framework, AVFoundation, native only
6. **Building locally** — Xcode requirements, clone + open `.xcodeproj`, run on simulator/device
7. **Project structure** — `ios/Geni/{Views,ViewModels,Services,Models}`, `site/`
8. **Contributing** — link to `CONTRIBUTING.md`
9. **License** — MIT

---

## Section 4: CONTRIBUTING.md

Location: repo root  
Sections:
- How to report bugs → GitHub Issues (bug template)
- How to suggest features → GitHub Issues (feature template)
- Dev setup: Xcode (no dependencies, just open `.xcodeproj`)
- PR process: fork → feature branch → PR against `main`
- Code style: follow existing SwiftUI/MVVM patterns in codebase

---

## Section 5: GitHub Issue Templates

Location: `.github/ISSUE_TEMPLATE/`

**`bug_report.md`:**
- Steps to reproduce
- Expected vs actual behavior
- iOS version + device model
- Xcode version (if building from source)

**`feature_request.md`:**
- Problem description
- Proposed solution
- Alternatives considered

---

## Section 6: Code of Conduct

Location: `CODE_OF_CONDUCT.md`  
Standard: Contributor Covenant v2.1  
Enforcement contact: `hello@geni.kids`

---

## Section 7: Go Public

1. Commit all new files: `"Open source Geni under MIT license"`
2. Flip GitHub repo from private to public (done manually in GitHub settings)

---

## Verification

- [ ] `.asc/config.json` no longer tracked by git (`git ls-files .asc/config.json` returns empty)
- [ ] `git log --all --full-history -- .asc/config.json` returns no commits (or history purged)
- [ ] `LICENSE` exists at root with correct copyright
- [ ] `README.md` renders correctly on GitHub (check badge, links)
- [ ] Issue templates appear when creating new issue on GitHub
- [ ] `CODE_OF_CONDUCT.md` references `hello@geni.kids`
- [ ] Repo is publicly accessible at `github.com/yagomp/geni`
