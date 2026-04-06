# Geni

**A guided reading app for kids — built with privacy first.**

[![Download on the App Store](https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83)](https://apps.apple.com/app/id6761134405)

---

## What is Geni?

Geni helps children learn to read through guided reading sessions, comprehension exercises, and a progress map that keeps them motivated. Parents get a dashboard to track progress and manage profiles. The app works entirely on-device — no account required, no data leaves the family's iCloud.

## Features

- **Guided reading** — age-appropriate texts with word-by-word highlighting and read-aloud support
- **Speech recognition** — kids read aloud and the app listens for fluency practice
- **Comprehension exercises** — auto-generated questions after each reading session
- **Progress map** — visual journey that rewards completing missions
- **Multiple child profiles** — switch between kids with a single tap
- **iCloud sync** — progress syncs automatically across iPhone and iPad via the family's iCloud account
- **Parental controls** — PIN-protected parent dashboard with per-child progress tracking
- **Multilingual** — available in English, Spanish, Portuguese, and Norwegian

## Privacy

Geni has **zero backend servers**. All data is stored locally on-device or synced via the family's own iCloud account (CloudKit). No analytics, no tracking, no third-party SDKs. The parent PIN is stored in the device Keychain and never synced.

## Tech Stack

- **UI:** SwiftUI
- **Storage:** Core Data + iCloud CloudKit (on-device, family's own iCloud)
- **Sync:** `NSUbiquitousKeyValueStore` (iCloud KVS)
- **Audio/Speech:** AVFoundation, Speech framework
- **Security:** Security framework (Keychain)
- **No external dependencies** — 100% native Apple frameworks

## Building Locally

**Requirements:**
- Xcode 16+
- iOS 17.0+ deployment target
- Swift 5.0

**Steps:**
1. Clone the repo: `git clone https://github.com/yagomp/geni.git`
2. Open `ios/Geni.xcodeproj` in Xcode
3. Select a simulator or connected device (iOS 17+)
4. Press **Run** (⌘R)

> Note: iCloud sync and Speech Recognition require a physical device and a signed-in iCloud account. These features are gracefully disabled in the simulator.

## Project Structure

```
geni/
├── ios/
│   └── Geni/
│       ├── Views/          # SwiftUI screens
│       ├── ViewModels/     # Business logic, state management
│       ├── Models/         # Data models (Core Data entities)
│       ├── Services/       # App services (sync, speech, persistence, exercises)
│       └── Utilities/      # Helpers and extensions
└── site/                   # Marketing website (static HTML/CSS/JS)
    ├── index.html
    ├── blog/
    └── ...
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

MIT — see [LICENSE](LICENSE) for details.
