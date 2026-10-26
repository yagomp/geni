# Agent instructions

## App Store releases

- Submit every App Store version with release type **`AFTER_APPROVAL`** (release automatically once Apple approves). Never `MANUAL`, never scheduled. Check it in App Store Connect before submitting and fix it if it differs.

- Before every upload run `scripts/release-check.sh` from the release checkout; never upload if it fails.
  It runs the full unit-test suite and rejects any `fatalError`/`preconditionFailure`/`try!` reachable from
  exercise generation (ios/Geni/Services/ExerciseGenerator.swift, ios/Geni/Games/).
- Urgent fixes for a live version ship as a separate patch release from the shipped commit (worktree
  `../geni-hotfix`), never bundled with unfinished work; port the same fix to the working branch.

## Builds on this Mac (16 GB — it crashed with ~10 parallel builds)

- Build and test only through `scripts/geni-build.sh` (`build-for-testing` by default, `app`, `test [Suite]`,
  `archive`). It allows one Xcode build at a time machine-wide and uses 4 jobs. Never call `xcodebuild`
  directly and never run builds in parallel; several agents may work at once but their builds queue.
- One shared simulator (see the global instructions); never let Xcode clone it (`-parallel-testing-enabled NO`).

## Code rules that prevent known crashes

- Exercise generation must never trap: every `ExerciseFormat` is built by one exhaustive `switch` without
  `default`; format pickers and builders must stay in sync through that switch, not by convention.
- Every chapter type × age × operation × topic is covered by fuzz tests (`ChapterFuzzTests`); add new
  formats, games, ages and chapter types to them in the same change.
- A new test counts only after you've seen it fail for the bug it guards (or deliberately broken the code
  once); a test that can never fail (or never pass) is a bug.
- Rounded corners everywhere via GeniShape / GameStyle.radius / GameStyle.cellRadius; never hardcoded RoundedRectangle/Capsule/cornerRadius for UI; only real-life round objects keep their own shape.
