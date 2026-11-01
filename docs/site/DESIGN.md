# Geni website — design system

Make geni.kids look like the app: cream page, white rounded surfaces with a soft shadow and no outline,
big emoji and real app screens as heroes, one accent colour used sparingly, heavy rounded type, lots of air,
no taglines or helper text. Light mode only (the site has no dark mode; keep `color-scheme: light`).

Source of truth for colour and shape: `ios/Geni/Utilities/Theme.swift` (`GeniColor`, `GeniShape`,
`SoftSurface`, `KidPressStyle`) and `docs/games/DESIGN.md`. Reference screens:
`/tmp/geni-shots-v6/*.png`, `screenshots/v1.3.0/iphone-6.7/en/*.png`.

## 1. Tokens

Put these in one shared stylesheet `site/geni.css` (tokens + components, ≤ 12 KB, linked from every page
before `nav.js`). Pages keep only page-specific CSS. `nav.js` / `footer.js` keep injecting their CSS but must
use these variables and nothing hard-coded.

```css
:root{
  color-scheme:light;

  /* Palette (GeniColor) — fills and decoration */
  --blue:#0066FF; --green:#21A84A; --yellow:#FFD60A; --orange:#FF9400;
  --pink:#FF2E54; --purple:#B052DE; --cyan:#66D9F2; --peach:#F5D1B8;

  /* Ink — text on cream/white (all ≥ 4.5:1) */
  --ink:#000000;            /* body, headings, labels */
  --ink-2:#5C5A52;          /* dates, meta, captions only — never for body copy */
  --blue-ink:#0052CC; --green-ink:#1B7A38; --orange-ink:#8A4B00; --pink-ink:#C70D38;

  /* Opaque tints (Color.soft) — stat tiles, chips, callouts. Never rgba on fills. */
  --blue-soft:#E6F0FF;   --blue-line:#A6C9FF;
  --green-soft:#E4F5E9;  --green-line:#B1E1C0;
  --yellow-soft:#FFF9DA; --yellow-line:#FFEFA8;
  --orange-soft:#FFF2E0; --orange-line:#FFD9A6;
  --pink-soft:#FFE6EB;   --pink-line:#FFB6C5;
  --purple-soft:#F6EAFB; --purple-line:#E3C2F3;
  --cyan-soft:#E8F9FD;   --cyan-line:#C2EFF9;

  /* Theme (overridden by body[data-theme]) */
  --bg:#FFF7E0; --card:#FFFFFF; --accent:#0066FF; --accent-ink:#0052CC; --accent-soft:#E6F0FF;

  /* Lines and depth */
  --hairline:rgba(0,0,0,.10);              /* dividers, progress tracks, input borders */
  --shadow:0 4px 10px rgba(0,0,0,.08);     /* SoftSurface — every card, button, menu */
  --shadow-lift:0 8px 20px rgba(0,0,0,.10);/* hover on linked cards / buttons */
  --shadow-press:0 2px 6px rgba(0,0,0,.08);
  --focus:0 0 0 4px var(--accent-soft);

  /* Radius (GeniShape 16 base, games 24) */
  --r-sm:12px;   /* chips, inputs, small tiles */
  --r-md:16px;   /* buttons, nav items, menus */
  --r-lg:24px;   /* cards, table card, callouts */
  --r-xl:32px;   /* hero panels, device screens, thank-you card */
  --r-pill:999px;

  /* Space (4-base) */
  --s-1:4px; --s-2:8px; --s-3:12px; --s-4:16px; --s-5:24px; --s-6:32px; --s-7:48px; --s-8:64px; --s-9:96px;
  --gutter:20px; --container:1120px; --content:760px;

  /* Type */
  --font:"Nunito",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  --lh-tight:1.05; --lh-heading:1.15; --lh-body:1.6;
  --fs-display:clamp(2.75rem,6vw,4.5rem);
  --fs-h1:clamp(2.125rem,4.5vw,3rem);
  --fs-h2:clamp(1.625rem,3vw,2.125rem);
  --fs-h3:1.25rem;
  --fs-lead:1.25rem; --fs-body:1.0625rem; --fs-small:.9375rem; --fs-meta:.875rem;
}
body[data-theme="standard"]{--bg:#FFF7E0;--card:#FFFFFF;--accent:#0066FF;--accent-ink:#0052CC;--accent-soft:#E6F0FF}
body[data-theme="ocean"]   {--bg:#E6F2FF;--card:#F2F7FF;--accent:#2E73D1;--accent-ink:#1F5CB0;--accent-soft:#D8E8FB}
body[data-theme="blossom"] {--bg:#FFEDF2;--card:#FFF7FA;--accent:#E0477A;--accent-ink:#B7265C;--accent-soft:#FBDCE6}
```

