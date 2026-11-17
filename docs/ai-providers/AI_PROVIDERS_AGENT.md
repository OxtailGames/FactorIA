# AI providers: the built-in agent and its settings

[AI providers](../AI_PROVIDERS.md) > AI providers: the built-in agent and its settings

## How the built-in agent behaves (API providers)

* Tools: not every command is sent as a tool on every step (with every command in full, the definitions alone were hundreds of thousands of tokens on each one). The
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

Every command is a tool the model could use, but sending the definitions of all of them on every step (summary, description
and input schema) costs more than 200k tokens before the model reads a word: the 372 commands of the test registry weigh
about 870 KB on the 0.19.0 engine (counted on 2026-11-09), and the agent reaches about 385 (every command but the `ai.*` ones
that would start another agent), a little more. Both numbers grow with each version. The built-in agent
offers instead:

* the **core commands** in full (the list above; `is_core_tool` in `tools/ai/include/fa/ai/tool_catalog.h`),
* the commands of the role's **tool groups** in full: a group is a command category (`assets`, `anim`, `audio`, `ui`, `i18n`,
  `platform`, `publish`, `perf`, `nav`, `physics`, `mesh`... the `category` of `factoria commands`), the exact name of a command
  (`assets.draw_icon`) or `"all"` (every command in full: the old behaviour),
* `tool_describe` and `tool_call`, and
* a `# Tools` section in the system prompt with one line per remaining command, grouped by category.

