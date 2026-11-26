# iDE — iOS Port Research & Phased Build Plan

Status: research + plan, 2026. Companion to `docs/MOBILE-WORKFLOW.md`, grounded in
`brand/tokens.css`, `brand/design-tokens.json`, and `ide-mobile-studio.html`.

The screen-level contract is `docs/DESIGN-PLAN.md`: screen inventory, the 6×48 pt
grid, layout arithmetic for the keyboard-up editor, semantic colour aliases, and a
binary design gate per phase. This document stays the source of truth for
architecture, App Store posture, and phase scope.

---

## 0. Verdict in five lines

1. **Do not ship a WKWebView wrapper around vscode.dev / Codespaces.** It is the
   fastest demo and the slowest product: Apple can reject it under 4.2 (minimum
   functionality) and 4.2.7(e) (thin clients for cloud-based apps), and on a
   6.1" screen VS Code's chrome is unusable without a keyboard.
2. **Build a native SwiftUI shell with a native code editor as the primary
   surface.** That is what makes it *comfy*, and it is what makes it shippable.
3. **Keep the webview — as the *fallback* mode** for OpenVSCode Server, JetBrains
   Gateway, and any host you don't have a native adapter for.
4. **Do not run code on the device in v1.** Execute remotely (SSH / Codespaces)
   and stream output into a native terminal sheet. This removes 80% of the
   App Store risk and 90% of the engineering.
5. **The hardest 20% is text input, not networking.** Budget your best weeks
   there (Phase 2). Everything else is plumbing.

---

## 1. What you are actually porting

"Visual Studio on iOS" is five separable products. Each has a different cost.

| Job | Desktop dependency | On iOS | Cost |
|---|---|---|---|
| **See code** (tree, syntax, search) | file system | local Files/iCloud + remote over SSH | low |
| **Edit code** (cursor, indent, selection) | NSTextView + 100 kbd shortcuts | must be invented for touch | **very high** |
| **Run code** (terminal, tasks, ports) | local shell | remote shell only, or an embedded interpreter | high |
| **Version** (diff, commit, push) | git CLI | libgit2 or host REST API | medium |
| **Extend** (extensions, LSP) | Node sidecar | remote LSP over the session, or nothing | medium |

The MVP is jobs 1, 2, 4. Job 3 arrives as a remote shell. Job 5 is post-1.0.

---

## 2. The three architectures, scored

| | **A. Webview wrapper** | **B. Native shell + native editor** | **C. Full remote client (RDP-like)** |
|---|---|---|---|
| Time to first demo | days | 3–4 weeks | weeks |
| Feel on a phone | poor | **good** | poor (latency, no touch model) |
| Works offline | no | **yes** | no |
| App Review risk | **high** (4.2, 4.2.7e) | low | **blocked** (4.2.7e) |
| Extensions | free (all of them) | none in v1 | free |
| Big-file performance | Safari-limited | native, good | host-limited |
| Keyboard / cursor control | fights WKWebView | full `UITextInput` control | none |
| Verdict | **fallback mode only** | **build this** | **do not build** |

Option C is explicitly out: guideline 4.2.7(e) — *"Thin clients for cloud-based
apps are not appropriate for the App Store."* Pixel-streaming VS Code cannot be
the product. (Streaming *your own* devcontainer's screen is the same thing with
extra steps.)

---

## 3. The decision

**Native shell, native editor, pluggable transports, webview escape hatch.**

```
┌─────────────────────────────────────────────┐
│ SwiftUI shell  (tokens from brand/)         │
│  ├ Connection pill  ◇ Dynamic Island / caps │
│  ├ File tree / Quick Open  ⌘P-as-sheet      │
│  ├ Editor  ── Runestone (tree-sitter)       │
│  ├ Thumb bar (48pt, bottom 35%)             │
│  ├ Sheets: terminal · palette · diff · git  │
│  └ FallbackWebView  (OpenVSCode / Gateway)  │
├─────────────────────────────────────────────┤
│ WorkspaceProvider  (protocol)               │
│  ├ LocalProvider      Files + iCloud        │
│  ├ SSHProvider        swift-nio-ssh         │
│  ├ CodespacesProvider GitHub API + tunnels  │
│  └ WebProvider        WKWebView URL         │
└─────────────────────────────────────────────┘
```

One protocol, four transports. The editor never knows where bytes came from.
This is the single design decision that lets Phase 3 be additive instead of a
rewrite.

