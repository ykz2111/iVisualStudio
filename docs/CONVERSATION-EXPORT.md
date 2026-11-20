# iDE — Research & Integration Conversation Export

Exported from the FreeMilk chat attached to the **iDE_CONCEPT** (`iVisualStudio`) project.

- **Topics covered:** Build Plan sheet wiring, OpenCode / Groq / local model research (two passes), routing Ollama into OpenCode.
- **Files changed during these turns:** `ide-mobile-studio-v2.html`, `ide-mobile-studio.html`, `AGENTS.md`.
- **Files read for context:** `.opencode/opencode.json`, `AGENTS.md`, `README.md`.
- **Note:** the prompt that opened turn 1 is not retained in this chat's visible history; turn 1 is recorded from the assistant reply that followed it.

---

## Turn 1 — Build Plan sheet in the studio

**User:** *(not retained in visible history — request was a plan for the iOS Visual Studio port, split into phases)*

**Assistant:**

The plan doc is now part of the studio's own navigation.

**What I wired up**

`ide-mobile-studio-v2.html` is the live surface, so the plan lives there as a real view rather than a link to a raw `.md`:

- A **Build Plan** button in the topbar (`#planBtn`, shortcut `P`, `aria-pressed` kept in sync).
- A page-level bottom-sheet dialog (`#planSheet` + `#planBackdrop`) — deliberately outside the 368px phone stage so the roadmap isn't clipped, styled entirely from `brand/tokens.css` variables (`--accent`, `--ide-bg-chassis`, `--ide-type-caption`, `--ide-safe-bottom-home`, `--studio-radius-*`), no new hex values.
- The sheet renders phases 0–6 from a `BUILD_PLAN` array: phase id, name, duration, goal, and the binary **ACCEPT** line. P0 and P2 are marked as gates with the emerald `--dot` edge, since those are the go/no-go points in the doc.
- A **Full doc** link to `docs/IOS-PORT-PLAN.md` plus a subtitle making clear the doc is the source of truth and the sheet is a view.
- Interaction matches the existing ⌘P palette exactly: focus save/restore, Tab focus trap, Esc closes, backdrop click closes, and deep link support via `#plan`.

`ide-mobile-studio.html` — the v1 playground the README points at first — now has a **Build Plan · Phases 0–6** link in its topbar that opens the v2 studio with the sheet already open.

`AGENTS.md` gained a short paragraph pointing at the plan doc and the `BUILD_PLAN` array, so the next agent updates the doc first and the sheet second instead of letting them drift.

**What I could not check**

I can't open a local `file://` page in this environment, so this is verified by reading back every edited region (CSS block, markup, JS block, keyboard handler, init) rather than by rendering it. The script is plain ES5-style inside the existing IIFE and every id it touches (`planBtn`, `planBackdrop`, `planSheet`, `closePlanBtn`, `planBody`, `planTitle`) exists in the markup. Tapping the button in a browser is the one thing left to confirm.

**One judgement call worth flagging:** the phase summaries in the sheet are a condensed copy of the doc's phases, so they can drift. I kept them short and labelled the doc as authoritative; if you'd rather have zero duplication, the alternative is fetching the markdown at runtime, which fails on `file://` due to CORS — that's why I embedded it.

---

## Turn 2 — OpenCode, Groq, and local models for an M1

**User:** Look what models opencode offers, groq and what local models similar to fable and hydrogen can run on macbook pro m1

**Assistant:**

**Short answer:** On a MacBook Pro M1, a local model can match your coding work only at the 16 GB and up tiers. Neither Fable nor Hydrogen can run locally on any M1. "Fable" is Anthropic's Claude Fable 5, a closed model with no downloadable weights. "Hydrogen" is Deep Principle's Hydrogen-1.0, a 753B open-weight science model, far beyond 64 GB. Nothing in this project mentions either name; I took them from the model catalogs.

**What OpenCode offers**

