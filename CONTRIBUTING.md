# Contributing to Geni

Thank you for your interest in contributing! Here's how to get involved.

## Reporting Bugs

Open an issue using the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) template. Please include:
- Steps to reproduce
- Expected vs actual behavior
- iOS version and device model
- Xcode version if building from source

## Suggesting Features

Open an issue using the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) template. Describe the problem you're solving and your proposed solution.

## Dev Setup

1. Clone: `git clone https://github.com/yagomp/geni.git`
2. Open `ios/Geni.xcodeproj` in Xcode 16+
3. No package manager, no `pod install`, no `npm install` — the project uses only native Apple frameworks
4. Run on a simulator (iOS 17+) or a physical device

## Making Changes

1. Fork the repo and create a branch: `git checkout -b your-feature-name`
2. Make your changes
3. Test on both simulator and a physical device if the change touches iCloud sync or Speech Recognition
4. Open a pull request against `main` with a clear description of what changed and why

## Code Style

- Follow the existing SwiftUI/MVVM patterns in the codebase
- Views go in `ios/Geni/Views/`, business logic in `ViewModels/`, data access in `Services/`
- Keep views focused on layout and presentation — logic belongs in ViewModels
- No external dependencies — keep the project dependency-free

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be kind.