### Editor choice — decided

| Library | Licence | Fit | Verdict |
|---|---|---|---|
| **Runestone** | MIT | iOS-first, tree-sitter, `UITextView`-backed so IME/undo/accessibility come free | **pick this** |
| STTextView | **GPLv3 or paid commercial** | TextKit 2, excellent, iOS 16+ | great, but the licence is a business decision — revisit only if Runestone's ceiling is hit |
| CodeEditTextView / CodeEditSourceEditor | MIT | AppKit-oriented (`NSView`), macOS-first | not for iOS v1 |
| Highlightr | MIT | simple `UITextView` + highlight.js | fallback if Runestone integration fights you |
| Hand-rolled TextKit 2 | — | — | never in v1 |

**Phase 0 must validate** that Runestone's input path gives you clean
`UITextInput` delegate control on iOS 18+ before committing. It is the one
assumption worth a week.

---

## 4. The five constraints that decide the whole UX

These are the things that separate "comfy" from "a desktop UI in a phone frame".

1. **Keyboard occlusion.** The thumb bar must ride above the keyboard, not be
   covered by it. Use `keyboardLayoutGuide` + `safeAreaInset(edge: .bottom)`.
   The editor's visible area shrinks to ~200 pt on an iPhone in portrait — design
   the layout around that number, not around the mockup.
2. **There are no arrow keys.** iOS has no software cursor keys and no Ctrl. The
   thumb bar therefore *is* the keyboard for a developer: `← ↑ ↓ →`, `Tab`,
   `{ } ( ) [ ]`, `" '`, `;`, `=`, and a "symbols" second page. This is the
   feature people will judge the app on.
3. **No more than one idea per screen.** On iPhone, the file tree, the editor,
   the terminal, and the diff are four full-bleed screens with a shared 48 pt
   bar — not four panes. On iPad they become panes.
4. **Autocorrect and smart punctuation must be off, always.** `UITextAutocorrectionType.no`,
   `.smartQuotesType = .no`, `.smartDashesType = .no`, `.smartInsertDeleteType = .no`.
   One smart quote in Swift and the app is dead to the user.
5. **Indentation is a model, not a view.** Tabs vs spaces, detected and preserved
   per file, applied on newline and on `Tab` inside a selection. Runestone gives
   you detection; the insert logic is yours.

The existing tokens already encode 1 and the touch geometry (`--ide-hit-recommended: 48px`,
`bottom-arc-35-percent`, `--ide-safe-*`). Reuse them verbatim; do not re-derive.

---

## 5. App Store reality check

Read against the live guidelines; the four that matter:

- **2.5.2** — apps must be self-contained and may not *download, install, or
  execute code that changes features or functionality*. The educational
  carve-out permits downloading code the user can view and edit.
  → **A native shell that edits files is safe. A shell that fetches a JS bundle
  from your server and executes it as the app's UI is the danger zone.**
- **2.5.6** — anything that browses the web uses WebKit. → webview mode must be
  `WKWebView`. No embedded Chromium, no exceptions that help you.
- **4.2** — must go beyond "a repackaged website". → this is the killer for
  Option A, and the reason the native editor must be the *default* surface.
- **4.2.7(e)** — thin clients for cloud-based apps are not appropriate. →
  deletes Option C outright.
- **4.7** — HTML5/JS plug-ins are permitted software. → if you ever add
  extensions, the sanctioned shape is sandboxed JS inside WebKit, plus an index
  of what is available (4.7.4). Not in v1.

**Practical posture:** native editor + local and remote file access + built-in
terminal client reads as a *developer tool*, which is what the App Store already
accepts in the "code editor" category. A webview that loads remote VS Code reads
as a *thin client*, which it rejects. Ship the former, keep the latter behind a
"Advanced" toggle.

Also required and easy to forget: privacy manifest (`PrivacyInfo.xcprivacy`),
account deletion if you add accounts, no forced login (5.1.1(v)), and a purpose
string for network/keychain use.

---

## 6. Phases

Durations assume one developer plus agent assistance, part-time. Acceptance
criteria are binary — do not advance on "looks fine".

