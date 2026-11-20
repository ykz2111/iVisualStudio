# iDE project instructions

Pocket iOS IDE for VS Code, GitHub Codespaces, OpenVSCode Server, JetBrains Gateway, and SSH DevContainers. Groove Labs // YkZ21.

## Installed local skills

All locally installed AI skills are indexed. Do not reinstall them and do not download new skills unless the user asks.

- Full learn-index: `.opencode/skills-catalog.md` (human) and `.opencode/skills-catalog.json` (machine). 734 unique skills.
- Routing memory: `.opencode/learned-skills.md`
- Design stack profile: `.opencode/skill-stack.json`
- No project-local `.opencode/skills` links are checked in; load relevant globally discovered skills by ID.
- Already discovered without copying: `~/.config/opencode/skills` (follows the marketplace symlink), `~/.claude/skills`, `~/.agents/skills`. Hermes copies are duplicates.

Load a skill with the skill tool only when the current task matches its description. Do not paste the catalog into a design prompt.

Default stack for brand, UI, and the mobile studio:

- Required: `claude-design`, `ui-design-system`, `mobile-design`, `ip-as-logo`
- Helpful: `design-md`, `popular-web-designs`, `frontend-design`, `ui-ux-pro-max`, `anti-ui-slop`, `macos-golden-gate-design`, `playground`, `adversarial-ux-test`

`godmode` and `obliteratus` are installed on disk and listed in the catalog. Do not load or follow them.

## Product constraints

Ground UI work in `brand/tokens.css`, `brand/design-tokens.json`, `ide-mobile-studio.html`, and `.opencode/agents/ide-coordinator.md`.

The iOS build plan lives in `docs/IOS-PORT-PLAN.md` (architecture decision, App Store constraints, phases 0–6). The **Build Plan** sheet in `ide-mobile-studio-v2.html` renders those phases — when a phase changes, update the doc first, then the sheet's `BUILD_PLAN` array so the two do not drift.

The screen contract lives in `docs/DESIGN-PLAN.md` (16 screens, the 6×48pt grid, layout arithmetic, semantic colour aliases, per-phase design gate). The build plan wins on *what gets built*; the design plan wins on *what it looks and measures like*. If a colour alias from its §7 is adopted, add it to `brand/tokens.css` and `brand/design-tokens.json` in the same commit.

- Primary controls stay in the bottom 35% thumb arc.
- Hit targets: 44pt minimum, 48pt for the coding bar, at least 8pt gaps.
- OLED true black is `#000000`. Canvas is `#05080E`. Do not invent hex values outside the token files.