Fixes while migrating: `--yellow` is currently `#0433FF` (a blue) on every page; `<meta name="theme-color">`
on index.html is `#0433FF` — set it to `#FFF7E0` (nav.js already updates it per theme).

**Font.** Self-host **Nunito** (OFL) for headings and body as one variable `woff2`, subset to Latin,
Latin-1 and Latin Extended-A (covers en, nb, es, pt), with general punctuation, euro and trademark.
`site/fonts/nunito-latin-variable.woff2` is about 43 KB, generated from Google Fonts' `ofl/nunito/Nunito[wght].ttf`;
`site/fonts/OFL.txt` contains the license. Declare `font-display: swap` and preload the same file on every
page (including blog pages). No icon fonts or second family. Weights: 900 display/h1, 800 h2/h3/buttons,
700 labels/links, 600 lead/meta, 500 body.

**Type scale**

| Role | Size | Weight | Line | Tracking | Case |
|---|---|---|---|---|---|
| Display (landing h1) | `--fs-display` | 900 | 1.05 | -0.02em | Sentence |
| H1 | `--fs-h1` | 900 | 1.1 | -0.015em | Sentence |
| H2 | `--fs-h2` | 800 | 1.15 | -0.01em | Sentence |
| H3 | 1.25rem | 800 | 1.25 | 0 | Sentence |
| Lead | 1.25rem | 600 | 1.5 | 0 | — |
| Body | 1.0625rem (17px) | 500 | 1.6 | 0 | — |
| Small / list in cards | .9375rem | 500 | 1.55 | 0 | — |
| Label / button-sm / chip | .875–1rem | 700 | 1 | 0 | Sentence |
| Meta (dates, breadcrumbs) | .875rem | 600 | 1.4 | 0 | Sentence, `--ink-2` |

No `text-transform: uppercase`, no positive letter-spacing anywhere. Those were the brutalist voice.

**Contrast (WCAG AA, checked)**: white on `--blue` 4.8:1, on ocean accent 4.7:1, on `--green` 3.1:1,
on blossom accent 3.9:1 → white-on-accent text must be ≥ 1.2rem bold (large text, 3:1); buttons comply
by spec. For running text on cream/white use the `*-ink` tokens only (`--blue-ink` 6.4:1, `--green-ink`
5.1:1, `--ink-2` 6.1:1). Never set text in `--yellow`, `--orange`, `--cyan`, `--pink` or raw `--green`.

## 2. Global rules

- **Surfaces**: `background: var(--card); border-radius: var(--r-lg); box-shadow: var(--shadow)`. No border.
  The only permitted lines are `--hairline` dividers and 2px `*-line` tints on stat tiles.
- **Never**: solid black borders, offset shadows (`6px 6px 0 #000`), square corners, hover `translate(-3px,-3px)`,
  uppercase, eyebrow labels, intro paragraphs under section titles, grey helper text, pastel card backgrounds
  that carry no meaning, icon fonts/SVG icon sets (emoji only), gradients, blur backdrops.