- **OpenCode Go** ($10/month, Go Plus $40, Go Teams $20 per member): about 32 curated open-weight models, including Kimi K3, GLM-5.2, Qwen3.8 Max, DeepSeek V4 Pro, GPT-6 Luna, MiniMax-M3 and Grok 4.7. Usage is capped per 5-hour window and per month. Source: <https://opencode.ai/console/go>.
- **Catalog (models.dev):** the full list, including Anthropic (Claude Fable 5 at $10/$50 per million tokens, Opus 5, Sonnet 5), OpenAI (GPT-5.6 Sol, Terra, Luna), Google Gemini 3.7 Flash, xAI Grok 4.6, and many open models. Source: <https://opencode.ai/docs/models/>.
- **Sign-ins and providers:** ChatGPT plan, GitHub Copilot, Azure, Bedrock, Vertex, OpenRouter, and custom OpenAI-compatible endpoints.
- **Local:** Ollama, LM Studio and vLLM are discovered automatically at their default ports. Models tagged `cloud` in Ollama run on Ollama's servers, not your Mac.
- **Groq:** not a named provider in OpenCode's docs. Add it as a custom OpenAI-compatible provider with base URL `https://api.groq.com/openai/v1` and your `GROQ_API_KEY`. Groq's list has gpt-oss-120b at about 500 tokens/s ($0.15/$0.60 per million) and gpt-oss-20b at about 1000 tokens/s ($0.075/$0.30). I did not confirm whether a Groq entry is already in OpenCode's catalog; check `/models`.

**What fits on an M1 MacBook Pro**

Check your exact memory under Apple menu > About This Mac. Bandwidth figures are from Wikipedia's M1 article.

- **8 GB (base M1, 68 GB/s):** 3–4B models only, such as gemma3 4B or phi4-mini. Too small for agentic coding.
- **16 GB (M1 base or M1 Pro, 68 or 200 GB/s):** gpt-oss:20b (14 GB download, 128K context, tool support) is the strongest fit. qwen2.5-coder:14b is also workable. Close other apps.
- **32 GB (M1 Pro or Max):** gpt-oss:20b runs comfortably. Also possible: devstral-small-2 (24B, tools), qwen3.6 27B, glm-4.7-flash (30B class, the closest local relative to the GLM base of Hydrogen), and qwen3-coder 30B (a mixture-of-experts model, roughly 18 GB at 4-bit, my estimate).
- **64 GB (M1 Max, 400 GB/s):** 27–32B models at higher quality, and llama3.3 70B at 4-bit (about 40 GB, my estimate). gpt-oss:120b is a 65 GB download, so it does not fit.

macOS lets the GPU use only part of unified memory by default, so the usable amount is smaller than the spec. Speeds are my estimates from bandwidth, not benchmarks: a dense 20 GB model on an M1 Max lands around 10–20 tokens/s. Choose models tagged `tools` in Ollama, since OpenCode's agent needs tool calling. gemma3 is vision-only in that tag list; gemma4 has tools.

**Closest local equivalents**

- For Fable (general strong assistant with coding): gpt-oss:20b on 16 GB or more, qwen3.6 27B or gemma4 26B on 32 GB or more. Nothing local reaches Fable's quality.
- For Hydrogen (scientific, GLM-based): glm-4.7-flash on 32 GB or more. Hydrogen itself is a hosted model only, through its API partners.

**Recommendation for your Mac**

- 16 GB: use OpenCode Go or Groq for heavy work, and keep gpt-oss:20b in Ollama as an offline fallback.
- 32 GB or more: run gpt-oss:20b or devstral-small-2 locally for everyday edits, and use a hosted model for hard tasks.
- Fable, via Anthropic at $10/$50 per million tokens, is the only route to that quality, and it is not local.

**Uncertain:** Hydrogen's details come from secondary coverage, since the Hugging Face page is gated. The "beats GPT-6-Astra" claim is flagged as unverified by one of those sources.

---

## Turn 3 — A wider model search

**User:** Look for more models

**Assistant:**

I pulled the full Ollama tools/thinking catalogue, Groq's complete model table, and both OpenCode catalogues (pay-per-token and Go). Here is what is new and what it changes.

