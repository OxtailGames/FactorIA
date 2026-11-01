# Connecting AIs to FactorIA

FactorIA lets you work with an AI inside the engine in two ways. You choose per
role (see [Roles](#roles)) and can mix them.

| | **Subscription via a CLI agent** | **API key with credits** |
|---|---|---|
| Providers | `claude-code` (Claude), `codex` (ChatGPT), `generic-cli` (any CLI agent) | `anthropic`, `openai-compatible` (OpenAI, OpenRouter, Gemini, Groq, DeepSeek, Ollama, LM Studio, ...) |
| Who runs the agent loop | the CLI itself | FactorIA (`AgentSession`) |
| What you pay | your existing Claude / ChatGPT plan | per token, to the provider |
| Credentials | the CLI's own login | key in an environment variable or `~/.factoria/ai.json` |

> **Subscriptions never go through FactorIA.** Using your Claude or ChatGPT
> subscription works by spawning the *official* CLI that you install and log in
> to yourself (`claude`, `codex`). FactorIA only starts that program and attaches
> its MCP server (`factoria mcp --project <dir>`, or in the editor the editor's own
> endpoint, see [CLI agents in the editor](#cli-agents-in-the-editor)); it never
> reads, stores or forwards subscription credentials or tokens.

## Quick start

```bash
factoria ai doctor        # what is installed / which keys are visible (never prints keys)
```

### A) Claude subscription (Claude Code CLI)
1. `npm i -g @anthropic-ai/claude-code`
2. Run `claude` once in a terminal and log in.
3. Point a role at it (or use `--provider claude-code`):
   ```json
   { "roles": { "orchestrator": { "provider": "claude-code", "model": "opus" } } }
   ```
FactorIA runs: `claude -p --output-format stream-json --input-format stream-json --verbose --model <model> --resume <session> --mcp-config <file> --allowedTools mcp__factoria --permission-mode acceptEdits`,
with the message on standard input (one `stream-json` line, which can carry pictures),
in the project directory. `--resume <session>` is left out for the first message of a conversation
(see [Conversations](#conversations-and-resume)). The MCP config file is generated at
`<project>/.factoria/ai/mcp-claude-code.json`: a `factoria mcp --project <dir>` server, or the editor's endpoint when the
editor started the CLI (see [below](#cli-agents-in-the-editor)).

### B) ChatGPT subscription (Codex CLI)
1. `npm i -g @openai/codex`
2. Run `codex` once (or `codex login`) and sign in with ChatGPT.
3. Use provider `codex`. FactorIA runs
   `codex exec --json -m <model> -c mcp_servers.factoria.command="factoria" -c 'mcp_servers.factoria.args=["mcp","--project","<dir>"]' -`,
   with the prompt on standard input. Codex starts a **fresh session every message**: FactorIA does not resume it,
   so a follow-up in the editor chat does not remember the earlier messages (the transcript on screen does).

### CLI agents in the editor
A CLI agent runs its own loop in a child process, so its tool calls have to come back to the editor to change the scene
that is open. The editor serves MCP itself: an HTTP endpoint on `127.0.0.1` (a free port, and a path with a random token,
`http://127.0.0.1:<port>/mcp/<token>`, new for each project the editor opens), started by the first message. The MCP
config it writes for Claude Code is `{"mcpServers": {"factoria": {"type": "http", "url": "<that URL>"}}}` instead of a
`factoria mcp` process. Every tool call then takes the same road as an API provider's: the editor's main thread runs the
command between frames. So:

* the viewport shows each edit while the agent works, and each one is a Ctrl+Z step;
* the agent works in edit mode only, and Play / Step wait until it finishes (see `docs/EDITOR.md`);
* `ai_run` (delegation) runs the worker, fast, artist or audio role inside the editor too; a CLI sub-agent gets the same endpoint.

The endpoint speaks MCP Streamable HTTP without a server stream or a session (a POST with one JSON-RPC message gets its
reply as `application/json`, a notification gets 202, GET gets 405). A call that runs longer than 10 s, such as an `ai_run`
that hands a task to the worker, is answered as an event stream that carries `notifications/progress` (what the sub-agent just did, at most one every 3 s,
and a heartbeat every 15 s), so the CLI does not give up on it after 5 minutes of silence. Only the token's path is served, so other programs on
the machine cannot drive the editor. **Codex** still starts its own `factoria mcp` (its argv names the command, not a
config file): its scene edits happen in that process, not in the open scene.

### C) Any other CLI agent
```json
{
  "providers": {
    "my-agent": {
      "type": "generic-cli",
      "command": "my-agent",
      "argv": ["--ask", "{prompt}", "--dir", "{project}", "--mcp", "{mcp_config}"]
    }
  }
}
```
Placeholders: `{prompt}` `{model}` `{project}` `{mcp_config}` (path of a generated
MCP config JSON) `{session}` (the CLI's session id of the conversation, see below) plus `{project_json}` / `{factoria_json}`
(JSON-quoted strings, used by the Codex template). A template without `{prompt}` gets the prompt on standard input: on Windows
prefer that, because CLIs installed with npm are `.cmd` files and `cmd.exe` cannot pass a multi-line argument
(FactorIA refuses arguments with line breaks or `% & | < > ^` for them). If `{model}`, `{mcp_config}` or `{session}` is
empty, that argument (and a bare flag right before it, like `--resume`) is dropped. Output lines are shown as text; JSON lines
with `text`/`result`/`message` are unwrapped.

A template with `--input-format stream-json` gets standard input as one JSON line
`{"type":"user","message":{"role":"user","content":[{"type":"text",...},{"type":"image",...}]}}` (what Claude Code expects).
Every other CLI gets the pictures as files: the prompt ends with `Attached images (read them): <absolute paths>`.

### D) Anthropic API key
```bash
export ANTHROPIC_API_KEY=sk-ant-...
```
No key? If the `ant` CLI is installed and logged in (`ant auth login`), FactorIA
asks it for a short-lived token with `ant auth print-credentials --access-token`
and sends it as `Authorization: Bearer ...`. Set `"useAntCli": false` to disable.

### E) OpenAI and OpenAI-compatible APIs
| Provider | Env var | Base URL |
|---|---|---|
| `openai` | `OPENAI_API_KEY` | https://api.openai.com/v1 |
| `openrouter` | `OPENROUTER_API_KEY` | https://openrouter.ai/api/v1 |
| `gemini` | `GEMINI_API_KEY` | https://generativelanguage.googleapis.com/v1beta/openai |
| `groq` | `GROQ_API_KEY` | https://api.groq.com/openai/v1 |
| `deepseek` | `DEEPSEEK_API_KEY` | https://api.deepseek.com/v1 |
| `ollama` | none | http://localhost:11434/v1 |
| `lmstudio` | none | http://localhost:1234/v1 |

Model names are yours to choose: there is no built-in default. Until you set one
FactorIA stops with `No model configured ... roles.<role>.model`. Any other
server that speaks `/chat/completions` works with
`{"type":"openai-compatible","baseUrl":"https://host/v1","apiKeyEnv":"MY_KEY"}`.
The model must support tool calling.

## Config file

Location: `~/.factoria/ai.json` (Linux/macOS), `%APPDATA%\factoria\ai.json`
(Windows). Override with the `FACTORIA_AI_CONFIG` environment variable. The
file is optional; without it the Anthropic defaults below apply. Schema:
`schemas/ai-config.schema.json` (errors name the JSON pointer and a fix).

```json
{
  "defaultProvider": "anthropic",
  "providers": {
    "anthropic":  { "apiKeyEnv": "ANTHROPIC_API_KEY" },
    "openrouter": { "preset": "openrouter", "headers": { "HTTP-Referer": "https://example.com" } },
    "local":      { "type": "openai-compatible", "baseUrl": "http://localhost:8080/v1", "defaultModel": "qwen2.5-coder" },
    "claude-code": { "command": "claude" },
    "codex":       { "command": "codex", "argv": ["exec", "--json", "-m", "{model}", "-"] }
  },
  "roles": {
    "orchestrator": { "provider": "anthropic", "model": "claude-opus-5-5",   "effort": "xhigh" },
    "worker":       { "provider": "openrouter", "model": "deepseek/deepseek-chat", "maxTokens": 8000 },
    "fast":         { "provider": "local" }
  },
  "limits": { "maxTurns": 40, "maxCostUsd": 5 }
}
```

Provider fields: `type`, `preset`, `baseUrl`, `apiKeyEnv`, `apiKey`, `headers`,
`defaultModel`, `useAntCli`, `sendReasoningEffort`, `command`, `argv` (full
template: **every CLI argument can be overridden**, CLI flags change over time),
`env`, `unsetEnv`, `factoriaCommand` (default `factoria`), `pricing`
(`inputPerMTok`, `outputPerMTok`, ...), `maxRetries`, `timeoutSeconds`, `license`
(asset providers, see [Asset providers](#asset-providers)).

Built-in providers exist without being listed: `anthropic`, `openai`,
`openrouter`, `gemini`, `groq`, `deepseek`, `ollama`, `lmstudio`, `claude-code`,
`codex`, and the asset providers `elevenlabs`, `meshy` and `fake`. Listing one overrides only the fields you give.
A top-level `"assets"` section assigns asset providers to the kinds of asset
(see [Asset providers](#asset-providers)); roles cannot use asset-only providers. A top-level `"assetSources"` section lists
the websites the AI should look at when it searches for assets (see [Asset sources](#asset-sources)). A top-level
`"mcpServers"` section connects external tool servers such as Scenario (see [External tools](#external-tools-mcp-servers)). A top-level
`"extensions"` section loads plugins, skills and hooks into the CLI agents (see [Extensions](#extensions)). The
editor's **AI settings** window edits all four ([below](#the-ai-settings-window)), so none has to be written by hand.

## Roles

The editor shows the roles in three groups with readable names; the `ai.json` keys are the ones in code font.

| Group | Role (name shown) | Job | Default (Anthropic) |
|---|---|---|---|
| Orchestration and code | `orchestrator` (Orchestrator) | plans, reviews, delegates with the `agent_delegate` tool | `claude-opus-5-5`, effort `xhigh` |
| Orchestration and code | `worker` (Worker) | implements features and fixes | `claude-sonnet-5-5`, effort `medium` |
| Orchestration and code | `fast` (Fast) | small mechanical edits; also the check of a feedback `share` text (`ai.review_feedback`) and, for the engine developer, the judging of pulled feedback | `claude-haiku-5-5`, effort `max` |
| Art and audio | `artist` (Artist) | makes all the art: sprites, models, textures, palettes, animation, VFX, UI look | `claude-opus-5-5`, effort `high` |
| Art and audio | `audio` (Audio) | sound effects, music, buses and mixing | `claude-sonnet-5-5`, effort `medium` |
| Critics and reviewers | `artCritic` (Art critic) | **read-only**: looks at the game and the art, gives an opinion and a score | `claude-opus-5-5`, effort `high` |
| Critics and reviewers | `reviewer` (Reviewer) | **read-only**: plays the game, gives an opinion and a score | `claude-opus-5-5`, effort `high` |

The role names are the keys of `roles` in `ai.json`. A role that is missing from `ai.json` follows the provider you
already use instead of falling back to an Anthropic API key: `artist` and `audio` get the provider of `worker`, and
`artCritic` and `reviewer` the one of `orchestrator`, with the model of the Anthropic default (as a tier: `opus`,
`sonnet`, `haiku`, for the CLI providers). So a file with only `orchestrator` / `worker` / `fast` on `claude-code` keeps
all seven roles on Claude Code, and old files keep working. Saving from the Roles window writes only the roles you set.

Each role is `{provider, model, effort?, maxTokens?, maxContextTokens?, enabled?, toolGroups?}`. `effort` is one of
`low|medium|high|xhigh|max` and is always sent explicitly to Anthropic. For
`openai-compatible` providers it is ignored unless `"sendReasoningEffort": true`
(then mapped to `low|medium|high`). A CLI provider runs its own loop and
ignores `effort` (set the CLI's own option in `argv` if it has one).

### Turning a role off

`"enabled": false` (default `true`) turns a role off; in the editor's Roles window it is the **Enabled** checkbox of each
role. For people who do not want sub-agents, or want to spend less. The orchestrator cannot be turned off (it is always
there, and `"enabled": false` on it is an error); every other role can.

* **`worker`, `fast`, `artist`, `audio` off:** nothing is delegated to that role and the orchestrator does the work
  itself. Its system prompt lists only the roles that are on and says which ones are off ("artist is off: make the art
  yourself with the asset tools"); when `artist` or `audio` is off it also gets the guidance that role's own prompt
  would have given (art direction, listening with the analysis tools, and so on). With all four off the orchestrator
  has no `agent_delegate` tool (nor `ai_run`, for a CLI orchestrator) and does everything itself. A delegation that asks
  for a role that is off (`agent_delegate`, `ai.run` / `ai_run`) fails with the error `role_off`, which says what is off
  and where to turn it on, so the orchestrator then does the task itself; `factoria ai run --role <role>` refuses it the
  same way.
* **`artCritic`, `reviewer` off:** the review buttons (and `factoria ai review`) still work, but the review runs on the
  orchestrator's provider, model, effort and limits instead of the role's own. It keeps the read-only critic prompt and
  tools. The button tooltip and the confirmation say so.
* A role that is off keeps its provider and model in the file for when you turn it on again.

`maxContextTokens` (at least 100000) caps how much context a session of that
role keeps, e.g. `400000` on a 1M model: when it gets there, the earlier turns
are replaced by a summary, so every message reads (and costs) less. Without it a
session uses the model's whole window.

| Provider | How the limit is applied |
|---|---|
| `claude-code` | `CLAUDE_CODE_AUTO_COMPACT_WINDOW=<n>` in the CLI's environment: Claude Code auto-compacts at that window |
| `anthropic` | server-side compaction (beta `compact-2026-01-12`, `context_management` edit `compact_20260112` with an `input_tokens` trigger); the summary block stays in the chat's history |
| others | ignored |

The panel's **Context** bar then shows the limit as the window (`47k / 400k`).

The orchestrator delegates on its own: the built-in loop gives it the
`agent_delegate {role, task}` tool; an orchestrator that is a CLI agent (Claude
Code, Codex) is told to use the `ai_run {role, task}` tool of the FactorIA MCP
server instead, which runs the `worker` or `fast` role from `ai.json` and returns
its report. So `orchestrator: claude-code/opus`, `worker: claude-code/sonnet`,
`fast: claude-code/haiku` works on a Claude subscription alone. `--no-delegate`
turns delegation off. The delegable roles are `worker`, `fast`, `artist` and `audio`: the orchestrator sends the art to
`artist` and the sound to `audio` (it can write a brief and judge the result, but the art and the audio are not its own
work). `artCritic` and `reviewer` are not delegable: they run only when the user asks (see [Reviews](#reviews)), and
`ai_run` / `agent_delegate` refuse them. They also refuse a delegable role that is turned off (see
[Turning a role off](#turning-a-role-off)).

**Only `ai_run` delegates.** Claude Code has sub-agent tools of its own (`Agent`, `Task`) that would run a model
nobody configured, outside FactorIA's roles, costs and live view. FactorIA starts Claude Code with
`--disallowedTools Agent,Task` (and `mcp__factoria__ai_review`, so the orchestrator cannot start a review either), and the
orchestrator's prompt says to use `ai_run`. Codex has no such switch in its
command line: there the rule is only in the prompt.

`ai_run` blocks: the orchestrator's tool call returns when the sub-agent has finished, which can take many minutes, and the
orchestrator is told so (it waits for the result and never promises to continue later or polls with Bash). While it runs:

* **in the editor** the sub-agent's steps (its messages and tool calls) appear in the chat as they happen, indented under
  the orchestrator's `ai_run` call, and the panel shows how long the run has lasted and when the agent last did something
  (see `docs/EDITOR.md`, AI Assistant);
* **toward the MCP client** the call reports progress (`notifications/progress`, `docs/MCP.md`), so Claude Code does not
  abort it after 5 minutes of silence, and the MCP config the editor and `factoria new` write carries a four-hour
  `timeout` for one tool call;
* **in a terminal**, `factoria ai run` prints `  | worker > ...` lines for the sub-agent's steps (with `--json`, events
  `{"event":"progress","text":...}`). The `ai_run` call runs in the `factoria mcp` process that the CLI orchestrator
  starts, so that process appends the lines to `.factoria/ai/progress.log` of the project, and the terminal follows the
  file while the run lasts. The file only grows; delete it any time.

If the orchestrator's turn ends while the sub-agent still runs (the CLI cut the call off, for instance), the editor keeps
the sub-agent going, and when it finishes it puts the report in the chat and continues the orchestrator's conversation
with it (the same Claude Code session, resumed): see `docs/EDITOR.md`. Outside the editor nothing continues the
orchestrator, so the report is only in the sub-agent's own output.

An agent that stops producing events is not necessarily stuck: a model can think for minutes before its next step. The
editor warns after `limits.stuckAfterSeconds` of silence (default 180, 0 = never; `docs/AI_COSTS.md`) and lets you check
what the agent's process is doing before you decide.

`factoria ai run "task"` and the `ai.run` command use the `orchestrator` role
unless told otherwise (`role`: orchestrator, worker, fast, artist or audio; `provider`, `model` options). The editor AI
panel always sends your messages to the orchestrator; its **AI > Roles...** menu item (the Roles tab of the AI settings window) sets the
provider, model, effort and context limit of the seven roles and saves them in `ai.json` (only
`roles` is rewritten: providers, limits and a role's `maxTokens` stay). The item is disabled
until the first provider detection has read `ai.json`.

### Choosing a model

In the Roles window the **Model** column is a dropdown of the models the selected provider really offers, so
nobody has to know or mistype their names. The lists are asked of the providers themselves when the editor opens a
project (right after the provider detection) and again with **Refresh models** next to the "Saved in" line, so a model
released today shows up without updating FactorIA. Only available providers are asked.

| Provider | Where its list comes from |
|---|---|
| `claude-code` | The CLI's own `initialize` control request (`claude -p --input-format stream-json --output-format stream-json --verbose`, one JSON line on stdin). No model call, no usage. Aliases (`opus`, `sonnet`...) come first, with the model each one stands for, then full names |
| `anthropic` | `GET <baseUrl>/v1/models?limit=1000`, authenticated like chat requests: the API key, or the `ant` login token |
| `openai-compatible` (`openai`, `openrouter`, `gemini`, `groq`, `deepseek`, `ollama`, `lmstudio`...) | `GET <baseUrl>/models`, with `Authorization: Bearer <key>` when a key is set (local servers need none). A server that is not running fails after 3 seconds |
| `codex`, other CLIs | They cannot list their models: the cell stays a text box, type the name |

The dropdown starts with `default` (the model setting is left empty: the role's own default for the Anthropic API, the
CLI's own for Claude Code, whose real default it shows when you hover it). Each model shows as `Display name  (id)`
(just the id when the provider gives no name); hover one for its description and, for an alias, the model it stands
for. **Other...** at the end turns that role's cell into a text box, for a name that is not in the list (clear it, or
type a listed name, to get the list back). A provider that is not available on this computer (its CLI is not
installed, no API key) shows **Provider not available** in the cell, with the reason and how to set it up as its
tooltip. When an available provider's list could not be fetched the cell is a text box with the reason as its tooltip;
fix it (a key, a server that is down) and press **Refresh models**. Claude Code's cell is a dropdown even then, with
the aliases it always accepts (`default`, `opus`, `sonnet`, `haiku`). Changing a role's provider resets its model to
`default`.

CLI providers are looked up in `PATH` and then in the folders their installers use (`~/.local/bin`, `~/.claude/local`,
the npm, bun, volta and nvm bins, Homebrew, `%APPDATA%\npm`): an editor opened from Finder or the Dock gets a shorter
`PATH` than a terminal, and the CLI would otherwise look missing.

The same lists are available to tools and AIs as the read-only command `ai.models {provider?}` (a CLI call, an MCP
tool `ai_models`):

```json
{"providers": [
  {"name": "claude-code", "models": [
    {"id": "default", "name": "Default (recommended)", "description": "Opus 5.5 · Best for everyday, complex tasks", "resolved": "claude-opus-5-5"},
    {"id": "sonnet", "name": "Sonnet 5.5", "description": "Efficient for routine tasks", "resolved": "claude-sonnet-5-5"}]},
  {"name": "codex", "models": [], "error": "Provider 'codex' (codex) does not list its models", "hint": "Type the model name; ..."}]}
```

Without `provider` it asks every available provider; one provider's failure is in its own entry (`error`, `hint`)
and does not fail the call. `resolved` is empty for a full model name.

## Reviews

Two roles do not build anything: they look, play and judge. `artCritic` looks at the art (screenshots of every scene, the
sprites and models, the UI) and `reviewer` plays the game like a press reviewer. Each writes a report with a **score from
0 to 10** and sub-scores (for art: direction, consistency, readability, polish; for a game: fun, game feel, design,
UX, stability, polish, art, audio), what works, what does not, and what to fix first.

**They run only when you ask.** The orchestrator, the worker and the other roles cannot start them (`ai_run` and
`agent_delegate` refuse these roles, and the orchestrator is told so). Ask from the editor's AI Assistant (the **Art
critique** and **Game review** buttons, see `docs/EDITOR.md`), from a terminal or from a script:

```bash
factoria ai review game                      # one reviewer, the all-rounder
factoria ai review art --count 3 --focus "the main menu"
factoria ai reviews --kind game --limit 10   # the saved ones, newest first, with their scores
```

The commands are `ai.review {kind: art|game, count?, focus?, provider?, model?, maxTurns?, maxCostUsd?}` (it blocks until
all the reviewers are done and returns `{reviews, averageScore, costUsd, errors}`) and `ai.reviews {kind?, limit?,
includeText?}`. `ai.review` is not read-only: it spends tokens and writes the review files.

* **Several reviewers.** `count` (default 1, at most 5) starts that many one after the other, each with its own persona.
  The first is always the all-rounder, so one reviewer is comparable from build to build. The art personas are
  all-rounder, art director, first impression, technical artist, and UI and accessibility designer; the game personas are
  all-rounder, genre veteran, newcomer, QA tester and design critic. Each works alone and writes its own opinion.
* **Saved.** Every review is returned and also written to `<project>/.factoria/ai/reviews/<time>-<role>.json`
  (`-2`, `-3` ... for the further reviewers of one request) with the text, the score, the sub-scores, the persona, the
  provider and model, the focus, the cost, the engine version and the game version from `factoria.json`, so you can see
  whether the score goes up between builds. A reviewer that gives no score is saved with `score: null`.
* **Read-only is enforced, not requested.** The reviewer keeps only the tools that look and play (listing and reading,
  `game.step`, `game.input`, `game.click`, `game.screenshot`, `scene.load`, UI scale and language checks, ...). With the
  built-in loop the other tools are not offered to the model. Claude Code runs with `--disallowedTools` for `Edit`, `MultiEdit`,
  `Write`, `NotebookEdit` and `Bash`, plus every FactorIA MCP tool that changes something, and Codex with `--sandbox read-only` and a
  `factoria mcp --read-only` server (Codex is the least tested of the three). Loading a scene to look at it does not
  change the project on disk.
* **REVIEW.md.** The reviewers read the `REVIEW.md` of the project first: controls, the goal, what is finished and what
  is a placeholder, and how to reach every scene and state quickly. A game that is easy to test gets a more useful review
  (`docs/AI_GUIDE.md`, "Keep the game reviewable"). `factoria export` leaves `REVIEW.md` out of the player's build.
* **Send to the orchestrator.** A review is only an opinion. In the editor you press **Send to orchestrator** on the
  report to post it into an orchestrator chat as your message (the active chat, or a new one); the orchestrator then
  plans the fixes and delegates them. Nothing is sent unless you press it.

The models come from the `artCritic` and `reviewer` roles (or from the orchestrator when you turned the role off, see
[Turning a role off](#turning-a-role-off)); the cost of a review is counted like any other run
(`docs/AI_COSTS.md`).

## How the built-in agent behaves (API providers)

* Tools: not every command is sent as a tool on every step (that was about 80k tokens of definitions on each one). The
  built-in agent gets the **core commands** in full (`fs_*`, `docs_*`, the scene commands `scene_spawn`, `scene_set_component`,
  `scene_save`..., `game_step`, `game_input`, `game_click`, `game_screenshot`, `game_state`, `game_logs`, `project_validate`,
  `project_info`, `project_test`, `script_*`, `feedback_report`, `assets_list`, `assets_import`), the commands of the
  **tool groups** of its role in full, and a **catalog** in the system prompt: one line (`command: what it does`) for every
  other command. Two loop tools reach those: `tool_describe {commands: [...]}` returns the full definition (description and
  input schema) of commands, and `tool_call {command, arguments}` runs one; a wrong call to a catalog command comes back
  with its input schema. Plus `agent_delegate {role: worker|fast|artist|audio, task}` for the orchestrator. `ai.*`
  commands are hidden from the model. See [Tool groups and the catalog](#tool-groups-and-the-catalog).
* Safety limits: `limits.maxTurns`, `maxCostUsd`, `maxTotalTokens`, Ctrl+C /
  cancel flag. Transient errors (429, 5xx, 529) are retried with backoff and
  `Retry-After`.
* Anthropic specifics: prompt caching (`cache_control`), adaptive thinking
  (default; thinking blocks are kept untouched in the history), `output_config.effort`,
  server-side refusal fallback for Opus/Sonnet 5.5. Refusals are surfaced with
  category and explanation.
* Transcripts: `<project>/.factoria/ai/sessions/<time>-<role>.jsonl`
  (one JSON object per line: messages, tool results, usage). They contain what
  the model saw, never your API keys. The last line is the `end` event; a run that was cancelled has `"cause"` there
  (`user_stop`, `stuck_stop`, `watchdog_process_gone`, `project_closed`, `editor_closing`, `editor_restart`...) and an
  `error` like `cancelled: the user pressed Stop`, which `ai.run` also returns to its caller.
* Times in the transcript: every line has `t`, the UTC time it was written (`2026-10-30T14:03:22.481Z`). A CLI agent's
  `tool_end` has `ms`, how long the tool ran; its `thinking` lines have `ms`, the time since the line before them (the
  model thought that long, also when its text is hidden and the line has none). The built-in agent's `assistant` lines
  have `ms` (the model call) and each entry of `tool_results` has `tool` and `ms`. Logs written before this have no `t`.
  `ai.session_timeline {session?, minGapSeconds?}` (CLI: `factoria call ai.session_timeline`) reads one transcript (the
  newest by default) and returns the gaps of at least `minGapSeconds` (default 30) with what was going on (`tool`,
  `thinking`, `model` = waiting for the model, `user` = waiting for the user), plus `totals` per kind and per tool, so you
  can tell a long think from a slow tool. For a log without times it returns `hasTimes: false` and a note.
* Context sizes in the transcript: each `assistant` line of the built-in agent has `context`, the split of the request that
  call sent: `systemBytes` (the system prompt, `catalogBytes` of it the command catalog), `toolBytes` (the tool
  definitions), `conversationBytes`, the same three as estimated tokens (bytes divided by 3.75, not the provider's count),
  `toolCount` and `catalogCount`. The `start` line has `tools` (how many), `catalogCommands` and `toolGroups`.
  `ai.session_timeline` returns a `context` object with this per step and the totals of the run (`toolShare` is the tool
  definitions' share of everything the run sent). CLI agents send their own tool list, so their logs have none of it.
* Screenshots: a command result `{"image": {"mediaType": "image/png", "data": "<base64>"}}`
  is attached to the model as an image.

### Tool groups and the catalog

Every command is a tool the model could use, but sending the definitions of all of them (summary, description and input
schema: 186 commands, about 320 KB) on every step costs about 80k tokens before the model reads a word. The built-in agent
offers instead:

* the **core commands** in full (the list above; `is_core_tool` in `tools/ai/include/fa/ai/tool_catalog.h`),
* the commands of the role's **tool groups** in full: a group is a command category (`assets`, `anim`, `audio`, `ui`, `i18n`,
  `platform`, `publish`, `perf`, `nav`, `physics`, `mesh`... the `category` of `factoria commands`), the exact name of a command
  (`assets.draw_icon`) or `"all"` (every command in full: the old behaviour),
* `tool_describe` and `tool_call`, and
* a `# Tools` section in the system prompt with one line per remaining command, grouped by category.

The model reads the catalog, describes the commands it is about to use (several in one call) and calls them through
`tool_call`, which runs the command under its own name: the chat shows `assets_slice_sheet`, not `tool_call`, and the transcript and
the events carry the command's arguments. The catalog is used only when it saves something (the definitions it leaves out add
up to more than 6000 bytes), so a small registry is offered in full.

A role names its groups in `ai.json`, `"roles": {"artist": {"toolGroups": ["assets", "anim"]}}`. Without `toolGroups` the
artist loads `assets` and the audio role `assets` and `audio`; every other role loads none. A list replaces the default
(`[]` loads nothing but the core). A name that matches no category or command is reported as an Info line in the chat when the
run starts, with suggestions. `factoria call ai.tool_plan '{"role":"artist"}'` shows what a role gets: the tools sent with
their estimated sizes, the catalog's size, the groups that matched and the cost of offering everything in full.
CLI agents (Claude Code, Codex...) choose their own tools and ignore `toolGroups`; see [MCP.md](MCP.md#tool-definitions-and-claude-code).

Why this shape. Tool definitions are the start of the prompt cache's prefix (before the system prompt and the messages):
adding a tool in the middle of a conversation would rewrite the cache of everything after it. So the tool list is computed once
per run and **never changes while the conversation goes on**: describing a command does not add a tool, its definition comes
back as the result of `tool_describe` and stays in the conversation like any other result. The catalog is part of the
system prompt, which is also fixed for the run (the registry can change between two messages, for example when a project
tool is added: then the next message pays one cache rewrite, as it does when the project's file listing changes).
The alternative, Anthropic's server-side tool search (`defer_loading` on each tool plus a search tool), still sends every
definition in every request and only keeps them out of the model's context, so the request stays large; it exists only on the
Anthropic API and could not be tested offline, so the engine does the same on the client for every API provider.

Read-only roles (`artCritic`, `reviewer`) get the same mechanism over the commands that look and play only: the catalog does
not list a command that changes the project, `tool_describe` does not know it, and `tool_call` refuses it with `not_allowed`
("a read-only role cannot use it"), the same set `is_read_only_tool` and `cli_disallowed_tools` already define. A command
that is excluded for every agent (`ai.*`) is refused the same way.

## Conversations and resume

The editor's AI panel keeps a real conversation per chat tab: a follow-up message continues the earlier one instead of
starting from scratch.

| Provider kind | How the conversation continues |
|---|---|
| Claude Code | the session id the CLI reports is kept and passed back with `--resume {session}`; only the new message is sent |
| API providers (`anthropic`, `openai`, ...) | the message history (text, tool calls and results; picture bytes are dropped from the saved copy) is sent again with the new message |
| Codex, other CLIs | no resume: every message is a fresh session (add `{session}` to `argv` if your CLI can resume one, and make it report the id in a `session_id` JSON field) |

If Claude Code no longer knows the session (`No conversation found`, e.g. its data was cleaned up), FactorIA says so in
the transcript and starts a new session with the whole earlier text. A conversation switched to another provider or
model starts fresh. The API history is not trimmed: a very long chat costs more per message, so open a new tab to start clean.
The editor also puts one line before the message that names the selected entity
(`[Viewport selection: entity "Player" (id "e3"). "this" and "it" in the request mean this entity.]`), so "make it bigger" works.
Chats are saved in `<project>/.factoria/ai/chats/` (see [EDITOR.md](EDITOR.md)).

## Pictures in messages

A message can carry pictures (png, jpg, jpeg, gif, webp; up to 20 MB each). In the editor you drop files on the window,
paste with Ctrl+V while the AI input has focus, or press **Attach image...**; each one is copied to
`<project>/.factoria/ai/attachments/`. Claude Code and the API providers get the pixels in the request itself; other CLIs get
the absolute paths of those files at the end of the prompt, so the agent can open them.

## Usage display

The AI panel shows what the provider reports, never a guess:

* **Session (5h)** and **Week**: how much of the plan's limit is used, with the local time the window resets. Claude Code
  reports them in `rate_limit_event` lines, Codex in its `rate_limits`. A window whose reset time has passed shows as 0%.
  Plan limits are shared by all chats. They are not kept between runs of the editor: other Claude Code / Codex sessions
  use the same plan in between, so old numbers would be wrong. Until the first message of a run the panel shows a dim
  "Plan usage updates after the first message.".
* **Context**: tokens in the model's context window now (the last request, not the sum of the run), for example `47k / 1M`.
  Hover it with the built-in agent to see where the last call's context went (estimated): the system prompt (and the part of it
  that is the command catalog), the tool definitions (and how many tools) and the conversation.
* **Tokens** (in / out / cache) and **API cost est.** of the chat. The cost is an estimate of what the same tokens would cost
  on the provider's pay-per-token API (the CLI's own number when it reports one); on a subscription plan (Claude Code /
  Codex sign-in) none of it is billed on top of the plan, and the line says so. Both are live while an agent works (every assistant message adds its usage once,
  sub-agents included; Codex adds each turn); the cost is the engine's price-table estimate until the CLI's final totals
  replace it. The plan windows are not refreshed during a run: Claude Code emits `rate_limit_event` once per message.

## Asset providers

The `assets.generate_*` commands ([ASSETS.md](ASSETS.md)) make images, sprite sheets, sounds, music, voices and 3D models
through **asset providers**. They are configured here, in `ai.json`, next to the LLM providers, but they are not roles:
the `assets` section maps each kind of asset (`image`, `sound`, `music`, `voice`, `model3d`) to the provider, and
optionally the model and voice, that makes it. In the editor, the [AI settings window](#the-ai-settings-window) does this
without editing the file.

```json
{
  "assets": {
    "image":   { "provider": "openai", "model": "gpt-image-1" },
    "sound":   { "provider": "elevenlabs" },
    "music":   { "provider": "elevenlabs" },
    "voice":   { "provider": "elevenlabs", "voice": "21m00Tcm4TlvDq8ikWAM" },
    "model3d": { "provider": "meshy" }
  }
}
```

There is **no default provider**. Generation costs money, so a kind that is not listed is an error that shows the JSON to add
(and mentions the `fake` provider); the `no_provider` error also lists which configured providers can make that kind
and which cannot (and why), the environment variables that would enable one, and the offline commands that make something
without a provider (`assets.generate_texture` and `assets.rasterize_svg` for images, `assets.synth_sound` and
`assets.generate_loop` for sounds). Every command also takes `provider` and `model` for one call. Keys come from the
environment, like the LLM keys.

| Provider | Makes | Key (env var) | Endpoints (official docs) |
|---|---|---|---|
| `openai` (and servers that copy its API) | image, voice | `OPENAI_API_KEY` | `POST {baseUrl}/images/generations`, `POST {baseUrl}/images/edits` (when reference images are sent), `POST {baseUrl}/audio/speech` ([images](https://developers.openai.com/api/docs/guides/image-generation), [speech](https://developers.openai.com/api/docs/guides/text-to-speech)) |
| `elevenlabs` | sound, music, voice | `ELEVENLABS_API_KEY` | `POST https://api.elevenlabs.io/v1/sound-generation`, `/v1/music`, `/v1/text-to-speech/{voice_id}` ([docs](https://elevenlabs.io/docs/api-reference)) |
| `meshy` | model3d | `MESHY_API_KEY` | `POST https://api.meshy.ai/openapi/v2/text-to-3d`, then `GET .../{id}` until it succeeds ([docs](https://docs.meshy.ai/en/api/text-to-3d)) |
| `fake` | all | none | none: offline placeholders, see below |
| `asset-command` | all | none | a program of yours, see below |

Details that matter:

- **OpenAI.** Images default to model `gpt-image-1`: it draws 1024x1024, 1536x1024 or 1024x1536 (whichever is closest to the
  aspect you asked for) and FactorIA resizes to your size. `transparent` asks for a transparent background. Reference images
  (from the call and from `style.references`) go to the image-edit endpoint as PNG, JPEG or WebP. Speech defaults to
  `gpt-4o-mini-tts`, voice `alloy`, and is returned as MP3. Any other `baseUrl` that copies the API works.
- **ElevenLabs.** Everything arrives as MP3, so the path ends in `.mp3`. Sound effects last 0.5 to 30 seconds, music 3 to 600
  and is instrumental. Speech needs a voice id (your voice library on elevenlabs.io): set it as `assets.voice.voice` or
  pass `voice`.
- **Meshy.** Text-to-3D in `preview` mode: an untextured mesh as `.glb`. The call creates a task and polls it every 5 seconds
  until it succeeds, fails, or `timeoutSeconds` (default 600) has passed; the task keeps running on Meshy's side.
- **`fake`.** Needs no key and no network. A PNG (a gradient with stripes and a shape, transparent when asked, a different
  shape in every frame of a sheet), a WAV (a falling tone for a sound, an arpeggio for music, a buzz for a voice) or a small
  glTF cube, all deterministic: the same request gives the same bytes. Use it to try the flow, in tests and CI, and in
  games' own test projects. Its files are marked `ai: true` in the provenance so that placeholders never ship unrecorded;
  its license note says to replace them.
- **`asset-command`.** A local program (ComfyUI or Stable Diffusion through a script, a Blender script, a CLI) makes the file.
  `command` and `argv` are a template, like a CLI agent's; the program writes the result to `{output}`.

  ```json
  {
    "providers": {
      "comfy": {
        "type": "asset-command",
        "command": "python",
        "argv": ["/home/me/tools/txt2img.py", "--prompt", "{prompt}", "--size", "{width}x{height}", "--seed", "{seed}", "--out", "{output}"],
        "env": { "COMFY_URL": "http://127.0.0.1:8188" },
        "license": "Output of my local SDXL checkpoint (CreativeML Open RAIL++-M)",
        "timeoutSeconds": 300
      }
    },
    "assets": { "image": { "provider": "comfy" } }
  }
  ```

  | Placeholder | Value |
  |---|---|
  | `{prompt}` | the prompt, on one line |
  | `{output}` | the file to write (PNG for images, WAV for sound, music and voice, GLB for models) |
  | `{width}` `{height}` | the size asked for (images; the result is resized to it) |
  | `{seconds}` | the length asked for (0 = the program chooses) |
  | `{kind}` | `image`, `sound`, `music`, `voice` or `model3d` |
  | `{model}` | `assets.<kind>.model` or the `model` of the call |
  | `{seed}` | the `seed` of the call, else a number derived from the prompt; the seed is recorded only when `argv` has `{seed}` |

  The program is run with `env`/`unsetEnv` of the provider and stopped after `timeoutSeconds`. A non-zero exit, a timeout
  and a missing `{output}` file are errors that say what happened. On Windows a `.cmd`/`.bat` program cannot receive
  `% & | < > ^` or line breaks in an argument: use an `.exe` or a Python wrapper if prompts need them. It cannot take
  reference images or voices (the result says so); use `style.prompt` for the look.

Provider fields used by asset providers: `type` (`openai-compatible` for OpenAI, `elevenlabs`, `meshy`, `fake`,
`asset-command`), `baseUrl`, `apiKeyEnv`, `apiKey`, `headers`, `command`, `argv`, `env`, `unsetEnv`, `maxRetries` (at most
2 are used: a retry is a second payment), `timeoutSeconds` and `license`: the note recorded in the provenance of what the
provider makes (default: where its terms are).

**Keys and privacy.** The same rules as for the LLM keys: environment variables or the user-level `ai.json`, never the
game project; keys go only to the provider's `baseUrl`, in headers, and are not written to assets.json, results or logs. What
is sent to an asset provider is the prompt (with the house style), the reference images and, for voice, the text.

**Cost.** Asset providers bill for every call, and FactorIA does not know their prices (`limits.maxCostUsd` covers LLM runs
only). Look at the first result before generating a batch, prefer `fake` while the flow is being built, and check the
provider's pricing page.

`factoria ai doctor` lists the asset providers (`[makes image, voice]`, whether a key was found) and which provider each kind
of asset is assigned to.

## The AI settings window

**AI > AI Settings...** (the AI menu of the menu bar) is where the roles and the asset side of `ai.json` are set up. Its
**Roles** tab (also **AI > Roles...**) has the role table and its own **Save**; the **Assets** tab has two sections and one
**Save** button:

* **Asset generation.** One row per kind of asset (Image, Sound, Music, Voice, 3D model): the provider that makes it (only
  providers that can make that kind are listed, and **None (made procedurally)** leaves the kind to the offline commands), the
  model (the hint is the provider's default), for Voice the voice id, and a status: the key was found (and where), or what is
  missing, the same checks as `factoria ai doctor`. `fake` and `asset-command` can be chosen too; for `asset-command` the window
  asks for the program and its arguments line (`{prompt}`, `{output}` and the other placeholders, see
  [Asset providers](#asset-providers)). Under **API keys** each provider in use has a masked box: a key pasted there is stored
  as that provider's `apiKey`. An environment variable is still the better place for a key, and the window says which one the
  provider reads; **Remove stored key** takes a stored one out again.
* **Asset sources.** The websites the AI looks at for assets, per category, and **Use only these sites**
  ([next section](#asset-sources)).

Save rewrites only `assets`, `assetSources` and the provider fields these need (`apiKey`; `type`, `command` and `argv` of an
`asset-command` provider). Providers, roles, limits and every other key of the file stay as they are, and a file that is not valid
JSON is left alone (the window says so instead of overwriting it). Then it reloads the file: the next asset the AI makes and the
next message use the new settings; nothing else needs a restart. The window always edits the user's `ai.json` (the one in
`FACTORIA_AI_CONFIG`, if set), never a file of the game project.

The **External tools** tab (between Roles and Assets) sets up the `mcpServers` of [External tools](#external-tools-mcp-servers):

* **Servers.** One row per server: a checkbox to turn it on or off, its name, where it lives (a web address or a program), which
  roles get it (`default`, or how many were chosen), and a status. **Test** connects to that server in the background (the editor
  stays usable) and shows what it said: `Connected to <server>: N tools (the first twelve names)`, or the error with its hint. It only
  asks for the tool list; no tool is called and nothing is spent. **Edit** opens the form, **Remove** drops the row (until Save).
* **Add server** / **Edit.** Name; Kind (Web service (HTTP) or Program on this computer); the Address and Headers (one
  `Name: value` per line), or the Program, Arguments (one line, quote what has spaces) and Environment (`NAME=value` per line);
  the Key (a masked box, stored as `apiKey`) or the name of the environment variable that holds it (the window suggests
  `<NAME>_API_KEY` and says an environment variable is the better place); a Note for the AI; checkboxes for who may use the server
  (the review roles are off unless ticked); and how long to wait per call. **Test these settings** tries the form before it is
  applied; **Apply** checks it the way the loader does and puts it in the table; **Cancel** drops it.
* **Paste JSON...** takes what a service's documentation shows for Claude Code: a whole `{"mcpServers": {...}}` or one server
  (then a name is taken from the address or program unless you type one). Keys FactorIA does not use (such as `disabled`) are
  listed and skipped. A server with a name already in the table replaces it.
* **Save** rewrites only `mcpServers` (the file is made private first when it holds a key) and reloads the file; every other key
  stays and a file that is not valid JSON is left alone. The next message uses the servers. **Close** drops what was not saved.

The **Extensions** tab (after External tools) sets up the `extensions` of [Extensions](#extensions):

* **Extensions.** One row per entry, yours and the open project's: On, its kind (plugin, skill, hooks), name, where it comes from
  (`you` = `ai.json`, `project` = the project's file), where it points, one checkbox per role (the same defaults as the tool
  servers: the review roles `ArtC` and `Rev` are off unless ticked), **Remove**, and a status: `Ready`, `Cannot load` (the tooltip
  says why and how to fix it) or `Not trusted` (a project's plugin or hooks, see below).
* **Skills.** Under the entries, one row per skill any role can be offered ([SKILLS.md](SKILLS.md)): FactorIA's own, the ones in
  `~/.factoria/skills`, the project's `skills/` and the folders of the entries above. On, its name, where it comes from (`engine`,
  `you`, `project`), what it is for, one checkbox per role and a status (`Ready`, `Off`, `Replaced` when another skill of the
  same name wins, or `Cannot load` with the reason in the tooltip). A change is kept as a skill entry (an engine skill by its `engine:<name>`
  path) and **Save** writes it like any other entry.
* **Add.** A plugin folder or `.zip`, a skill folder, or an installed Claude Code plugin typed as `name@marketplace`; **Browse...**
  picks a folder; the name is taken from the folder unless you type one; **Only for this project** keeps the entry in the project's
  `.factoria/extensions.json` (the path is then stored relative to the project) instead of your `ai.json`. A mistake is refused with the
  loader's own message, for example a relative path in `ai.json`.
* **Paste hooks JSON...** takes the `hooks` of a Claude Code `settings.json` (`{"hooks": {...}}` or the events object itself), checks
  the event names and handler types, and adds it as one named hooks entry.
* **Claude Code also loads my own plugins, skills and hooks** is `inheritUserPlugins`. Off drops ALL of your own Claude Code
  settings for FactorIA's runs (plugins, skills, hooks, permissions and env), not only the plugins.
* **This project** shows the project's file and, when it lists plugins or hooks, or when its `.claude/settings*.json` runs a program or
  widens what the AI may do (env, allowed tools), what they would run (**Review what would run...**) with **Trust this project** (and **Stop trusting this project**
  afterwards); the trust covers both sources. A warning line appears when the project's
  `.claude/settings*.json` denies FactorIA's own tools to Claude Code, naming the rule and how to remove it.
* **Save** rewrites only `extensions` of your `ai.json` and, when the project's entries changed, the project's
  `.factoria/extensions.json`; every other key stays. A trust you had given carries over to a project file you save from here
  (you just saw its content), but not to one that changed on disk behind the editor's back.

## Asset sources

`assetSources` tells the AI where to get assets that it does not generate: websites for images and textures, 3D models, audio,
fonts and the rest. Without it the AI searches the internet as it wishes.

```json
{
  "assetSources": {
    "images": [{ "url": "https://opengameart.org", "note": "CC0 packs" }, "kenney.nl"],
    "models": ["https://kenney.nl/assets/category:3D"],
    "audio":  [{ "url": "freesound.org", "note": "CC0 only" }],
    "fonts":  ["fonts.google.com"],
    "other":  [],
    "onlyListed": true
  }
}
```

Each entry is a web address or just a domain (a string, or `{ "url", "note" }`; the note tells the AI what the site is good
for or its license). `onlyListed` is `false` by default:

* **Off** (the checkbox is clear): the listed sites come first; the AI may search the internet too when none of them has
  what the game needs, as before.
* **On** (**Use only these sites**): the AI searches and fetches assets only on the listed sites.

An empty list (or no section) changes nothing. A site that is not a web address is an error that names its JSON pointer
(`/assetSources/images/0/url`) and what to write instead.

**What the AI is told.** The orchestrator, worker, fast, artist and audio roles get an "Asset sources" section in their system
prompt: the sites per category with their notes and the rule above. Whatever the AI takes from a site, it is told to check the
license, bring the file in with `assets.import` and pass `sourceUrl`, `license` and `author`, so `assets.json` keeps them
([ASSETS.md](ASSETS.md)). The reviewers do not get the section: they do not bring assets in.

**What is enforced.** Telling the model is not a guarantee. Where the provider lets FactorIA restrict the tools, it does:

| Provider | `onlyListed` off | `onlyListed` on |
|---|---|---|
| Claude Code | WebFetch of the listed sites is allowed up front (the host and its `www.` twin) | the same, and **WebSearch is disallowed**; Claude Code in `-p` mode denies any WebFetch outside the allow list, so only the listed sites can be fetched |
| Codex, generic CLI agents | the prompt rule | the prompt rule only: FactorIA cannot restrict their web access |
| API providers (the built-in agent) | the prompt rule | the prompt rule; the built-in agent has no web tool, so it cannot browse at all and tells you which site to download from |

Limits of the enforcement, so it is not trusted for more than it does: it covers Claude Code's WebFetch and WebSearch tools,
not `curl` or a script run through Bash, and a domain rule matches that exact host (`kenney.nl` and `www.kenney.nl` are covered,
a subdomain such as `cdn.kenney.nl` has to be listed as its own entry). A WebFetch allowed globally in the user's own Claude Code
settings still works. Use the prompt rule as the user's wish and the allow list as a safety net.

## External tools (MCP servers)

`mcpServers` in your `ai.json` connects the AI to services and programs of your own choosing: an image generator such as
[Scenario](https://www.scenario.com) (game art), a search or file tool, anything that speaks the Model Context Protocol (MCP). The
AI calls their tools when it sees fit, next to the engine's own tools. FactorIA does not know any service in particular: a server
is an address (or a program) plus the key it wants, so Scenario is one entry among whatever you add.

The shape is the one Claude Code's `.mcp.json` uses, so the JSON a service's documentation gives for Claude Code can be pasted
(the editor has a button for it, [below](#the-ai-settings-window)):

```json
{
  "mcpServers": {
    "scenario": {
      "type": "http",
      "url": "https://mcp.scenario.com/mcp",
      "headers": { "Authorization": "Basic {key}" },
      "apiKeyEnv": "SCENARIO_API_KEY",
      "note": "AI game art: sprites, textures, icons, consistent styles. Costs Scenario credits.",
      "roles": ["orchestrator", "artist"],
      "timeoutSeconds": 300
    },
    "files": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${ART_DIR:-./art-references}"],
      "env": { "SOME_TOKEN": "${SOME_TOKEN:-none}" }
    }
  }
}
```

The server name is the key (`[A-Za-z0-9_-]`, up to 40 characters, not `factoria`: that is the engine's own server).

| Field | Meaning |
|---|---|
| `type` | `http` (a web service, Streamable HTTP) or `stdio` (a program on this computer). Left out: `command` means `stdio`, `url` means `http`. The old SSE transport (`type: "sse"`) is not supported. |
| `url` | `http`: the server's endpoint, usually ending in `/mcp`. `https://`, or `http://` for a server on this computer. |
| `headers` | `http`: extra headers (name to value), usually the one that carries the key. |
| `command`, `args`, `env` | `stdio`: the program, its arguments and extra environment variables (added to the editor's own). |
| `apiKeyEnv`, `apiKey` | Where `{key}` comes from: the environment variable named by `apiKeyEnv`, otherwise `apiKey` (the key written in this file). Prefer the variable. |
| `note` | One or two lines for the AI's prompt: what the server is good for and what it costs. The AI reads it, so write for it. |
| `roles` | Who may use the server (role names, see [Roles](#roles)). Left out: orchestrator, worker, fast, artist and audio. The review roles (`artCritic`, `reviewer`) get a server only when listed here. |
| `enabled` | `false` keeps the entry without using it. |
| `timeoutSeconds` | How long one tool call may take (default 120; generating an image takes a while). |

`{key}` in a header value, an argument or an environment value is replaced by the key, and `${NAME}` or `${NAME:-default}` by
an environment variable. A reference with nothing to fill it in is not guessed: the server is left out of the run and the error
says which variable to set (restart the editor, or open a new shell, after setting one).

**Scenario.** Create an API key and secret in your Scenario account (see Scenario's documentation for the current address and
header; the entry above is its `Basic` scheme). The header carries `base64(KEY:SECRET)` and FactorIA puts `{key}` in as it
is, so store that value, not the two halves:

```bash
export SCENARIO_API_KEY="$(printf '%s' 'YOUR_KEY:YOUR_SECRET' | base64)"
```

On Windows PowerShell: `[Environment]::SetEnvironmentVariable("SCENARIO_API_KEY", [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("YOUR_KEY:YOUR_SECRET")), "User")`.
Then run `factoria ai doctor` (it lists the server and where its key was found) or press **Test** in the editor (below).

**What each provider does with the servers**

| Provider | How the server is used |
|---|---|
| `claude-code` | Claude Code connects itself: the run gets the servers in the `--mcp-config` file and `mcp__<name>` in `--allowedTools` (tools show up as `mcp__<name>__<tool>`). The file holds the keys, so it is created readable only by you (Linux, macOS), is named per run and is deleted when the run ends. Servers that want OAuth work here after you log in once inside Claude Code (`/mcp`); FactorIA never touches those credentials. |
| `codex` (default `argv`) | Codex connects itself: `-c mcp_servers.<name>.*` arguments. The key never appears in the argument list (anyone can read it with `ps`): headers and a program's environment travel through environment variables that the arguments only name. With your own `argv` Codex is not given the servers (the run says so). |
| `generic-cli` | A CLI whose `argv` has the `{mcp_config}` placeholder gets the same file as Claude Code (every server for that role, in `.mcp.json` shape); one without it is not given the servers, and the run says so. |
| `anthropic`, `openai-compatible` | The built-in agent connects: at the start of each run FactorIA starts the program or opens the session, asks for the tool list, adds the tools as `<name>__<tool>` (reduced to letters, digits, `_` and `-`, at most 64 characters) and passes the model's calls to the server. Results come back as text, and as pictures when the server returns png, jpeg, gif or webp. Everything closes when the run ends. |

A server that cannot be used (a missing key, unreachable, a program that is not installed, refused credentials) is left out of
that run with a one-line note in the chat; the run goes on without it. Every run connects for itself: a worker handed a task by
the orchestrator uses the servers listed for the `worker` role, not the orchestrator's.

**What is not supported.** OAuth: a server must take a header or a key, except through Claude Code as said above (`401` with a
`WWW-Authenticate` header is reported as "this server may want OAuth" with that advice). The old SSE transport. Server-initiated
requests other than `ping`. Resources and prompts: only tools are used.

**Permission, cost and privacy.**

* Listing a server in `roles` is the permission: FactorIA does not ask before each call (the CLI agents run non-interactively and
  the engine's own tools are not asked about either). A tool that generates content can spend credits on the service's side and
  FactorIA cannot see what it costs (`limits.maxCostUsd` covers model tokens only). The prompt tells the AI to try one small call
  first, to stop on an error instead of retrying, and to bring what a tool makes into the project with `assets_import`, giving the
  source and license so the credits stay right. Keep `roles` narrow and put the price in `note`.
* Only your own `ai.json` is read for servers: a game project cannot add one (that would let a downloaded project run a program
  or send data to a host you did not pick). `apiKey` and header or environment values written in full are secrets like the provider keys:
  the file is saved readable only by you, the key box of the settings window shows dots, and `ai.tool_servers`, `factoria ai doctor`
  and the config dumps leave keys out (`***`) or never list them. Prefer `apiKeyEnv` and write `{key}` in the header instead of the
  secret itself, so the header box of the window holds no secret either.
* What goes to a server is what the AI puts in its calls (prompts, file names, sometimes images) and the key; the service's own
  privacy terms apply to it. A server of type `stdio` runs with your permissions: add only programs you trust.
* `http://` to another computer with a key is allowed but `factoria ai doctor` and the loader warn that it travels unencrypted.

`factoria ai doctor` lists each server with `[ok]` (ready), `[--]` (what is missing) or `[off]`, its address (without any query
string), where its key was found and which roles get it. The command `ai.tool_servers` returns the same as JSON and, with
`{"test": true}`, connects to every enabled server that is ready and lists its tools (it only asks for the tool list: no tool is
called and nothing is spent).

## Extensions

`extensions` loads plugins, skills and hooks into the AI agents that are command-line programs, next to the engine's own tools. It is
the same idea as `mcpServers` ([above](#external-tools-mcp-servers)) for the things Claude Code calls plugins, skills and hooks: a plugin
(a folder with `.claude-plugin/plugin.json`, a `.zip`, or one you installed with `claude plugin install name@marketplace`), a skill
folder (one that holds a `SKILL.md`, or a folder of such folders) and hooks (a program that runs on an event such as
`PostToolUse` or `Stop`, in the shape of Claude Code's `hooks`). **Plugins and hooks** are for **Claude Code** today (a generic CLI
takes them through placeholders); **skills** reach every provider, see [Skills](#skills-for-every-provider) and
[what each provider does](#what-each-provider-does-with-extensions).

It lives in two places, both validated with errors that name the JSON pointer and a fix, and with "did you mean" for a misspelled key,
role or hook event:

* **Your `ai.json`**, `"extensions"`: yours, for every project. The only place for `inheritUserPlugins`.
* **The project's `.factoria/extensions.json`**: the same sections at the top level, without `inheritUserPlugins`; it travels with the
  project (commit it). Paths there are relative to the project and a skill must stay inside it. Its plugins and hooks need your
  [trust](#trusting-a-projects-extensions); its skills (text only) do not.

```json
{
  "extensions": {
    "inheritUserPlugins": true,
    "plugins": {
      "notes":       { "path": "~/plugins/notes", "note": "keeps a design diary", "roles": ["orchestrator", "worker"] },
      "superpowers": { "plugin": "superpowers@claude-plugins-official" }
    },
    "skills": {
      "gdd": { "path": "~/skills/game-design", "enabled": false }
    },
    "hooks": {
      "log-edits": {
        "hooks": {
          "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "echo edited >> ~/edits.log" }] }]
        }
      }
    }
  }
}
```

The entry name is its key (`[A-Za-z0-9_-]`, up to 40 characters, unique among the entries of its kind).

| Field | Meaning |
|---|---|
| `path` | `plugins`: a plugin folder or `.zip`. `skills`: a skill folder, or a folder of skill folders (each subfolder with a `SKILL.md` is one skill). `~` is your home folder. In `ai.json` it must be absolute or start with `~` (the file is not inside any folder it could be relative to); in a project file it is relative to the project. |
| `plugin` | `plugins` instead of `path`: `name@marketplace` of a plugin you installed in Claude Code. FactorIA reads its `installPath` from `~/.claude/plugins/installed_plugins.json` (`$CLAUDE_CONFIG_DIR` when set); the one installed for this project wins over the one installed for you. If it is not installed the run says so and gives the `claude plugin install` command. |
| `hooks` | `hooks`: Claude Code's hooks object, `event -> [{ "matcher", "hooks": [{ "type": "command", "command": ... }] }]`. |
| `note` | What it is for (shown in `ai.extensions` and the editor). |
| `roles` | Who loads it (role names, see [Roles](#roles)). Left out: orchestrator, worker, fast, artist and audio; the review roles only when listed. |
| `enabled` | `false` keeps the entry without loading it. |
| `inheritUserPlugins` | Top level of the section, `ai.json` only, default `true`: Claude Code also loads your own setup (`~/.claude`). `false` starts it with `--setting-sources project,local`, which drops ALL of your user-level Claude Code settings, not only the plugins: your plugins, skills and hooks, but also your permissions (`allow` / `deny` / `ask`) and `env`. Only what is listed here (and the trusted project's own `.claude`) loads. It applies to Claude Code only. |

### What each provider does with extensions

| Provider | How the extensions are used |
|---|---|
| `claude-code` | One `--plugin-dir <folder>` per plugin; the skills go in a plugin FactorIA writes for the run (`factoria-extensions`, a copy of the skill folders under `<project>/.factoria/ai/ext-skills-*`); the hooks of the entries are merged into a private `--settings` file (`<project>/.factoria/ai/settings-*.json`, readable only by you). Both are removed when the run ends. `--setting-sources` is also passed when `inheritUserPlugins` is `false` (`project,local`) or when the project's own `.claude/settings*.json` runs a program or widens what the AI may do (see below) and the project is not trusted (`user`; an empty value with both), see [below](#trusting-a-projects-extensions). If your own `argv` uses `{plugin_dirs}` or `{settings}` those place the folders and the file and FactorIA adds no flag for them; an `argv` that already has `--settings` or `--setting-sources` is not given a second one. |
| `codex` | Skills only. Codex reads Agent Skills from `.agents/skills` of the folder it starts in, so FactorIA copies the skills of the run to `<project>/.agents/skills/factoria-r<tag>-<name>/` (and writes `.agents/skills/.gitignore` with `factoria-*/` when there is none) and removes them when the run ends; folders of your own there are not touched. Codex has no plugin folder or hooks file for FactorIA to fill: a plugin or hooks entry for a Codex role is skipped, and the run says so (an Info line in the chat and the CLI output). Codex also keeps the `# Skills` lines in the prompt and `skills_read`, so a Codex version that does not scan `.agents/skills` still reads the skills. Not tested against a real Codex here (no Codex was available): `codex` must be a version with Agent Skills. |
| `generic-cli` | Plugins when the `argv` has the `{plugin_dirs}` placeholder, hooks when it has `{settings}` (the path of the private settings file). `{plugin_dirs}` after a flag (`"--plugin-dir", "{plugin_dirs}"`) repeats that flag once per folder; with no folder, the placeholder and its flag are dropped. A skill folder is not passed (no flag is known for it); the skills reach it as prompt lines and `skills_read`. What cannot be passed is listed in the run output with the placeholder to add. |
| `anthropic`, `openai-compatible` | Not yet: the API providers do not use extensions yet (planned with the built-in agent's skills and hooks), and `ai.extensions` and the run say so. |

### Skills for every provider

A skill is a folder with a `SKILL.md` (the Agent Skills format) that the AI reads only when the task needs it. They come from the
engine (baked into the binary), from `~/.factoria/skills`, from the project's `skills/` and from the skill entries above; the
project's wins over yours, and yours over the engine's. The built-in agent (anthropic, openai-compatible), Codex and generic CLIs get
one line per skill in the system prompt and read one with the tool `skills_read`; Claude Code and Codex are also given the skill
folders (above). A skill entry may name an engine skill as `"path": "engine:<name>"` to set its `roles` or switch it off. Role
defaults, the commands (`skills.list`, `skills.read`, `skills.new`) and the format are in [SKILLS.md](SKILLS.md).

### Trusting a project's extensions

A plugin or a hook runs a program with your permissions, and the project's `.factoria/extensions.json` can come from anyone (a
downloaded project, a teammate, the AI itself). So a project's **plugins and hooks load only after you trust the project once**: in the
editor, **AI > AI Settings... > Extensions > This project**, read what would run and press **Trust this project**. The trust is kept
per project path and per hash of the project's files in `ai-trust.json` next to your `ai.json` (readable only by you) and ends as soon as
one of them changes, so an edit by anyone shows up as "not trusted" again until you look at it. No command or tool can grant the trust:
an AI cannot trust what it has just written. Until then the run lists each skipped entry with the reason and where to trust it; the
project's skills still load.

The same trust covers **Claude Code's own project settings**. Claude Code in `-p` mode (how FactorIA runs it) skips its own
workspace-trust dialog, so a downloaded game's `.claude/settings.json` or `.claude/settings.local.json` would take effect in your AI runs
without asking. Two kinds of content need your trust:

* **They run programs:** `hooks`, `enabledPlugins`, `extraKnownMarketplaces`, `statusLine`, `apiKeyHelper`, `fileSuggestion`,
  `awsAuthRefresh`, `awsCredentialExport`, `otelHeadersHelper`, `enableAllProjectMcpServers`, `enabledMcpjsonServers`.
* **They widen what the AI may do:** any non-empty `env` (`ANTHROPIC_BASE_URL` or a proxy would send your requests, with your key, to
  another server; `BASH_ENV`, `NODE_OPTIONS`, `PATH`, `LD_PRELOAD` change what hooks, MCP servers and Bash run), any
  `permissions.allow` rule (`Bash`, `Bash(*)`, `WebFetch`: there is no dialog in `-p` mode, so they grant tools FactorIA did not, to a
  prompt injection hidden in the project too), a `permissions.defaultMode` other than `default` (`bypassPermissions`, `acceptEdits`,
  `dontAsk`) and a non-empty `permissions.additionalDirectories`. `permissions.deny`, `ask` and `disableBypassPermissionsMode` only
  restrict, so they do not count.
* **Anything FactorIA does not know:** the rule is "trust unless known harmless". Only a short list of keys that run nothing, send
  requests nowhere new and widen no permission is free (`$schema`, `model`, `outputStyle`, `language`, `cleanupPeriodDays`,
  `includeCoAuthoredBy`, `includeGitInstructions`, `spinnerTipsEnabled`, `alwaysThinkingEnabled`, `disableAllHooks`,
  `respectGitignore`, `showTurnDuration`, `prefersReducedMotion`, `companyAnnouncements`, `attribution`, `forceLoginMethod`,
  `forceLoginOrgUUID`, `disabledMcpjsonServers`). Any other non-empty key, at the top level or inside `permissions`, is listed as
  `unknown setting KEY` (the name only, never the value) and needs your trust, so a setting a newer Claude Code adds cannot slip in.
  Empty values (`null`, `""`, `{}`, `[]`) count for nothing.

When either file has any of these and the project is not trusted, FactorIA starts Claude Code without the `project` and `local` setting
sources (`--setting-sources user`; with `inheritUserPlugins: false` an empty list, so nothing is loaded besides FactorIA's own
`--settings` file). Side effect: the rest of those files is not applied either (their `deny` and `ask` rules and other settings). The run
output, `ai.extensions` (`claudeSettings`, listing the `grants` of each file, and `projectSettingsSkipped` per role) and `factoria ai doctor`
say what was skipped and how to trust the project. The hash covers both files together, and is empty (nothing to trust) while neither has
any of the above, so a project whose `.claude` only holds `deny` rules or the harmless keys loads as before; the trust ends when either file
changes. Only Claude Code runs are affected: other providers never read `.claude`. A project's `.mcp.json` is Claude Code's own
mechanism and is not covered here.

### Deny rules on FactorIA's tools

Claude Code applies the `permissions.deny` rules of the project's `.claude/settings.json` and `.claude/settings.local.json` (when it loads
them: an untrusted project's files are not loaded, but FactorIA reads them and reports the rule anyway) over the tools
FactorIA allows, so a rule such as `mcp__factoria__*` silently takes the engine's tools away from the AI. FactorIA reads those two files
and reports `mcp__factoria`, `mcp__factoria__*` and `mcp__factoria__<tool>` rules: in the run output, in `factoria ai doctor` and in
`ai.extensions`, each naming the file, the rule, what is lost and how to restore it (remove that entry from `permissions.deny`). It never
edits those files.

### Looking at what a run gets

`ai.extensions` (read-only, `{"role": "worker"}` optional) returns the entries with what stops each from loading, per role the
provider and what it `receives`, `skipped` (reason and fix), `notes`, the project's file (`exists`, `hash`, `trusted`), `claudeSettings` (what in the project's `.claude/settings*.json` needs trust, whether the project
is trusted and so whether Claude Code loads them), the deny rules
and a `scope` sentence on the providers that do not use extensions. `factoria ai doctor` prints the same in its "Extensions" section;
`factoria ai doctor --project DIR` (default: the current folder when it holds `factoria.json`) says which project's file and deny rules.
The report never changes the trust file.

## Costs

Estimated from reported token usage (input, output, cache read/write):

| Model | Input / Output per 1M tokens | Cache read |
|---|---|---|
| claude-opus-5-5 | $4 / $20 | $0.20 |
| claude-sonnet-5-5 | $2 / $10 | $0.20 |
| claude-haiku-5-5 | $0.10 / $0.50 | $0.01 |

(prompts up to 100K tokens; estimates only, your invoice is authoritative).
For other models add `"pricing"` to the provider to get estimates; otherwise
cost shows as $0 and only token limits apply. CLI agents report their own cost
when they provide it. Set `limits.maxCostUsd` to cap a run (API providers only; a CLI agent runs its own loop).
What a whole game cost, what drives it and how to see it: [AI_COSTS.md](AI_COSTS.md) (`factoria docs read ai-costs`).

## Privacy and key safety

* API keys come **only** from environment variables or the user-level
  `~/.factoria/ai.json`. A key in a game project is never used, and FactorIA
  warns (`ai.run`, `factoria ai doctor`) when a project file contains something
  that looks like a key (`sk-...`, `sk-ant-...`, `AIza...`, `gsk_...`).
* Prefer `apiKeyEnv` over `apiKey`; if the file holds a key, `chmod 600` it
  (FactorIA warns when it is world-readable). A key pasted into the editor's
  [AI settings window](#the-ai-settings-window) is stored as `apiKey` in this same
  user-level file, which the window writes readable only by you (Linux and macOS: the
  file is created private before the key goes in), and the box never shows a stored key
  again. The key is not written to a game project, a log, a notification or a command
  result, and is forgotten from the window once saved or closed.
* Keys are sent only to the provider's `baseUrl`, in headers (never in URLs or
  logs). With the `curl` fallback they go through a private temp file, not the
  command line.
* External tool servers (`mcpServers`) are read from your user-level `ai.json` only, and the same rules hold for their keys:
  environment variable first, owner-only file, never in a log, a command result or an argument list
  ([External tools](#external-tools-mcp-servers) says what each provider does).
* What is sent to providers: your task, the system prompt, project file
  names, `factoria.json`, feedback titles and the results of tools the model
  calls (which can include file contents and screenshots). Use a local
  provider (Ollama, LM Studio) if that must not leave your machine.
* Proxies: `HTTPS_PROXY`/`HTTP_PROXY`/`NO_PROXY` are honoured; localhost is
  never proxied.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `'claude' was not found in PATH` | `npm i -g @anthropic-ai/claude-code`, then run `claude` once to log in. |
| `'codex' was not found in PATH` | `npm i -g @openai/codex`, then `codex login`. |
| `... is not logged in or its credentials were rejected` | Run the CLI in a terminal and log in again. |
| Claude Code bills the API instead of your plan | `ANTHROPIC_API_KEY` is set in the environment; add `"unsetEnv": ["ANTHROPIC_API_KEY"]` to the `claude-code` provider. |
| CLI exits at once / ignores flags | Flags changed in a newer CLI version: override `argv` in `ai.json`; test it in a terminal. |
| MCP server `factoria` failed | `factoria` puts its own directory first on PATH for the agents it starts, so this only happens when `factoriaCommand` names another binary: fix it or set it to an absolute path. (Claude Code started from the editor connects to the editor itself and needs neither.) |
| `No Anthropic credentials found` | Set `ANTHROPIC_API_KEY` or log in with `ant auth login`. |
| `No API key for provider 'openrouter'` | `export OPENROUTER_API_KEY=...` (see table above). |
| `No model configured for role ...` | Set `roles.<role>.model` for non-Anthropic providers. |
| HTTP 401/403 | The key is wrong or lacks access. HTTP 404: wrong model name or `baseUrl`. |
| HTTP 429 / 529 | Rate limit or overload; FactorIA retries automatically, then gives up with the message. Check credits. |
| Tool-call errors with a local model | The model needs tool-calling support; try a larger/instruct model. |
| Corporate proxy / TLS | Set `HTTPS_PROXY`; for a custom CA set `SSL_CERT_FILE` / `CURL_CA_BUNDLE`. |
| Invalid `ai.json` | The error lists the JSON pointer (e.g. `/roles/worker/effort`) and allowed values. |
| `No provider is configured for image generation` | Add `"assets": {"image": {"provider": "openai"}}` to `ai.json` (or another kind/provider, see [Asset providers](#asset-providers)), or pass `provider` to the command. `fake` works offline. |
| `'assets/a.wav' ends in '.wav', but the provider 'elevenlabs' makes sound as .mp3 files` | Use the extension the error names; it is checked before anything is paid for. |
| `Meshy task ... was still IN_PROGRESS after N seconds` | Raise `timeoutSeconds` of the `meshy` provider; the task keeps running on Meshy's side. |
| `... exited without writing asset.png` | The `asset-command` program must write to the path `{output}` stands for: put `{output}` in its `argv`. |
| `External tool server 'scenario' skipped: Tool server 'scenario': ... uses {key}, which has no value` | Set the environment variable `apiKeyEnv` names (and restart the editor or open a new shell), or put the key in `apiKey`. `factoria ai doctor` shows it as `[--]` with the missing variable. |
| `... refused the credentials (HTTP 401)` from a tool server | The key is wrong, or the header is not what the service wants (for Scenario: `Basic` plus `base64(KEY:SECRET)`). If the answer carries a `WWW-Authenticate` header the server may want OAuth: use it through Claude Code, or a key if it offers one. |
| `... HTTP 404 ...` or `not an MCP reply` from a tool server | The address is not the server's Streamable HTTP endpoint (often ending in `/mcp`; an address ending in `/sse` is the old transport, not supported). |
| A tool server works in Claude Code but not in the built-in agent or Codex | It uses OAuth; the built-in agent and Codex (through FactorIA) need a key or header. See [External tools](#external-tools-mcp-servers). |
