[Back to the index](../README.md)

# Commands: ai

## `ai.models`

List the models each AI provider offers (the values for roles.<role>.model).

Asks the providers themselves, so newly released models show up: Claude Code through its CLI (aliases such as opus first, then full names; no model call, no usage), the Anthropic API and OpenAI-compatible APIs through GET /models. Codex and generic CLIs cannot list their models: their entry has an error. Without `provider` it lists every provider that ai.providers reports available; one provider's failure is in its own entry (error, hint) and does not fail the call. Returns {providers:[{name, models:[{id, name, description, resolved}], error?, hint?}]}: id is the value for roles.<role>.model, name the display name (empty when the provider gives none), description one line, resolved the model an alias stands for (empty for a full name). Example: {"provider":"claude-code"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `provider` | string | no | Only this provider (a name from ai.providers). Omit for every available one. |

## `ai.providers`

List configured AI providers and roles, or diagnose which ones are usable (doctor).

action "list" (default) shows providers and the role mapping from ~/.factoria/ai.json. action "doctor" also checks for CLIs (claude, codex, ant) and API keys (never printed). `assets` maps each kind of asset (image, sound, music, voice, model3d) to the provider that generates it (assets.generate_* commands). Example: {"action":"doctor"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string ["list","doctor"] | no | list or doctor. Default "list". |

## `ai.run` (modifies state)

Run an AI agent on a task in the current project (blocks until it finishes).

Uses the provider/model mapped to `role` in ~/.factoria/ai.json (default orchestrator). CLI providers (claude-code, codex) run their own loop with the FactorIA MCP server attached; API providers run the built-in tool loop. An orchestrator that is itself a CLI agent delegates with this tool: role "worker" or "fast" and a self-contained task; the result's finalText is the sub-agent's report. Example: {"task":"Add a pause menu","role":"orchestrator","maxCostUsd":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `task` | string | yes | What the agent should do. |
| `role` | string ["orchestrator","worker","fast"] | no |  Default "orchestrator". |
| `provider` | string | no | Override the role's provider (e.g. claude-code, codex, openrouter). |
| `model` | string | no | Override the role's model. |
| `maxTurns` | integer | no |  |
| `maxCostUsd` | number | no |  |
| `stream` | boolean | no |  Default true. |