**Implementation status (2026-11).** Phases 1–3 are built in `ios/iDE/`. Phase 4
and 5 landed in a deliberately thinner shape: the terminal is a streamed `exec`
surface rather than a `SwiftTerm` emulator, and the language server is a
four-request LSP client (`initialize`, `didOpen`, `completion`, `definition`,
`publishDiagnostics`) rather than a full protocol surface. Phase 6 shipped its
static requirements (privacy manifest, onboarding, haptics off switch,
credential erasure) but not the submission work. Deviations and their reasons:

- **Codespaces** is not connected over its tunnel. The REST git path and the
  webview fallback both reach a codespace's repository, which is what the accept
  criterion actually tests; the tunnel needs a device-flow OAuth app registered
  before it can be shipped.
- **SSH** uses one credential at a time (the last key or password saved), pins
  the host key on first connect, and mirrors the remote tree into Application
  Support. Push-back is per-file over `base64`, not SFTP.
- **GitHub git** goes through blobs → tree → commit → ref with `force: false`,
  so a moved branch produces the "pull, then push" state instead of a silent
  overwrite.
- **lpBOT** has no bundled endpoint; it is off until a model endpoint and name are
  set in Settings, and it only ever sends the selection.
- **Live Activities** are not built: a task's duration lives in the terminal
  sheet header, and a widget extension is the missing piece.

### Phase 0 — De-risk the two unknowns (1 week)

Build a Throwaway app, two screens, hardcoded local bundle. Answer only:

- Does Runestone accept paste, IME, dictation, and undo on iOS 18 without
  fighting? Does a 48 pt accessory row with `← ↓ ↑ → Tab` feel right at
  `--ide-type-code` (13.5 pt)?
- Can `swift-nio-ssh` open a session and round-trip `cat` on a real host?

**Accept:** you can type 40 characters of Swift on a phone without wanting to
throw it. **Fail:** swap to STTextView (pay for the licence) or Highlightr and
re-run the week.
**Duration gate:** if Phase 0 takes 3 weeks, the project is not viable as scoped.

---

### Phase 1 — Native skeleton, read-only (2–3 weeks)

Themed shell only: token-driven `Theme` object, workspace list, file tree as
`List` with `DisclosureGroup`, syntax-highlighted read-only viewer, in-file
search, Quick Open. No persistence, no editing, no network beyond LocalProvider.

- Everything 44 pt minimum, thumb bar 48 pt, OLED `#000000`, canvas `#05080E`.
- Dynamic Type respected through the token ramp 11→34 pt.
- VoiceOver labels on the tree and bar.

**Accept:** open the repo's own `brand/` folder and read `tokens.css` in dark
mode at 200% Dynamic Type with no clipping. Internal TestFlight build exists.

---

### Phase 2 — The editor you can actually use (3–4 weeks) ← the make-or-break

- Runestone integration, line numbers, `--ide-type-code`, horizontal scroll off
  in portrait / on in landscape.
- **Thumb bar v1:** cursor cluster, Tab, bracket pairs, `;`, `=`, undo, escape.
- Indent engine (spaces/tabs detected per file, `Tab` in selection indents block).
- Find & replace with regex; quick-jump to line.
- Autosave with debounce + conflict guard; crash-safe write buffer.
- iPad: hardware keyboard, `.keyboardShortcut` set, split view, second pane.
- Haptics wired to tokens: `.light` on key tap, `.medium` on command run.

**Accept:** edit a real 800-line Swift file for 10 minutes on an iPhone without
a single accidental cursor jump, and with autocorrect never once changing what
you typed. If this does not pass, nothing later matters.

---

### Phase 3 — Round trip: it talks to the world (3–4 weeks)

- `WorkspaceProvider` protocol; `LocalProvider` (Files, iCloud, security-scoped
  bookmarks) and `SSHProvider` (Keychain-stored key, `swift-nio-ssh`).
- **Git:** `GitHubRestProvider` first (commit via blobs+tree, push in one call —
  no libgit2 build), `libgit2` later for real branching. Show diff before commit.
- `CodespacesProvider`: OAuth device flow → list → connect over its tunnel.
- Connection pill in the status bar (Dynamic Island on supported devices):
  host, protocol, live RTT. This is the repo's signature UI idea — ship it here.
- WebProvider + "Advanced" toggle for OpenVSCode/Gateway users.

**Accept:** clone a repo on iPhone, edit a file, view the diff, commit, push to
GitHub, and see the commit on github.com. Then do it again over SSH to a real
devcontainer.

---

### Phase 4 — Run it (3–4 weeks)

