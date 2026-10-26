# Geni Kids 1.3.0 App Store screenshots

Local capture and composition only. The orchestrator handles App Store Connect uploads.

`plan.json` is the manifest for ten screenshots in English and Norwegian. Capture and compose derive their default output paths from its version. Existing `screenshots/v1.2.0/` artwork is preserved.

| # | Screen(s) | EN | NO |
|---|---|---|---|
| 01 | onboarding1 + onboarding2 | Made for your child | Laget for ditt barn |
| 02 | storeHome | Math and reading every day | Matte og lesing hver dag |
| 03 | game.ordinal, age 4 | Learning starts at 4 | Læring fra 4 år |
| 04 | game.moneyShopping, age 7 | Learn about money | Lær om penger |
| 05 | game.codingPath, age 7 | Code with the robot | Kod med roboten |
| 06 | clockRead | Learn to tell time | Lær klokka |
| 07 | guidedReading | Read with guidance | Les med veiledning |
| 08 | storeRewards | Earn rewards | Tjen belønninger |
| 09 | game.symmetry, age 8 | Think like a mathematician | Tenk som en matematiker |
| 10 | parentDashboard | Built for parents | Laget for foreldre |

## Fixtures and localization

All captures use the current DEBUG app and actual app views. `-designPreviewStore` adds fixed examples for the four game shots, a seeded Daniel profile, and mid-chapter progress (4/10 for age 4; 8/20 otherwise). Store profiles have level 3, 420 coins, 270 XP toward the next level, a three-day streak, earned badges, twelve historical chapters and eight reading sessions. History includes today so the weekly summary has meaningful data even on Monday. The parent preview scrolls to Progress and clips scrolling content out of the status bar. All fixture code lives in `ios/Geni/Utilities/DesignPreviewSupport.swift` under `#if DEBUG`.

Preview launches use isolated local defaults and an inert cloud store. Real profiles, Keychain PIN and iCloud are preserved. Reading is frozen at word 17 and 1:08 without audio, timers, speech recognition or permission prompts.

Capture passes `-designPreviewAge`, `-geni_app_language english|norwegian`, `-AppleLanguages '(en)'|'(nb)'`, `-AppleLocale en_US|nb_NO`, and `-AppleInterfaceStyle Light`. `-geniStoreRegion US` for English and `NO` for Norwegian gives the shop USD and NOK respectively. Simulator-wide language settings are unchanged.

## Run

Check disk space and the Mac development storage policy before building. Build only with the queued repository wrapper; never invoke Xcode builds directly. Reuse `/tmp/geni-dd` and the two approved shared simulators; do not create or clone devices or download runtimes. Boot only after simulator ownership is handed over. Run one device at a time to reduce memory pressure.

```sh
df -h /
scripts/geni-build.sh app

xcrun simctl boot B0B5D7B2-D70D-4621-8B4A-23A0F1E03067
xcrun simctl bootstatus B0B5D7B2-D70D-4621-8B4A-23A0F1E03067 -b
xcrun simctl install B0B5D7B2-D70D-4621-8B4A-23A0F1E03067 /tmp/geni-dd/Build/Products/Debug-iphonesimulator/Geni.app
scripts/appstore-screenshots/capture.sh iphone
swift scripts/appstore-screenshots/compose.swift --device iphone
xcrun simctl shutdown B0B5D7B2-D70D-4621-8B4A-23A0F1E03067

xcrun simctl boot EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C
xcrun simctl bootstatus EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C -b
xcrun simctl install EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C /tmp/geni-dd/Build/Products/Debug-iphonesimulator/Geni.app
scripts/appstore-screenshots/capture.sh ipad
swift scripts/appstore-screenshots/compose.swift --device ipad
xcrun simctl shutdown EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C
```

Capture refuses a shut-down simulator and clears its 09:41/full-battery status-bar override using EXIT/INT/TERM traps. `--dry-run` does not contact CoreSimulator. Optional capture flags: `--languages en|no|en,no`, `--raw-root PATH`, `--wait SECONDS`, `--device iphone|ipad`. Compose supports `--languages`, `--raw-root`, `--output-root`, and `--device`.

## Outputs and verification

- Raw: `screenshots/v1.3.0/raw/{iphone-6.7,ipad-12.9}/{en,no}/<screen>.png` (11 per set).
- Deliverables: `screenshots/v1.3.0/{iphone-6.7,ipad-12.9}/{en,no}/01.png`–`10.png` (40 total).
- iPhone: 1290×2796, App Store `APP_IPHONE_67`.
- iPad: 2048×2732, App Store `APP_IPAD_PRO_3GEN_129`.

The compositor preserves raw aspect ratios, uses a rounded bezel and iPhone Dynamic Island, SF Rounded Bold captions, and the established cyan gradient. PNGs are opaque RGB. Raw captures must be 1206×2622 for iPhone or 2064×2752 / 2048×2732 for iPad. Capture and composition receipts contain SHA-256 hashes; interrupted capture invalidates its old receipt. Open every final image to review layout, language, currency, status bars and captions.

`upload.py` and `asc-coverage.json` are historical 1.2.0 tools/data and were not run or repointed. The manifest intentionally sets `versionId` to null: the orchestrator must resolve the 1.3.0 ASC version and localization targets before uploading. Do not use the old uploader for 1.3.0.
