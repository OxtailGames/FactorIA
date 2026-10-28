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
* `ai_run` (delegation) runs the worker or fast role inside the editor too; a CLI sub-agent gets the same endpoint.

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
(see [Asset providers](#asset-providers)); roles cannot use asset-only providers.

## Roles

| Role | Job | Default (Anthropic) |
|---|---|---|
| `orchestrator` | plans, reviews, delegates with the `agent_delegate` tool | `claude-opus-5-5`, effort `xhigh` |
| `worker` | implements features and fixes | `claude-sonnet-5-5`, effort `medium` |
| `fast` | small mechanical edits | `claude-haiku-5-5`, effort `max` |

Each role is `{provider, model, effort?, maxTokens?, maxContextTokens?}`. `effort` is one of
`low|medium|high|xhigh|max` and is always sent explicitly to Anthropic. For
`openai-compatible` providers it is ignored unless `"sendReasoningEffort": true`
(then mapped to `low|medium|high`). A CLI provider runs its own loop and
ignores `effort` (set the CLI's own option in `argv` if it has one).

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
turns delegation off.

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
unless told otherwise (`role`, `provider`, `model` options). The editor AI panel
always sends your messages to the orchestrator; its **Roles...** button sets the
provider, model, effort and context limit of the three roles and saves them in `ai.json` (only
`roles` is rewritten: providers, limits and a role's `maxTokens` stay). The button is disabled
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

## How the built-in agent behaves (API providers)

* Tools: every registered command (`scene.spawn` -> `scene_spawn`), plus
  `agent_delegate {role: worker|fast, task}` for the orchestrator. `ai.*`
  commands are hidden from the model.
* Safety limits: `limits.maxTurns`, `maxCostUsd`, `maxTotalTokens`, Ctrl+C /
  cancel flag. Transient errors (429, 5xx, 529) are retried with backoff and
  `Retry-After`.
* Anthropic specifics: prompt caching (`cache_control`), adaptive thinking
  (default; thinking blocks are kept untouched in the history), `output_config.effort`,
  server-side refusal fallback for Opus/Sonnet 5.5. Refusals are surfaced with
  category and explanation.
* Transcripts: `<project>/.factoria/ai/sessions/<time>-<role>.jsonl`
  (one JSON object per line: messages, tool results, usage). They contain what
  the model saw, never your API keys.
* Screenshots: a command result `{"image": {"mediaType": "image/png", "data": "<base64>"}}`
  is attached to the model as an image.

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
* **Tokens** (in / out / cache) and **Cost** of the chat. Cost is an estimate (`est.`): the CLI's own number for subscription
  plans, which are not billed per token.

## Asset providers

The `assets.generate_*` commands ([ASSETS.md](ASSETS.md)) make images, sprite sheets, sounds, music, voices and 3D models
through **asset providers**. They are configured here, in `ai.json`, next to the LLM providers, but they are not roles:
the `assets` section maps each kind of asset (`image`, `sound`, `music`, `voice`, `model3d`) to the provider, and
optionally the model and voice, that makes it.

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
(and mentions the `fake` provider). Every command also takes `provider` and `model` for one call. Keys come from the
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
  (FactorIA warns when it is world-readable).
* Keys are sent only to the provider's `baseUrl`, in headers (never in URLs or
  logs). With the `curl` fallback they go through a private temp file, not the
  command line.
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