- **Colour = meaning**: blue math / primary action, green reading / success, yellow coins / highlight,
  orange bonus, pink errors (never red). Chrome stays cream and white; pictures carry the colour.
- **Heroes are pictures**: a 3.5–4.5rem emoji or a real app screen, sitting directly on the surface
  (no tile, circle or square behind it; the app dropped those).
- **Copy**: one title + one sentence per block, max 2 lines. If a block "needs" a subtitle, remove the
  subtitle and fix the picture or layout.
- **Shape of interaction**: hover = lift (`translateY(-1px)` + `--shadow-lift`), press = sink
  (`scale(.97) translateY(2px)` + `--shadow-press`), 200 ms ease-out. Only elements that navigate or submit
  get hover/press; cards that are not links do nothing on hover.
- **Focus**: `:focus-visible{outline:3px solid var(--accent-ink);outline-offset:3px}` on all interactive
  elements; the outline follows the radius automatically.
- **Targets**: ≥ 44×44 px for every link/button/dot on touch.
- **Motion**: transitions ≤ 250 ms, one property set per element, no scroll-reveal, no idle animation
  (the one exception is the animated Geni in the landing hero, below),
  no parallax. `@media (prefers-reduced-motion: reduce){*{transition:none!important;transform:none!important}
  html{scroll-behavior:auto}}`.
- **Performance**: no JS beyond nav.js/footer.js/i18n and the hero scripts (phone-demo.js, hero-demo.js, geni-hero.js); one shared CSS file; at most one webfont file;
  screenshots as `webp` with `srcset` (600w/1200w) and explicit width/height; `loading="lazy"` below the fold.
- **Responsive**: phone ≤ 600, tablet 601–1024, desktop > 1024. Container 1120 (hero, grids, table), prose 760.
  Gutter 20 px (24 px ≥ 601). Everything single-column on phone.

## 3. Components

### Header / nav (`nav.js`)
- `nav`: sticky, `background: var(--bg)`, height 72 (68 on phone), no border, no shadow; add
  `box-shadow: var(--shadow)` only when `scrollY > 8` (class `is-scrolled`) so it reads as a floating surface.
- `.nav-logo`: `icon-mark.png` 40×40, `border-radius: var(--r-sm)`, + wordmark "Geni" 1.25rem/900 sentence
  case. No box, no uppercase, no letter-spacing.
- `.nav-links a`: 1rem/700 `--ink`, `padding: 10px 14px; border-radius: var(--r-md)`; hover `color:
  var(--accent-ink)`; current page `aria-current="page"` → `background: var(--card); box-shadow: var(--shadow)`.
  Remove bottom borders.
- Download in nav: `.btn.btn--primary.btn--sm` ("Download"), appears on scroll as today (opacity/scale).
  Drop the Apple private-use glyph; use the text, or the badge on desktop ≥ 1200 px only.
- `.nav-menu-btn`: 48×48, `--card`, `--r-md`, `--shadow`; three 2px bars, 18 px wide, `--ink`.
- `.nav-mobile`: `--card`, `border-radius: 0 0 var(--r-lg) var(--r-lg)`, `--shadow-lift`, padding 8 20 20;
  rows 52 px tall, 1.0625rem/700, no row borders; `--hairline` only between the link group and the
  language group.
- `.theme-dot`: 22 px circle, theme bg colour, `box-shadow: 0 0 0 2px var(--card), var(--shadow)`;
  active `box-shadow: 0 0 0 2px var(--card), 0 0 0 4px var(--accent)`; wrap in a 44 px hit area.
- `.lang-btn`: same as a nav link. `.lang-menu-inner`: `--card`, `--r-md`, `--shadow-lift`, padding 8;
  items 44 px, radius `--r-sm`, hover `background: var(--accent-soft)`.

### Hero (`index.html`)
- Grid `minmax(0,1fr) minmax(320px,46vw)`, gap `clamp(24px,4vw,48px)`, `min-height: calc(100svh - 72px)`,
  padding `--s-7` 0. Phone: single column, copy centred, screens below.
