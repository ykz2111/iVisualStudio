<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./brand/repo-banner-dark.svg" />
    <source media="(prefers-color-scheme: light)" srcset="./brand/repo-banner-light.svg" />
    <img alt="iDE_CONCEPT — Pocket VS Code, GitHub Codespaces & Cloud IDE for iOS" src="./brand/repo-banner-dark.svg" width="100%" />
  </picture>

  <br />

  <img src="./brand/badges/alternatives/B2a.svg" alt="TestFlight" height="26" />
  <img src="./brand/badges/alternatives/B1a.svg" alt="Codespaces" height="26" />
  <img src="./brand/badges/alternatives/B4a.svg" alt="Thumb zone" height="26" />
  <img src="./brand/badges/alternatives/B3a.svg" alt="OLED" height="26" />
</div>

---

# iDE (`iVisualStudio`)

**Visual Studio Code, GitHub Codespaces, OpenVSCode Server, JetBrains Gateway & SSH DevContainers — re-engineered for one-handed iOS touch.**

Built under **Groove Labs // YkZ21**. One repository, one `iVisualStudio` remote, pushed to two hosts:

- GitLab: https://gitlab.com/groove-labz/iVisual-Studio
- GitHub: https://github.com/ykz2111/iVisualStudio

---

## Interactive Playground & Brand Studio

Open **[`./ide-mobile-studio.html`](./ide-mobile-studio.html)** in any browser to:
1. **Play with the Live iPhone 16 Pro Pocket VS Code Simulator**:
   - Tap the **Dynamic Island Tunnel Pill** (`codespace-main · 14ms`) to switch live between GitHub Codespaces, OpenVSCode Server, SSH DevContainers, and JetBrains Gateway.
   - Tap the **48pt Ergonomic Thumb-Zone Coding Bar** (`{ }`, `=>`, `⌘P`, `RUN ▶`, `lpBOT`, `3000`, `GIT`, `SSH`) to insert snippets, open the iOS Bottom-Sheet Command Palette, run builds in the pull-up terminal sheet, or invoke `lpBOT` AI refactoring.
   - Toggle the **Fitts' Law Thumb-Zone Heatmap (`H`)** and test **OLED True-Black (`#000000`)**, **Machined Obsidian (`#05080E`)**, **VS Code Dark+**, and **Outdoor Sunlight High-Contrast** themes.
2. **Customize & Export the `iDE` & `lpBOT` Icon Suite**:
   - Switch between 4 structural icon variants (`01 Pocket Code Ribbon`, `02 Mobile Coder lpBOT`, `03 iDE Geometric Prism`, `04 Cloud DevContainer Pod`), tweak colors/tilt/squircle radius, inspect the `16×16` 8× pixel loupe, and export SVGs or PNGs (`1024px`, `512px`, `180px`, `1200×630` OG, `1280×360` Repo Banner).

---

## Native iOS app (`./ios/`)

A SwiftUI shell with a native editor — built against `docs/IOS-PORT-PLAN.md`
(phases 1–3 shipped, 4–6 partial) and `docs/DESIGN-PLAN.md`.

```sh
open ios/iDE.xcodeproj    # Xcode 26+, iOS 18+
```

| Surface | What it does |
|---|---|
| Workspaces | Sample, imported folders (security-scoped bookmarks), GitHub clones, SSH hosts — all persisted across relaunch |
| Editor | Native `UITextView` editing, line numbers, indent engine, find & replace with regex, autosave with a 0.9 s debounce |
| Thumb bar | 48 pt cursor cluster, brackets, symbols page, undo/redo, above the keyboard |
| Git | Changes → unified diff (glyph + rule, never colour alone) → commit, pushed through GitHub's blobs → tree → commit → ref API |
| SSH | `swift-nio-ssh`, pinned host keys, mirrored tree with per-file push-back, terminal sheet, task runner, port list |
| Diagnostics | Minimal LSP client over the session (completion, definition, publishDiagnostics) |
| lpBOT | Selection-scoped assist against a model endpoint you name; off until configured |
| Connections | The signature pill: host · protocol · live round trip, text only, no pulsing |

Credentials live in the Keychain. No code executes on device by design (build
plan §5); the webview runs remote VS Code only behind the Advanced toggle.

---

## Mobile UX & UI Design System (`@mobile-design` + `@ui-design-system`)

| Principle | Desktop VS Code Problem on Phone | `iDE` iOS Solution |
|---|---|---|
| **Fitts' Law & Thumb Zone** | Menu bar, file tabs, and activity bar sit in the top-left stretch zone with `<28px` targets. | **48pt × 46pt (`≥8pt` gap) Thumb-Zone Coding Bar** + pull-up **Terminal & `⌘P` Bottom Sheets** in the bottom 35% arc. |
| **OLED Battery & Outdoor Legibility** | Washed-out gray themes drain OLED power and fail in sunlight. | **OLED True-Black (`#000000`)** & **Machined Obsidian (`#05080E`)** surfaces + **WCAG AAA (`>11:1`)** syntax tokens and an outdoor sunlight mode. |
| **iOS HIG & Safe Areas** | Web wrappers clip under the Dynamic Island and Home Indicator. | **Dynamic Island** becomes the live SSH/Codespace latency pill; **SF Pro / SF Mono Dynamic Type** (`11pt`–`34pt`) + native haptic feedback (`.light`, `.medium`, `.success`). |

---

## Complete Brand, Xcode & Workspace Asset Pack (`./brand/`)

See [`./brand/README.md`](./brand/README.md) for the full inventory:
- **Xcode `AppIcon.appiconset`**: `./brand/ios/AppIcon.appiconset/` (`1024`, `180`, `167`, `152`, `120`, `87`, `80`, `60`, `58`, `40` opaque 24-bit RGB PNGs + `Contents.json`).
- **Master & Micro Vectors**: `ide-icon.svg`, `ide-icon-micro.svg`, `ide-icon-mono.svg`, `ide-wordmark-{dark,light,compact}.svg`.
- **Announcements & Social**: `og-image.png` (`1200×630`), `social-announcement-square.png` (`1080×1080`), `repo-banner.png` (`1280×360`).
- **Workspace & iPhone OLED Wallpapers**: `backgrounds/ide-workspace-bg-4k.png` (`3840×2160`), `ide-workspace-bg-fhd.png` (`1920×1080`), and `ide-ios-wallpaper.png` (`1179×2556`).
- **Design Tokens**: `brand/tokens.css` & `brand/design-tokens.json` (W3C DTCG format).
