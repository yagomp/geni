# Geni 1.2.0 App Store screenshots

Preparation only. No simulator was booted, installed, launched, or captured for this change, and no ASC data was mutated. Version 1.2.0/build 80 and its submission are unchanged. Fixtures compile only in DEBUG.

## Shot plan

Both device families use the same ten captions, in numerical upload order. Shots 01 and 05 contain two devices; all other shots contain one. Capture collects twelve screens per language. Step 1 shows the entire avatar catalog; step 2 shows the name and age; step 3 shows colors and shapes.

| # | Screen(s) | EN | NO |
|---|---|---|---|
| 01 | onboarding1 + onboarding2 | Made for your child | Laget for ditt barn |
| 02 | onboarding3 | Their colors, their style | Dine farger, din stil |
| 03 | storeHome | Daily missions motivate | Daglige oppdrag motiverer |
| 04 | storeExercise | Learn by playing | Lær gjennom lek |
| 05 | clockRead + clockSet | Learn to tell time | Lær klokka |
| 06 | storeMatch | Make the connection | Finn parene |
| 07 | guidedReading | Read with guidance | Les med veiledning |
| 08 | storeRewards | Earn rewards | Tjen belønninger |
| 09 | storeBadge | Celebrate progress | Feire fremgang |
| 10 | parentDashboard | Built for parents | Laget for foreldre |

`plan.json` is the caption/screen manifest. Store fixtures use Daniel (age 6 on home for optional reading, otherwise age 7), level 3, 420 coins, 270 XP toward the next level, a three-day streak, earned medallions, and twelve historical chapters at 95% accuracy. Home shows math completed with reading next and Challenges open. Exercises are at 8/20; matching has one connected pair. Reading is frozen at word 17 and 1:08 with highlighting, without starting audio, timers, speech recognition, or permission prompts. The dashboard opens scrolled to its actual Progress section. Clock setting starts at 3:00 for the 3:30 target.

Preview launches use an isolated local defaults suite and an inert cloud store. `-uiTestReset -designPreview ...` does not clear the real app's local profiles, Keychain PIN, or iCloud. Normal DEBUG launches keep their usual dependencies. `-geni_app_language english|norwegian` is a UserDefaults argument-domain override; it takes precedence over a saved language. `-AppleLanguages '(en)'|'(nb)'` and `-AppleLocale` are also supplied. Both `L` and `LanguageManager` therefore select the requested language without changing simulator-wide preferences.

## Existing artwork audit

Visually reviewed all 28 source PNGs (both EN/NO, both families). They use a blue-to-cyan gradient, centered white bold captions, and a device frame. The old NO assets have Norwegian captions but English app UI.

| iPhone source | EN caption | NO caption | App content |
|---|---|---|---|
| screenshot-2 | Made for your child | Laget for ditt barn | Old single-page profile creation: Daniel, age 7, 12 avatars, operations |
| screenshot-3 | Daily missions motivate | Daglige oppdrag motiverer | Old home: zero streak/chapters/coins, Math & Reading mission, extra challenges, progress map |
| screenshot-4 | Learn by playing | Lær gjennom lek | Multiplication 3 × 5, answer 15 selected, green Correct banner |
| screenshot-5 | Earn rewards | Tjen belønninger | Old darkened badge popup: First Steps |
| screenshot-6 | Read with guidance | Les med veiledning | The Lost Kite, listen-to-me-read, highlighted passage |
| screenshot-7 | Celebrate progress | Feire fremgang | Math chapter complete, five stars, +50 coins, reading next |
| screenshot-8 | Three ways to read | Tre måter å lese på | Reading-mode chooser: self, read aloud, listen |
| screenshot-9 | Built for parents | Laget for foreldre | Parent Settings: Daniel/Eva profiles, language choices, progress |
| screenshot-11 | Multiple players | Flere spillere | Profile-switch sheet: Daniel/Eva/Add over home |

| iPad source | EN caption | NO caption | App content |
|---|---|---|---|
| screenshot-1 | Daily missions motivate | Dagsmål motiverer | Lucas's old home, mission, extra challenges, progress map |
| screenshot-2 | Learn by playing | Lek deg til læring | Subtraction 12 − 6, four answer tiles |
| screenshot-3 | Built for parents | Laget for foreldre | Parent Settings: Lucas, languages, progress, reminder, sync, PIN |
| screenshot-4 | Celebrate progress | Feire fremgang | Math chapter complete, five stars, +50 coins, reading next |
| screenshot-5 | Read with guidance | Les med veiledning | The Little Cat, listen-to-me-read, highlighted passage |

## ASC coverage (read-only audit, 2026-10-25)

App `6761134405`, version `1.2.0`, version resource `1aedb79e-6564-4516-94c9-672925e46d1a`, state PREPARE_FOR_SUBMISSION. Exact screenshot IDs and filenames are in `asc-coverage.json`.

| ASC locale | iPhone display type / set ID / count | iPad display type / set ID / count |
|---|---|---|
| en-US | APP_IPHONE_67 / a7e71946-bf90-48be-adcb-946e10377eda / 9 | APP_IPAD_PRO_3GEN_129 / 54713d3b-6e69-4d82-b11d-6c38c2e4620b / 5 |
| no | APP_IPHONE_67 / adfc7f3e-2cae-4c1c-987d-2d95e4edd9d9 / 9 | APP_IPAD_PRO_3GEN_129 / ed1c8a59-b588-41c1-8766-1b996d0a585c / 5 |
| es-ES | No dedicated screenshots | No dedicated screenshots |
| pt-PT | No dedicated screenshots | No dedicated screenshots |