- Copy: `h1` Display, `max-width: 12ch`; one `p.lead` (1.25rem/600, `max-width: 40ch`) — plain text, no box;
  CTA row: App Store badge + `.btn--secondary` "See how it works" (anchor to `#features-heading`), gap 16, wrap.
- Visual: two real app screens (standard theme, EN) staggered like the App Store shot
  (`screenshots/v1.3.0/.../01.png`): `.screen{width:min(280px,36vw);aspect-ratio:1206/2622;border-radius:
  var(--r-xl);box-shadow:var(--shadow-lift);object-fit:cover}`; second screen offset `translateY(48px)` and
  overlapping 15%. No bezel. Assets: raw simulator captures (1206×2622, like
  `/tmp/geni-shots-v6/home.png`) → `site/img/screens/{home,math,reading,rewards,parents}.webp` at 600w and
  1200w. Keep the static mascot (`icon-hero*`) only for `thankyou.html` and social images.
- Mascot (landing only, `geni-hero.js`): the animated 3D Geni stands in front of the page beside the phone's
  lower-left corner, feet on the hero's baseline, overlapping only the phone's bezel; never behind the phone.
  At rest he never touches the headline, lead, CTA row or the phone's game; he is as big as that allows
  (video ≈ 0.58 × phone height, ≤ 460 px). Desktop: walks in from off-screen left at the foot-locked speed
  (0.407 body heights/s), passing in front of the CTA row on the way, then waves and idles.
  Tablet: waves hello, idles. Phone: pops up in front of the cropped phone's corner, lower body hidden by the
  hero's faded bottom edge. Tap = cheer. Clips in `site/media/geni/` (`.mov` HEVC + alpha for Safari, `.webm`
  VP9 + alpha elsewhere, 720 px, chained so each clip starts on the previous clip's last pose); loaded only
  after page load when the hero is in view, paused off-screen. Reduced motion: the idle still
  (`media/geni/idle.webp`), no animation. Decorative: videos are `aria-hidden`, the tap target is a button
  labelled "Geni cheers".

### Buttons
```css
.btn{display:inline-flex;align-items:center;justify-content:center;gap:10px;min-height:56px;padding:0 28px;
  border:0;border-radius:var(--r-md);font:800 1.2rem/1 var(--font);text-decoration:none;cursor:pointer;
  box-shadow:var(--shadow);transition:transform .2s ease-out,box-shadow .2s ease-out}
.btn--primary{background:var(--accent);color:#fff}
.btn--secondary{background:var(--card);color:var(--ink)}
.btn--sm{min-height:44px;padding:0 18px;font-size:1rem}
.btn:hover{transform:translateY(-1px);box-shadow:var(--shadow-lift)}
.btn:active{transform:scale(.97) translateY(2px);box-shadow:var(--shadow-press)}
.btn[disabled]{background:#E6E6E6;color:rgba(0,0,0,.35);box-shadow:none}
.link{color:var(--accent-ink);font-weight:700;text-decoration:underline;text-underline-offset:3px}
```
- Full width on phone inside forms and cards (`width:100%`), auto elsewhere.
- **App Store badge**: Apple's official black badge, `height: 56px` (44 in nav), never recoloured or
  outlined; always the first item in a CTA row, to the left of/above any secondary button. One badge per
  viewport-height of content at most.
- Don't: green primary buttons on the site (green = reading/success), text-only uppercase buttons,
  two primaries side by side.

### Cards and sections
- `.section{padding:clamp(48px,8vw,96px) 0}`; `.section > h2` centred, margin-bottom `--s-6`; no intro `<p>`.
- `.card{background:var(--card);border-radius:var(--r-lg);padding:var(--s-6) var(--s-5);box-shadow:var(--shadow)}`
  (phone: `padding: var(--s-5) var(--s-4)`). `a.card` adds the lift hover; plain cards don't.
