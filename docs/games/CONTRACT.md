# Geni picture games — contract for parallel work

Many agents build games at the same time in ONE shared checkout (`/Users/yago/Documents/geni`, branch
`codex/testflight-math-fixes`, lots of uncommitted work — never stash, reset, checkout or commit).

## Ownership (strict)
- You may edit ONLY your folder `ios/Geni/Games/<Folder>/` (any new files inside it) and
  `ios/GeniTests/Games/<Folder>Tests.swift`. Nothing else. If you need a change elsewhere, say so in your report.
- Shared, read-only for you: `ios/Geni/Games/GameKit.swift` (GameKind, GameSpec, GamePayload, GameChoice,
  ChoicePayload, `Exercise.choiceGame`, GameFactory, GameCurriculum), `GameUI.swift` (shared views),
  `StoreRegion.swift` (country, currency, imperial units, southern hemisphere).
- Keep the two entry points of your folder exactly:
  `enum <Name>Games { static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise }`
  `struct <Name>GameView: View { let exercise: Exercise; let spec: GameSpec; let chapterVM: ChapterViewModel; let persistence: PersistenceService }`
  The placeholder in your folder shows the shape. Handle every `GameKind` your folder owns (see `GameFactory`).
  `GameKind.ages` says which ages get each game.

## Building an exercise
- Pick-one games: `Exercise.choiceGame(kind, prompt:, scene: [[String]], choices: [GameChoice], correct:, difficulty:)`.
  Rendered by the shared `ChoiceGameView` (question line, picture card of emoji rows, 2–4 big tiles). Prefer this.
- Custom games: define your own `struct …: GamePayload`, build
  `Exercise(game: GameSpec(kind:, prompt:, answerText:, payload:), correctAnswer:, options:, difficulty:)` and draw
  it in your view with the shared pieces: `GameQuestion`, `GameSceneCard`, `GameEmojiRow`, `GameChoices`,
  `GameChoiceTile`, `GameSubmitButton` (for build-then-check: answers with the value the child built).
- Answering: `chapterVM.submitAnswer(value, persistence:)`; right iff `value == exercise.correctAnswer`.
  ChapterViewModel already handles 2 tries, haptics, the feedback banner (`spec.answerText` after two misses)
  and advancing. Tappable answers must carry `.accessibilityIdentifier("answer.<value>")` (the shared tiles do).
- Local @State (e.g. coins put on the counter) is fine: the view is re-created per exercise (`.id(exercise.id)`).

## Kid design rules (ages 4–10, "super easy, super graphical")
- One question line only (`GameQuestion`). No helper text, subtitles, instructions or labels beyond it.
  If a game needs more words to make sense, change the picture, not the text.
- Pictures first: emoji / drawn shapes, big. Ages 4–6 must be playable without reading
  (the prompt is read aloud for 4–5, so phrase it as a short spoken question).
- 2–4 choices, big tiles (≥ 64pt tall, the shared tiles are 88pt), correct choice at a random position,
  values distinct. Numbers stay within what the age knows.
- Existing look only: `GeniColor` (blue, green, cyan, yellow, orange, pink, lightYellow, lightGray, card, border),
  `GeniShape`, 3pt border + 4pt offset shadow, `KidPressStyle`, `.rounded` black/heavy fonts. No new colors/fonts.
- Must fit an iPhone SE (375×667) without scrolling; scale up on iPad via `@Environment(\.geniExpandedLayout)`
  and `iPadScale.value(_:)` (see GameUI.swift).

## Text, languages, international
- All text via `L.t("English", no: "Norsk bokmål", es: "Español", pt: "Português (Portugal)")` — natural,
  kid-level, short. Never hardcode one language.
- International by default. Money: currency of the App Store storefront (`StoreRegion.currencyCode`), with
  that currency's real everyday coins/notes and symbol placement (use `NumberFormatter`/`Locale` for formatting).
  Units: metric, imperial when `StoreRegion.usesImperial`. Seasons: flip when `StoreRegion.isSouthernHemisphere`.
- Culture may follow the app language (`L.selectedLanguage`): e.g. Norwegian stories can use Bukkene Bruse,
  others use widely known equivalents. Keep it kind and neutral.

## Tests and build
- Swift Testing (`import Testing`, `@testable import Geni`), file `ios/GeniTests/Games/<Folder>Tests.swift`.
  For every kind you own × every age in `kind.ages` × every `ExerciseDifficulty`, generate ~100 and check:
  `format == .game`, `game?.kind == kind`, non-empty prompt and answerText, options distinct and containing
  `correctAnswer` (when the game has fixed options), ≤ 4 options, numbers in range, no "+", "=", "−", "×", "÷"
  in prompts for ages ≤ 5, plus your game's own correctness (e.g. coins add up to the price). Check all 4
  languages produce non-empty strings (set `L.selectedLanguage`, restore it; mark the suite `.serialized`).
- Compile check ONLY with `scripts/geni-build.sh` (from the repo root). It waits for any other Geni build,
  uses one shared DerivedData and 4 jobs — the Mac (16 GB) crashed when many builds ran at once. Never call
  `xcodebuild` directly, never boot or use a simulator, never run tests. Build rarely: once when your code is
  complete, again only to verify fixes. If the build fails in a file you don't own, report it; never touch it.
- Visual check later uses `-designPreview game.<kind> [-designPreviewAge N] [-geniStoreRegion NO]`.

## Report
Files you created/changed, one line per game describing what the child sees and does, test names, build
status, and anything you need outside your folder.
