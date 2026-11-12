# Recorded CLI outputs (contract tests)

`tools/ai/tests/test_cli_contract.cpp` replays these files through the code the engine runs on a live CLI
(`CliStreamParser`, `list_models`, `detect_providers`) and checks the facts the engine depends on: final text, success or
error, session id, usage and cost, tool calls, a refused tool. A CLI update that changes its output format fails there,
with the fixture and the field named.

One folder per CLI and version: `<cli>-<version>/` is a **recording**; `<cli>-docs/` is **written from the CLI's documentation**
and the format `tools/ai/src/cli_agent.cpp` expects (the CLI is not installed on the development machines). A fixture that
is not a recording says so: the first line of its `.jsonl` is `{"_note": ...}` (the parsers ignore it), and this file says so.

## claude-code-2.1.318 (recorded)

Recorded on 2026-11-12 with Claude Code 2.1.318 (`claude --version` prints `2.1.318 (Claude Code)`, `version.txt`), model
`haiku`, each run in an empty throwaway directory holding only `hello.txt` ("The secret word is banana."). The command line is
the one the engine builds (`default_cli_argv` + `apply_permission_mode`) without `--mcp-config` / `--allowedTools` (they only
add the `factoria` MCP server), the prompt as one stream-json user message on standard input:

```
echo '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"<prompt>"}]}}' |
  claude -p --output-format stream-json --input-format stream-json --verbose --model haiku \
         --permission-mode <mode> --max-turns <n>
```

| File | Prompt | `--permission-mode` | `--max-turns` | What it shows |
|---|---|---|---|---|
| `plain.jsonl` | `Reply with exactly the word: pong` | acceptEdits | 2 | text answer, usage, cost, rate-limit event |
| `tool_use.jsonl` | `Read the file hello.txt and tell me the secret word in one short sentence.` | acceptEdits | 3 | `tool_use` / `tool_result` of `Read` |
| `permission_denied.jsonl` | `Create a file named out.txt containing the word hi, using the Write tool.` | default | 3 | `Write` refused: errored `tool_result`, `permission_denials`, `system/permission_denied` |
| `max_turns.jsonl` | `Read the file hello.txt and tell me the secret word.` | acceptEdits | 1 | `result` with `subtype: error_max_turns`, `is_error: true`, `errors[]` |
| `models.jsonl` | (the `initialize` control request `list_models` sends, no model call) | | | `control_response` with the model list |

The model list was recorded with `echo '{"type":"control_request","request_id":"fa-models","request":{"subtype":"initialize"}}' |
claude -p --input-format stream-json --output-format stream-json --verbose`.

Scrubbed before committing (the recording is otherwise byte for byte what the CLI printed, minus the lines named here):

- Dropped: `system/ui_panes` and `system/commands_changed` events (the user's plugins and slash commands), and from the
  `initialize` reply the account (email, organization), `agents`, `commands`, `pid`, output-style folders; from `rate_limit_event`
  the overage fields; from `result` the credential expiry.
- Emptied or replaced in `system/init`: `tools` (kept to `Bash`, `Edit`, `Read`, `Write`), `mcp_servers` (the user's list is
  replaced by one connected `factoria`, as in an engine run), `slash_commands`, `skills`, `plugins`, `agents`,
  `capabilities`, `memory_paths`, `scratchpad_path`, socket and timing fields.
- Rewritten everywhere: the throwaway directory is `/tmp/fa-contract/proj`, the home folder `/home/user`; every UUID
  (session ids, event ids) is a stable fake `00000000-0000-4000-8000-0000000000NN`; `toolu_`, `msg_` and `req_` ids are
  `..._FIXTUREnnnn`.
- Left as printed: token counts, costs, model names, durations, the rate-limit percentages (they only say how much of a plan
  was used) and the text the model answered (some answers are in Spanish because of the recorder's CLI settings).

There is no scrub script in the repository: write a few lines of Python each time, then check the result with
`grep -ril 'Users/\|@\|private/tmp' <folder>` and by reading the `init` and `control_response` lines.

## codex-docs (written from the docs, not a recording)

`codex exec --json` events as the Codex documentation lists them (`thread.started`, `turn.started`, `item.started` /
`item.completed` with `reasoning`, `command_execution`, `mcp_tool_call`, `file_change`, `agent_message`, `turn.completed` with
`usage`, `turn.failed`, `error`), and `legacy_events.jsonl` in the older `{"id", "msg": {...}}` wrapper the parser still reads.
`version.txt` is an example of the `--version` line (`codex-cli <version>`). The values are invented. Replace the folder by a
recording (`codex-<version>/`, same file names) when a Codex is installed, with
`echo '<prompt>' | codex exec --json -m <model> --sandbox <mode> -`.

## generic-docs (written from the format the engine expects)

A generic CLI (`kind: "generic"`) prints plain lines (`plain_text.txt`: every line is text, the lines together the answer) or JSON
lines read best-effort from the first of `text`, `result`, `message`, `content` (`json_lines.jsonl`). No real CLI is behind them.

## Re-recording after a CLI update

1. Update the CLI. Run the commands above in an empty temporary directory (never in a project), with the model of the table.
   At most a handful of runs: each is a paid model call (about one cent with `haiku`).
2. Scrub the output as listed above, then read it: no user name, home path, e-mail, organization, account or plugin names.
3. Put the files in a new folder `<cli>-<new version>/` (keep the old one until the new one passes), point the constant at the top
   of `test_cli_contract.cpp` (`kClaude`) to it and run `scripts/agent-build.sh build/agent-x --target fa_test_ai --tests ai`.
4. A failure names the fixture and the field. If the CLI changed on purpose, change the parser in `tools/ai/src/cli_agent.cpp`
   (or `models.cpp`) so the engine reads the new shape, and keep the old shape's handling if older CLIs are still in use.