- `.card--tint-{blue|green|yellow|orange|pink|purple|cyan}`: `background: var(--*-soft)`, no shadow,
  `border: 2px solid var(--*-line)` — use for stat tiles and callouts only (mirrors the parent dashboard).
- `.card h2/h3`: emoji first (`<span aria-hidden>🎯</span>`) at 1.5rem, then title; `display:flex;gap:10px;
  align-items:center`.
- Stack of cards: gap `--s-4`. Grid of cards: gap `--s-5`.

### Feature grid (`index.html .features`)
- Section on cream (drop the white band and its borders). Grid 3 → 2 (≤ 1024) → 1 (≤ 600), gap 24.
- `.feature-card` = `.card` with `.feature-emoji` 3.5rem (`line-height:1`, margin-bottom 16) on top, no
  tile behind, `h3` 1.25rem/800, `p` `--fs-body`. Delete `.feature-label` (eyebrow) and the seven
  `nth-child` pastel backgrounds. White cards; emoji carry the colour.

### Age table (`index.html .age-table`)
- Wrapper `.card` (`--r-lg`, padding 32 28). Title h2; delete the intro `p`.
- `table{border-collapse:separate;border-spacing:0}`; `th,td{border:0;padding:16px 14px;vertical-align:top}`.
- `thead th`: `background: var(--yellow-soft)`, `font: 700 .9375rem`, first/last th radius `--r-sm` on the
  outer corners. Rows: `td{border-bottom:1px solid var(--hairline)}`, last row none.
- Age cell: `<span class="age-pill">6</span>` — 44×44, `--blue-soft` background, `--r-sm`, 1.25rem/900,
  centred. Math/Reading cells: 1rem, `line-height: 1.7`, emoji inline as today.
- Phone (≤ 600): thead hidden, each `tr` → stacked block with `padding: 16px 0` and hairline below; the age
  pill floats left of the "Math"/"Reading" labels (`.age-cell-label` .875rem/700 `--ink-2`, no uppercase).

### FAQ / accordion (new, optional — for parents.html and privacy.html groupings)
```css
.faq{background:var(--card);border-radius:var(--r-md);box-shadow:var(--shadow)}
.faq+.faq{margin-top:12px}
.faq summary{list-style:none;display:flex;justify-content:space-between;align-items:center;gap:16px;
  padding:18px 24px;font:800 1.125rem/1.3 var(--font);cursor:pointer;border-radius:var(--r-md)}
.faq summary::-webkit-details-marker{display:none}
.faq summary::after{content:"";width:12px;height:12px;border-right:3px solid var(--ink);border-bottom:3px solid var(--ink);
  transform:rotate(45deg);transition:transform .2s ease-out;flex:none;margin-right:4px}
.faq[open] summary::after{transform:rotate(-135deg)}
.faq > div{padding:0 24px 20px;font-size:var(--fs-body)}
```
Use native `<details>`; no JS. Only group into an accordion when a page has more than 8 same-shaped
sections and SEO text can stay in the DOM (it does with `<details>`).

### Blog
- Index header: `h1` Display, no paragraph. `.post-grid`: `auto-fill minmax(300px,1fr)`, gap 24, bottom 96.
- `a.post-card` = `.card` + lift hover; inside: `.chip` (pill, `--blue-soft` bg, `--blue-ink`, .8125rem/700,
  padding 4 12, sentence case — replaces the black `.post-tag`), `h2` 1.375rem/800, `p` `--fs-body`, `.post-meta`
  .875rem/600 `--ink-2`.
- Article: `.article-wrap{max-width:var(--content)}`, padding 48 20 96. `.breadcrumb` meta style, links
  `--ink-2` underline → `--ink` on hover. `h1` H1 scale, `.post-meta` under it with a `--hairline` bottom,
  no 3px black rule. `.article-body`: `p,li` 1.125rem/1.75, `h2` 1.75rem/800 margin 48 0 16, `h3` 1.25rem/800
  margin 32 0 12, `a` `.link` style.
