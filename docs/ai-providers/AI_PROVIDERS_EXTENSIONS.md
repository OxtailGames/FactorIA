# AI providers: tools, savers, retrospective and extensions

[AI providers](../AI_PROVIDERS.md) > AI providers: tools, savers, retrospective and extensions

## External tools (MCP servers)

`mcpServers` in your `ai.json` connects the AI to services and programs of your own choosing: an image generator such as
[Scenario](https://www.scenario.com) (game art), a search or file tool, anything that speaks the Model Context Protocol (MCP). The
AI calls their tools when it sees fit, next to the engine's own tools. FactorIA does not know any service in particular: a server
is an address (or a program) plus the key it wants, so Scenario is one entry among whatever you add.

The shape is the one Claude Code's `.mcp.json` uses, so the JSON a service's documentation gives for Claude Code can be pasted
(the editor has a button for it, [below](AI_PROVIDERS_AGENT.md#the-ai-settings-window)):

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
| `roles` | Who may use the server (role names, see [Roles](AI_PROVIDERS_CONFIG.md#roles)). Left out: orchestrator, worker, fast, artist and audio. The review roles (`artCritic`, `reviewer`) get a server only when listed here. |
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
  FactorIA cannot see what it costs (`limits.maxCostUsd` and `limits.maxAssetCostUsd` cover model tokens and asset providers, not a tool server). The prompt tells the AI to try one small call
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

## Token savers

Savers of FactorIA's own loop, for the providers that use it (the API providers; Claude Code and Codex run their own
loops and ignore them). Each has a switch in **AI settings > Extensions > Token savers** and in the `savers` section of `ai.json`
(the first three on by default, the [retrospective](#retrospective) off; Save writes only what differs from the default, and every
other key stays):

```json
"savers": { "loopGuard": true, "loopGuardJudge": "", "learnedToolGroups": true, "projectFacts": true,
            "retrospective": false, "retrospectiveSteps": 150, "retrospectiveCostUsd": 3.0 }
```

* **Loop guard** (`loopGuard`). When the same command fails with the same error code three times in one turn, the third failure's
  result carries a short `loopGuard` redirect (what failed, its hint, "try a different way") and the loop makes no model call
  of its own for it; the model reads the redirect with its next step. `loopGuardJudge` names a role (for example `fast`) whose model
  writes the redirect instead of the fixed text: one short model call per redirect, with its tokens and cost added to the run's
  usage and checked against the run's limits like any other call. A judge on a CLI provider, without a model or whose call fails is
  skipped and the fixed text is used (the transcript line says why). Every redirect is a `saver` line of the session transcript and an `Info` event "Loop guard: ...".
  A command and code get one redirect; the count starts again after the command works.
* **Learned tool groups** (`learnedToolGroups`). Per project, `.factoria/ai/savers.json` counts for each role the runs that
  loaded a command outside its plan (`tool_describe`, or `tool_call` of a catalog command) and that command's group (its category).
  After 3 runs that needed the same group, the editor proposes loading it in full up front for that role. Only **Load up front**
  applies it, for that role in that project, from its next run; your `ai.json` is not changed. **No thanks** stops the proposal. Nothing
  is ever denied: every command stays reachable through the catalog.
* **Project facts** (`projectFacts`). A command that failed with the same code in 3 runs, where a later call of it worked, proposes
  one line for the project's `AGENTS.md`. The file is written only on accept, under a `## Project facts` heading (created when
  missing); accepting twice adds the line once.
* **Retrospective** (`retrospective`, off by default because it spends a model call nobody asked for): after a long run, the
  [retrospective](#retrospective) files efficiency feedback about it. `retrospectiveSteps` (150 model calls) and
  `retrospectiveCostUsd` (3 US dollars) say what a long run is: either one reached starts it.

The state and the answers go through commands, so the CLI and MCP can use them:
`ai.savers` (read-only: switches, thresholds, counts and proposals), `ai.saver_group {role, group, answer}` and
`ai.saver_fact {id, answer, line?}` with `answer` of `accept`, `decline` or `forget` (`line` replaces the proposed text when accepting).

## Retrospective

Efficiency feedback without writing the report by hand ([ENGINE_FEEDBACK.md](../ENGINE_FEEDBACK.md), "Efficiency feedback"). The
retrospective looks back at the recorded AI runs of the open project, finds where they spent steps, minutes or tokens that an
engine change would save, and files the entries. Two steps:

1. **A mechanical pass, no model.** It reads the transcripts of `<project>/.factoria/ai/sessions` (the newest 40, or the ones you
   name, or those since a date) and measures the usual waste: the same command failing with the same code (3 times or more), the
   same doc or file read again and again (3 times or more), a tool result over 40 KB (two or more from one command), five or more
   screenshots in a row, calls that kept the run waiting a minute or more (or five minutes in all), long edit-run-check loops on one
   or two systems, and commands that an open ENGINE_FEEDBACK workaround already names. The same transcripts always give the same
   candidates and numbers. A candidate is kept when a fix could save at least what the lowest row of the
   [threshold table](../ENGINE_FEEDBACK.md#efficiency-feedback) asks (a doc or guide: 10 minutes or 100k tokens per game); the most
   promising come first, at most 12. Evidence that an open efficiency entry already counts is skipped.
2. **One call of the fast role** (the orchestrator when the fast role is off) with the 8 best candidates. The model picks **at most
   three** that a fix in the engine would remove and writes each as an entry: the title, the cheapest fix that would work, what the
   fix would save, why a cheaper one would not. Every entry goes through the gate of `feedback.report` with kind `efficiency` (the
   threshold per fix type, the cheapest-fix rule, the dedupe by fix), so a candidate the gate refuses comes back in `dropped`
   with the reason. A lesson that is true only of this game (its own scripts, scenes or assets) becomes a **project-fact
   proposal** instead: it waits in `ai.savers` and goes to `AGENTS.md` only when you accept it, like the savers' own facts.

Before it looks for new waste it **checks the fixes of earlier entries** ([ENGINE_FEEDBACK.md](../ENGINE_FEEDBACK.md), "Did the fix work?"): an
efficiency entry the engine fixed (`fixed-in-engine`, with the version, the day and what one occurrence cost before) is compared with the same
pattern in the transcripts since that day, when this engine is at least the fixing version. `fixChecks` in the answer says `waiting` (no run
since), `gone`, `worked`, `partial` or `no_change`, each with one sentence, and the answer is recorded on the entry (`fixCheck`; with
`candidatesOnly` nothing is written). A pattern a fix did not remove is filed again with `afterFix` set to that version, so the engine
developer sees a fix that saved nothing. The transcripts do not record which engine ran them: the version of the running engine and the day of
the fix stand for it.

It never sends anything: the entries stay in `ENGINE_FEEDBACK.json` until you share them like any other. A model that cannot be asked
(no key, the role off) is not an error: the candidates come back and `note` says why. The cost of the model call is returned as
`costUsd`; inside a run it is added to the run's usage.

Where to start it:

* **The Feedback panel's Retrospective button** runs it in the background (the panel stays usable) and then says what it did, for
  example "1 efficiency entry filed, 0 project-fact proposals, 0 candidates dropped", and adds up what the open efficiency
  entries' fixes would save.
* **`factoria ai retrospective [project] [--session NAMES] [--since DATE] [--candidates-only] [--json]`**, the command
  `ai.retrospective {sessions?, since?, candidatesOnly?}` for MCP and scripts. `--candidates-only` is the mechanical pass alone: it asks
  no model, files nothing and costs nothing.
* **By itself after a long run**, when `savers.retrospective` is on: a run that took `retrospectiveSteps` model calls (150) or cost
  `retrospectiveCostUsd` (3 US dollars). It runs at most once per run (not for one you cancelled or one without a project), and never
  inside another retrospective. When it files an entry or proposes a fact, the run shows an Info line "Retrospective: ...";
  otherwise it says nothing.

One retrospective runs at a time in a process: a second `ai.retrospective` call gets the error code `busy`. **Stop** (the editor's
button, the cancel of the command) reaches the model call too: the request is dropped, a CLI agent's process is killed, and the
retrospective returns at once with the error code `cancelled` and nothing filed.

How much it reads: a transcript is read line by line (a line over 8 MB is skipped and counted), a file over 64 MB is not read, and
one pass reads 256 MB in all. A transcript left out for that is listed in the result's `skipped` (`[{id, reason}]`) and the `note`
says how many, so a finding may be missing for that session; naming one in `sessions` is an error with the same reason. Delete the
oldest files of `.factoria/ai/sessions` to bring a project back under the limits.

## Extensions

`extensions` loads plugins, skills and hooks into the AI agents, next to the engine's own tools. It is
the same idea as `mcpServers` ([above](#external-tools-mcp-servers)) for the things Claude Code calls plugins, skills and hooks: a plugin
(a folder with `.claude-plugin/plugin.json`, a `.zip`, or one you installed with `claude plugin install name@marketplace`), a skill
folder (one that holds a `SKILL.md`, or a folder of such folders) and hooks (a program that runs on an event such as
`PostToolUse` or `Stop`, in the shape of Claude Code's `hooks`, or a small JavaScript file). **Claude Code** takes all three;
**skills** reach every provider ([Skills](#skills-for-every-provider)); the API providers (`anthropic`, `openai-compatible`) also run
the **hooks** in FactorIA's own loop, and the engine runs two hook events of its own around every command ([HOOKS.md](../HOOKS.md)); see
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
| `hooks` | `hooks`: Claude Code's hooks object, `event -> [{ "matcher", "hooks": [{ "type": "command", "command": ... }] }]`; a handler may also be `{ "type": "js", "module": "hooks/x.js" }` and take a `timeout` in seconds, and the events `beforeCommand` / `afterCommand` are FactorIA's own. Everything about hooks (events, what a hook reads and answers, trust, where failures show) is in [HOOKS.md](../HOOKS.md). |
| `note` | What it is for (shown in `ai.extensions` and the editor). |
| `roles` | Who loads it (role names, see [Roles](AI_PROVIDERS_CONFIG.md#roles)). Left out: orchestrator, worker, fast, artist and audio; the review roles only when listed. |
| `enabled` | `false` keeps the entry without loading it. |
| `inheritUserPlugins` | Top level of the section, `ai.json` only, default `true`: Claude Code also loads your own setup (`~/.claude`). `false` starts it with `--setting-sources project,local`, which drops ALL of your user-level Claude Code settings, not only the plugins: your plugins, skills and hooks, but also your permissions (`allow` / `deny` / `ask`) and `env`. Only what is listed here (and the trusted project's own `.claude`) loads. It applies to Claude Code only. |

### What each provider does with extensions

| Provider | How the extensions are used |
|---|---|
| `claude-code` | One `--plugin-dir <folder>` per plugin; the skills go in a plugin FactorIA writes for the run (`factoria-extensions`, a copy of the skill folders under `<project>/.factoria/ai/fa-run-ext-skills-*`); the hooks of the entries are merged into a private `--settings` file (`<project>/.factoria/ai/fa-run-settings-*.json`, readable only by you). Both are removed when the run ends. `--setting-sources` is also passed when `inheritUserPlugins` is `false` (`project,local`) or when the project's own `.claude/settings*.json` runs a program or widens what the AI may do (see below) and the project is not trusted (`user`; an empty value with both), see [below](#trusting-a-projects-extensions). If your own `argv` uses `{plugin_dirs}` or `{settings}` those place the folders and the file and FactorIA adds no flag for them; an `argv` that already has `--settings` or `--setting-sources` is not given a second one. |
| `codex` | Skills only. Codex reads Agent Skills from `.agents/skills` of the folder it starts in, so FactorIA copies the skills of the run to `<project>/.agents/skills/factoria-r<tag>-<name>/` (and writes `.agents/skills/.gitignore` with `factoria-*/` when there is none) and removes them when the run ends; folders of your own there are not touched. Codex has no plugin folder or hooks file for FactorIA to fill: a plugin or hooks entry for a Codex role is skipped, and the run says so (an Info line in the chat and the CLI output). Codex also keeps the `# Skills` lines in the prompt and `skills_read`, so a Codex version that does not scan `.agents/skills` still reads the skills. Not tested against a real Codex here (no Codex was available): `codex` must be a version with Agent Skills. |
| `generic-cli` | Plugins when the `argv` has the `{plugin_dirs}` placeholder, hooks when it has `{settings}` (the path of the private settings file). `{plugin_dirs}` after a flag (`"--plugin-dir", "{plugin_dirs}"`) repeats that flag once per folder; with no folder, the placeholder and its flag are dropped. A skill folder is not passed (no flag is known for it); the skills reach it as prompt lines and `skills_read`. What cannot be passed is listed in the run output with the placeholder to add. |
| `anthropic`, `openai-compatible` | **Skills and hooks**: FactorIA's own loop runs the seven events of Claude Code's hooks (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `SessionEnd`) for handlers of type `command` and `js`, with the same JSON on stdin and the same decisions on stdout, so one hook script serves Claude Code and these providers ([HOOKS.md](../HOOKS.md)). Handlers of type `http`, `prompt` and `agent` are Claude Code's and are skipped. Skills reach them as one line each in the system prompt, read with `skills_read` ([Skills](#skills-for-every-provider)). Plugins are not used by these providers, and `ai.extensions` and the run say so for each one listed. |
| every provider | `beforeCommand` and `afterCommand` hooks fire around every command of the engine, whoever calls it (an MCP client, the CLI, the editor, a script, the built-in AI), whatever provider the role has. A call the caller's capabilities refuse (`capability_denied`) is not hooked: no `beforeCommand`, no `afterCommand`. |

### Skills for every provider

A skill is a folder with a `SKILL.md` (the Agent Skills format) that the AI reads only when the task needs it. They come from the
engine (baked into the binary), from `~/.factoria/skills`, from the project's `skills/` and from the skill entries above; the
project's wins over yours, and yours over the engine's. The built-in agent (anthropic, openai-compatible), Codex and generic CLIs get
one line per skill in the system prompt and read one with the tool `skills_read`; Claude Code and Codex are also given the skill
folders (above). A skill entry may name an engine skill as `"path": "engine:<name>"` to set its `roles` or switch it off. Role
defaults, the commands (`skills.list`, `skills.read`, `skills.new`) and the format are in [SKILLS.md](../SKILLS.md).

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

### Installing a plugin

`ai.plugin_install {marketplace, plugin, roles?, name?, note?, requiresPython?, preset?, dryRun?}` installs a Claude Code marketplace plugin for
you and adds it to the `extensions` of your `ai.json` (the editor's **Add TokenEconomizer** button calls it). It runs the Claude Code
CLI's own commands, with the executable of the configured `claude-code` provider, and skips a step that is already done:

1. `claude plugin marketplace add <marketplace>` unless `claude plugin marketplace list` already shows it (or the plugin is installed);
2. `claude plugin install <plugin> --scope user` unless `claude plugin list` already shows `plugin` (`name@marketplace`) installed for
   the user (an install of scope `local` or `project` belongs to one folder and does not count: the entry is for every project);
3. a `plugin` entry `name@marketplace` in your `ai.json` `extensions` (with `roles`, default roles when left out), unless one exists. Every
   other key of the file stays. The roles are checked before anything is installed, so a typo leaves nothing half done.

The lists are read with `--json` and, for a CLI without it, from the plain listing. `requiresPython` (for example `3.10`) checks `python3`
(`python` on Windows) before the first command and refuses to install, with how to fix it, when it is missing or older; a plugin
already installed needs no Python check. `dryRun` returns the same report without installing anything: each step with its `command`,
whether it is `needed` and `status` (`would_run` or `not_needed`), the `python` check and the `entry` it would add. A failure names the
step, the exit code and what the CLI printed, and the command to run in a terminal to see the rest; steps that finished before it are in the
message, and a failed install writes nothing to `ai.json`.

`preset: "tokeneconomizer"` fills in the marketplace `microsoft/TokenEconomizer` (GitHub), the plugin
`tokeneconomizer@tokeneconomizer` and `requiresPython` 3.10. TokenEconomizer (Microsoft) is a Claude Code plugin that learns
micro-skills per repository, prunes the tools the agent is offered (one command gives them back) and guards against failure loops; it
needs Python 3.10 or newer. Because it installs software that runs hooks on your computer, only YOU start this command: the built-in agent
never gets any `ai.*` command (except `ai.review_feedback`) and `factoria mcp` and the editor's MCP endpoint never list or run
`ai.plugin_install`, so no AI client can call it.

```
factoria call ai.plugin_install '{"preset":"tokeneconomizer","dryRun":true}'
factoria call ai.plugin_install '{"preset":"tokeneconomizer","roles":["orchestrator","worker"]}'
```

### Looking at what a run gets

`ai.hooks` (read-only) lists the hooks entries with their handlers and the recent runs of each, and `ai.hooks_test` runs the hooks of one
event with a sample input ([HOOKS.md](../HOOKS.md#trying-a-hook)).

`ai.extensions` (read-only, `{"role": "worker"}` optional) returns the entries with what stops each from loading, per role the
provider and what it `receives`, `skipped` (reason and fix), `notes`, the project's file (`exists`, `hash`, `trusted`), `claudeSettings` (what in the project's `.claude/settings*.json` needs trust, whether the project
is trusted and so whether Claude Code loads them), the deny rules
and a `scope` sentence on the providers that do not use extensions. `factoria ai doctor` prints the same in its "Extensions" section;
`factoria ai doctor --project DIR` (default: the current folder when it holds `factoria.json`) says which project's file and deny rules.
The report never changes the trust file.
