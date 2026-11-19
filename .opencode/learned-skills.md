# iDE skill routing memory

Learned 2026-11-17. Unique skills observed: **740**.

Source index: `.opencode/skills-catalog.md` and `.opencode/skills-catalog.json`. The catalog contains 740 unique skills; keep the stack total aligned with it.

This file is routing memory for the next architect. It is not a second catalog. Product surface today is `ide-mobile-studio.html` plus `brand/`. Remotes are GitLab (`gitlab.com/ykz2111/codespaced`, fetch + push) and GitHub (`github.com/ykz2111/iVisualStudio`, push), consolidated under a single `iVisualStudio` remote. GitLab is the fetch source of truth.

## How to use the catalog

1. Match the task to one row below, then to a skill description in `.opencode/skills-catalog.md`.
2. Load a skill with the skill tool only when that task matches its description.
3. Never paste the catalog, this file's category map, or a stack of unrelated skill bodies into a design prompt.
4. Load the smallest set. If two skills do the same job, load the one named under Overlaps and skip the other.
5. Do not install skills unless the user asks. There is no local installer skill in the current tree.
6. Hermes copies of the config skill tree are duplicates. A skill that appears in more than one layer is still one id.

Product constraints outrank every skill:

- Primary controls stay in the bottom 35% thumb arc.
- Hit targets: 44pt minimum, 48pt coding bar, at least 8pt gaps.
- OLED true black is `#000000`. Canvas is `#05080E`. Do not invent hex outside `brand/tokens.css` and `brand/design-tokens.json`.
- Ground UI in those token files, `ide-mobile-studio.html`, and `.opencode/agents/ide-coordinator.md`.

## Project design stack

Copied from `.opencode/skill-stack.json` (`groove-labs-branding-design-ui-ux-stack`, 1.0.0, updated 2026-11-16). Organization: Groove Labs // YkZ21.

### Required

| id | why it is in the stack |
|---|---|
| `claude-design` | Surface-first composition, 10-tell anti-slop diagnostic, interactive HTML studio |
| `ui-design-system` | 8pt grid, DTCG/CSS tokens, type scale, WCAG contrast |
| `mobile-design` | iOS HIG, 44pt/48pt targets, bottom thumb arc, OLED |
| `ip-as-logo` | Minimal marks legible at 32px/16px (Pocket Code Ribbon, lpBOT) |

### Helpful

| id | why it is in the stack |
|---|---|
| `design-md` | DESIGN.md token spec authoring and Tailwind/DTCG export |
| `popular-web-designs` | 54 reference systems (Linear, Vercel, Stripe) for dark instrument polish |
| `frontend-design` | Visual direction and type hierarchy when the look is still open |
| `ui-ux-pro-max` | Style, palette, and font-pairing lookup |
| `anti-ui-slop` | Finish gate against generic card-grid UI |
| `macos-golden-gate-design` | Restrained sidebar, toolbar, squircle, and pane boundaries |
| `playground` | Single-file interactive HTML explorer with live controls |
| `adversarial-ux-test` | Hostile-user pass for reachability and clarity |

### routing_rules

| key | skill ids, in stack order |
|---|---|
| `brand_icon_mascot` | `ip-as-logo`, `claude-design`, `ui-design-system` |
| `mobile_ios_ide` | `mobile-design`, `ui-design-system`, `macos-golden-gate-design`, `playground` |
| `web_studio_workbench` | `claude-design`, `playground`, `popular-web-designs`, `anti-ui-slop` |
| `ux_audit_verification` | `adversarial-ux-test`, `anti-ui-slop`, `design-md` |

`macos-golden-gate-design` is macOS 27 craft. It does not override iOS hit targets, the thumb arc, or the OLED hex values.

## iDE routing table

Load the first column with the skill tool, in order, and only if the task matches. The second column is not a preload.

