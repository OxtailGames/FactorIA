# Hooks

A hook is a program (or a small JavaScript file) that FactorIA runs when something happens: the AI is about to call a tool, a tool
finished, the AI wants to stop, an engine command is about to run. A hook can add information, refuse the action with a reason,
change its arguments, or stop the run. Hooks are how you make a rule the AI cannot forget ("never delete a scene without asking",
"run the tests after every script edit", "log every asset the AI generates").

The events, the JSON a hook reads on stdin and the decisions it prints on stdout are Claude Code's, so **one hook script serves
Claude Code and FactorIA's own loop** (the `anthropic` and `openai-compatible` providers). On top of those, FactorIA has two events of
its own, `beforeCommand` and `afterCommand`, that fire around **every command of the engine for every caller**: an MCP client, the
`factoria` CLI, the editor, a script, the built-in AI.

Hooks live in the `hooks` entries of `extensions` ([AI_PROVIDERS.md](AI_PROVIDERS.md#extensions)): in your `ai.json` (every project)
or in the project's `.factoria/extensions.json` (it travels with the project). The editor lists them, and the recent runs with their
failures, in **AI > AI Settings... > Extensions > Hooks** ([EDITOR.md](EDITOR.md)). The commands `ai.hooks` and `ai.hooks_test`
do the same for an AI.

## Which provider runs what

| Provider | Hooks |
|---|---|
| `claude-code` | Claude Code runs the hooks of its seven events. FactorIA writes them into the run's private `--settings` file; a `js` handler becomes `factoria hooks run <module>`. `beforeCommand` / `afterCommand` are not given to it: the engine runs them itself when Claude Code calls a FactorIA tool. `http`, `prompt` and `agent` handlers are Claude Code's own. |
| `anthropic`, `openai-compatible` | FactorIA's loop runs the seven events and handlers of type `command` and `js`. `http`, `prompt` and `agent` handlers are skipped; `ai.hooks` lists them under `notRun`. Plugins and skills are not used by these providers. |
| `codex`, `generic-cli` | None of the AI events (Codex gets no extensions; a generic CLI gets the settings file only if its `argv` has `{settings}`). The engine's `beforeCommand` / `afterCommand` still fire, because they belong to the command registry, not to the AI. |

## The configuration

```json
{
  "extensions": {
    "hooks": {
      "guard": {
        "roles": ["orchestrator", "worker"],
        "hooks": {
          "PreToolUse": [
            { "matcher": "scene_delete|entity_delete", "hooks": [{ "type": "js", "module": "hooks/guard.js" }] }
          ],
          "PostToolUse": [
            { "matcher": "script_*", "hooks": [{ "type": "command", "command": "./scripts/lint.sh", "timeout": 30 }] }
          ],
          "beforeCommand": [
            { "matcher": "assets.generate_*", "hooks": [{ "type": "command", "command": "./scripts/budget-check.sh" }] }
          ]
        }
      }
    }
  }
}
```

An entry has the usual fields (`roles`, `enabled`, `note`; see [AI_PROVIDERS.md](AI_PROVIDERS.md#extensions)) and `hooks`:
`event -> [ { "matcher", "hooks": [ handler... ] } ]`. A group may write `match` instead of `matcher`. A handler is:

| Field | Meaning |
|---|---|
| `type` | `command` (a program), `js` (a JavaScript module, [below](#javascript-hooks)). `http`, `prompt` and `agent` are accepted for Claude Code and ignored by FactorIA's loop. |
| `command` | `command`: run by the shell (`/bin/sh -c`, `cmd.exe /C` on Windows) in the project folder. |
| `module` | `js`: a `.js` file inside the project's `hooks/` folder, written relative to the project (`hooks/guard.js`). |
| `timeout` | Seconds, above 0 and up to 3600. Default 60. A hook that takes longer is stopped and reported. |

Handlers of a group run in order, and the same handler listed twice runs once. When one refuses (or stops the run), the ones after
it are not asked.

### Events

| Event | When | Matcher compares with | Can refuse |
|---|---|---|---|
| `SessionStart` | A run begins (`startup`, or `resume`). | the source | no; its output is added to the message as context |
| `UserPromptSubmit` | The user's message, before the model sees it. | none | yes: the model is not called |
| `PreToolUse` | The AI calls a tool, before it runs. | the tool name | yes; can also change the arguments |
| `PostToolUse` | The tool ran and succeeded. | the tool name | no (the tool already ran); can add feedback |
| `PostToolUseFailure` | The tool ran and failed. | the tool name | no; can add feedback |
| `Stop` | The model finished its answer. | none | yes: the model is asked to keep going |
| `SessionEnd` | The run is over (also after a cancel or an error). | the reason | no |
| `beforeCommand` | **Engine:** a command is about to run, for any caller. | the command name | yes: the command does not run |
| `afterCommand` | **Engine:** the command ran, whatever the outcome. | the command name | no |

In the built-in loop `Stop` is asked only for the top-level run, and at most 8 times in a row: a hook that keeps refusing cannot
hold the run forever. A delegated worker run does not fire `SessionStart`, `UserPromptSubmit`, `Stop` or `SessionEnd`.

### Matchers

The matcher is Claude Code's: empty, missing or `*` = everything; letters, digits, `_ - space , |` = a list of exact names
(`Edit|Write`); anything else is a regular expression, tested unanchored (`^script_`). For `beforeCommand` and `afterCommand` the dot
is part of the name, so `scene.*`, `assets.generate_*` and `scene.spawn,scene.delete` are lists of names where `*` stands for any
text. In the AI events the tool name is the AI's tool name (`scene_spawn`, the command `scene.spawn` with its dot turned into an
underscore); a call through `tool_call` is shown to hooks under the command it names.

## What a hook reads

The event as one JSON object on stdin. The common fields: `session_id`, `transcript_path` (the run's session log), `cwd` (the
project folder), `permission_mode`, `hook_event_name`, and `agent_type` in a delegated run. Then the event's own:

| Event | Fields |
|---|---|
| `SessionStart` | `source`, `model` |
| `UserPromptSubmit` | `prompt` |
| `PreToolUse` | `tool_name`, `tool_input`, `tool_use_id` |
| `PostToolUse` | `tool_name`, `tool_input`, `tool_response`, `tool_use_id` |
| `PostToolUseFailure` | `tool_name`, `tool_input`, `error`, `is_interrupt`, `tool_use_id` |
| `Stop` | `stop_hook_active` (true after a continuation a hook asked for), `last_assistant_message` |
| `SessionEnd` | `reason` |
| `beforeCommand` | `command`, `args` |
| `afterCommand` | `command`, `args`, `ok`, `durationMs`, and `result` (clipped when large) or `error` |

A program also gets the environment variables `CLAUDE_PROJECT_DIR` and `FACTORIA_PROJECT_DIR` (the project folder),
`FACTORIA_HOOK_EVENT`, and `FACTORIA_IN_HOOK=1`. A `factoria` that a hook starts sees that last variable and runs **no hooks of its
own**, so a hook that calls the engine cannot trigger itself in a loop. For the same reason, commands that a hook makes the registry
run in the same process are not hooked.

## What a hook answers

* **Exit 0**: the action goes on. Stdout may be a JSON object with decisions (below). For `SessionStart` and `UserPromptSubmit` plain
  text on stdout is added to the message as context. Text that starts with `{` but is not valid JSON is a failure of the hook.
* **Exit 2**: blocks the action where the event can refuse (`PreToolUse`, `UserPromptSubmit`, `Stop`, `beforeCommand`); stderr is the
  reason the AI is given. For `PostToolUse` / `PostToolUseFailure` stderr becomes feedback next to the result. For the other
  events it is shown to the user.
* **Any other exit code**, a program that cannot start, a timeout: the hook **failed**. The action goes on, and the failure is reported
  (never silent, [below](#where-a-failing-hook-shows)).

The JSON a hook may print (Claude Code's):

| Field | Effect |
|---|---|
| `decision: "block"`, `reason` | Refuses where the event can (as exit 2). On `PostToolUse` the reason is feedback added to the result. |
| `continue: false`, `stopReason` | Stops the whole run after the current step (the AI events). |
| `systemMessage` | A line shown to the user in the chat. |
| `hookSpecificOutput.additionalContext` | Text added for the model: to the message (`SessionStart`, `UserPromptSubmit`) or after the tool result (`PostToolUse`). |
| `hookSpecificOutput.permissionDecision` | `PreToolUse`: `deny` refuses (with `permissionDecisionReason`); `allow` is noted; `ask` and `defer` go ahead as if the hook said nothing (FactorIA's loop has nobody to ask). |
| `hookSpecificOutput.updatedInput` | `PreToolUse` / `beforeCommand`: the arguments the tool or command gets instead. |
| `hookSpecificOutput.updatedMCPToolOutput` | `PostToolUse`: the result the model sees instead. |

When a `PreToolUse` or `beforeCommand` hook refuses, the AI (or the caller of the command) gets the error code `blocked_by_hook`
with the reason and a hint, and the tool or command does not run. A hook that fails adds a `hookWarnings` list to the result of the
command it ran around.

### Example: a guard in a shell script

```sh
#!/bin/sh
# scripts/no-delete.sh: PreToolUse for scene_delete. Reads the event on stdin.
input=$(cat)
case "$input" in
  *'"tool_name":"scene_delete"'*) echo "Scenes are never deleted by the AI. Ask the user." >&2; exit 2 ;;
esac
exit 0
```

## JavaScript hooks

A `js` handler is a module of the project's `hooks/` folder. It runs inside FactorIA in a QuickJS runtime of its own and needs **no
trust**, even when the project is downloaded: the runtime has the language and `console` and nothing else. No engine bindings (it is
not a game script: no `world`, `fa`, `input`), no files, no network, no timers, no way to start a program, no packages. It has a
time limit (the handler's `timeout`) and a 64 MB memory limit. A module may `import` other files of the project with a relative path
(`import { rules } from "./rules.js"`), as long as they stay inside the project folder.

The module exports one function per event, named like the event, on the default export or as named exports; a default export that is
a function is called for every event. Its argument is the same JSON a program reads on stdin; what it returns is the same JSON a
program prints (an object with decisions, or for `SessionStart` and `UserPromptSubmit` a string of context, or nothing). It answers
synchronously.

```js
// hooks/guard.js
export default {
  PreToolUse(input) {
    if (input.tool_name === "scene_delete") {
      return { decision: "block", reason: "Scenes are never deleted by the AI. Ask the user." };
    }
  },
  PostToolUse(input) {
    console.log("ran", input.tool_name); // goes to the run's log, not to the model
  },
  beforeCommand(input) {
    if (input.command === "assets.generate_image" && !input.args.prompt) {
      return { decision: "block", reason: "assets.generate_image needs a prompt." };
    }
  },
};
```

FactorIA's loop and the engine's command events run the module in-process. Claude Code only starts programs, so for it FactorIA writes
the handler as `factoria hooks run hooks/guard.js --project <dir>`: that command reads the event on stdin, calls the module and prints
its answer, with `console` output on stderr. You can run it by hand:

```sh
echo '{"hook_event_name":"PreToolUse","tool_name":"scene_delete","tool_input":{}}' | factoria hooks run hooks/guard.js
```

A module that has no function for the event it is given is a failed run, with the names it does export in the message. Leave the
event out of the entry's `hooks` instead of exporting nothing for it.

## Trust

A `command` handler starts a program with your permissions, so a project's hooks that start a program run only after you trust the
project (the same trust as its plugins: [AI_PROVIDERS.md](AI_PROVIDERS.md#trusting-a-projects-extensions); no command can grant it). Hooks
in your own `ai.json` need no trust. A `js` handler needs none either, in either file: it cannot start anything. Until the project is
trusted, `ai.hooks` and the editor show its program hooks as not trusted and they do not run.

`beforeCommand` / `afterCommand` hooks apply to every role's entries: the registry has no role. `roles` in an entry limits the AI events
only.

## Where a failing hook shows

* **The chat**: an Info line ("Hook failed (PostToolUse, guard: ./lint.sh): exited with code 3: ...") when the built-in loop ran it;
  a `beforeCommand` / `afterCommand` hook that failed adds `hookWarnings` to the command's result, and a warning goes to the engine log.
* **The session log** (`.factoria/ai/sessions/*.jsonl`): a `hook` line for every handler run with the event, what it matched, the
  command or module, the exit code, how long it took, what it decided, its stdout and stderr (clipped), and the error. The
  session timeline reads it: it has a `hook` kind and `totals.hook` with the time hooks cost and how many failed.
* **The editor**: AI > AI Settings... > Extensions > Hooks lists the last runs of this editor with failures in red.
* **`ai.hooks`**: every hooks entry with its handlers, trust and problems, and `recentRuns` of this process.

## Trying a hook

`ai.hooks_test {event, match, input}` runs the configured handlers of one event the way the loop or the registry would, and returns
what they decided. **The handlers really run**: a program does what it does.

```sh
factoria call ai.hooks_test '{"event":"PreToolUse","match":"scene_delete","input":{"tool_name":"scene_delete","tool_input":{}}}'
factoria call ai.hooks_test '{"event":"beforeCommand","match":"scene.spawn","input":{"command":"scene.spawn","args":{"name":"Coin"}}}'
```

`ai.hooks {recent: 20}` lists the entries and the last runs. Both are commands, so they are also MCP tools and `factoria call` calls.
Commands reload the hooks from `ai.json` and the project's file at most once a second, so an edit applies without a restart.