**New local models worth knowing (Ollama, verified sizes)**

Coding-agent models, best fit first, with publisher-reported SWE-bench Verified where given:

- **ornith:9b** — 5.6 GB, 256K ctx, tools+thinking, MIT. Sizes 9B/35B (35B is 21 GB). Built for agentic coding.
- **mimo-v2.6** — 6.6–8.7 GB, 9B, 256K ctx, vision+tools. SWE-V 61.1, Terminal-Bench 27.0. **This beats gpt-oss:20b (SWE-V 34) at two-thirds the size** — it is the better 16 GB pick than what I suggested last time.
- **bonsai-2** — ternary weights, 2B/4B/9B/27B at **911 MB / 1.6 GB / 3.2 GB / 8.3 GB**, all with 256K ctx, vision, tools, thinking. The 9B is the best thing I found for an 8 GB Mac.
- **gemma4** — e2b 4.6 GB, e4b 6.6–9.5 GB, 12b 7.7 GB, 26b MoE 16–19 GB (3.8B active), 31b 19–20 GB. SWE-V 66.6 for 31B. Has `-mlx` tags.
- **flint** — 40B MoE with **2.5B active**, 23 GB, 256K ctx, Apache 2.0. SWE-V **74.2**, SWE-Pro 89.7, Terminal-Bench 2.1 **54.9**. The standout for a 32 GB M1: the low active-param count means it generates fast.
- **qwen3.8:27b** — 18 GB, 256K ctx, vision, `reasoning_effort` knob. Also `qwen3.6:27b` 18–19 GB and `:35b` 23 GB (SWE-V 77.2 for 27B).
- **muse-glimmer** — Meta, 30B, 18 GB, 128K ctx, vision, Apache 2.0, built for always-on local agents. SWE-V 76.0, MCP-Atlas 75.5. Designed around tool failure and retry.
- **nemotron-3.5-lightning** — 30B MoE with **3B active**, 19–25 GB, **1M ctx**. NVIDIA's always-on-agent model.
- **qwen3-coder:30b** — 19 GB, 3.3B active, 256K ctx.
- **qwen3-coder-next** — 80B MoE, 3B active, **52 GB**, 256K ctx, non-thinking. 64 GB only, but very fast per token.
- **ripple-preview** — 65B **dense**, 39–46 GB, up to 2M ctx, Terminal-Bench **80.5**. Needs 64 GB and will be slow (dense 65B on a 400 GB/s M1 Max: realistically 4–6 tok/s).
- **nemotron-3.5-bolt** — e4b is 7.2–7.9 GB and fits 16 GB; the 74B-A9B variant **does not run on Metal at all** per NVIDIA's own notes.
- **lfm3** 1.7B (1.1–1.7 GB, 256K ctx) — the authors explicitly say *not* recommended for agentic coding. Fine as a router, not as your agent.

**The finding that matters most for an M1**

Ollama now publishes **`-mlx` tags** for Apple Silicon (`gemma4:*-mlx`, `qwen3.6:*-mlx`, `muse-glimmer:30b-mlx`, `nemotron-3.5-lightning:30b-mlx`), running on Ollama's MLX engine with DFlash speculative decoding. Prefer the MLX tag whenever one exists. Many tags also ship Q4/Q8 variants with a 2–3× size spread (glm-4.7-flash: q4 19 GB → q8 32 GB → bf16 60 GB), so "does it fit" depends on the quant you pull.

**Cloud-tagged traps**

These look local in search results but run on Ollama's servers (paid, `cloud` tag): `deepseek-v4.1-flash`, `glm-5.3`, `glm-5.3-flash`, `kimi-k3.1-pro`, `minimax-m3`, `muse-spark-open`, `mistral-large-4`, `inkling-2-small`, `mimo-v2.6-flash`, `beam`.

**Groq — the real picture**

