# Project Chat Summary

## Coverage
This export summarizes the project conversation captured in `docs/CONVERSATION-EXPORT.md`. It does not claim to cover project chat threads that have not been exported.

## Topics and outcomes

### iOS port build-plan view
The studio prototype was updated with a Build Plan sheet for phases 0–6, a link to the authoritative plan document, and keyboard, focus, and deep-link behavior. The change was reviewed by reading the edited code; it was not visually tested in a browser.

### OpenCode, Groq, and local models on M1 Macs
The conversation compared hosted model providers and local options by unified-memory tier. It noted that Fable and Hydrogen are not downloadable models suitable for running locally on an M1. Recommendations included using hosted models for heavier work and selecting local models based on available memory.

### Expanded model research
A broader Ollama, Groq, and OpenCode catalogue review changed the local recommendations: Bonsai-2 or Ornith for 8 GB; MiMo-V2.6 for 16 GB; Flint, Muse-Glimmer, or Qwen3.6 for 32 GB; and Qwen3-Coder-Next or Ripple for 64 GB. Reported benchmark scores and estimated speeds were flagged as indicative, not independently measured.

### Ollama with OpenCode
OpenCode can discover Ollama models automatically; `ollama launch opencode` and a manual provider configuration are alternatives. The discussion emphasized configuring at least 64K context for agentic OpenCode work, and distinguished locally hosted models from Ollama cloud models. OpenCode-hosted models cannot be served through Ollama.

## Detailed source
See `docs/CONVERSATION-EXPORT.md` for the full captured conversation and its model tables.
