# Design System: iDE (iVisualStudio)

The single source of truth for screens generated for this product — in Google Stitch,
in SwiftUI, or in the HTML studio (`ide-mobile-studio.html`). Calibrated from
`brand/tokens.css`, `brand/design-tokens.json`, `ios/iDE/IDETheme.swift` and
`docs/DESIGN-PLAN.md`.

**Every hex in this document is an existing token. Nothing here invents colour.**
If a screen needs a value this file does not name, the answer is ink, space, or a
divider — not a new hue.

---

## Configuration dials

| Dial | Level | Why this level for this product |
|---|---|---|
| **Creativity** | `7` | Not 9. The expressiveness is spent on one signature structure (the two-state bottom block) and typographic discipline, not decoration. A coding tool that surprises you costs money. |
| **Density** | `9` | Cockpit. 30 lines of code visible when reading, 16 when typing. Every chrome element is charged against code rows. |
| **Variance** | `4` | Predictable. Asymmetry appears only where it encodes hierarchy (a 320 pt sidebar beside flexible editor, a 72 pt RUN slot in a row of 48 pt keys), never where it only looks interesting. |
| **Motion** | `3` | Interaction feedback only. OLED longevity is a brand promise (`oled-zero-smear`); loops and shimmer contradict it. |

---

## 1. Visual Theme & Atmosphere

A machined instrument in a black room. The atmosphere is obsidian, precise and
quiet: a matte graphite chassis where the code is the only lit surface, and the
controls live exactly where a thumb already is. Nothing glows, nothing pulses,
nothing decorates. Density runs high, variance runs low, and the one moment of
composure-breaking generosity is the 72 pt RUN key — the only filled key in the
product, and the reason the app exists.

Reference points: a calibrated measuring tool, a synthesizer front panel, an
aeroplane checklist. Not: a dashboard, a fintech card, a glass panel.

---

## 2. Colour Palette & Roles

### Surfaces (dark is the product, not a theme)

| Token | Hex | Role |
|---|---|---|
| **Editor Black** | `#000000` (`--ide-bg-oled-true`) | Editable text canvas only — editor and terminal. Full-bleed, never a card, never chrome |
| **Machined Obsidian** | `#05080E` (`--ide-bg-canvas`) | App chrome: navigation, list backgrounds, screen base |
| **Chassis** | `#0A0F18` (`--ide-bg-chassis`) | Secondary panels, gutters, inactive bar behind the active bar |
| **Elevated Slate** | `#111926` (`--ide-bg-elevated`) | Sheets, rows with elevation, key caps, workspace glyph squircles |
| **Thumb Bar Steel** | `#131E2E` (`--ide-bg-thumb-bar`) | The bar container itself, and a key in its pressed state |

**The one deliberate exception to "no pure black".** `#000000` is banned as a chunk
of UI — as a card, a bar, a background behind text that needs depth. It survives in
exactly one job: the full-bleed text surface a user stares at for an hour, where
"true black" means zero OLED smear and no wasted pixels. Chrome never sits on it,
and nothing is drawn *on top* of the editor except the gutter and the caret.

### Inks (measured on `#05080E`)

| Token | Hex | Contrast | Role |
|---|---|---|---|
| **Ice Ink** | `#F4F9FD` | 18.8:1 AAA | All body text, code plain text, row titles |
| **Alloy Secondary** | `#9BB0C5` | 8.9:1 AAA | Paths, latency, line numbers, sublabels, metadata |
| **Slate Muted** | `#64748B` | 4.2:1 | Placeholders, disabled glyphs, comment syntax only. Never body copy |

### Signals — one accent, five states, one legacy badge