Only six models are usable for chat: `openai/gpt-oss-120b` (500 t/s), `openai/gpt-oss-20b` (1000 t/s), `qwen/qwen3.8-27b` (450 t/s, $0.80/$4.00, 131K ctx), `openai/gpt-oss-safeguard-20b`, and Llama 3.1 8B / 3.3 70B which are now **Enterprise only — no self-serve price**. The rest of the catalogue is non-chat: Whisper large-v3 and v3-turbo ($0.111 and $0.04/hour), the two Prompt Guard classifiers, and Orpheus TTS. New since last time: `minimaxai/minimax-m2.7` and `meta-models/muse-spark-open` exist but are enterprise-only previews.

**OpenCode — two catalogues**

Pay-per-token (OpenCode Models, 29 rows, verified prices): cheap end — **Claude Haiku 5.5 $0.10/$0.50**, GPT-6 Luna $0.10/$0.50, Qwen3.8 Flash $0.15/$0.47, GLM-5.3-Flash $0.15/$0.50, DeepSeek V4.1 Flash $0.30/$1.20, MiniMax-M3 $0.30/$1.20, Kimi K2.7 Code $0.95/$4.00, Grok Build 0.1 $1.00/$2.00. Top end: GPT-5.5 Pro $30/$180, GPT-6 Astra $10/$50, Claude Fable 5.1 $10/$50, Claude Opus 5.5 $4/$20.

Go ($10/mo, 32 models) includes **four free unlimited ones**: Beam Free, Hy4 flash Free, Iceman Contributor Free, LongCat 2.5 Free. Best allowances per request are DeepSeek V4.1 Flash 1017 (~43,300 req/5h) and MiMo-V2.6-Flash (~30,100).

**Revised picks per tier**

- 8 GB — bonsai-2:9b (3.2 GB) or ornith:9b (5.6 GB), tight.
- 16 GB — mimo-v2.6 (7–9 GB) is the new default; bonsai-2:27b (8.3 GB) or gemma4:12b (7.7 GB) as alternates; gpt-oss:20b only if you want the 14 GB download.
- 32 GB — **flint:40b (23 GB)** for coding quality with MoE speed, or muse-glimmer:30b-mlx (19 GB) for failure-recovery behaviour and vision; qwen3.6:27b-mlx for the highest published SWE-V.
- 64 GB — qwen3-coder-next (52 GB) for speed, ripple-preview (46 GB) for maximum quality at low speed.

**Caveats:** every SWE-bench/Terminal-Bench figure above is publisher-reported, and benchmarks differ per release, so treat the rankings as indicative. Sizes are download sizes — usable memory on macOS is lower, and long context eats KV cache.

---

## Turn 4 — Routing Ollama into OpenCode

**User:** How to route ollama to produce opencode models?

**Assistant:**

Short answer: there are three ways, and only the first needs no configuration at all.

**1. Nothing to route: OpenCode discovers Ollama itself**

OpenCode's model docs say it automatically discovers Ollama, LM Studio and vLLM at their default local addresses, refreshing the inventory in the background and reading context, vision and tool support from Ollama. So:

- `ollama serve` (or the Ollama app) running, model pulled, then in OpenCode: `/models` and pick the `ollama/<name>` entry, e.g. `ollama/qwen3.8`, `ollama/flint:40b`, `ollama/mimo-v2.6`.
- Or pin it in config as `"model": "ollama/flint:40b"`.
- Embedding-only models are excluded automatically. Disable discovery with `"plugins": ["-opencode.provider.ollama"]`.

Verify the server is answering in OpenAI shape first:

```bash
curl -s http://127.0.0.1:11434/v1/models | jq '.data[].id'
```

**2. `ollama launch opencode` — the one-liner**

```bash
ollama launch opencode --model flint:40b
ollama launch opencode --config   # writes config without starting a session
```

Two behaviours from the doc matter:

- It uses an inline config and **does not overwrite** `~/.config/opencode/opencode.json`; your existing settings still apply.
- Models you define only in `opencode.json` **do not appear** in the `ollama launch` model picker.

**3. Manual provider block**

In the project config `.opencode/opencode.json` (which already carries `$schema`), add a provider. Current OpenCode uses the **plural** shape:

```json
"providers": {
  "ollama": {
    "settings": { "baseURL": "http://127.0.0.1:11434/v1" }
  }
}
```