The replacement retains this localization coverage: EN and NO only. ES/PT use ASC fallback artwork, so no dedicated ES/PT captions are added. `IPHONE_67` is the CLI type for the existing 6.7/6.9-inch set, accepting 1290×2796. `IPAD_PRO_3GEN_129` is the existing 12.9/13-inch set, accepting 2048×2732. These names were checked with `asc screenshots sizes --all` and actual read-only replacement dry-runs.

**iPad screenshots are required.** The app's TARGETED_DEVICE_FAMILY is `1,2`; [Apple requires iPad 13-inch screenshots for apps that support iPad](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). Old EN/NO iPad screenshots already satisfy presence but still show the old design. The owner approved the existing Shared iPad Pro 13-inch (`EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C`). The orchestrator owns its boot/layout check; these scripts never boot any simulator.

## Run after simulator handoff

From `/Users/yago/Documents/geni`. Build once, then install the same DEBUG app on the already-booted target(s). Reuse existing DerivedData; check storage first. The Mac had only ~3.3 GiB free during preparation; the storage report is `/Users/yago/.local/share/dev-storage/latest.md`. No cleanup was performed.

```sh
xcodebuild -project ios/Geni.xcodeproj -scheme Geni -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/geni-sim-dd \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build

# iPhone, only once its owner releases it:
xcrun simctl install B0B5D7B2-D70D-4621-8B4A-23A0F1E03067 /tmp/geni-sim-dd/Build/Products/Debug-iphonesimulator/Geni.app
scripts/appstore-screenshots/capture.sh iphone
swift scripts/appstore-screenshots/compose.swift --device iphone

# iPad, coordinated with the orchestrator's current layout check:
xcrun simctl install EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C /tmp/geni-sim-dd/Build/Products/Debug-iphonesimulator/Geni.app
scripts/appstore-screenshots/capture.sh ipad
swift scripts/appstore-screenshots/compose.swift --device ipad

# Read-only current set IDs, then replacement plans for all EN/NO files:
python3 scripts/appstore-screenshots/upload.py --list
python3 scripts/appstore-screenshots/upload.py --device iphone --dry-run
python3 scripts/appstore-screenshots/upload.py --device ipad --dry-run

# After reviewing every final PNG, run the replacements (NOT executed during preparation):
python3 scripts/appstore-screenshots/upload.py --device iphone --apply
python3 scripts/appstore-screenshots/upload.py --device ipad --apply
```

Capture takes about two minutes per device at the default two-second settle delay. `capture.sh --dry-run` only prints the plan and never calls CoreSimulator. Optional `--languages en` or `--languages no`, `--raw-root PATH`, `--wait SECONDS`, and `--device iphone|ipad` are supported. The devices must already be booted and have the new DEBUG app installed. The script overrides the status bar, then clears it via EXIT/INT/TERM traps, including screenshot failures. Capturing invalidates old receipts first; interrupted runs must be repeated.

Raw captures go under `screenshots/v1.2.0/raw/{iphone-6.7,ipad-12.9}/{en,no}/<screen>.png`. Composed opaque RGB PNGs go to `screenshots/v1.2.0/{iphone-6.7,ipad-12.9}/{en,no}/01.png`–`10.png`. The compositor requires original 1206×2622 iPhone captures, or 2064×2752 / 2048×2732 iPad captures. It preserves aspect ratio, draws a rounded bezel and iPhone Dynamic Island, uses SF Rounded Bold, and samples the old gradient's sRGB endpoints (approximately #44CAFE → #00EBFE). No dependencies or frame packs are installed.

Capture/composition receipts include hashes; the uploader stages only PNGs because ASC also counts JSON files in its input directory. upload checks the complete ten-image set in both locales before any replacement. `--apply` first performs the same read-only ASC dry-runs, then uses `asc screenshots upload --replace --confirm` for the pinned version/localizations/device type only. This deletes existing screenshots in those target sets before upload; an interrupted upload can leave an incomplete set and should be rerun. Current inventory is saved to `.asc/reports/screenshots-1.2.0/before.json`. Existing ASC auth is reused; no key material is read or printed. No version, build, metadata, or submission command is run.

## Local compose checks (already run)

These use existing full-resolution v4/v5 raws, **not fresh fixtures**. In particular the sample status bars, names and app language are old. They are visual checks of framing only and cannot be uploaded through `upload.py` because they have no capture/composition receipts.

```sh
swift scripts/appstore-screenshots/compose.swift \
  --sample /tmp/geni-home-shots/v5/home-a.png --output /tmp/geni-compose-test/03.png
swift scripts/appstore-screenshots/compose.swift \
  --sample /tmp/geni-home-shots/v5/onboarding1.png \
  --secondary /tmp/geni-home-shots/v4/onboarding2.png \
  --caption 'Made for your child' --output /tmp/geni-compose-test/01.png
swift scripts/appstore-screenshots/compose.swift \
  --sample /tmp/geni-home-shots/v5/onboarding3.png \
  --caption 'Dine farger, din stil' --output /tmp/geni-compose-test/02-no.png
swift scripts/appstore-screenshots/compose.swift \
  --sample /tmp/geni-home-shots/v4/rewards.png \
  --caption 'Earn rewards' --output /tmp/geni-compose-test/08.png
```

All four output 1290×2796 without alpha. `/tmp/geni-compose-test/ipad-10.png` is a **synthetic geometry test**, 2048×2732 without alpha; it is not app artwork. Full manifest, language arguments, device mapping, capture error cleanup, and receipt generation were checked with a mock `xcrun` under `/tmp/geni-script-checks`; that check never contacted a simulator. Full mocked sets were composed for both device families and passed read-only ASC replacement planning. Real on-device appearance/localization and layout still need the orchestrator's capture/review.