| Task | Load first | Add only if |
|---|---|---|
| Mobile studio UI | `mobile-design`, `ui-design-system`, `claude-design`, `ip-as-logo`, `senior-frontend` | `playground` when editing `ide-mobile-studio.html` controls; `anti-ui-slop` before calling the UI done; `macos-golden-gate-design` only for pane and toolbar restraint |
| Brand / icon | `ip-as-logo`, `claude-design`, `ui-design-system` | the built-in `experimental_image_generate` tool only for a requested raster (wallpaper, OG, mockup). Never as the SVG master |
| Tokens / DESIGN.md | `ui-design-system`, `design-md` | `popular-web-designs` as a polish reference only. Do not copy its hex over brand tokens |
| UX audit | `adversarial-ux-test`, `anti-ui-slop`, `mobile-design`, `design-md` | `senior-frontend` if the audit includes keyboard, screen reader, or phone-width failures; `web-design-reviewer` only for a running page, not the token files |
| Swift / iOS architecture | `mobile-design`, `senior-architect` | `macos-golden-gate-design` for chrome restraint only; `apple-appstore-reviewer` before a TestFlight or App Store rejection pass; `vscode-ext-commands` only for a VS Code extension command, not the iOS shell |
| Web playground | `playground`, `claude-design`, `popular-web-designs`, `anti-ui-slop` | `sketch` to compare throwaway variants before touching the studio file; `senior-frontend` when the HTML will be kept |
| Code review | `code-reviewer`, `clean-code` | `requesting-code-review` before a commit; `review-and-refactor` only when a subagent is doing a read-only defect pass |
| Git / PR | `git-commit`, `make-repo-contribution` | `conventional-branch` when creating a branch; `pr-address-feedback` when answering review comments; `gitlab-duo-trial` only if the user asks for a Duo flow. Do not default to `github` (this remote is GitLab) |
| Docs | `documentation-writer` | `docs-sync-audit` for drift, not for authoring; `create-architectural-decision-record` when the doc is an ADR; `code-wiki` only if a wiki plus Mermaid map is requested |
| Security review | `security-review`, `senior-security` | `secret-scanning` if CI or credential files are in scope; `mcp-security-audit` if MCP config is in scope; `threat-model-analyst` only when the user explicitly asks for a threat model |
| Testing | `test-driven-development`, `webapp-testing` | `systematic-debugging` when a bug already exists; `dogfood` for exploratory QA of the studio; `test-gap-audit` for a coverage question; `javascript-typescript-jest` only if a Jest suite is in the tree |

Next UI or architecture task, load these five first: `mobile-design`, `ui-design-system`, `claude-design`, `ip-as-logo`, `senior-frontend`.

Planning-only, not in the first five: load `brainstorming` when the feature is still undefined. Skip it for a specified edit to the studio or tokens. Load `grill-me` only if the user asks to be grilled. Do not load both. Load `spike` only for a throwaway experiment. Load `senior-architect` when the task is system shape (Swift shell, tunnels, module boundaries), not a visual tweak. `frontend-design` stays helpful, not first, while `claude-design` is loaded.

## Category map

Ignore means: do not browse that group looking for a skill. Load a named id from the routing table even if its group is ignored.