Note the discrepancy: Ollama's own integration page still shows the older v1 shape (`"provider"`, `"npm": "@ai-sdk/openai-compatible"`, `"options": {"baseURL": …}`). OpenCode's config and models docs use `providers`, `package` and `settings` instead. If the plural block is ignored by your version, use the old keys. Do not set `package` for Ollama if you want to keep native discovery — overriding it swaps you onto the `/v1` endpoint and you lose the auto-read of context and capability flags.

To pin limits for a model OpenCode misreports, add an entry under `models:<name>` with `modelID`, `limit.context`, `limit.output` and `capabilities.tools: true`.

**The setting that actually decides whether it works**

Ollama sizes context by VRAM: **under 24 GiB it defaults to 4k**, 24–48 GiB to 32k, 48 GiB+ to 256k. OpenCode needs **64k or more**, so on an 8 GB, 16 GB *or* 32 GB Mac the default is too small and the agent will truncate or fail mid-task. Fix it one of three ways:

- `OLLAMA_CONTEXT_LENGTH=64000 ollama serve`
- the context slider in the Ollama app's settings
- a Modelfile with `FROM <model>` and `PARAMETER num_ctx 64000`, then `ollama create <name>`

Check with `ollama ps`: the `CONTEXT` column should read 64000+, and `PROCESSOR` should be `100% GPU`. On the multi-hundred-thousand-token models, context is what pushes you past unified memory, not the weights.

**Cloud models, two routes**

- Through the local server: `ollama signin`, then name the model with the `cloud` tag (`gemma4:cloud`, `kimi-k3.1-pro:cloud`). Same endpoint, no download.
- Direct, no Ollama install: `baseURL: "https://ollama.com/v1"` with `apiKey: "{env:OLLAMA_API_KEY}"`, model ids like `gemma4:31b`. The cloud API does not support stateful Responses, built-in web search through `/v1/responses`, or custom/freeform tool-call replay.

**Two clarifications**

- Local auth is ignored: any string works as the key (`"ollama"` is conventional). If you get a 401, set `settings.apiKey` to a dummy value rather than hunting for a real key.
- If you meant the reverse — running OpenCode Go/Zen models *through* Ollama — that is not possible. Ollama serves weights you host; Console models run on OpenCode's inference.

---

## Appendix A — Local model reference (Ollama, verified downloads)

| Model | Size | Ctx | Params / active | Notes |
|---|---|---|---|---|
| bonsai-2:2b / :4b / :9b / :27b | 911 MB / 1.6 GB / 3.2 GB / 8.3 GB | 256K | dense, ternary | vision, tools, thinking; Apache 2.0 |
| lfm3:1.7b | 1.1–1.7 GB | 256K | 1.73B | not for agentic coding (author note) |
| ornith:9b / :35b | 5.6 GB / 21 GB | 256K | 9B / 35B | agentic coding, MIT |
| mimo-v2.6 | 6.6–8.7 GB | 256K | 9B | SWE-V 61.1, Terminal-Bench 27.0 |
| gemma4:e2b / e4b / 12b / 26b / 31b | 4.6 / 6.6–9.5 / 7.7 / 16–19 / 19–20 GB | 128K–256K | 26b = 3.8B active | SWE-V 66.6 (31B); `-mlx` tags |
| qwen3.8:27b | 18 GB | 256K | 27B | vision, `reasoning_effort` |
| qwen3.6:27b / :35b | 18–19 / 23 GB | 256K | 27B / 35B | SWE-V 77.2 (27B) |
| qwen3-coder:30b | 19 GB | 256K | 3.3B active | long-context agentic |
| glm-4.7-flash | 19 GB (q4) / 32 GB (q8) / 60 GB (bf16) | 198K | 30B-A3B | SWE-V 59.2 |
| devstral-small-2 | 15 GB | 384K | 24B | SWE-V 65.8, Terminal-Bench 32.0 |
| nemotron-3.5-lightning:30b | 19–25 GB | 1M | 3B active | always-on agents; `-mlx` |
| nemotron-3.5-bolt:e4b | 7.2–7.9 GB | 128K | 8B / 4B eff. | 74B variant unsupported on Metal |
| muse-glimmer:30b | 18 GB | 128K | 30B | SWE-V 76.0, MCP-Atlas 75.5 |
| flint:40b | 23 GB | 256K | 2.5B active | SWE-V 74.2, Terminal-Bench 54.9 |
| qwen3-coder-next | 52 GB | 256K | 80B / 3B active | non-thinking, fast |
| ripple-preview:65b | 39–46 GB | 2M | 65B dense | Terminal-Bench 80.5, slow |
| gpt-oss:20b / :120b | 14 GB / 65 GB | 128K | 21B / 117B | SWE-V 34 (20b) |

