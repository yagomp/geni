# Overhaul to true brutalist design — sharp corners, thick borders, solid shadows

## What's changing

The entire app's visual style will be updated to match the reference screenshot's true brutalist aesthetic:

**Design System (Theme)**
- All corner radii changed from rounded (6pt) to **sharp square (0pt)**
- All borders made consistently **thick black (3pt standard, 4pt for buttons)**
- All shadows changed to **solid black offset (4pt right, 4pt down)** — no blur, no colored shadows
- Button press effect: shadow shrinks and button shifts on tap (already exists, will be tightened)

**Exercise Screen**
- Number pad buttons become **yellow with thick black borders** and solid black shadow (matching the reference)
- The "?" answer box gets a thick black border, square corners
- Progress bar gets thicker borders
- "Clear" and "Delete" buttons get distinct muted colors (light gray / peach) with thick borders
- "Check" button stays blue/cyan with thick border and shadow

**All Cards & Containers across the app**
- Welcome screen: sharp square brain icon, square symbol tiles
- Profile creation: square input fields, square age buttons, square avatar tiles, square operation chips
- Home screen: square stat bubbles, square chapter card, square progress map nodes
- Chapter complete: square reward card
- Rewards view: square stat cards, square badge tiles
- Profile picker: square avatar cards
- Parent dashboard: square profile rows, square PIN pad buttons
- Progress map: square nodes (already square, will ensure consistency)

**Buttons everywhere**
- All brutalist buttons become fully square with 0 corner radius
- Thick 4pt black border
- Solid black shadow offset 4pt right and 4pt down
- Press animation shifts button into shadow position

This is a visual-only change — no functionality, data, or layout structure changes.