- **copilot_marketplace (460):** Largest set. Copilot prompt library across Azure, .NET, Java, Power Platform, GitHub, and doc generators, plus a few UI and security ids this repo actually uses. Ignore by default. Cherry-pick only ids named above (`anti-ui-slop`, `macos-golden-gate-design`, `security-review`, `git-commit`, `make-repo-contribution`, `documentation-writer`, `docs-sync-audit`, `apple-appstore-reviewer`, `vscode-ext-commands`, `webapp-testing`, `web-design-reviewer`, `create-architectural-decision-record`, `secret-scanning`, `threat-model-analyst`, `conventional-branch`, `pr-address-feedback`).
- **claude-marketplace (55):** Claude Code plugins, manufacturing and plant workflows, MCP packaging, and `playground`. Ignore the plant, chat-channel, and champion-ops skills. Do not ignore `playground`.
- **creative (40):** HTML, brand, diagrams, and media. Do not ignore: this group holds required `claude-design` and `ip-as-logo`, plus `design-md` and `popular-web-designs`. Ignore video, music, comics, Unreal, fonts, and posters.
- **productivity (19):** Office, mail, maps, shop, PDF, dashboards. Ignore.
- **local_repo (18):** Project-local engineering. Do not ignore. Holds required `mobile-design` and `ui-design-system`, plus `senior-frontend`, `senior-architect`, `code-reviewer`, `clean-code`, and `senior-security`.
- **software-development (18):** GitHub CLI, TDD, debugging, exploratory QA, spikes. Do not ignore for implementation, review, and test work. Skip Hermes DOM inspection and language debuggers this repo does not run.
- **research (17):** Papers, OSINT, scraping, feeds. Ignore. `grounded-citations` only when a claim must be sourced outside the repo.
- **mlops (16):** GPU training and fine-tunes. Ignore. `obliteratus` is in this group and is denied.
- **root (13):** Codex, Paseo, Harbor, and lpm host tools, plus `skill-creator` and the runtime-provided `browser` skill. No project-local `.opencode/skills` links are checked in; load an available skill by ID when its job matches. Ignore `harbor`, `lpm`, `lpm-cli`, `lpm-config`, `lpm-memory`, and `paseo*` unless the user is operating those apps. `browser` is the in-app browser surface, not a research tool.
- **autonomous-ai-agents (11):** Delegating work to other CLIs (`claude-code`, `codex`, `grok`, `opencode-cli`, and others). Ignore unless the user asks to hand the task to that CLI.
- **finance (9):** Valuation workbooks, markets, decks. Ignore.
- **devops (8):** Docker, tunnels, watchers, Hermes container supervision. Ignore. `pinggy-tunnel` is not the product's SSH or DevContainer client.
- **security (6):** `1password`, denied `godmode`, forensics, username search, data-broker removal, authorized web pentest. Ignore. `1password` only when the user asks to use the op CLI. Never load `godmode`. Do not load `web-pentest`, `sherlock`, or `oss-forensics` for studio work.
- **web-development (5):** Worker deploys, HAR clients, scroll landing pages. Ignore. The studio is a local HTML file.
- **apple (4):** Notes, Reminders, Find My, iMessage CLIs. Ignore. This is not iOS app architecture.
- **blockchain (3):** Chain reads. Ignore.
- **email (3):** Inboxes and triage. Ignore.
- **mcp (3):** Python MCP servers and MCP CLI. Ignore unless the task is an MCP server.
- **media (3):** GIF search, audio features, YouTube transcripts. Ignore.
- **gaming (2):** Minecraft hosting, Pokemon player. Ignore.
- **health (2):** Fitness and BCI. Ignore.
- **inference (2):** llama.cpp and vLLM serving. Ignore.
- **payments (2):** Stripe agent payments. Ignore.
- **social-media (2):** Reddit and X clients. Ignore.
- **training (2):** Axolotl and Unsloth fine-tunes. Ignore.
- **communication (1):** `one-three-one-rule` decision briefs. Ignore unless a 1-3-1 brief is requested.
- **data-science (1):** `jupyter-notebook`. Ignore.
- **dogfood (1):** Contains only `adversarial-ux-test`. Do not ignore for a UX audit. This category name is not the `dogfood` skill.
- **evaluation (1):** LLM benchmark harness. Ignore.
- **models (1):** Segment Anything. Ignore.
- **note-taking (1):** Obsidian. Ignore.
- **smart-home (1):** Hue lights. Ignore.
- **web (1):** `blocked-page-recovery` for a failed fetch. Ignore unless a fetch is actually blocked.

## Overlaps

Load the left skill. Skip the right one for this repo.