## Appendix B — Hosted options at a glance

**OpenCode Models (pay-per-token, cheapest first)**

| Model | Input / Output per 1M |
|---|---|
| Claude Haiku 5.5 | $0.10 / $0.50 |
| GPT-6 Luna | $0.10 / $0.50 |
| Qwen3.8 Flash | $0.15 / $0.47 |
| GLM-5.3-Flash | $0.15 / $0.50 |
| DeepSeek V4.1 Flash | $0.30 / $1.20 |
| MiniMax-M3 | $0.30 / $1.20 |
| Mistral Large 4 | $0.68 / $2.09 |
| Kimi K2.7 Code | $0.95 / $4.00 |
| Grok Build 0.1 | $1.00 / $2.00 |
| Claude Sonnet 5.5 | $2.00 / $10.00 |
| GPT-6.1 Sol | $2.00 / $10.00 |
| Grok 4.7 | $2.00 / $6.00 |
| Claude Opus 5.5 | $4.00 / $20.00 |
| GPT-5.5 | $5.00 / $30.00 |
| Claude Fable 5.1 | $10.00 / $50.00 |
| GPT-6 Astra | $10.00 / $50.00 |
| GPT-5.5 Pro | $30.00 / $180.00 |

**Groq (self-serve)**

| Model | Speed | Input / Output per 1M | Context |
|---|---|---|---|
| openai/gpt-oss-20b | ~1000 t/s | $0.075 / $0.30 | 131K |
| openai/gpt-oss-120b | ~500 t/s | $0.15 / $0.60 | 131K |
| qwen/qwen3.8-27b | ~450 t/s | $0.80 / $4.00 | 131K |
| openai/gpt-oss-safeguard-20b | ~1000 t/s | $0.075 / $0.30 | 131K |
| llama-3.1-8b / llama-3.3-70b | 560 / 280 t/s | Enterprise only | 131K |

**OpenCode Go — $10/mo, free tier items:** Beam Free, Hy4 flash Free, Iceman Contributor Free, LongCat 2.5 Free (unlimited, limited regions/time). Best request allowances: DeepSeek V4.1 Flash 1017 (~43,300/5h), MiMo-V2.6-Flash (~30,100), LongCat-2.0, GLM-5.3-Flash.

---

## Appendix C — Sources

- <https://opencode.ai/docs/models/>
- <https://opencode.ai/docs/config/>
- <https://opencode.ai/console/models>
- <https://opencode.ai/console/go>
- <https://models.dev/api.json>
- <https://console.groq.com/docs/models>
- <https://docs.ollama.com/integrations/opencode>
- <https://docs.ollama.com/api/openai-compatibility>
- <https://docs.ollama.com/context-length>
- Ollama library pages for each model listed in Appendix A

## Appendix D — Unverified / caveats

- All SWE-bench, Terminal-Bench and MCP-Atlas numbers are publisher-reported; setups differ, so treat rankings as indicative.
- Token/s figures for local models are estimates from memory bandwidth, not measured benchmarks.
- Hydrogen (Deep Principle) details come from secondary coverage; the Hugging Face page is gated and the "beats GPT-6-Astra" claim is flagged unverified by one source.
- `ollama launch opencode` and the `providers.ollama` schema were read from docs, not executed on this device.
