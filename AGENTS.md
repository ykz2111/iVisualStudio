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

- Primary controls stay in the bottom 35% thumb arc.
- Hit targets: 44pt minimum, 48pt for the coding bar, at least 8pt gaps.
- OLED true black is `#000000`. Canvas is `#05080E`. Do not invent hex values outside the token files.