- `SwiftTerm` terminal sheet (pull-up, keyboard-aware, scrollback, selection).
- Task runner: named commands from a workspace `.ide/tasks.json` (or VS Code's
  `.vscode/tasks.json`), streamed over the same session.
- Port forwarding list with copyable URLs; "open in Safari" hand-off.
- Build lifecycle → haptics (`.success` / error) → Live Activity for long tasks.
- Log viewer sheet, ANSI-coloured, filterable.

**Accept:** `npm test` in a Codespace from a phone, read the failure, fix it,
re-run, all without leaving the app.

---

### Phase 5 — Make it smart (4 weeks, then ongoing)

- **LSP over the existing session** — completions, diagnostics, hover, Go to
  Definition in a bottom sheet. Reuse the remote server's language servers; do
  not build a language stack.
- `lpBOT` inline assist: explain selection, refactor selection, generate from
  comment. Selection-scoped only; never a whole-file rewrite.
- Share extension (send a file to the workspace), Files provider so other apps
  can see workspaces, iPad Stage Manager polish.

**Accept:** a missing import is flagged in-editor and one tap inserts the import.

---

### Phase 6 — App Store hardening (2 weeks)

Privacy manifest, purpose strings, account deletion, onboarding that explains
"your code runs on your server", App Review notes with a demo Codespace and a
demo SSH host, checklist against the 4.x guidelines above, light-mode and
accessibility audit, 200% text, VoiceOver pass, haptics off switch.

**Accept:** submitted, and the review notes pre-empt the "is this a thin client"
question before a reviewer asks it.

---

## 7. The thinnest comfy slice

If you only ever ship one thing, ship this — it is Phases 1 + 2 + a single
transport (3 weeks after Phase 0):

> Open a repo → see the tree → open a file → move the cursor to the exact
> character you meant → type it → save → see the diff.

Nothing else in this document beats that. Everything else is additive.

---

## 8. Explicit non-goals for v1

- Running compilers, interpreters, or a VM on device.
- Extension marketplace / `.vsix` loading.
- Remote desktop or screen-streamed VS Code (blocked by 4.2.7(e)).
- Multi-repository workspaces, merge conflict editor (v1 = "resolve on the host").
- Liquid Glass / iOS 26+ chrome reskin (do it after the editor works).
- Android, Mac Catalyst, visionOS.

---

## 9. Risks, ranked

| Risk | Likelihood | Mitigation |
|---|---|---|
| Text input on iPhone is worse than expected | **high** | Phase 0 gate; thumb bar is a first-class product surface, not a toolbar |
| App Review calls it a thin client | medium | native editor is the default surface; ship webview behind "Advanced" |
| Runestone licence/ceiling | low | MIT; STTextView commercial licence is the documented escape |
| `swift-nio-ssh` maturity for interactive shells | medium | Phase 0 validates; fall back to libssh2 via a thin C shim |
| Git on-device is a tar pit | medium | REST-API provider first; libgit2 only when branching is genuinely needed |
| Codespaces auth churn | medium | keep `WebProvider` as the zero-maintenance path |
| Scope creep into "desktop IDE in a phone" | **high** | the Phase gate question: *does this make typing code on a phone better?* If no, it waits |

---

## 10. What this repository already gives you

- `brand/tokens.css` + `brand/design-tokens.json` → generate `Theme.swift`
  directly (DTCG → Swift constants). Single source of truth, zero drift.
- `brand/ios/AppIcon.appiconset` → the Xcode icon set is already built and
  correctly sized.
- `ide-mobile-studio.html` / `-v2.html` → the thumb bar, sheet geometry, and
  connection pill are already designed and interactive. Port the *layout*, not
  the HTML.
- `docs/MOBILE-WORKFLOW.md` → already establishes that a `.git` directory cannot
  live in a cloud-shimmed folder. The app must own a local container for
  workspaces; Working Copy stays the external git escape hatch.
- Design contract to keep: 44 pt minimum, 48 pt coding bar, ≥8 pt gaps, bottom
  35% thumb arc, `#000000` / `#05080E` only.

**Fonts:** bundle **JetBrains Mono (OFL)** for the editor rather than shipping
SF Mono — SF Mono's licence is limited to Apple-platform UI use. Keep SF Pro for
chrome via the system font. The tokens already name JetBrains Mono as the mono
fallback, so this needs no token change.
