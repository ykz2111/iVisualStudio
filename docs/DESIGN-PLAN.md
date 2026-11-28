# iDE — iOS Design Plan (screen contract)

Status: design plan, 2026. Companion to `docs/IOS-PORT-PLAN.md` (build plan) and
`docs/MOBILE-WORKFLOW.md`. Every value below is a token from `brand/tokens.css` /
`brand/design-tokens.json` or arithmetic on those tokens. **No new hex.**

Prepared by the `ios-ui-designer` subagent pass, coordinated against
`.opencode/agents/ide-coordinator.md`. Where this document and the build plan
disagree, the build plan wins on *what gets built*; this document wins on *what it
looks and measures like*.

---

## 0. Scope

| This document decides | This document does not decide |
|---|---|
| Screen inventory, navigation model, layout arithmetic | SwiftUI types, module boundaries, `WorkspaceProvider` shape |
| Per-surface measurements in pt, grid, hit targets | Runestone/STTextView integration details |
| Semantic colour roles → token aliases | Transport/auth implementation (SSH, Codespaces, REST git) |
| Type ramp usage, motion, haptics | Release sequencing (phases are the build plan's) |

Everything routed here uses the stack in `.opencode/skill-stack.json`:
`mobile-design` (geometry), `ui-design-system` (grid, type, contrast),
`claude-design` (surface-first composition), `ip-as-logo` (marks),
`macos-golden-gate-design` (pane restraint on iPad only).

---

## 1. Ten decisions that decide the app

1. **One grid, everywhere: 6 columns of 48 pt with 8 pt gaps and 12 pt gutters.**
   `6×48 + 5×8 = 328 pt` inside `402 − 24 = 378 pt` of usable width on iPhone 16
   Pro. 7 columns would need 384 pt and break the 8 pt gap rule, so 6 is the
   maximum — and it makes the mode ring and every sheet footer the same rhythm.
   The key row is the single exception: **5 key slots + one 72 pt action slot**
   (`5×48 + 72 + 5×8 = 352 pt`), because RUN must be reachable *while typing* —
   edit-then-run is the loop the app exists for, and it may not cost a keyboard
   dismissal.
2. **The bottom block is a two-state machine, never both at once.** Focused text
   surface → *key row* (48 pt keys, the developer's keyboard, RUN on the right).
   No focus → *mode ring* (Files · Editor · Terminal · Git · ⋯ · RUN). The editor
   is the visible product, so nothing idle sits above it, and RUN survives both
   states.
3. **One idea per screen. The transition is the navigation.** There is no tab bar
   and no top toolbar beyond a 44 pt document strip. Files, Editor, Terminal, Git
   are four full-bleed screens swapped from the mode ring; iPad turns them into
   panes (§9).
4. **Editor surface is true black `--ide-bg-oled-true`; chrome is canvas
   `--ide-bg-canvas`.** The editor is the surface you stare at for an hour, so it
   gets the zero-smear OLED black; navigation gets the obsidian chassis so panes
   read as separate objects. Sheets are `--ide-bg-elevated`, key rows
   `--ide-bg-thumb-bar`.
5. **Line numbers use `--ide-ink-secondary`, not muted.** The token file states
   muted (`#64748B`) is ~4.2:1 and decorative-only; a line number is information
   you act on. Muted is reserved for placeholder text and disabled glyphs.
6. **`--ide-signal-vscode` is a rule-and-fill colour, never body text on canvas**
   (measured ~4.4:1 — see §7). It is the "this came from VS Code" accent: tab
   underlines, 2 pt rules, the 🄿 badge on workspace rows.
7. **Diff is never colour-only.** Every added line carries a `+` glyph and a 2 pt
   emerald leading rule; every removed line a `−` and a coral rule. Colour is the
   second signal, not the only one (§8).
8. **Nothing pulses.** The connection pill updates text at most every 5 s and
   never animates a loop. Motion is: key press 80 ms scale, tint 120 ms, sheet
   presentation native. `prefers-reduced-motion` equivalent (Reduce Motion) zeroes
   the first two.
9. **Every destructive or irreversible act gets a 48 pt confirmation row, not a
   gesture.** Force-push, discard-hunk, delete-branch, close-with-unsaved: the
   confirm button is `--ide-signal-coral`, 48 pt, thumb arc.
10. **Design ships against phases, not vibes.** Each phase in the build plan has a
    design deliverable and a binary acceptance check (§10). Nothing is "looks
    fine".

---

## 2. Layout arithmetic (the number the mockups must answer to)

Assumptions: iPhone 16 Pro portrait, `402 × 874 pt`. Token safe areas
`--ide-safe-top-island: 59`, `--ide-safe-bottom-home: 34`. Code line box
`--ide-type-code: 13.5 pt` at `line-height 22 pt` (the studio's 1.6 ratio).
iOS QWERTY portrait height ≈ 336 pt including the predictive bar — **verify in
Phase 0; if it is 300 or 360, only the line counts change.**

| Block | pt | Note |
|---|---|---|
| Top safe area | 59 | `--ide-safe-top-island` |
| Document strip | 44 | back · filename · dirty dot · ⋯ |
| Editor viewport, keyboard down | 673 | 874 − 59 − 44 − 64 (mode ring) − 34 |
| Editor viewport, keyboard up | 371 | 874 − 59 − 44 − 64 (key row) − 336 |
| Mode ring / key row block | 64 | 8 + 48 + 8 (`--ide-hit-recommended` + `--ide-space-2`) |
| Home indicator | 34 | overlaid by the keyboard when it is up |

**Consequences the design must honour:**

- 30 lines of code visible when reading, **16 when typing**. Sixteen lines is
  enough to work; it is not enough to keep a 44 pt header *and* a 48 pt footer
  *and* a sheet on screen. Hence decision 2.
- The document strip is 44 pt because it is the only chrome that survives a
  keyboard. It may not grow a second row.
- Minimum sheet detent is `.medium` (437 pt) — a smaller palette would leave
  fewer than 8 result rows at 44 pt. Palette rows: 8 visible, scroll for more.

---

## 3. Navigation model

```
Workspaces ──▶ Connect ──▶ (host sheet) ──▶ Editor
     │                                        
     └────▶ Files ──▶ Editor ──▶ Terminal / Git / ⋯     
                        ▲            (mode ring, keyboard down)
                        └─ key row ──┘ (keyboard up)
```

- Left-edge swipe pops one screen (safe: the editor disables horizontal scroll in
  portrait per the build plan, so the gesture cannot fight the text view).
- Sheets are the second storey: Quick Open, Find, Command Palette, Diff, Ports,
  lpBOT. All use the same grabber (36 × 4 pt) and the same 48 pt footer primary.
- The mode ring's `⋯` opens Command Palette (Phase 2) / app-level actions (Phase
  3: Sync, Settings, Disconnect).

---

## 4. Screen inventory

Phases refer to `docs/IOS-PORT-PLAN.md` §6.

| ID | Screen | Phase | Primary action | States designed |
|---|---|---|---|---|
| S1 | Workspaces | 1 | Open workspace | empty · loading · local-only · remote-broken |
| S2 | Connect | 3 | Connect or open a Web IDE | browser sign-in · repository/branch launch · SSH host-key verification · auth expired · bad token |
| S3 | Editor | 1 (read) / 2 (write) | Type | read-only · editing · saving · conflict · unsaved-on-close |
| S4 | Thumb bar (component) | 2 | Insert character / move caret | page 1–3 · disabled-in-read-only |
| S5 | Quick Open (sheet) | 1 | Open file | typing · no results · > 2 000 files |
| S6 | Find & Replace (sheet) | 2 | Replace · Replace all | no match · regex error · replace preview |
| S7 | Command Palette (sheet) | 2 | Run command | recents-first · empty query |
| S8 | Terminal (sheet) | 4 | Send key | connecting · running · exited · long-task |
| S9 | Git / Diff (screen + sheet) | 3 | Commit & Push | selected files · clean · push rejected · host conflict |
| S10 | Ports & Tasks (screen) | 4 | Open URL · Run task | none forwarded · task failed |
| S11 | Diagnostics (inline + sheet) | 5 | Fix | warning · error · stale |
| S12 | lpBOT (sheet) | 5 | Apply to selection | thinking · proposal · rejected-by-user |
| S13 | Settings | 3 | — | haptics off · advanced webview on |
| S14 | Fallback WebView | 3 | Reload | loading · loaded · WebKit error |
| S15 | Onboarding | 3 | First connect | 3 pages · skip |
| S16 | System states (banners) | 1 | Reconnect | reconnecting · offline · app-update required |

---

## 5. Surface specs

### S4 · Thumb bar — the product's second screen

Two faces, one 64 pt block, one set of measurements: `--ide-hit-recommended: 48 px`
heights, `--ide-hit-gap-min: 8 px` gaps, 12 pt outer gutters, radius 8 pt
(studio-local `--studio-radius-sm`; promote to `--ide-radius-key` when tokens are
next touched). The mode ring uses the six equal columns; the key row uses five
columns plus the 72 pt RUN slot (§1, decision 1).

**Face A — key row** (text surface focused, above the keyboard).
Layout: `[key][key][key][key][key]   [ RUN ▶ ]` — five 48 pt keys and one 72 pt
emerald action, 8 pt gaps, total 352 pt of 378 pt usable.

| Page | Keys (left → right) | Why |
|---|---|---|
| 1 · caret | `←` `→` `↕` `Tab` `⌫` | horizontal arrows stay separate (the common precision move); `↕` moves a whole visual line — upper half up, lower half down, two 4 pt chevrons as the glyph |
| 2 · pairs | `{}` `()` `[]` `""` `''` | one tap inserts the pair with the caret between; long-press inserts only the opening character |
| 3 · symbols | `;` `=` `:` `#` `$` | the five characters that cost the most keystrokes and sit three keyboard layers deep |

RUN is constant across all three pages: it is the one thing that never changes, so
it gets the slot that never changes.

Page switching: horizontal swipe on the key row, with a 4 pt dot strip (three 4 pt
dots, active = `--ide-signal-azure`) under the keys. Long-press the row opens a
page picker — a 44 pt sheet, not a menu.

- Press feedback: `scale 0.96`, 80 ms, then `UIImpactFeedbackGenerator(.light)`.
- Held repeat: `←/→/↕/⌫` repeat after 400 ms at 60 ms (matches iOS caret feel).
- Disabled in read-only files: 40% opacity, `accessibilityLabel` still announced,
  no haptic.

**Face B — mode ring** (nothing focused):

| Slot | Glyph | Destination |
|---|---|---|
| 1 | ▤ | Files (S-tree) |
| 2 | ⟨⟩ | Editor (S3) |
| 3 | ▷_ | Terminal (S8) |
| 4 | ⑂ | Git (S9) |
| 5 | ⋯ | Command Palette / actions |
| 6 | ▶ | **RUN** — `--ide-signal-emerald` fill, 12% emerald background |

RUN is the only filled key in the app. Current destination is `aria-selected`
equivalent: 12% azure wash + 1 pt azure top rule.

**Where the two faces never compromise:** no row may exceed 64 pt, because 30 pt
of editor is worth more than a fifth control.

### S3 · Editor

```
┌──────────────────────────────────────────┐
│ 59   island / connection pill            │
├──────────────────────────────────────────┤
│ ‹   RunestoneView.swift •      ⌄    ⋯    │ 44
├──────────────────────────────────────────┤
│ 12 │ func makeEditor() {                 │
│ 13 │   let view = EditorView()           │ 673 / 371
│ 14 │   view.theme = .iDEObsidian         │
├──────────────────────────────────────────┤
│ [←][→][↕][Tab][⌫]        [ RUN ▶ ]       │ 64
│            ●○○  (in the 8 pt inset)       │
├──────────────────────────────────────────┤
│                ▁▁▁▁▁▁ home               │ 34
└──────────────────────────────────────────┘
```

The page dots live in the block's lower 8 pt inset, so they cost no height: the
block stays `8 + 48 + 8 = 64 pt` in every state.

- Gutter 24 pt, right-aligned, `--ide-font-mono` `--ide-type-caption`,
  `--ide-ink-secondary`.
- Active line: `inset 2 pt` azure rule + azure @ 14% wash (studio values).
- Caret `--ide-signal-cyan`, 2 pt wide, 18 pt tall, no blink animation while
  typing (blink only when idle, 1 Hz — OLED smear discipline).
- Dirty dot: 6 pt `--ide-signal-amber` next to the filename; saving swaps it for a
  6 pt emerald dot for 600 ms, no spinner.
- `⌄` (outline) opens a 3-row breadcrumb sheet: file · symbol · line. `⋯` holds
  Save, Save As, Find, Share, Close.
- Syntax roles (from the studio, palette-only):
  keyword `--ide-signal-violet`, function `--ide-signal-cyan`, type
  `--ide-signal-azure`, string `--ide-signal-emerald`, number
  `--ide-signal-amber`, comment `--ide-ink-muted` italic, plain
  `--ide-ink-primary`.
- Save conflict: 44 pt amber banner between strip and text, two actions
  (Overwrite · Reload) at 48 pt.

### S1 · Workspaces

- Header `--ide-type-large-title` (34 pt), 16 pt gutters, one line only: "Workspaces".
- Rows 72 pt (`8 + 48 + 8 + caption`), leading 44 pt glyph
  (`--ide-bg-elevated` squircle, radius 12 pt), title 17 pt, subtitle 12 pt mono
  `--ide-ink-secondary` = protocol · latency.
- Trailing: connection chip (cyan dot + `14 ms`) or a coral `!` with
  `accessibilityLabel` "last connection failed".
- Empty state: no illustration. Three lines of mono copy + one 48 pt emerald
  "Connect a host" button. A brand mark (micro icon) at 64 pt above it, nothing else.
- Add row is sticky at the bottom of the list, inside the thumb arc.

### S2 · Connect

A single scrolling form, 48 pt fields, 16 pt gutters, grouped as: **Codespaces**
(device flow) · **SSH** (host, user, key, passphrase) · **Local folder** ·
**Advanced** (OpenVSCode / Gateway URL, hidden behind a toggle — App Store
posture, build plan §5).

- Device flow: 40 pt monospace code at `--ide-type-title-2` (22 pt), 48 pt "Copy
  code" + "Open github.com/login/device". Waiting state = 3 dim lines and a
  countdown, not a spinner.
- SSH host key: 48 pt trust row, fingerprint in 12 pt mono, `--ide-signal-amber`
  frame.
- Failures never red-fill a whole screen: 44 pt coral banner + retry, form stays
  filled.

### S5 · Quick Open (sheet)

`.medium` detent. 44 pt search field (mono 13.5), then 44 pt rows: filename
17 pt/mono 13.5 + 12 pt path in `--ide-ink-secondary`. Match highlight = azure @
22% behind characters, no bold-on-match (bold reflows the line). Footer: recent
files (max 4) and a 48 pt "New file" secondary.

### S6 · Find & Replace (sheet)

Two 44 pt fields stacked, 8 pt apart; toggle row for `Aa` `.*` `↺` (case, regex,
wrap) as 44 pt toggles. Result counter right-aligned in mono, `--ide-signal-coral`
when zero. Replace-all commits only after a 48 pt confirmation row that states the
count.

### S7 · Command Palette (sheet)

`.medium` detent, 44 pt rows, two columns: command (17 pt) · scope (12 pt mono,
`--ide-ink-secondary`). Fuzzy match on azure wash. Bottom 48 pt row is always
"Run custom…" (Phase 4 → task runner).

### S8 · Terminal (sheet)

`.fraction(0.45)` default, draggable to `.large`. 12 pt mono, 18 pt line box,
ANSI mapped to the signals (green→emerald, red→coral, yellow→amber, blue→azure,
magenta→violet, cyan→cyan). ANSI background tints are rejected — they invent
colour. Accessory row replaces the key row inside the sheet: `Esc` `Tab`
`Ctrl` `⌫` `↑` `↓` at 48 pt. Long-press selects; two-handle selection native.
Long tasks: emerald duration chip in the sheet header, and a Live Activity
(Phase 4) rather than an in-app animation.

### S9 · Git / Diff

Three segments, one screen: **Changes** (file list, 44 pt rows, `M`/`A`/`D`
glyphs 12 pt mono coloured emerald/azure/coral) → **Diff** (unified, inline) →
**Commit** (48 pt message field + 48 pt "Commit & Push").

Diff line: 20 pt per hunk context line, 22 pt for changed, 2 pt leading rule
(emerald for `+`, coral for `−`), no background wash above 10% — text legibility
wins. Push rejected → 44 pt amber banner with the exact remote message and a
48 pt "Pull then push" action.

### S10 · Ports & Tasks

Port rows: `3000 → localhost:3000` in 13.5 mono, 44 pt "Open" and 44 pt "Copy"
targets, 8 pt apart. Tasks list reads `.vscode/tasks.json` names, 48 pt run
buttons, live duration in the row while running.

### S11 · Diagnostics

Squiggle: 1.5 pt wavy under the span, amber for warnings, coral for errors,
`--ide-ink-muted` for hints. Tapping opens a `.fraction(0.35)` sheet with the
message, a `Fix…` 48 pt primary (Phase 5: one-tap import insert), and the file
path. No inline popovers over the caret — they occlude the line you are editing.

### S12 · lpBOT

Selection-scoped only (build plan §6 Phase 5). `.medium` sheet: the selected code
in 13.5 mono, a single-sentence proposal in 17 pt, then three 48 pt actions:
Apply · Replace · Discard. Violet is the AI role (`--ide-signal-violet`), used on
the header mark and the apply button outline — never as a fill behind text.

### S13 · Settings

Grouped list, 44 pt rows, 8 pt section gaps. Appearance (theme, code size 11–20 pt
stepper), Haptics toggle, Terminal (font size), Advanced (webview fallback
toggle), About (version, licences — JetBrains Mono OFL, Runestone MIT, no SF Mono).

### S14 · Fallback WebView

Full-bleed `WKWebView`, 44 pt top strip with the host and a reload glyph, 48 pt
"Back to native" when a file is opened from within it. Explicit label: "Advanced —
remote VS Code in WebKit". This screen must never be the default surface (build
plan §5, guideline 4.2).

### S15 · Onboarding

Three screens, one idea each: (1) *your code runs on your server* — two lines of
mono, no illustration; (2) connect something (Codespaces · SSH · folder); (3)
thumbs, not cursors — an arrow drawn to the bottom 35% with the key row highlighted.
Skip is 44 pt, always present, top-trailing.

### S16 · System states

| State | Presentation | Colour |
|---|---|---|
| Reconnecting | 44 pt banner under the strip, text updates per attempt | amber |
| Offline | Same banner, "edits kept locally" | coral |
| Auth expired | Sheet, device-flow code + copy | amber |
| Host key unknown | Sheet, fingerprint | amber |
| App update required | Full-bleed, one 48 pt button | coral |

---

## 6. Type ramp in use

| Token | Size | Used for | Never used for |
|---|---|---|---|
| `--ide-type-large-title` | 34 | Workspaces header, onboarding | sheet titles |
| `--ide-type-title-1` | 28 | Screen titles inside sheets | list rows |
| `--ide-type-title-2` | 22 | Sheet titles, device-flow code | body copy |
| `--ide-type-headline` | 17 | Primary buttons, row titles | editor text |
| `--ide-type-body` | 17 | Settings rows, lpBOT proposal | code |
| `--ide-type-code` | 13.5 | Editor, terminal-off, Quick Open filenames | labels |
| `--ide-type-caption` | 12 | Paths, latency, line numbers, badges | anything tappable alone |

Dynamic Type: chrome scales with the system ramp; **code scales only 100 / 115 /
135 %** (the studio's `data-dt` behaviour) so that a line never exceeds 30 pt and
horizontal scrolling never appears in portrait. Users who need bigger code use the
explicit 11–20 pt stepper in Settings, which is a distinct control from the system
size — that distinction must be stated in Settings copy.

---

## 7. Colour roles and contrast

Semantic aliases — **each is a `var()` of an existing palette entry; no hex is
added.** They must land in `brand/tokens.css` and `brand/design-tokens.json` in the
same commit (zero-drift rule, `.opencode/agents/ide-coordinator.md`).

| Alias | = | Role |
|---|---|---|
| `--ide-surface-editor` | `--ide-bg-oled-true` | editor + terminal canvas |
| `--ide-surface-chrome` | `--ide-bg-canvas` | navigation, list backgrounds |
| `--ide-surface-sheet` | `--ide-bg-elevated` | sheets, cards, key caps |
| `--ide-surface-key` | `--ide-bg-thumb-bar` | bar containers |
| `--ide-role-accent` | `--ide-signal-azure` | selection, focus, active tab |
| `--ide-role-live` | `--ide-signal-cyan` | connection OK, caret |
| `--ide-role-pass` | `--ide-signal-emerald` | RUN, diff add, build success |
| `--ide-role-fail` | `--ide-signal-coral` | diff remove, destructive, offline |
| `--ide-role-warn` | `--ide-signal-amber` | dirty, reconnecting, warnings |
| `--ide-role-ai` | `--ide-signal-violet` | lpBOT, keyword syntax |
| `--ide-role-legacy` | `--ide-signal-vscode` | "from VS Code" rules and badges |
| `--ide-text-primary` | `--ide-ink-primary` | all body text |
| `--ide-text-secondary` | `--ide-ink-secondary` | paths, latency, line numbers |
| `--ide-text-disabled` | `--ide-ink-muted` | placeholders, disabled glyphs only |

Contrast against `#000000` / `#05080E`. Ink rows quote the figures stated in
`brand/tokens.css`; signal rows are computed from the token values with the WCAG
sRGB formula.

| Colour | on black | on canvas | Verdict |
|---|---|---|---|
| `--ide-ink-primary` | 19.6:1 | 18.8:1 (token) | AAA |
| `--ide-ink-secondary` | 9.5:1 | 8.9:1 (token) | AAA |
| `--ide-ink-muted` | 4.4:1 | 4.2:1 (token) | decorative only, as the token comment states |
| `--ide-signal-cyan` | 14.7:1 | 14.0:1 | AAA |
| `--ide-signal-amber` | 12.6:1 | 12.0:1 | AAA |
| `--ide-signal-emerald` | 10.9:1 | 10.4:1 | AAA |
| `--ide-signal-azure` | 9.8:1 | 9.4:1 | AAA |
| `--ide-signal-coral` | 7.3:1 | 7.0:1 | AA body, AA large |
| `--ide-signal-violet` | 5.3:1 | 5.1:1 | AA body (thin) |
| `--ide-signal-vscode` | 4.6:1 | **4.4:1** | AA large only — rules, icons ≥ 17 pt, never 12 pt text |

Re-verify these with a checker in Phase 1; they are derived from the token values,
not from a design tool. Anything that fails otherwise: raise size to 17 pt or
switch role.

---

## 8. Motion, haptics, feedback

| Event | Motion | Haptic (`brand/design-tokens.json`) |
|---|---|---|
| Key tap | 96 % scale, 80 ms | `UIImpactFeedbackGenerator(.light)` |
| Mode switch | cross-fade 120 ms, no slide | none |
| Sheet present / dismiss | native, medium detent | none |
| Command / task run | none (text state change) | `.medium` |
| Build or task success | emerald dot, 600 ms | `UINotificationFeedbackGenerator(.success)` |
| Failure | coral banner appears in 120 ms | `.error` via `UINotificationFeedbackGenerator` |
| Reconnect | banner text only, no shimmer | none |

Reduce Motion: scales and fades become instant. Haptics toggle in Settings
(Phase 6 requires it). No looping animation anywhere in the app; OLED longevity is
part of the brand promise (`oled-zero-smear` badge) and a pulsing pill contradicts
it.

---

## 9. iPad adaptation (Phase 2+)

- Same grid; the 6-column rule survives at any width because key caps grow, not
  multiply (52–56 pt caps on iPad, still ≥ 8 pt gaps).
- Panes: Files 320 pt sidebar · Editor flexible · Terminal as a bottom sheet
  (`.medium`) rather than a third column, so the code keeps the centre.
- Hardware keyboard attached → the key row hides entirely; the mode ring becomes a
  48 pt floating bar anchored bottom-trailing, within 60 pt of the trailing edge
  (still a thumb/stylus reach).
- `.keyboardShortcut` map mirrors the visible bar: ⌘P palette, ⌘F find, ⌘S save,
  ⌘⇧P run, ⌘⌥T terminal — the bar's labels are the legend for the shortcuts, so
  bar and keyboard cannot drift.
- Diff goes side-by-side at ≥ 900 pt width; unified below.

---

## 10. Design acceptance gate per phase

| Phase | Design deliverable | Binary check |
|---|---|---|
| 0 | Thumb bar page 1 at 48 pt with real `--ide-type-code`, on device | 40 characters of Swift typed without a mis-tap that needs undo |
| 1 | S1, S3-read, S5 built; Theme generated from tokens | `brand/` browsable at 200 % Dynamic Type, no clipping, no horizontal scroll in portrait |
| 2 | S4 all three pages, S6, S7, editor states | 10 minutes of editing, zero accidental caret jumps, zero autocorrect changes |
| 3 | S2, S9, S13, S14, S15, S16 | Commit + push from the thumb arc alone; every failure state reachable in 2 taps |
| 4 | S8, S10, Live Activity | `npm test` read and re-run without leaving the app; accessory row never hidden by the keyboard |
| 5 | S11, S12 | One-tap import fix; lpBOT never rewrites outside the selection |
| 6 | Light-mode audit, VoiceOver labels, 200 % text, haptics off | Reviewer cannot call it a thin client from screenshots alone |

---

## 11. Not designed (and why)

- **Liquid Glass reskin.** Build plan §8 defers it until the editor works; native
  components already carry it on iOS 26.
- **On-device compile/run UI.** Out of scope by 2.5.2; the terminal is a client.
- **Extension browser.** 4.7 territory, v1 says no.
- **Pulsing "live" chrome.** Contradicts OLED discipline (decision 8).
- **Light theme beyond the audit pass.** Phase 6 audit maps ink tokens onto paper
  surfaces as the studio already does (`data-theme="paper"`), but it is a fallback,
  not a designed theme.
- **Illustration.** The brand is a mark, a wordmark, and mono type. No mascot
  scenes, no empty-state art.

---

## 12. Open decisions (needed before Phase 2 layout is locked)

1. **App display name** — `iDE` or `iVisualStudio` on the home screen? Affects
   wordmark scaling and the onboarding header only.
2. **Default editor surface** — true black (this plan) or obsidian canvas for
   users who find pure black harsh? If both, Phase 1 needs a theme picker that the
   tokens already imply.
3. **Light mode in 1.0** — design it now or ship dark + audit fallback?
4. **WebView toggle home** — Connect screen's Advanced group, or Settings?
   (This plan assumes Settings, with a pointer from Connect.)
5. **iPad in 1.0** — Phase 2 includes it; the design work above is two extra
   days and two extra acceptance runs.
6. **JetBrains Mono bundling** — the plan assumes yes (OFL); confirm the licence
   file ships in About.

---

## 13. Handoff format

The `ios-ui-designer` subagent reports every review in three parts, per
`.opencode/agents/ios-ui-designer.md`:

1. **Ergonomic & safe-area check** — measured pt, gap, island/home clearance.
2. **Token & contrast compliance** — exact `--ide-*` and DTCG paths, no invented
   values.
3. **Concrete patch** — token-backed SwiftUI or HTML/CSS, no filler.

Any proposed surface that cannot name its tokens in step 2 is not ready to build.
