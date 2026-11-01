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

## `ai.review` (modifies state)

Since 0.4.0.

Ask the art critics (kind art) or the game reviewers (kind game) for their opinion and a score (blocks until done).

Starts `count` read-only AI reviewers (1 to 5, one after the other, each with a different persona; the first is always the all-rounder, so the score of one reviewer stays comparable over time). They play the current build (REVIEW.md first), never change the project, and write a report with a score from 0 to 10 and sub-scores. Each review is saved in <project>/.factoria/ai/reviews/ and returned: {reviews:[{id, path, persona, score, subScores, summary, text}], averageScore, costUsd, errors}. Only a person asks for reviews: the orchestrator is told not to call this. The roles artCritic and reviewer of ~/.factoria/ai.json choose the models. Example: {"kind":"game","count":3,"focus":"the first five minutes"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `kind` | string ["art","game"] | yes | art: the art critics (role artCritic). game: the game reviewers (role reviewer). |
| `count` | integer | no | How many critics or reviewers, each with a different persona. Default 1. |
| `focus` | string | no | Something to pay special attention to (optional), e.g. "the UI" or "the boss fight". |
| `provider` | string | no | Override the role's provider. |
| `model` | string | no | Override the role's model. |
| `maxTurns` | integer | no |  |
| `maxCostUsd` | number | no | Cost limit of each review. |
| `stream` | boolean | no |  Default true. |

## `ai.review_feedback` (modifies state)

Since 0.10.0.

Check an ENGINE_FEEDBACK.json entry's `share` text before it can be shared: a real gap, about the engine, not possible yet.

Run this after feedback.report when you wrote a `share` text (a person also gets it as "Review with AI" in the Engine Feedback panel). A cheap model checks the entry against the engine's command list and documentation: (1) the gap is real, (2) it is about the engine and not about the game, (3) the engine cannot already do it. The text also goes through the automatic sanitizer, which refuses anything with names, paths or quotes from the game. On a PASS the entry is marked reviewed: true and, if the text needed it, `share` is rewritten in engine terms (components, fields, commands and API names only; nothing about the game). On a FAIL nothing is changed: you get `reasons` (which check failed and why) and `fix`, what to change (rewrite the share text, use what the engine already has, or drop `share`). The model is the "fast" role of ai.json, the cheapest one (the orchestrator when fast is off; docs/AI_PROVIDERS.md). The result is {id, pass, checks:{real, aboutEngine, notPossibleYet, sanitizer}, reasons, fix, rewritten, reviewed, share, role}. This command never changes the sharing mode and never sends anything: only a person decides whether entries leave the machine. Example: {"id":"FB-0003"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The entry to review, e.g. FB-0003 (feedback.list shows the ids). It needs a `share` text. |

## `ai.reviews`

Since 0.4.0.

List the saved reviews of the art critics and the game reviewers, newest first, with their scores.

Reads <project>/.factoria/ai/reviews/. Each entry has id, path, role, persona, time, engineVersion, gameVersion, score (0 to 10, null when none), subScores and summary; `text` (the report) only with includeText. Use it to see how the score changes between builds. Example: {"kind":"game","limit":10}

| Argument | Type | Required | Description |
|---|---|---|---|
| `kind` | string ["art","game"] | no | Only the art critiques or only the game reviews. Omit for both. |
| `limit` | integer | no | At most this many (newest first). |
| `includeText` | boolean | no | Include each report's full text. Default false. |

## `ai.run` (modifies state)

Run an AI agent on a task in the current project (blocks until it finishes).

Uses the provider/model mapped to `role` in ~/.factoria/ai.json (default orchestrator). CLI providers (claude-code, codex) run their own loop with the FactorIA MCP server attached; API providers run the built-in tool loop. An orchestrator that is itself a CLI agent delegates with this tool: role "worker" (code), "fast" (small edits), "artist" (all the art) or "audio" (all the sound) and a self-contained task; the result's finalText is the sub-agent's report. The roles artCritic and reviewer are refused here: only the user asks for reviews (ai.review). A role the user turned off (roles.<role>.enabled false in ai.json) is refused too (error role_off): do that work yourself. Example: {"task":"Add a pause menu","role":"orchestrator","maxCostUsd":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `task` | string | yes | What the agent should do. |
| `role` | string ["orchestrator","worker","fast","artist","audio"] | no |  Default "orchestrator". |
| `provider` | string | no | Override the role's provider (e.g. claude-code, codex, openrouter). |
| `model` | string | no | Override the role's model. |
| `maxTurns` | integer | no |  |
| `maxCostUsd` | number | no |  |
| `stream` | boolean | no |  Default true. |

## `ai.session_timeline`

Since 0.9.0.

Show where the time of a recorded AI session went: the long gaps and what was going on in each.

Reads one transcript of <project>/.factoria/ai/sessions/ (every event has "t", the UTC time with ms; tool_end has "ms", the duration of the tool; thinking has "ms", how long the model thought, also when its text is hidden). Returns `gaps`: each pause of at least minGapSeconds with start, end, seconds, activity (tool, thinking, model = waiting for the model, user = waiting for the user) and detail (the tool's name...), and `totals` per activity with the tools sorted by time. A session recorded before events carried times gives hasTimes false and a note. Example: {"minGapSeconds":60}

| Argument | Type | Required | Description |
|---|---|---|---|
| `session` | string | no | File name of the session (20261014-153012-orchestrator or with .jsonl) in .factoria/ai/sessions. Omit for the newest. |
| `minGapSeconds` | number | no | List only the gaps at least this long (seconds). Totals always count every gap. Default 30. |

## `ai.tool_servers`

Since 0.8.0.

List the external tool servers (MCP) the user configured in ai.json, and optionally test them.

The user's "mcpServers" (docs/AI_PROVIDERS.md, External tools): services such as Scenario (game art) or local programs whose tools the AI may call. Each entry has name, type (http|stdio), target (URL without its query, or program), enabled, roles (who gets it), usesKey, keySource (where the key was found, never the key), problem (what is missing, "" when ready) and note. With test:true each enabled, ready server is contacted (initialize + tools/list; no tool is called, nothing is spent) and gets `connected`, `server` (how it introduced itself), `tools` [{name, description}] or `error` + `hint`. Keys are never returned. `name` limits the call to one server. Example: {"test":true,"name":"scenario"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `test` | boolean | no | Connect to each server and list its tools. Default false. |
| `name` | string | no | Only this server (a name from the list). |

