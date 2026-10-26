# Geni kid games — visual guideline

Calm, round, obvious. A 4-year-old should know what to tap without reading. The shared pieces in
`ios/Geni/Games/GameUI.swift` already do this; custom pieces copy them via `GameStyle`, `.gameSurface()`
and `GameTileStyle`. No new colours, fonts or shapes.

## Layout of a game screen (top → bottom)
1. `GameQuestion` — one line, the only words on screen.
2. `GameSceneCard` — one white picture card (emoji rows / drawn shapes / counter). Optional.
3. Answers — `GameChoices` (2–4 tiles) or a built answer + `GameSubmitButton`.
Outer `VStack(spacing: 24)` (36 on iPad expanded). Must fit iPhone SE 375×667 under the header with no
scrolling: budget ≈ 60 question + 24 + card ≤ 220 + 24 + tiles (88 or 2×88+14). Nothing else.

## Tokens
| | phone | iPad expanded (`geniExpandedLayout`) |
|---|---|---|
| Spacing scale | 4 · 8 · 12 · 16 · 24 · 32 | × 1.5 (`GameStyle.gap`) |
| Corner radius | 24 | × 1.3 (`GameStyle.radius`) |
| Question | 28 rounded black, 2 lines max | 44 |
| Tile label | 36 (24 for words) rounded black | 52 |
| Emoji in scene | 40 | 64 |
| Tile height | 88 (never < 64) | × 1.6 |
| ✓ button | 72 tall, green, white checkmark | 110 |
| Grid gap | 14 | 21 |
Other sizes go through `iPadScale.value(_:)` on compact iPad windows.

## Surfaces, borders, shadows
- Surface = `GeniColor.card` fill + 2pt hairline `GameStyle.hairline` (black 10 %) + shadow black 8 %, radius 10, y 4.
- Tappable = surface + 4pt bottom edge `GameStyle.edge` (black 14 %). Pressing sinks the tile into the edge
  (scale 0.97, 3pt down, spring 0.22 s). This edge is the only cue that something can be tapped: never put it
  on decoration.
- No 3pt black borders, no 4pt black offset shadows, no `.brutalistCard` in games.
- Text on surfaces is always `GeniColor.border` (black). Never grey helper text.

## Colour = state, nothing else
| State | Fill | Outline | Edge |
|---|---|---|---|
| Idle | card (white) | hairline | edge |
| Correct | `GeniColor.green` (+ scale 1.04) | green.deep(0.25) | green.deep(0.3) |
| Wrong (tapped) | `GeniColor.pink.soft(0.3)` | `GeniColor.pink` | pink.soft(0.6) |
| Other tiles during feedback | card, opacity 0.5 | | |
| ✓ enabled / disabled | green, white ✓ / lightGray, black 25 % ✓ | none | green.deep(0.3) / edge |
Pictures carry the colour (emoji, drawn shapes in yellow/cyan/orange/blue). Chrome stays white and cream.
Selected-but-not-submitted pieces (a coin on the counter, a block picked): `GeniColor.yellow.soft(0.35)` fill
with a `GeniColor.yellow` 2pt outline. Use opaque tints (`.soft`), not `.opacity`, on fills.

## Motion and haptics
- Tap: `HapticManager.impact(.medium)` + the press sink. Nothing else on tap.
- Feedback is owned by `ChapterViewModel` (banner, haptic, advance); tiles only change colour (spring 0.35 s).
- One animation per event, ≤ 0.35 s, springs not eases. No idle animation, no particles inside a game.
- Scenes may animate a single reveal (e.g. the missing item appears) once, when the view appears.

## Do / don't
- Do: `GameQuestion("How many apples?")` → card with 🍎🍎🍎 → tiles `2 · 3 · 4`.
- Do: build-then-check: coins tray (surface) → counter (surface, picked coins yellow) → `GameSubmitButton`.
- Do: use `Text(emoji)` at 40pt+; one scene card; 2–4 distinct choices; correct at a random spot.
- Don't: a subtitle, label or instruction under the question. Fix the picture instead.
- Don't: two cards, scrolling, small tiles, outlined/black-shadow boxes, red for wrong (pink only), grey text.
- Don't: tiles that both show the answer and the picture twice (the card shows the scene; tiles show choices).
- Don't: new colours, system fonts, `.opacity` on fills, icons where an emoji does the job.

Home screen and other kid screens later follow the same surface, tile, state and motion rules.