- `.callout` → `.card.card--tint-yellow` (`--r-md`, padding 24), its `strong` as a 1.0625rem/800 heading,
  no uppercase. `.cta-box` → `.cta` (below). `.back-link` → `.btn.btn--secondary.btn--sm` with "← Blog".

### CTA block (`.cta-section`, `.cta-box`, in-page CTAs)
- `.cta{text-align:center;padding:var(--s-7) 0}` containing `h2` (H2 scale) and the App Store badge, gap 24.
  Drop the uppercase lead `p`. On blog articles wrap it in `.card` (`--r-lg`, padding 40 32).

### Footer (`footer.js`)
- `footer{padding:var(--s-8) 0 var(--s-7);background:var(--bg)}` — no top border. Content centred, gap 16:
  `.footer-brand` (icon-mark 32 px + "Geni" 1.125rem/800), `.footer-links` (1rem/700 `--ink`, gap 24, wrap,
  hover `--accent-ink`), then `© 2026 Geni` .875rem `--ink-2`. Delete `.footer-copy` (it is a tagline;
  `llms.txt` keeps the description).

### Forms (`contact.html`)
```css
label{display:block;font:700 .9375rem/1 var(--font);margin-bottom:8px}
input,textarea,select{width:100%;min-height:52px;padding:14px 16px;border:2px solid var(--hairline);
  border-radius:var(--r-sm);background:#fff;color:var(--ink);font:500 var(--fs-body)/1.4 var(--font);
  transition:border-color .2s,box-shadow .2s}
input:focus,textarea:focus,select:focus{outline:0;border-color:var(--accent);box-shadow:var(--focus)}
textarea{min-height:160px;resize:vertical}
.field{margin-bottom:20px}  .form-row{display:grid;grid-template-columns:1fr 1fr;gap:16px}
input[aria-invalid="true"]{border-color:var(--pink)}
.field-error{margin-top:6px;font:700 .875rem var(--font);color:var(--pink-ink)}
.success-msg{background:var(--green-soft);border:2px solid var(--green-line);color:var(--green-ink)}
.error-msg{background:var(--pink-soft);border:2px solid var(--pink-line);color:var(--pink-ink)}
.success-msg,.error-msg{border-radius:var(--r-md);padding:16px 20px;font-weight:700;text-align:center;margin-top:20px}
```
- Form sits in a `.card`; submit is `.btn.btn--primary` full width on phone, `min-width: 200px` on desktop,
  right-aligned. Phone: `.form-row` single column. Delete `.subtitle`.
- Placeholders are not labels; every field keeps its visible `<label>`.

### Small pieces
- `.chip`: pill, `--*-soft` bg + matching `*-ink`, .8125rem/700, padding 4 12, no uppercase.
- `.emoji-hero`: `font-size: clamp(3.5rem,8vw,4.5rem); line-height: 1`, centred, no background.
- `.progress` (optional decoration, mirrors the home screen): track 10 px `--accent-soft` pill, fill `--accent`.
- `.screen`: see Hero. Use for any in-page screenshot (math.html, reading.html, parents.html) at
  `width: min(240px, 60vw)`, right-aligned beside a card's text at ≥ 900 px, below it on phone.

## 4. Page-by-page migration checklist

Shared, all pages: add `<link rel="stylesheet" href="geni.css">` (blog: `../geni.css`); delete the duplicated
`:root`, reset, `a`, `footer*`, `.app-store-badge` rules from the inline `<style>`; fix `--yellow`;
`<meta name="theme-color" content="#FFF7E0">`; replace every `border:3/4px solid #000`, `box-shadow:Npx Npx 0`,
`text-transform:uppercase`, `letter-spacing` with the component rules above; remove `translate(-3px,-3px)` hovers.