The core list and the group rules (category, exact name, `core`, `all`, a did-you-mean for an unknown group) live in
`tools/common/include/fa/tooling/tool_groups.h` and are shared with the MCP server, whose `--tools` profiles
([MCP.md](../MCP.md#tool-profiles)) offer the same core set to clients that do not defer tools themselves.

The model reads the catalog, describes the commands it is about to use (several in one call) and calls them through
`tool_call`, which runs the command under its own name: the chat shows `assets_slice_sheet`, not `tool_call`, and the transcript and
the events carry the command's arguments. The catalog is used only when it saves something (the definitions it leaves out add
up to more than 6000 bytes), so a small registry is offered in full.

A role names its groups in `ai.json`, `"roles": {"artist": {"toolGroups": ["assets", "anim"]}}`. Without `toolGroups` the
artist loads `assets` and the audio role `assets` and `audio`; every other role loads none. A list replaces the default
(`[]` loads nothing but the core). A name that matches no category or command is reported as an Info line in the chat when the
run starts, with suggestions. `factoria call ai.tool_plan '{"role":"artist"}'` shows what a role gets: the tools sent with
their estimated sizes, the catalog's size, the groups that matched and the cost of offering everything in full.
CLI agents (Claude Code, Codex...) choose their own tools and ignore `toolGroups`; see [MCP.md](../MCP.md#tool-definitions-and-claude-code).

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
Chats are saved in `<project>/.factoria/ai/chats/` (see [EDITOR.md](../EDITOR.md)).

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

The `assets.generate_*` commands ([ASSETS.md](../ASSETS.md)) make images, sprite sheets, sounds, music, voices and 3D models
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
  | `{input}` `{mask}` | images only, **inpainting**: `input.png` (the picture to repaint) and `mask.png` (grey, white where it must be repainted) in the program's temporary folder, both the same size. A plain generation gets a transparent `{input}` and a white `{mask}`. |

  The program is run with `env`/`unsetEnv` of the provider and stopped after `timeoutSeconds`. A non-zero exit, a timeout
  and a missing `{output}` file are errors that say what happened. On Windows a `.cmd`/`.bat` program cannot receive
  `% & | < > ^` or line breaks in an argument: use an `.exe` or a Python wrapper if prompts need them. It cannot take
  reference images or voices (the result says so); use `style.prompt` for the look.

**Inpainting.** `image.inpaint` ([IMAGES.md](../IMAGES.md), "Pictures from a provider") repaints part of a picture, so it needs a
provider that can: the built-in `openai` (it sends the picture and a mask to `/images/edits`, whose transparent pixels are the ones
repainted), `fake`, and an `asset-command` provider whose `argv` has both `{input}` and `{mask}` (the program reads them and writes the
whole repainted picture to `{output}`). Any other image provider still serves `image.generate_layer` and `assets.generate_image`. The
error for a provider that cannot inpaint names the configured ones that can.

Provider fields used by asset providers: `type` (`openai-compatible` for OpenAI, `elevenlabs`, `meshy`, `fake`,
`asset-command`), `baseUrl`, `apiKeyEnv`, `apiKey`, `headers`, `command`, `argv`, `env`, `unsetEnv`, `maxRetries` (at most
2 are used: a retry is a second payment), `timeoutSeconds` and `license`: the note recorded in the provenance of what the
provider makes (default: where its terms are).

**Keys and privacy.** The same rules as for the LLM keys: environment variables or the user-level `ai.json`, never the
game project; keys go only to the provider's `baseUrl`, in headers, and are not written to assets.json, results or logs. What
is sent to an asset provider is the prompt (with the house style), the reference images and, for voice, the text.

**Cost.** Asset providers bill for every call. The built-in ones (`openai`, `elevenlabs`, `meshy`) carry a price table,
`assetPricing`, looked up on 2026-11-06 (unverified: OpenAI voice, the three ElevenLabs figures, Meshy 3D, and OpenAI images made with a model other than `gpt-image-1`, see
[AI_COSTS.md](../AI_COSTS.md#asset-generation)): every result has `estimatedCostUsd` (an estimate, never an invoice), the limits
`limits.maxAssetCostUsd.perRun` and `.perDay` refuse a call that would pass them, and a call above `limits.askAboveUsd`
(default $0.50), or small calls that add up above it since the user last said yes, wait for the user. `limits.maxCostUsd` covers LLM runs only. `fake` and local programs cost 0 and never ask.
Look at the first result before generating a batch and prefer `fake` while the flow is being built.

`assetPricing` is a provider key, in `ai.json` only. It replaces the built-in table; every key is optional:

| Key | Meaning |
|---|---|
| `image` | USD per picture: one number for any size, or `{ "<size>": { "<quality>": usd } }` with the sizes the provider draws (`1024x1024`, `1536x1024`, `1024x1536`; `default` for any) and the qualities `low`, `medium`, `high`, `auto` (`default` for any) |
| `voicePer1000Chars` | USD per 1000 characters of the text |
| `soundPerSecond`, `musicPerSecond` | USD per second of audio (10 s and 60 s are assumed when the call leaves the length to the provider) |
| `model3d` | USD per model |
| `model` | the image model the `image` figures are for; a picture made with another model is priced with them but marked unverified |
| `unverified` | the kinds whose figure was not confirmed (`image`, `voice`, `sound`, `music`, `model3d`) |
| `checked`, `source`, `note` | the day the prices were looked up (`YYYY-MM-DD`), the page that publishes them and what they leave out; shown on the approval card and in results |

An `asset-command` or a local server with no `assetPricing` is free. A remote provider with none has an unknown price: its call
asks the user, and a per-run or per-day limit refuses it. `ai.providers` lists each provider's table, its date and page.

`factoria ai doctor` lists the asset providers (`[makes image, voice]`, whether a key was found) and which provider each kind
of asset is assigned to.

## Permission mode

FactorIA starts Claude Code and Codex without a terminal, so nothing can answer "may I edit this file?". The **permission mode** of
a provider says how much its agent may do on its own. It is the `permissionMode` key of the provider in your `ai.json`, in the
**Agents** tab of the AI settings window (a combo per agent, with one line under it for what each value allows), or through the
commands `ai.settings.get` (the `permissionModes` field lists every value with what it allows) and `ai.settings.set` with the
pointer `/providers/claude-code/permissionMode` (scope `user`; value `null` goes back to the default):

```json
{ "providers": { "claude-code": { "permissionMode": "plan" }, "codex": { "permissionMode": "workspace-write" } } }
```

Only the `claude-code` and `codex` providers have it, and only **your** `ai.json` can hold it: a project's `.factoria/ai/settings.json`
that sets it is refused, and `ai.settings.set` refuses scope `user` to an MCP or agent caller, so neither a project you downloaded nor the
AI can widen what an agent may do. An unknown value is an error that names the pointer and lists the choices.

| Agent | Value | What the agent may do |
|-------|-------|-----------------------|
| Claude Code | `manual` | Reads files and uses the FactorIA tools. Every file edit and shell command would need a yes nobody can give in a background run, so it is refused. |
| Claude Code | `plan` | Reads and plans only: no file is edited and no command runs. |
| Claude Code | `dontAsk` | Never asks: uses what is already allowed (the FactorIA tools, the sites you listed) and refuses everything else, edits included. |
| Claude Code | `acceptEdits` | **Default.** Edits and creates files in the project without asking; other shell commands and tools that are not already allowed are refused. |
| Claude Code | `auto` | A safety check approves the actions it judges safe and blocks the rest. Less strict than `acceptEdits`. |
| Claude Code | `bypassPermissions` | **Dangerous.** No permission checks: it edits or deletes any file it can reach, runs any shell command and uses the network. |
| Codex | `read-only` | Reads files; its shell cannot write or use the network. The FactorIA tools still work (they run in FactorIA, not in the sandbox). |
| Codex | `default` | **Default.** No flag: Codex uses its own `~/.codex/config.toml`, which is a read-only sandbox without one. |
| Codex | `workspace-write` | Its shell may edit files in the project folder and temporary folders; no network, nothing outside those folders. |
| Codex | `danger-full-access` | **Dangerous.** No sandbox: its shell edits or deletes any file you can, runs any command and uses the network. |

The Claude Code values are the ones `claude --help` lists for `--permission-mode`; the Codex values are the ones documented for
`codex exec --sandbox` (they were taken from its documentation: Codex was not installed where this was written, so the exact
sandbox behaviour of your version is worth a look at `codex exec --help`).

* **Dangerous modes need an explicit choice.** `bypassPermissions` and `danger-full-access` are never a default: they are in the file
  only when you wrote them (the window asks "Yes, allow it" before it saves one, and `ai.settings.set` answers with `dangerous: true`).
  They are not forbidden, because an agent in a throwaway folder or a container is a real use and the choice is yours alone to
  make (see above), but they are labelled dangerous everywhere they appear.
* **A role that only reads stays read-only.** A reviewer (and any run FactorIA starts read-only) is held to read-only whatever the
  setting is: for Codex the sandbox is `read-only`; for Claude Code `bypassPermissions` and `auto` become `acceptEdits` for that run
  and its edit tools stay switched off (`--disallowedTools`), as they were before the setting existed. This is about the setting:
  a permission or sandbox flag you wrote in your own `argv` template is kept as written (next point), for a read-only role too.
* **A command line of your own wins.** With the built-in command line the flag is always added (the default when you set none).
  With your own `argv` template the flag is added only when the provider has a `permissionMode`, and never when the template already
  has `--permission-mode`, `--dangerously-skip-permissions`, or for Codex `--sandbox`, `-s`, `--full-auto`,
  `--dangerously-bypass-approvals-and-sandbox`, `--yolo` or `-c sandbox_mode=...`: what you wrote stays, with no second flag.
* `generic-cli` providers have no permission mode: their command line is yours.

## The AI settings window

**AI > AI Settings...** (the AI menu of the menu bar) is where the roles and the asset side of `ai.json` are set up. Its
**Roles** tab (also **AI > Roles...**) has the role table and its own **Save**; the **Agents** tab sets the [permission mode](#permission-mode) of Claude Code and Codex; the **Assets** tab has three sections; the first two share one
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
* **Spending limits.** **Ask above**, **Most per run** and **Most per day** (US dollars; `limits.askAboveUsd` and
  `limits.maxAssetCostUsd.perRun` / `.perDay`, [AI_COSTS.md](../AI_COSTS.md#asset-generation)) with their own **Save limits**,
  which rewrites only those three keys of your `ai.json` (in a project too: the limits you save here are your defaults, and the
  line under them shows what holds in this project now; a project can set its own in `.factoria/ai/settings.json`). They are
  estimates from each provider's price list, not an invoice.

Save rewrites only `assets`, `assetSources` and the provider fields these need (`apiKey`; `type`, `command` and `argv` of an
`asset-command` provider). Providers, roles, limits and every other key of the file stay as they are, and a file that is not valid
JSON is left alone (the window says so instead of overwriting it). Then it reloads the file: the next asset the AI makes and the
next message use the new settings; nothing else needs a restart. Without a project open the window edits the user's `ai.json` (the one in
`FACTORIA_AI_CONFIG`, if set), as described above. With a project open it edits that project's AI settings, see the next section.

### This project's settings in the window

With a project open the window (and the Roles window) is titled **AI settings - This project: <name>** and edits the project's file,
`<project>/.factoria/ai/settings.json` ([Per project](AI_PROVIDERS_CONFIG.md#per-project)); without one it is titled **AI settings - Your defaults** and edits
`ai.json`. What changes with a project open:

* **Where each value comes from.** The Roles table has a **From** column and the Assets tab one per row and per category: **This
  project** (the file sets it), **Your defaults** (it comes from your `ai.json`) or **Built in** (neither sets it). A role that follows
  another one the project changes (an Artist with no provider of its own, following the Worker) says **This project** too, with no Reset:
  reset the role it follows.
* **Save** writes the project's file, only with what differs from your defaults (the writer of [Per project](AI_PROVIDERS_CONFIG.md#per-project)), records that
  you saved it on this computer (so it applies at once) and invalidates what the editor cached, so the next message and the next asset use
  it. It never writes `ai.json`, except for what a project file cannot hold: an API key or the program of an `asset-command` provider
  typed in the Assets tab always goes to `ai.json`. The Roles tab shows where the file is.
* **Reset** (on a row marked This project) takes that one value out of the project's file: the row shows your default again. **Reset tab
  to my defaults** does it for the whole tab (the roles; the asset routes and sites). Both write the file at once, they do not wait for Save.
* **Save as my defaults** writes the values in the window to your `ai.json` (a role that follows another is not written as its own),
  and the project's file then keeps only what still differs from them. Every project that does not change those values, and every new
  project, starts from them.
* **A project file you have not accepted** (it came with a copied, unzipped or pulled project): the window says so at the top and lists
  what it would change. **Accept** is the call `accept_project_settings`; **Ignore** leaves the file alone and works with your settings
  (**Review it** brings the list back); **Delete the file** asks first ("Delete the project's AI settings file?"), then removes the file and
  forgets that you accepted it. While the box is shown, Save and the resets are disabled, since the project behaves as without the file;
  after Ignore they work again, and Save then replaces the file with what you chose: it asks first ("Replace the project's AI settings
  file?": Save replaces the AI settings file that came with the project) and keeps the file it replaced as
  `<project>/.factoria/ai/settings.replaced.json` (the last one; nothing reads it). A file that cannot be accepted (invalid)
  shows `invalidError` and no Accept, only Ignore and Delete. A file you had accepted that no longer resolves is shown with its error and
  Delete. Warnings of the resolution are listed under it (five at most; `factoria ai doctor` has them all).
* **Save as my defaults** writes every value you see in that tab, the ones this project sets and the ones that come from your defaults.
  It writes two files in this order: `ai.json` first, then the project's file; when the second write fails the message says that your
  defaults were saved and that the project's file was not updated. **Reset tab to my defaults** on the Assets tab resets the routes and
  then the sites, and says so when the second step fails.
* **A file that changes under the window.** When `ai.settings.set` (an AI agent, an MCP client) or another program changes `ai.json` or
  the project's file while the window is open, the window reads the files again and keeps what you had changed and not saved: a row you
  changed (a role, an asset route, a list of sites, a typed key or program) stays as you typed it and the other rows show the new values;
  a notice says so. **Accept** works the same way: the rows you changed before accepting stay, and Save writes them over the file's values.
  A box with many changes scrolls inside the window (it takes at most half of its height) so the tabs stay reachable on a small display.
* **Switching project** reloads the roles and the asset settings the window shows (and drops a pending Ignore and unsaved edits).
* **Not per project.** The Tools, Extensions and Token savers parts of the window stay your own (`ai.json`), and say so: a project's file
  can switch them on and off by name, which the window does not edit (write them in the file, [Per project](AI_PROVIDERS_CONFIG.md#per-project)). The `limits` of the file have no window either.
  An asset kind a project sets to **None** while your defaults have a route is refused with a hint, since a project file cannot remove a route.

The **External tools** tab (between Roles and Assets) sets up the `mcpServers` of [External tools](AI_PROVIDERS_EXTENSIONS.md#external-tools-mcp-servers):

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

The **Extensions** tab (after External tools) sets up the `extensions` of [Extensions](AI_PROVIDERS_EXTENSIONS.md#extensions):

* **Extensions.** One row per entry, yours and the open project's: On, its kind (plugin, skill, hooks), name, where it comes from
  (`you` = `ai.json`, `project` = the project's file), where it points, one checkbox per role (the same defaults as the tool
  servers: the review roles `ArtC` and `Rev` are off unless ticked), **Remove**, and a status: `Ready`, `Cannot load` (the tooltip
  says why and how to fix it) or `Not trusted` (a project's plugin or hooks, see below).
* **Skills.** Under the entries, one row per skill any role can be offered ([SKILLS.md](../SKILLS.md)): FactorIA's own, the ones in
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
* **TokenEconomizer.** One click installs Microsoft's [TokenEconomizer](https://github.com/microsoft/TokenEconomizer) plugin for Claude Code
  ([Installing a plugin](AI_PROVIDERS_EXTENSIONS.md#installing-a-plugin)). The section first asks the Claude Code CLI (in the background) what is installed.
  **Add TokenEconomizer...** opens a confirmation that lists what will run (the marketplace `microsoft/TokenEconomizer`, the plugin
  `tokeneconomizer@tokeneconomizer`, the two `claude plugin` commands, the entry added to your `ai.json`), whether Python 3.10 or newer was
  found (**Install** stays off without it) and what the plugin does; nothing runs until **Install**. The install runs off the UI thread
  with its steps listed and a **Stop** button. When the plugin is installed and listed the button reads **Installed**; when it is
  installed but has no entry, **Add the entry** writes only the entry (it goes to `ai.json` at once, your other unsaved changes stay in the window).
* **Claude Code also loads my own plugins, skills and hooks** is `inheritUserPlugins`. Off drops ALL of your own Claude Code
  settings for FactorIA's runs (plugins, skills, hooks, permissions and env), not only the plugins.
* **This project** shows the project's file and, when it lists plugins or hooks, or when its `.claude/settings*.json` runs a program or
  widens what the AI may do (env, allowed tools), what they would run (**Review what would run...**) with **Trust this project** (and **Stop trusting this project**
  afterwards); the trust covers both sources. A warning line appears when the project's
  `.claude/settings*.json` denies FactorIA's own tools to Claude Code, naming the rule and how to remove it.
* **Token savers.** The three savers of [Token savers](AI_PROVIDERS_EXTENSIONS.md#token-savers): a switch each (Loop guard, Learned tool groups, Project
  facts), the loop guard's **Judge** (a role, or "none (fixed text)"), and what this project's runs learned: **Load up front** /
  **No thanks** for a tool group, **Add to AGENTS.md** / **No thanks** for a fact. Nothing is changed until you press one.
* **Save** rewrites only `extensions` and `savers` of your `ai.json` and, when the project's entries changed, the project's
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
([ASSETS.md](../ASSETS.md)). The reviewers do not get the section: they do not bring assets in.

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