**Electric Sky `#38BDF8` (`--ide-signal-azure`) is the single interactive accent:**
selection, focus, active tab, active page dot, the leading rule on the active line.
It may cover at most **14 % of any surface** (the token's own wash value) and is
narrower than the 80 %-saturation rule allows — the discipline that replaces it is
area: no full-bleed azure field, no azure gradient, no azure glow, ever.

| Token | Hex | Role | Hard limit |
|---|---|---|---|
| **Electric Sky** | `#38BDF8` | Interactive accent: focus, selection, active state | ≤ 14 % area, no fill behind long text |
| **Signal Azure** | `#007ACC` | "This came from VS Code" — legacy rules and badges | Rule/fill only. 4.4:1 on canvas → never 12 pt text |
| **Live Cyan** | `#14F1D9` | Liveness: connection OK, caret | Marks and 2 pt strokes only |
| **Pass Emerald** | `#34D399` | The action colour: RUN, "Connect", commit, diff add, success | Exactly one primary action per screen |
| **Fail Coral** | `#FC6D26` | Destructive and failure: diff remove, offline, confirm-irreversible | 7.0:1 — text allowed ≥ 13.5 pt |
| **Warn Amber** | `#FBBF24` | Unsaved, reconnecting, warnings, host-key prompt | Never as a fill behind body text |
| **AI Violet** | `#A855F7` | lpBOT role marker, keyword syntax | Marks and 1 pt outlines only. Never a fill behind text, never a gradient stop |

**Two-colour discipline (how the accent rule is honoured here).** Azure owns *state*;
emerald owns *action*. They never trade jobs: a primary button is never azure, and a
focus ring is never emerald. Every other signal is a status readout, not a design
choice — if a screen uses four signals, two of them are lying.

### Banned

Violet-to-blue neon gradients, any purple glow, gradient text, tinted near-black as a
substitute for obsidian, warm/cool grey mixed in one screen, and any hex not listed
above.

---

## 3. Typography Rules

**Display / UI: SF Pro** (`.system`, Dynamic Type). This is the platform typeface,
not a default-by-accident: on iOS it is the legible, correct choice and the HIG
requires it. `Inter` is banned. **Mono: SF Mono**, with `JetBrains Mono` on HTML and
marketing surfaces (OFL, bundled). **Serif is banned everywhere** — this is a
software instrument, not an editorial page.

| Size | Token | Used for | Never for |
|---|---|---|---|
| 34 pt | `--ide-type-large-title` | Screen headers (one line, one word or two) | Sheet titles |
| 28 pt | `--ide-type-title-1` | Titles inside sheets | List rows |
| 22 pt | `--ide-type-title-2` | Sheet titles, device-flow code | Body copy |
| 17 pt | `--ide-type-headline` | Primary buttons, row titles (semibold) | Editor text |
| 17 pt | `--ide-type-body` | Settings rows, lpBOT proposal (regular) | Code |
| 13.5 pt | `--ide-type-code` | Editor, terminal, filenames, port numbers | Anything tappable on its own |
| 12 pt | `--ide-type-caption` | Paths, latency, line numbers, badges | A target smaller than 44 pt around it |

- **Hierarchy comes from weight and ink, not size jumps.** 17 semibold over 12 mono
  is a complete hierarchy; adding a third size is usually a mistake.
- **Track-tight on the two display sizes:** `-0.022em` at 34 pt, `-0.015em` at 28 pt.
  Body and mono stay at their natural tracking. Never letterspace a label to fake
  importance.
- **Line boxes:** code 13.5 pt on 22 pt; body 17 pt on 24 pt; mono metadata 12 pt on
  16 pt. Code leading is fixed — a variable code line-box breaks the 30/16-row
  arithmetic the whole layout is built on.
- **Mono is never bold.** Bold reflows a monospace line and shifts a cursor. Emphasis
  in mono is ink colour or nothing.
- **Every numeral in the product is mono** (density override): latency, durations,
  line numbers, port numbers, counts, diff stats.
- **Mono is reserved for literal data.** A monospace eyebrow or section label is the
  tell of a generated page and is banned. If the string is not a value, path, or
  command, it is not mono.
- Dynamic Type: chrome scales with the system ramp; **code scales only 100 / 115 /
  135 %**, so a line never exceeds 30 pt and portrait never scrolls horizontally. The
  explicit 11–20 pt code-size stepper in Settings is a different control and its copy
  must say so.

---

## 4. Component Stylings

**Buttons.** Flat fill or flat outline — no outer glow, no gradient, no shadow. Primary
is emerald `#34D399` at 48 pt height with `#05080E` label (a lit panel, not a
sticker); secondary is a 1 pt `#9BB0C5` at 18 % outline on transparent; destructive is
coral at 48 pt, and irreversible actions additionally need a 48 pt confirmation row
stating the consequence. Pressed state is `scale 0.96` / 80 ms plus
`UIImpactFeedbackGenerator(.light)` — never a colour change alone. A button's label is
the outcome: "Commit & push", "Pull then push", "Copy code", "Connect a host". Never
"Submit", never "Continue" when the verb is known.

**Key caps.** 48 × 48 pt, radius 8 pt, `#111926` fill, 1 pt `#9BB0C5` at 12 % edge,
13.5 pt mono glyph in Ice Ink. The RUN slot is 72 pt wide, emerald fill, 12 % emerald
hairline behind it in the mode ring. Pressed: 96 % scale for 80 ms. Disabled (read-only
file): 40 % opacity, accessibility label still announced, no haptic.

**Bars.** One 64 pt block at the bottom, two faces, never both: key row when text is
focused, mode ring when nothing is focused. Page dots live in the lower 8 pt inset and
cost no height. No row may exceed 64 pt.

**Cards.** Used only when elevation encodes hierarchy; in a dense list a 1 pt
`#9BB0C5` at 10 % top divider plus negative space beats a card. When used: radius
12 pt (`IDETheme.cardRadius`), `#111926` fill, whisper border, and a shadow tinted to
the background hue at ≤ 6 % — never the default black 10 % drop.

**Sheets.** Native presentation, minimum `.medium` detent, 36 × 4 pt grabber, 22 pt
title, 48 pt footer primary. A smaller detent leaves fewer than eight 44 pt rows and
is not allowed.

**Inputs.** 44 pt (48 pt in Connect) field height, label above, error below in coral,
helper text as 12 pt mono `#9BB0C5`. Focus is a 1 pt azure rule plus a 14 % azure wash
— not a ring, not a border on every edge, no floating labels.

**Loaders.** No spinners anywhere. Skeletons match the exact final dimensions and
radius; long operations show text state — the device-flow wait is three dim lines and
a countdown, a running task is a live mono duration chip in the row.

**Empty states.** No illustration — brand law: a mark, a wordmark, mono type, nothing
else. Micro mark at 64 pt, three lines of 12 pt mono explaining what this screen is
for, and one 48 pt primary inside the thumb arc.

**Errors.** Never a red-filled screen. A 44 pt banner with the exact message from the
remote, the form still filled, and the recovery action as a 48 pt row. Failure states
must be reachable in two taps.

**Diff.** Never colour alone: every added line carries a `+` glyph and a 2 pt emerald
leading rule, every removed line a `−` and a coral rule. Background wash stays under
10 % — legibility of the code wins over the gesture.

**Glyphs.** SF Symbols or geometric marks (`▤ ⟨⟩ ▷_ ⑂ ⋯ ▶`) only. No emoji, no icon
fonts, no logo watermark over the editor.

---

## 5. Layout Principles

**The grid is arithmetic, not a suggestion.** Six columns of 48 pt with 8 pt gaps and
12 pt gutters: `6×48 + 5×8 = 328 pt` inside `402 − 24 = 378 pt` of usable width on
iPhone 16 Pro. Seven columns need 384 pt and break the 8 pt gap rule, so six is the
maximum. The key row is the single exception — five 48 pt keys plus one 72 pt action
slot (`5×48 + 72 + 5×8 = 352 pt`) — because RUN must be reachable while typing.

```
┌──────────────────────────────────────────┐
│ 59   island / connection pill            │  text only, no pulse
├──────────────────────────────────────────┤
│ ‹   RunestoneView.swift •      ⌄    ⋯    │  44  one row, never grows
├──────────────────────────────────────────┤
│ 12 │ func makeEditor() {                 │
│ 13 │   let view = EditorView()           │  673 reading / 371 typing
│ 14 │   view.theme = .iDEObsidian         │  true black, gutter 24
├──────────────────────────────────────────┤
│ [←][→][↕][Tab][⌫]        [ RUN ▶ ]       │  64  the only filled key
│            ●○○                           │  dots in the 8 pt inset
├──────────────────────────────────────────┤
│                ▁▁▁▁▁▁ home               │  34
└──────────────────────────────────────────┘
```

- **One idea per screen. The transition is the navigation.** No tab bar, no floating
  action button, no top toolbar beyond the 44 pt document strip. Files, Editor,
  Terminal, Git are four full-bleed screens swapped from the mode ring.
- **Primary controls live in the bottom 35 %.** Hit targets 44 pt minimum, 48 pt for
  the coding bar, ≥ 8 pt between targets. Nothing irreversible sits above the middle
  of the screen.
- **No overlapping, ever.** No text over imagery, no card stacked on a card, no
  absolute-positioned badge over a label. Every element owns its cell.
- **Structural devices must carry information.** A divider separates two things that
  differ; a `▤ ▷_ ⑂` glyph names a destination; a 2 pt rule marks provenance. Numbered
  markers only where the content is genuinely a sequence, which in this product is
  only the onboarding pages.
- **Web and marketing surfaces** (`ide-mobile-studio.html`, README, OG cards): grid
  first, `max-width: 1400px`, `min-height: 100dvh` (never `height: 100vh`), 1 rem
  mobile / 2 rem tablet / 4 rem desktop gutters, section gaps
  `clamp(3rem, 8vw, 6rem)`. Banned: the three equal cards in a row (use a 2-column
  zig-zag or an asymmetric bento `2fr 1fr 1fr`), centred hero sections, and any
  `calc()` percentage flex maths.

---

## 6. Motion & Interaction

| Event | Motion | Haptic |
|---|---|---|
| Key tap | `scale 0.96`, 80 ms | `.light` |
| Tint / state change | 120 ms cross-fade | none |
| Mode switch | cross-fade 120 ms, no slide | none |
| Sheet present / dismiss | native, `.medium` detent | none |
| Command or task run | none — text state change | `.medium` |
| Success | emerald dot, 600 ms, then idle | `.success` |
| Failure | coral banner in 120 ms | `.error` |
| Reconnect | banner text updates only | none |

- **No linear easing, and no loops.** Nothing in the app pulses, shimmers, floats, or
  typewriters on a loop. A live latency pill that breathes is the single most common
  AI-generated detail and this product's OLED discipline forbids it: the pill updates
  its text at most every 5 s and is otherwise still. The caret blinks at 1 Hz only
  while idle.
- **One orchestrated moment per product:** the onboarding screen 3 arrow drawn to the
  bottom 35 %. Everything else answers a tap.
- **Web surfaces** use spring physics (`stiffness: 100, damping: 20`), animate
  `transform` and `opacity` only, mount lists without a cascade, and reserve one
  page-load sequence — if any — for the hero, never for each section.
- **Reduce Motion** makes every scale and fade instant. Haptics have an off switch in
  Settings and every new surface must respect it.

---

## 7. Hero and First Screen

**App first screen — Workspaces.** 34 pt header, one line, 16 pt gutters, no subtitle
and no eyebrow. Rows are 72 pt: 44 pt squircle glyph (`#111926`, radius 12), 17 pt
title, 12 pt mono subtitle carrying protocol and live latency. Trailing chip is a cyan
mark plus `14 ms`, or a coral `!` with an accessibility label. The add row is sticky at
the bottom of the list, inside the thumb arc. Nothing above it is decorative.

**Marketing hero** (if a landing or OG surface is generated): open with the most
characteristic object in the product's world — the 64 pt thumb bar under live code —
not with a headline over a gradient. The signature move is **inline image
typography**: a single small, rounded, crisp screenshot of the bar or the pill set at
type height between the words of the headline, acting as punctuation. It stacks below
the headline below 768 px. One primary CTA, maximum. Banned in the hero: centred
layout, "scroll to explore", scroll arrows, bouncing chevrons, more than one CTA,
abstract 3D renders, and invented metrics.

---

## 8. Copy Voice

Plain verbs, sentence case, no exclamation, no apology, no personality at the user's
expense. An action keeps its name through the whole flow: the button that says
"Commit & push" produces "Committed and pushed". Errors state what happened and what
to do, in the interface's voice: "Push rejected — the remote has newer commits. Pull
then push." Empty states invite the next action instead of describing emptiness.

Banned copy: "Elevate", "Seamless", "Unleash", "Next-Gen", "Revolutionize", "Oops",
"Something went wrong", "Scroll to explore", "Swipe down". Banned structure:
`LABEL // YEAR`, `WORD — fragment` eyebrows, tracked-out ALL-CAPS labels.

Real names only: files, hosts and repositories that exist or look like they exist
(`RunestoneView.swift`, `groove-labz/api`, `dev.groove-labs.net`). No "Acme", "Nexus",
"John Doe", no `99.99 %`, no invented uptime or response-time figures — if the value
is not live, it is `[metric]`.

---

## 9. Anti-Patterns (Banned)

- No pure black as UI chunk (editor text surface only), no tinted `#0B0B0B` standing in
  for obsidian, no warm/cool grey mix in one screen.
- No purple/violet neon gradient, no neon outer glow, no gradient text on headers, no
  azure field above 14 % of a surface.
- No `Inter`; no `Times New Roman`, `Georgia`, `Garamond`, `Palatino`; no serif at all.
- No monocase eyebrow labels, no numbers in a sans face, no bold mono.
- No emoji anywhere — UI, code, alt text, commit messages.
- No circular spinners; no pulsing status dot; no shimmer on chrome.
- No centred hero, no "3 equal cards" row, no overlapping text over imagery.
- No floating action button, no tab bar, no top toolbar beyond the 44 pt strip, no
  glassmorphism reskin of the editor.
- No cards around code, no card-and-shadow on dense lists, no `shadcn` default radii.
- No illustration, mascot scene, or empty-state art — the brand is a mark, a wordmark,
  mono type.
- No fabricated data, fake metric sections, fake round numbers, or placeholder
  personas.
- No light-mode screen generated for this product. Dark is the design; the paper theme
  is an audit fallback, not a look.
- No custom mouse cursors, no `z-index` spam, no `h-screen`, no `calc()` percentage
  layout maths.

---

## 10. Screen Generation Contract

When prompting Stitch (or any generator) from this document, append:

> Generate in the iDE system: Machined Obsidian `#05080E` chrome, `#000000` only as the
> full-bleed code surface, Ice Ink `#F4F9FD` text, Alloy `#9BB0C5` metadata, one
> Electric Sky `#38BDF8` accent for state and emerald `#34D399` for the single primary
> action. Six 48 pt columns, 8 pt gaps, 12 pt gutters, 44 pt rows, a 64 pt bottom block
> and a 44 pt document strip. SF Pro and SF Mono only, no serif, mono for values only.
> No glow, no gradient, no pulsing, no illustration, no spinners, no emoji. Density 9,
> variance 4, motion 3. Do not add navigation the product does not have — no tab bar,
> no FAB, no settings gear on the editor.
