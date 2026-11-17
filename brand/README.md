# iDE (`ide_concept`) — Brand, Xcode AppIcon, Workspace & Announcement Kit

Complete identity and design-system asset pack for **`iDE` (`ide_concept`)**, built in the **Groove Labs // YkZ21** visual system and engineered with `@ui-design-system` + `@mobile-design`.

## Asset Inventory (`ide_concept/brand/`)

| File / Directory | Dimensions / Format | Purpose |
|---|---|---|
| `ide-icon.svg` | Vector (`1024×1024`) | Architectural master icon — Titanium iPhone bezel + Dynamic Island + 3D folded VS Code Azure/Cyan ribbon + `i` touch-cursor pillar. |
| `ide-icon-micro.svg` | Vector (`64u` lattice) | Pixel-snapped micro master (`16px` & `32px`) — integer grid alignment, zero blur filters. |
| `ide-icon-mono.svg` | Vector (`currentColor`) | Single-ink stencil mark for CLI headers, docs, and SF Symbol-style masks. |
| `ios/AppIcon.appiconset/` | Xcode Asset Catalog | Complete iOS/iPadOS `Contents.json` + opaque 24-bit RGB PNGs (`1024`, `180`, `167`, `152`, `120`, `87`, `80`, `60`, `58`, `40`). |
| `ide-wordmark-dark.svg` | Vector (`960×220`) | Horizontal lockup for dark UI & docs (pure vector `iDE_CONCEPT` outlines). |
| `ide-wordmark-light.svg` | Vector (`960×220`) | Horizontal lockup for daylight/paper surfaces. |
| `ide-wordmark-compact.svg` | Vector (`660×112`) | Compact navbar header lockup (`currentColor` wordmark). |
| `og-image.svg` / `og-image.png` | Vector & `1200×630` RGB PNG | OpenGraph link preview card featuring an iPhone 16 Pro running a live Codespace + thumb bar. |
| `social-announcement-square.svg` / `.png` | Vector & `1080×1080` RGB PNG | 1:1 launch announcement post for X/Twitter, LinkedIn, and Discord. |
| `repo-banner-dark.svg` / `repo-banner.png` | Vector & `1280×360` PNG | Dark GitLab / GitHub README hero masthead. |
| `repo-banner-light.svg` | Vector (`1280×360`) | Daylight paper README hero masthead for `<picture>` switching. |
| `backgrounds/ide-workspace-bg-dark.svg` / `-4k.png` / `-fhd.png` | Vector, `3840×2160` 4K & `1920×1080` FHD PNG | Desktop & Codespace workspace background wallpaper. |
| `backgrounds/ide-ios-wallpaper.svg` / `.png` | Vector & `1179×2556` PNG | Native iPhone OLED lock/home screen wallpaper. |
| `badges/*.svg` | Vector (`26px` height) | `ios-testflight.svg`, `codespaces-ready.svg`, `thumb-zone-ergonomics.svg`, `oled-zero-smear.svg`. |
| `tokens.css` & `design-tokens.json` | CSS & W3C DTCG JSON | 8pt spacing scale, iOS Dynamic Type scale, 44pt/48pt touch tokens, OLED color tokens, and haptic mapping. |

## Rebuilding All Assets

```bash
node brand/scripts/build-ide-brandkit.mjs
```