| Page | Existing element / class | Becomes |
|---|---|---|
| nav.js | `.nav-logo` boxed GENI | icon-mark + "Geni" wordmark, no box |
| nav.js | `.nav-links a` underline tabs | pill links, `aria-current` → white pill |
| nav.js | `.nav-store-mobile`, `.nav-store-desktop` | `.btn--primary.btn--sm` "Download" |
| nav.js | `.nav-menu-btn`, `.nav-mobile` (3px border, `0 8px 0 #000`) | soft white surface, rounded bottom corners |
| nav.js | `.theme-dot` (black ring, 1px offset shadow) | white ring + soft shadow; accent ring when active |
| nav.js | `.lang-menu-inner` | `--card` + `--r-md` + `--shadow-lift` |
| index.html | `.hero h1` uppercase | Display, sentence case, no uppercase |
| index.html | `.hero p` boxed with 4px border | `p.lead`, plain |
| index.html | `.hero-visual .hero-icon` mascot | two `.screen` app screenshots, staggered |
| index.html | `.features` white band with 4px borders | plain `.section` on cream |
| index.html | `.features-intro` | delete |
| index.html | `.feature-card` + `nth-child` pastels, `.feature-label` | `.card` white, 3.5rem emoji on top, h3 + p; delete label |
| index.html | `.age-table-card` (8px offset shadow) | `.card` |
| index.html | `.age-table-card p` intro | delete |
| index.html | `.age-table th/td` 3px cell borders | yellow-soft header, hairline rows, `.age-pill` for the age |
| index.html | inline `footer` CSS | delete (footer.js owns it) |
| math/reading/parents.html | `h1` uppercase centred | H1 scale, sentence case; add one `.screen` beside the first card |
| math/reading/parents.html | `.info-card` (offset shadow, hover shift) | `.card`, emoji + h3-sized h2, p/ul `--fs-small`; no hover |
| math/reading/parents.html | `.cta-section p` uppercase + badge | `.cta` (h2 + badge) |
| parents.html | 8 `.info-card` per language | `.card` stack, or `.faq` if the content grows beyond 8 |
| privacy.html | `.content-card` | `.card` at `--content` width, padding 40 32 |
| privacy.html | `.content-card h2` with 3px underline | H3-sized h2, `margin-top: var(--s-6)`, no rule |
| privacy.html | `.updated` grey | `.meta` (`--ink-2`, .875rem) under h1 |
| privacy.html | `.content-card a` | `.link` |
| contact.html | `.subtitle` | delete |
| contact.html | `.contact-card`, inputs, `.submit-btn`, `.success-msg`, `.error-msg` | Forms spec above |
| thankyou.html | `.card` (border + offset), `.icon`, `.btn` | `.card` with `--r-xl` + padding 48, `.emoji-hero`, `.btn--primary` |
| blog/index.html | `.blog-header h1` uppercase, `.blog-header p` | Display, sentence case; delete the p |
| blog/index.html | `.post-card` (3px border), `.post-tag` black | `a.card` with lift, `.chip` |
| blog/*.html | `.breadcrumb`, `.post-meta` with 3px rule | meta style, hairline |
| blog/*.html | `.post-tag` | `.chip` |
| blog/*.html | `.callout` (3px border + offset) | `.card.card--tint-yellow` |
| blog/*.html | `.cta-box` (4px border + offset) | `.cta` inside `.card` |
| blog/*.html | `.back-link` underline, uppercase | `.btn--secondary.btn--sm` |
| footer.js | 4px top border, `.footer-copy` paragraph | no border, delete copy, brand + links + © |

**Done when**: a grep of `site/` finds no `solid #000`, `0 #000`, `uppercase`, `letter-spacing:` (except the
negative heading tracking in `geni.css`), and no `--yellow:#0433FF`; every page renders at 375, 768 and
1280 px with no horizontal scroll; keyboard focus is visible on every control; Lighthouse accessibility ≥ 95
and performance ≥ 95 on index.html with the screenshots in place.
