[Back to the index](../README.md)

# Commands: ai

## `ai.extensions`

Not released yet (on main after 0.10.0).

Show the extensions (plugins, skills, hooks) AI runs load, per role, and what stops one from loading.

The user's "extensions" in ai.json plus the project's .factoria/extensions.json (docs/AI_PROVIDERS.md, Extensions). Returns {inheritUserPlugins, projectFile:{path, exists, hash, trusted, error}, entries:[{kind plugin|skill|hooks, name, source user|project, enabled, roles, target (the folder it resolves to), problem + fix when it cannot load, trusted for a project's plugin or hooks}], roles:{<role>:{provider, providerKind, receives:[{kind, name, source}], skipped:[{kind, name, source, reason, fix}], notes, userPluginsOff, projectSettingsSkipped}}, claudeSettings:{files:[{path, exists, needsTrust, grants (what in the file runs a program or widens what the AI may do: hooks, enabledPlugins, statusLine, env, permissions.allow, defaultMode...)}], needsTrust, trusted, loadedByClaudeCode, message + fix when a file needs trust and the project is not trusted: Claude Code then runs without them}, denyRules:[{file, rule, tool, fix}] (rules in the project's .claude/settings*.json that remove FactorIA's own tools from Claude Code), scope}. Claude Code uses plugins, skills and hooks; Codex uses skills only; a generic CLI uses plugins and hooks when its argv has {plugin_dirs} / {settings}; the API providers (anthropic, openai-compatible) use skills and hooks in FactorIA's own loop, not plugins. A plugin or hook that comes from a project loads only after the USER trusts the project in the editor (AI settings > Extensions); no command can grant that. Read-only. Example: {"role":"worker"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `role` | string | no | Only this role (orchestrator, worker, fast, artist, audio, artCritic, reviewer). Omit for all. |

## `ai.hooks`

Not released yet (on main after 0.10.0).

List the hooks (programs and JavaScript modules run on events) and the recent runs of every hook.

The "hooks" entries of `extensions` in ai.json and the project's .factoria/extensions.json (docs/HOOKS.md). Returns {entries:[{name, source user|project, enabled, roles, runsProgram, trusted (a project's entry that starts a program), events:{<Event>:[{matcher, handlers:[{type command|js|http|prompt|agent, target (the command, the module or the url), timeout?, runsHere}]}]}, problem + fix when it cannot be used}], events (the events FactorIA runs: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, Stop, SessionEnd, and beforeCommand / afterCommand around every command of the registry), defaultTimeoutSeconds, notRun (handlers only Claude Code runs), recentRuns:[{event, matched, extension, source, type, target, startedMs, ms, exitCode, timedOut, failed, error, decision, reason, output, stderr}] (this process's last runs, newest last)}. Read-only. Example: {"recent":20}

| Argument | Type | Required | Description |
|---|---|---|---|
| `role` | string | no | Only the entries this role loads (orchestrator, worker, fast, artist, audio, artCritic, reviewer). Omit for all. |
| `recent` | integer | no | How many recent runs to include. Default 50. |

## `ai.hooks_test`

Not released yet (on main after 0.10.0).

Run the configured hooks of one event with a sample input and show what they decide.

Try a hook before relying on it: runs the handlers configured for `event` whose matcher fits `match` with `input` as the event's JSON (the common fields session_id, cwd, hook_event_name... are added), exactly as the AI loop or the registry would. The handlers REALLY run (a program does what it does). Returns {event, matched, groups, outcome:{blocked, reason, blockedBy, stop, stopReason, context, feedback, systemMessages, allowed, updatedInput?, failed, runs:[{...exitCode, ms, decision, reason, output, stderr, failed, error}]}, skipped, note?}. `match` is what the matcher is compared with: the tool name (PreToolUse, PostToolUse, PostToolUseFailure), the command name (beforeCommand, afterCommand), the source of SessionStart or the reason of SessionEnd. A project's hooks that start a program run only after the user trusts the project in the editor. Example: {"event":"PreToolUse","match":"scene_spawn","input":{"tool_name":"scene_spawn","tool_input":{"name":"Coin"}}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `event` | string | yes | SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, Stop, SessionEnd, beforeCommand or afterCommand. |
| `match` | string | no | What the matcher is compared with (tool name, command name, source). Omit for events without a matcher. Default "". |
| `input` | object | no | The event's own fields, e.g. {tool_name, tool_input} for PreToolUse, {command, args} for beforeCommand, {prompt} for UserPromptSubmit. Default {}. |
| `role` | string | no | Whose entries count for the AI events (the engine's command events use every role's). Default "orchestrator". |

## `ai.models`

List the models each AI provider offers (the values for roles.<role>.model).

Asks the providers themselves, so newly released models show up: Claude Code through its CLI (aliases such as opus first, then full names; no model call, no usage), the Anthropic API and OpenAI-compatible APIs through GET /models. Codex and generic CLIs cannot list their models: their entry has an error. Without `provider` it lists every provider that ai.providers reports available; one provider's failure is in its own entry (error, hint) and does not fail the call. Returns {providers:[{name, models:[{id, name, description, resolved}], error?, hint?}]}: id is the value for roles.<role>.model, name the display name (empty when the provider gives none), description one line, resolved the model an alias stands for (empty for a full name). Example: {"provider":"claude-code"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `provider` | string | no | Only this provider (a name from ai.providers). Omit for every available one. |

## `ai.plugin_install` (modifies state)

Not released yet (on main after 0.10.0).

Install a Claude Code marketplace plugin (the user's action) and add it to ai.json extensions.

Runs the Claude Code CLI's own commands with the executable of the claude-code provider: `claude plugin marketplace add <marketplace>`, then `claude plugin install <plugin> --scope user`; a step already done (the marketplace listed by `claude plugin marketplace list`, the plugin installed for the user by `claude plugin list`; an install for one folder does not count) is skipped. Then adds a plugin entry name@marketplace to the user's ai.json "extensions" (the other keys stay), with `roles`. It installs software, so only the USER starts it (the editor's AI settings > Extensions > Add TokenEconomizer, or the CLI); the built-in agent and the MCP server never offer it. `preset` "tokeneconomizer" fills marketplace microsoft/TokenEconomizer, plugin tokeneconomizer@tokeneconomizer and requiresPython 3.10 (checks python3 / python before installing). `dryRun` returns what it would do. Returns {ok, dryRun, provider, command, marketplace, plugin, python:{required, command, version, ok, message}, steps:[{id marketplace|plugin|entry, command, needed, status would_run|not_needed|done|skipped|failed, detail}], entry:{name, added, present, path}, message}. Failures name the step, what the CLI said and how to fix it. Example: {"preset":"tokeneconomizer","dryRun":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `preset` | string ["tokeneconomizer"] | no | A known plugin: fills marketplace, plugin and requiresPython (your own values win). |
| `marketplace` | string | no | What `claude plugin marketplace add` takes: owner/repo of GitHub, a git URL or a path. |
| `plugin` | string | no | name@marketplace, as `claude plugin install` takes it. |
| `roles` | array | no | Roles that load the entry (default: orchestrator, worker, fast, artist, audio). |
| `name` | string | no | The entry's name in ai.json (default: the plugin's name). |
| `note` | string | no | The entry's note. |
| `requiresPython` | string | no | Minimum Python version the plugin needs, e.g. 3.10. Checked before installing. |
| `dryRun` | boolean | no | Report the commands and whether each is needed; install nothing. |

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

## `ai.saver_fact` (modifies state)

Not released yet (on main after 0.10.0).

Accept or decline a proposed project fact: one line added to the project's AGENTS.md.

A command that failed with the same error code in several runs until a later call of it worked proposes one line for AGENTS.md (ai.savers lists them with their id). Accept appends the line under "## Project facts" in the project's AGENTS.md (created when missing); `line` replaces the proposed line. Nothing is written before an accept. Decline: not proposed again. Forget: undecided again (the line is not removed from AGENTS.md). Returns {id, status, written?, file?}. Example: {"id":"scene.load:not_found","answer":"accept"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The fact's id as ai.savers shows it: command:code. |
| `answer` | string ["accept","decline","forget"] | yes | accept (write it), decline or forget (back to undecided). |
| `line` | string | no | With accept: the line to write instead of the proposed one. |

## `ai.saver_group` (modifies state)

Not released yet (on main after 0.10.0).

Accept or decline a proposed tool group for this project (loaded in full up front from the next run).

The runs of a project count the commands they load from the tool catalog (ai.savers shows the counts and proposals). Accept: from the next run on, `role` loads the commands of `group` (a command category such as assets or anim) in full besides its own toolGroups, in this project only (kept in .factoria/ai/savers.json; ai.json is not changed). Decline: the group is not proposed again. Forget: undecided again. Nothing is ever denied: a command outside the loaded groups stays reachable through the catalog. Returns {role, group, status, note}. Example: {"role":"worker","group":"assets","answer":"accept"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `role` | string | yes | The role that gets the group: orchestrator, worker, fast, artist, audio, artCritic or reviewer. |
| `group` | string | yes | A command category (the part of a command name before the dot, e.g. assets). |
| `answer` | string ["accept","decline","forget"] | yes | accept, decline or forget (back to undecided). |

## `ai.savers`

Not released yet (on main after 0.10.0).

Show the engine's token savers (loop guard, learned tool groups, project facts), what this project's runs learned and the proposals waiting for an answer.

The built-in agent loop (the API providers) has three savers, each with a switch in ai.json "savers" and in the editor's AI settings > Extensions tab (docs/AI_PROVIDERS.md, Token savers). Returns {switches:{loopGuard, loopGuardJudge, learnedToolGroups, projectFacts}, thresholds, projectFile:{path, exists} (.factoria/ai/savers.json), runs:{<role>:n}, groups:{<role>:{<group>:{runs, commands:{<command>:n}, status accepted|declined|""}}} (the commands the runs loaded from the tool catalog), acceptedGroups:{<role>:[group]}, facts:{<id>:{runs, status, line}}, proposals:{toolGroups:[{role, group, runs, commands, definitionBytes}], facts:[{id, command, code, runs, line}]}}. A proposal changes nothing until it is accepted with ai.saver_group or ai.saver_fact; nothing is ever denied. Read-only. Example: {}

## `ai.session_timeline`

Since 0.9.0.

Show where the time of a recorded AI session went: the long gaps and what was going on in each.

Reads one transcript of <project>/.factoria/ai/sessions/ (every event has "t", the UTC time with ms; tool_end has "ms", the duration of the tool; thinking has "ms", how long the model thought, also when its text is hidden). Returns `gaps`: each pause of at least minGapSeconds with start, end, seconds, activity (tool, thinking, model = waiting for the model, user = waiting for the user) and detail (the tool's name...), and `totals` per activity with the tools sorted by time. A session recorded before events carried times gives hasTimes false and a note. `context` splits what each model call carried (built-in agent only): per step the system prompt, the tool definitions and the conversation, in bytes and estimated tokens, plus how many commands were tools and how many only catalog lines, and the totals of the run. Example: {"minGapSeconds":60}

| Argument | Type | Required | Description |
|---|---|---|---|
| `session` | string | no | File name of the session (20261014-153012-orchestrator or with .jsonl) in .factoria/ai/sessions. Omit for the newest. |
| `minGapSeconds` | number | no | List only the gaps at least this long (seconds). Totals always count every gap. Default 30. |

## `ai.tool_plan`

Not released yet (on main after 0.10.0).

Show which commands the built-in AI agent of a role gets as tools in full and which only as catalog lines.

The built-in agent (API providers) does not send every command's definition on every step: it gets the core commands (files, docs, scene, running the game, validating, scripts) and the tool groups of the role (ai.json roles.<role>.toolGroups, default: artist assets, audio assets and audio) in full, plus tool_describe and tool_call, and lists the other commands in its system prompt. Returns `tools` (name and estimated bytes of each tool sent), `catalogCommands`, the estimated `toolBytes`/`toolTokens` against `fullBytes`/`fullTokens` (every command in full), `groups` (the tool groups loaded), `notes` (a group that matches nothing, with suggestions) and `categories` (per category: commands, inCatalog, inFull). CLI agents (claude-code...) choose their own tools; this plan is what the API providers get. Example: {"role":"artist","catalog":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `role` | string | no | Role to plan for: orchestrator, worker, fast, artist, audio, artCritic, reviewer. Default "orchestrator". |
| `catalog` | boolean | no | Also list every catalog command (command, category, summary). Default false. |

## `ai.tool_servers`

Since 0.8.0.

List the external tool servers (MCP) the user configured in ai.json, and optionally test them.

The user's "mcpServers" (docs/AI_PROVIDERS.md, External tools): services such as Scenario (game art) or local programs whose tools the AI may call. Each entry has name, type (http|stdio), target (URL without its query, or program), enabled, roles (who gets it), usesKey, keySource (where the key was found, never the key), problem (what is missing, "" when ready) and note. With test:true each enabled, ready server is contacted (initialize + tools/list; no tool is called, nothing is spent) and gets `connected`, `server` (how it introduced itself), `tools` [{name, description}] or `error` + `hint`. Keys are never returned. `name` limits the call to one server. Example: {"test":true,"name":"scenario"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `test` | boolean | no | Connect to each server and list its tools. Default false. |
| `name` | string | no | Only this server (a name from the list). |

