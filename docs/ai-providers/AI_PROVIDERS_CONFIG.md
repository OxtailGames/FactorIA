# AI providers: configuration, roles and reviews

[AI providers](../AI_PROVIDERS.md) > AI providers: configuration, roles and reviews

## Config file

Location: `~/.factoria/ai.json` (Linux/macOS), `%APPDATA%\factoria\ai.json`
(Windows). Override with the `FACTORIA_AI_CONFIG` environment variable. The
file is optional; without it the Anthropic defaults below apply. Schema:
`schemas/ai-config.schema.json` (errors name the JSON pointer and a fix). A save (the editor's AI settings, `ai.settings.set`) takes a lock file (`ai-config.lock`) next to
`ai.json` for its read-modify-write (the trust file `ai-trust.json` too) and replaces the file atomically (a temporary file, then a rename; on Windows the rename is
retried for about a second when another program has the file open), so two programs saving at once never mix their changes;
a save that cannot get the lock in a second changes nothing and says to try again (a lock left by a program that crashed expires after about 10 s).

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
`env`, `unsetEnv`, `inheritEnv` (see [Environment of the programs the AI starts](#environment-of-the-programs-the-ai-starts)),
`factoriaCommand` (default `factoria`), `pricing`
(`inputPerMTok`, `outputPerMTok`, ...), `maxRetries`, `timeoutSeconds`, `license`
(asset providers, see [Asset providers](AI_PROVIDERS_AGENT.md#asset-providers)).

### Environment of the programs the AI starts

The editor's environment holds secrets (the API key of every provider, `FACTORIA_*_PASSWORD` for signing), so the programs the AI
starts do not inherit it whole. Each gets an allow-list:

| Program | Inherits |
|---|---|
| Command hooks ([HOOKS.md](../HOOKS.md)) | the base list, network and config variables (proxies, certificate files), the hook's own `CLAUDE_PROJECT_DIR`, `FACTORIA_*` variables, and the top-level `inheritEnv` |
| CLI agents (Claude Code, Codex, `generic-cli`), model listing, plugin installs | the base list, network and config variables (`XDG_*`, `HTTP(S)_PROXY`, `NO_PROXY`, `SSL_CERT_*`, `NODE_EXTRA_CA_CERTS`), the variables of the CLI (`CLAUDE_*` and `ANTHROPIC_*` for Claude Code, `CODEX_*` and `OPENAI_*` for Codex), the provider's own API key variable, the provider's `inheritEnv` and the top-level `inheritEnv` |
| `asset-command` providers | the same as a CLI agent of that provider |
| Stdio tool servers (`mcpServers`) | the base list, network and config variables, the server's `apiKeyEnv`, its `inheritEnv` and the top-level `inheritEnv`; the server's `env` is always passed |
| Version probes (`--version`), `curl` | the base list and the network and config variables |

The base list is `PATH`, `HOME`, `USER`, `LOGNAME`, `SHELL`, `TMPDIR`/`TEMP`/`TMP`, `LANG`, `LANGUAGE`, `LC_*`, `TERM`, `TZ`,
`FACTORIA_HOME`, `FACTORIA_AI_CONFIG`, `FACTORIA_CALLER` and a few more of FactorIA's own, and on Windows `SystemRoot`,
`ComSpec`, `PATHEXT`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `ProgramData`, `ProgramFiles*`, `USERNAME` and the like. Claude Code
on macOS finds its login in the keychain through `HOME`; it needs no other variable. `env` of a provider or server is added on
top, `unsetEnv` removes names again.

Not inherited, unless listed: the signing passwords (`FACTORIA_*_PASSWORD`), the API keys of other providers, the Amazon Bedrock
login (`AWS_PROFILE`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_BEARER_TOKEN_BEDROCK`),
the Google Vertex AI login (`GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `CLOUD_ML_REGION`) and `SSH_AUTH_SOCK`
(Claude Code's `CLAUDE_CODE_USE_BEDROCK` and `CLAUDE_CODE_USE_VERTEX` are inherited, the variables they need are not). A signed
export that you run through the stdio `factoria mcp` (an agent's tool server) therefore gets no `FACTORIA_*_PASSWORD`: this is by
design, signing passwords are set in the environment of the editor or the terminal that runs the export.

This list is a floor against leaking a secret by accident, not a barrier. A program that runs with no sandbox (an agent in
`bypassPermissions` or `danger-full-access`, a shell the agent starts) runs as you: it can read `~/.factoria/ai.json`, the
keychain and your files, and start a program that gets the whole environment from another place. For an agent that must not reach
a secret, use the permission modes below or keep the secret out of the files it can read.

A program that needs another variable (`AWS_PROFILE`, `GIT_SSH_COMMAND`, `SSH_AUTH_SOCK`, `NODE_OPTIONS`, a company proxy
variable) needs its name listed. Names are exact (`"AWS_PROFILE"`) or a prefix ending in `*` (`"AWS_*"`); on Windows they ignore
case. Two places, both in `~/.factoria/ai.json` (a project's AI settings file cannot set them):

```json
{
  "inheritEnv": ["AWS_PROFILE", "SSH_AUTH_SOCK"],
  "providers": { "claude-code": { "inheritEnv": ["NODE_OPTIONS"] } },
  "mcpServers": { "files": { "command": "node", "args": ["server.js"], "inheritEnv": ["FILES_TOKEN"] } }
}
```

The top-level list applies to every hook, agent and tool server; the other two to one provider or one server. A name with `=`, a
space, or a `*` anywhere but the end is refused with its JSON pointer when the file is read. If an agent works in the terminal but
not in FactorIA and the cause is a missing variable, add its name here (or in the provider's `env`, with the value).

Built-in providers exist without being listed: `anthropic`, `openai`,
`openrouter`, `gemini`, `groq`, `deepseek`, `ollama`, `lmstudio`, `claude-code`,
`codex`, and the asset providers `elevenlabs`, `meshy` and `fake`. Listing one overrides only the fields you give.
A top-level `"assets"` section assigns asset providers to the kinds of asset
(see [Asset providers](AI_PROVIDERS_AGENT.md#asset-providers)); roles cannot use asset-only providers. A top-level `"assetSources"` section lists
the websites the AI should look at when it searches for assets (see [Asset sources](AI_PROVIDERS_AGENT.md#asset-sources)). A top-level
`"mcpServers"` section connects external tool servers such as Scenario (see [External tools](AI_PROVIDERS_EXTENSIONS.md#external-tools-mcp-servers)). A top-level
`"extensions"` section loads plugins, skills and hooks into the CLI agents (see [Extensions](AI_PROVIDERS_EXTENSIONS.md#extensions)). The
editor's **AI settings** window edits all four ([below](AI_PROVIDERS_AGENT.md#the-ai-settings-window)), so none has to be written by hand.

### Per project

A project can change some of these settings for itself, in `<project>/.factoria/ai/settings.json` (schema
`schemas/ai-project-settings.schema.json`). The file lives inside `.factoria/`, which a game project keeps out of git: it is your choice
for this project (a project that needs no sub-agents, a cheaper model for a prototype), not part of the game. It is optional; a project
without it behaves exactly as before and nothing is written to it.

```json
{
  "roles": { "artist": { "enabled": false }, "worker": { "model": "claude-haiku-5-5" } },
  "limits": { "maxCostUsd": 2 },
  "mcpServers": { "scenario": false },
  "extensions": { "skills": { "gdd": false } }
}
```

Every key is optional and is resolved **key by key, and role by role**: engine defaults, then your `ai.json`, then the project's file. A
role the file names changes only the fields it lists (`{"roles": {"worker": {"model": "x"}}}` keeps the worker's provider, effort and
limits), except that a `provider` different from the inherited one brings its own model and effort unless the file gives them too (the
model of the old provider means nothing on the new one). What the file may hold:

| Key | What it does |
|---|---|
| `roles.<role>` | `enabled`, `provider`, `model`, `effort`, `maxTokens`, `maxContextTokens`, `toolGroups` (see [Roles](#roles)); a role absent from the file keeps your value |
| `limits` | `maxTurns`, `maxCostUsd`, `maxTotalTokens`, `stuckAfterSeconds`, `maxConcurrentRuns`, `askAboveUsd` and `maxAssetCostUsd.perRun` / `.perDay` ([AI_COSTS.md](../AI_COSTS.md#asset-generation)), key by key |
| `assets.<kind>` | `provider`, `model`, `voice` of one kind of asset (`image`, `sound`, `music`, `voice`, `model3d`); the file must name the provider when your `ai.json` has no route for that kind. It cannot remove a route |
| `assetSources` | a category (`images`, `models`, `audio`, `fonts`, `other`) given here **replaces** that category of `ai.json`; `onlyListed` replaces yours |
| `savers` | `loopGuard`, `loopGuardJudge`, `learnedToolGroups`, `projectFacts`, `retrospective` (with `retrospectiveSteps` and `retrospectiveCostUsd`), key by key (the learned tool groups and saved facts of a project go on working: they stay in `.factoria/ai/savers.json`) |
| `mcpServers` | `true` or `false` per **name** of a tool server of your `ai.json`: `{"scenario": false}` turns Scenario off in this project |
| `extensions` | `true` or `false` per name of one of your plugins, skills or hooks, by kind: `{"plugins": {"notes": false}}`. The project's own extensions stay in `.factoria/extensions.json` ([trust](AI_PROVIDERS_EXTENSIONS.md#trusting-a-projects-extensions)) |

**A project file can only name, never define.** It may name a provider, tool server or extension your `ai.json` defines; a command, an
address (`url`, `baseUrl`), `headers`, `env`, `apiKey`, `apiKeyEnv`, `argv`, `path` or any other key that would make something run or
send data somewhere is an error, and the error says so and says where it belongs (`~/.factoria/ai.json`, **AI settings > Providers /
Tool servers / Extensions**), for example:

```
.../settings.json: /mcpServers/scenario/url: 'url' is not allowed in a project's AI settings file: a project may only NAME the providers,
tool servers and extensions you defined, never define one (...). Put it in ~/.factoria/ai.json (AI settings > Tool servers); here, name it
instead, for example {"mcpServers": {"scenario": false}}
```

A provider, server, role, asset kind, extension or key that does not exist is an error with the JSON pointer and a "Did you mean"
(`/roles/worker/provider: no provider named 'claud-code' in your AI settings. Did you mean 'claude-code'?`). So a copied project can never
run a program or spend a key you did not choose. A file you have not accepted yet has **no effect, not even failing**: when it is also
invalid (a provider you do not have, a key a project may not hold, not JSON), the project runs with your settings as if the file were not
there, and the problem is shown instead of thrown: `factoria ai doctor` (`projectSettings.invalidError` with `--json`), `ai providers`
and `ai config` print it, it is a warning of the resolved config, and the resolver's `invalidError` carries it for the editor. A file you
accepted that becomes invalid (for example you removed the provider it names from your `ai.json`) is an error in every place that reads
it (`factoria ai run`, the editor's runs, `factoria ai doctor`), since you had agreed to it.

**Trust.** A file you did not save on this computer (it came inside a copied, unzipped or pulled project) applies only after you accept
it once: until then the project behaves as if the file were not there and `factoria ai doctor` lists what the file would change. The acceptance is the hash of the file in `ai-trust.json` next to your `ai.json` (readable only by you,
the same file as the [extensions' trust](AI_PROVIDERS_EXTENSIONS.md#trusting-a-projects-extensions), in its own `aiSettings` record) and stops counting as soon as the
file changes (a line-ending change does not count); reading never writes `ai-trust.json`, only accepting does. `accept_project_settings` accepts a file as it is
(the call the editor makes when you accept; it refuses an invalid file), and the engine's own writer (`save_project_settings`) records the acceptance of what it saves only when its caller asks
for it (`recordTrust`, for code that saves what you just chose on this computer). No command or tool can accept a file: an AI cannot trust
what it has just written.

**Where a value comes from.** The resolver (`fa::ai::resolve_ai_config`, `fa/ai/project_settings.h`) returns the resolved config and,
for every value, `default`, `you` (your `ai.json`) or `project`, plus what an unaccepted file would change, for the windows and commands that show it. The writer (`save_project_settings`) keeps only the values that differ from what the
project would inherit, removes a key that equals the inherited value, and removes the file when nothing is left; `reset_project_setting`
takes one override out ("/roles/artist/enabled", or a whole branch). None of them writes your `ai.json`.

Everything that runs inside a project uses the resolved config: `factoria ai run`, `ai review`, the `ai.*` commands (including the asset
commands and `skills.*`), and the editor's chats and reviews. The project is the one given with `--project DIR` (or as the positional
argument of `ai run` / `ai review`), else the project that contains the current folder (`factoria.json` in it or a parent), the same rule
as every other command; `factoria ai doctor`, `ai providers` and `ai config` take `--project DIR` too. `ai doctor` prints the project's
file and, for an accepted one, the values it sets (`/roles/artist/enabled = false`); for one that is not accepted, what it would change;
and for an invalid one, what is wrong (`projectSettings` in `--json`). A CLI orchestrator (Claude Code, Codex) uses the project that
`factoria mcp` serves (`--project`, or the project containing its folder): `ai_run` and `agent_delegate` use that project's roles, and a
role the project turned off is refused with `role_off`, which says that the project's AI settings did it, the file, the pointer
(`/roles/artist/enabled`) and how to change it.

**Commands.** `ai.settings.get {scope}` and `ai.settings.set {scope, pointer, value}` (MCP: `ai_settings_get`, `ai_settings_set`) read and
write these settings by JSON pointer (`/roles/artist/enabled`, `/limits/maxCostUsd`, `/mcpServers/scenario`, ...):

* `get` with scope `resolved` (default) lists every value the project runs with and its `source`: `project`, `you` or `default`;
  `project` returns the project's raw file (`overrides`) with `pendingTrust`, `pending` and `invalidError` when they apply; `user` shows
  your `ai.json` view (`you` or `default`).
* `set` writes one value. Scope `project` writes the project's file, scope `user` your `ai.json` defaults. `value` null removes the
  setting (the project's override, so the value goes back to yours; or the key of `ai.json`, so it goes back to the engine's). It checks
  what the file rules check: a pointer that is not a setting is `unknown_pointer` with a "Did you mean" (also when `value` is null: a typo
  is never "already the default"), a key that would define a provider, server or extension, or hold a command, address or key, is
  `rejected_key` (with where it belongs), a name you do not have or a wrong value is refused before anything is written.
  The result's `removed` is true only when a value was really taken out: `value` null for a setting that the project's file (scope
  `project`) or `ai.json` (scope `user`) did not hold changes nothing and returns `removed: false` with a hint that starts "Nothing
  changed".
* **`set` never accepts a project file.** The file it writes is NOT applied until you accept it in the editor (AI settings, with the project
  open): the result says `needsAcceptance: true` and `applied: false`, with a hint, and `runsWith` is what the project still runs with.
  Setting a value never writes `ai-trust.json`: changing a file you had accepted makes the whole file wait again (the record still holds
  the old content). Removing a value (null) from an accepted file leaves it accepted: the file only got smaller, so its record is updated
  to the new content. Removing a value from a file nobody accepted leaves it waiting. When the last value goes, the file is deleted and its
  record forgotten.
* **Scope `user` is the user's own call.** `ai.settings.set` with scope `user` is refused with `user_only` when an AI is behind the call, and
  the error says to ask you to change it in the editor's AI settings window (Your defaults). Three ways in are closed: MCP clients
  (`ai_settings_set`, every client including the editor's endpoint), the built-in agent (and its delegates), and the CLI agents (Claude
  Code, Codex) when they run `factoria call ai.settings.set` from their shell: factoria starts them with `FACTORIA_CALLER=agent` in the
  environment, and any `factoria` that sees the variable treats every command it runs as an AI's (a value it does not know counts as
  `agent`, never as you; a value you set yourself in the environment is kept; the editor window itself is unaffected). Run by you, in a
  shell without that variable, `factoria call ai.settings.set` may (the editor's console has no `ai.*` commands). What this does NOT do:
  an agent that can edit files can still edit `~/.factoria/ai.json` by hand, and this is a refusal of the command, not a sandbox.
  `ai.settings.get` is open to everyone. What a scope `user` call changed is in
  its result: `changed: [{pointer, from, to}]` (a new provider for a role also drops its model, so the model shows up too).
  In the editor, a change a command makes to your `ai.json` or to the project's file reloads the AI settings window, the Roles window and
  the provider list on the next frame, so a Save there never writes over it.

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
A project can change a role for itself without touching your file: see [Per project](#per-project).

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
  same way. When the role was turned off by the project's own AI settings ([Per project](#per-project)), the refusal names the file and
  the pointer and says how to change it instead of pointing at `ai.json`.
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

The same lists are available to tools and AIs as the command `ai.models {provider?}` (a CLI call, an MCP tool `ai_models`). It changes no file, but it
starts a CLI or calls an API, so it needs the Read, Process and Network capabilities and is not offered to a read-only caller:

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
* **Every role has a capability set** (docs/design/ARCHITECTURE.md, "Capabilities"; repository only, not in the binary). Builders (orchestrator, worker, fast, artist,
  audio) may do everything except write outside the project (`writeAnywhere`) and publish; the critics and reviewers have
  `{read, state}`, and their tool list adds `anim.filmstrip` and `vfx.filmstrip` next to `game.screenshot` and `play.auto`.
  Those pictures are returned to the model; a `path` argument (a copy written to the project) needs `writeProject` and is refused
  to them. The same holds for the other commands that look at an asset or a sound (`model.preview`, `anim3d.preview`,
  `skin3d.preview`, `assets.contact_sheet`, `assets.preview_sheet`, `assets.preview_in_scene`, `assets.check_art`,
  `assets.spectrogram`, `assets.check_mix`, `audio.render`, `music.info`, `music.check`, `music.mix`): they are on the roles' tool
  list by name, they write only an engine-chosen temporary picture, and an output path of their own (`out`, `path`, `pictureOut`)
  is refused with `capability_denied`. A tool call that falls outside the set fails with `capability_denied` whose hint names the role, what it has and
  that the user or a builder role must do it. The set also reaches the `factoria mcp` a CLI agent starts
  (`FACTORIA_CAPABILITIES`, `FACTORIA_ROLE`), so a CLI builder over MCP cannot publish either: run that command yourself in a
  terminal (`factoria call <command>`) or in the editor.
* **The automatic player supports the reviewer, it does not replace playing.** A game reviewer (not the art critic) may run
  `play.auto` (it plays the game headless with a bot and writes only a session under `.factoria/sessions/`; the other tools
  that change something stay refused). Its instructions fix the order: play the first minutes by hand first, without reading
  any automatic session, so the first impression of the controls, the goal and the onboarding is that of someone new; then
  run `play.auto` and read its report (crashes, stuck and broken marks are taken as known, its phases show what was not
  reached); then play by hand the phases it reached and the reviewer did not, before judging them; and back opinions with the
  report's numbers, saying which parts were judged by hand and which only from the bot's report and screenshots. The prompt
  states that the bot's success says nothing about whether a person finds the game clear or fair.
* **REVIEW.md.** The reviewers read the `REVIEW.md` of the project first: controls, the goal, what is finished and what
  is a placeholder, and how to reach every scene and state quickly. A game that is easy to test gets a more useful review
  (`docs/AI_GUIDE.md`, "Keep the game reviewable"). `factoria export` leaves `REVIEW.md` out of the player's build.
* **Send to the orchestrator.** A review is only an opinion. In the editor you press **Send to orchestrator** on the
  report to post it into an orchestrator chat as your message (the active chat, or a new one); the orchestrator then
  plans the fixes and delegates them. Nothing is sent unless you press it.

The models come from the `artCritic` and `reviewer` roles (or from the orchestrator when you turned the role off, see
[Turning a role off](#turning-a-role-off)); the cost of a review is counted like any other run
(`docs/AI_COSTS.md`).