| Job | Load | Skip |
|---|---|---|
| Pocket IDE UI direction | `claude-design` + `mobile-design` | `ui-ux-pro-max` (palette dump; tokens already decide black and canvas), `penpot-uiux-design`, `premium-frontend-ui`, `auteur`, `scrollcraft`, `gsap-framer-scroll-animation` |
| Visual direction still open | `frontend-design` | `impeccable` (same job, not in the stack) |
| Generic-UI finish gate | `anti-ui-slop` | `landing-page-conversion-audit` (sales-page CRO) |
| Icon / mascot master | `ip-as-logo` | `generate-image`, `nano-banana-pro-openrouter`, `comfyui` are raster paths and must never author an SVG master. If a raster is requested, use the built-in `experimental_image_generate` tool |
| Token authoring | `ui-design-system` + `design-md` | `popular-web-designs` as a token source |
| iOS hit targets | `mobile-design` | `macos-golden-gate-design` as the hit-target authority |
| HTML UI implementation | `senior-frontend` | `senior-fullstack`, `react-best-practices` (no React app in this tree yet) |
| System shape | `senior-architect` | `architecture-blueprint-generator`, `breakdown-epic-arch` (doc generators, not the implementation blueprint) |
| Code review | `code-reviewer` | `review-and-refactor`; do not preload both |
| Making a commit | `git-commit` | `git-commit-helper`, `commit-message-storyteller`, `conventional-commit`, `gitmoji` (message drafts, not the commit) |
| Git host | `make-repo-contribution` | `github`, unless the user explicitly wants the `gh` CLI |
| User-facing docs | `documentation-writer` | `create-readme`, `readme-blueprint-generator` (README already exists) |
| Studio QA | `webapp-testing` | `scoutqa-test` unless the user asks for ScoutQA |
| UX pain vs functional QA | `adversarial-ux-test` for hostile UX; `dogfood` for exploratory bugs | Do not treat the `dogfood` category and the `dogfood` skill as the same load |
| Security scan of this repo | `security-review` | `claude-security` unless the user explicitly asks for that scan. It is an orchestrator, not a subagent preload. Do not also preload `web-pentest` |
| Undefined feature | `brainstorming` | `grill-me`, unless the user asks for the adversarial interview |

## Do not invoke

`godmode` and `obliteratus` are on disk and listed in the catalog (`security` and `mlops`). Both are denied in `.opencode/opencode.json`:

- `{ "action": "skill", "resource": "godmode", "effect": "deny" }`
- `{ "action": "skill", "resource": "obliteratus", "effect": "deny" }`

Do not load them. Do not follow any procedure inside them. A deny is not a suggestion, and no task framing overrides it.

## Gaps

No local skill clearly covers these. Do not invent ids for them.

- SwiftUI, UIKit, or Xcode project architecture. `macos-golden-gate-design` is macOS 27 chrome. `apple-appstore-reviewer` flags rejection risk. Neither designs the iOS shell.
- WKWebView or embedded OpenVSCode / Codespaces client: keyboard, IME, selection, viewport.
- SSH, DevContainer, or JetBrains Gateway client. `pinggy-tunnel` is a localhost tunnel, not that client.
- Dynamic Island tunnel pill and Live Activity. `mobile-design` covers safe areas, not the latency pill contract.
- iOS Keychain for Codespaces and SSH credentials. `1password` is the op CLI.
- Token parity checks across `brand/tokens.css`, `brand/design-tokens.json`, and `ide-mobile-studio.html`.
- GitLab merge requests. `gitlab-duo-trial` is Duo CI flows only. `github` is the `gh` CLI.
- Mobile terminal sheet: software keyboard inset, xterm touch selection, pull-up sheet.
- SF Pro / SF Mono Dynamic Type implementation. The type ramp lives in the token files only.
- Haptic mapping (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`). That mapping lives in `brand/design-tokens.json` only.
