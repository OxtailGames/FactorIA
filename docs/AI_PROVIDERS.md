# Connecting AIs to FactorIA

FactorIA lets you work with an AI inside the engine in two ways. You choose per
role (see [Roles](ai-providers/AI_PROVIDERS_CONFIG.md#roles)) and can mix them.

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

## Pages

- [AI providers: configuration, roles and reviews](ai-providers/AI_PROVIDERS_CONFIG.md): The config file, roles and reviews.
- [AI providers: the built-in agent and its settings](ai-providers/AI_PROVIDERS_AGENT.md): Agent behaviour, conversations, asset providers, permission mode, the AI settings window and asset sources.
- [AI providers: tools, savers, retrospective and extensions](ai-providers/AI_PROVIDERS_EXTENSIONS.md): External MCP tools, token savers, the retrospective and extensions.

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
FactorIA runs: `claude -p --output-format stream-json --input-format stream-json --verbose --model <model> --resume <session> --mcp-config <file> --allowedTools mcp__factoria --permission-mode <mode>` (`<mode>` is `acceptEdits` unless you set another, see [Permission mode](ai-providers/AI_PROVIDERS_AGENT.md#permission-mode)),
with the message on standard input (one `stream-json` line, which can carry pictures),
in the project directory. `--resume <session>` is left out for the first message of a conversation
(see [Conversations](ai-providers/AI_PROVIDERS_AGENT.md#conversations-and-resume)). The MCP config file is written for each run as
`<project>/.factoria/ai/fa-run-mcp-claude-code-<unique>.json` (readable by your user only: mode 0600, on Windows a protected ACL; when the project's folder refuses that, for example on a
network share or a NAS, the file goes to a new owner-only folder `factoria-run_*` in your temporary folder instead, never to one that already existed, and the log says why; a folder of a run that crashed is removed by a later run after a day) and
deleted when the run ends (also when the CLI fails, crashes or is stopped): a `factoria mcp --project <dir>` server, or the editor's endpoint when the
editor started the CLI (see [below](#cli-agents-in-the-editor)). Two runs at the same time each have their own file. A file
that cannot be deleted (on Windows, while another program holds it open) is reported in the log and removed by a later run
once it is a day old. That sweep removes only `fa-run-*` entries of that folder, and the names FactorIA 0.19.0 gave its
run files there (`mcp-<provider>-<n>-<n>.json`, `settings-<provider>-<n>-<n>.json`, `ext-skills-<provider>-<n>-<n>`).

### B) ChatGPT subscription (Codex CLI)
1. `npm i -g @openai/codex`
2. Run `codex` once (or `codex login`) and sign in with ChatGPT.
3. Use provider `codex`. FactorIA runs
   `codex exec --json -m <model> -c mcp_servers.factoria.command="factoria" -c 'mcp_servers.factoria.args=["mcp","--project","<dir>"]' -`,
   with the prompt on standard input (plus `--sandbox <mode>` when you set a [permission mode](ai-providers/AI_PROVIDERS_AGENT.md#permission-mode) other than the default). Codex starts a **fresh session every message**: FactorIA does not resume it,
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
reply as `application/json`, a notification gets 202, a request the client cancelled gets no response (an empty event
stream, or 204 for a client that takes no event streams), GET gets 405). A call that runs longer than 10 s, such as an `ai_run`
that hands a task to the worker, is answered as an event stream that carries `notifications/progress` (what the sub-agent just did, at most one every 3 s,
and a heartbeat every 15 s), so the CLI does not give up on it after 5 minutes of silence. Only the token's path is served, so other programs on
the machine cannot drive the editor. The endpoint serves at most 16 connections at once, plus a spare one so that a
`notifications/cancelled` gets in even when all 16 are busy; while the spare is in use the keep-alive connection idle the
longest is closed, so it frees again (a request that arrives on it just as it closes is not run: its client sees the connection close and can send it
again on a new connection). A client that opens more waits until one ends (it is never answered 503). Replies
say `Keep-Alive: timeout=5`, so a client lets an idle connection go after 5 s; a connection that sends nothing for 30 s
is closed, a request that stops half way gets 408, and a request body over 8 MiB
gets 413 with a JSON-RPC error that says to put a big file into the project another way or send it in smaller parts.
A `notifications/cancelled` the CLI sends stops the call it names (see `docs/MCP.md`, "Cancellation"). **Codex** still starts its own `factoria mcp` (its argv names the command, not a
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
MCP config JSON, deleted when the run ends) `{session}` (the CLI's session id of the conversation, see below) plus `{project_json}` / `{factoria_json}`
(JSON-quoted strings, used by the Codex template). They are expanded in one pass: a prompt that contains `{model}` keeps
that text as it is. For the `claude-code` and `codex` providers a `{prompt}` element that is a positional argument (not the
value of the flag before it; `-p {prompt}` counts as positional) is moved to the end after `--`, so a prompt that starts
with `-` is never read as an option, and the flags FactorIA adds (`--disallowedTools`, `--plugin-dir`...) go before that
`--`; a template that has its own `--` is left as written, and so is every `generic-cli` one. A template without `{prompt}` gets the prompt on standard input: on Windows
prefer that, because CLIs installed with npm are `.cmd` files and `cmd.exe` cannot pass a multi-line argument
(FactorIA refuses arguments with line breaks or `% & | < > ^` for them). If `{model}`, `{mcp_config}` or `{session}` is
empty, that argument (and a bare flag right before it, like `--resume`) is dropped. Output lines are shown as text; JSON lines
with `text`/`result`/`message` are unwrapped.

A template with `--input-format stream-json` gets standard input as one JSON line
`{"type":"user","message":{"role":"user","content":[{"type":"text",...},{"type":"image",...}]}}` (what Claude Code expects).
Every other CLI gets the pictures as files: the prompt ends with `Attached images (read them): <absolute paths>`.

#### Contract tests for the CLIs (engine developers)

The output formats of the CLIs are not ours and change between their versions. `tools/ai/tests/fixtures/cli/` keeps recorded
outputs: Claude Code 2.1.318 (`stream-json` runs: a plain answer, a tool use, a tool refused by the permission mode, the turn limit as
an error result; the model list; `--version`), and, written from the documentation because no Codex is installed on the development
machines, Codex `exec --json` events and a generic CLI's lines. `test_cli_contract.cpp` replays each file through the code that parses a live
run (`CliStreamParser`, `list_models`, `detect_providers`) and checks what the engine reads: final text, error or success, session id, tokens and
cost, tool calls, the refusal. A CLI update that changes its format fails there and names the fixture and the field.
`tools/ai/tests/fixtures/cli/README.md` has the exact command line of every recording, what was scrubbed from it and how to re-record
after a CLI update.

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
  [AI settings window](ai-providers/AI_PROVIDERS_AGENT.md#the-ai-settings-window) is stored as `apiKey` in this same
  user-level file, which the window writes readable only by you (the file is created private before the key goes in:
  mode 0600 on Linux and macOS, a protected ACL with your account as the only entry on Windows), and the box never shows a stored key
  again. The key is not written to a game project, a log, a notification or a command
  result, and is forgotten from the window once saved or closed.
* Keys are sent only to the provider's `baseUrl`, in headers (never in URLs or
  logs). With the `curl` fallback they go through a private temp file, not the
  command line.
* External tool servers (`mcpServers`) are read from your user-level `ai.json` only, and the same rules hold for their keys:
  environment variable first, owner-only file, never in a log, a command result or an argument list
  ([External tools](ai-providers/AI_PROVIDERS_EXTENSIONS.md#external-tools-mcp-servers) says what each provider does).
* A project's own AI settings (`.factoria/ai/settings.json`) can only name providers and tool servers your `ai.json` defines, never
  define one, and a file that arrived with a copied project applies only after you accept it ([Per project](ai-providers/AI_PROVIDERS_CONFIG.md#per-project)).
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
| `No provider is configured for image generation` | Add `"assets": {"image": {"provider": "openai"}}` to `ai.json` (or another kind/provider, see [Asset providers](ai-providers/AI_PROVIDERS_AGENT.md#asset-providers)), or pass `provider` to the command. `fake` works offline. |
| `'assets/a.wav' ends in '.wav', but the provider 'elevenlabs' makes sound as .mp3 files` | Use the extension the error names; it is checked before anything is paid for. |
| `Meshy task ... was still IN_PROGRESS after N seconds` | Raise `timeoutSeconds` of the `meshy` provider; the task keeps running on Meshy's side. |
| `... exited without writing asset.png` | The `asset-command` program must write to the path `{output}` stands for: put `{output}` in its `argv`. |
| `External tool server 'scenario' skipped: Tool server 'scenario': ... uses {key}, which has no value` | Set the environment variable `apiKeyEnv` names (and restart the editor or open a new shell), or put the key in `apiKey`. `factoria ai doctor` shows it as `[--]` with the missing variable. |
| `... refused the credentials (HTTP 401)` from a tool server | The key is wrong, or the header is not what the service wants (for Scenario: `Basic` plus `base64(KEY:SECRET)`). If the answer carries a `WWW-Authenticate` header the server may want OAuth: use it through Claude Code, or a key if it offers one. |
| `... HTTP 404 ...` or `not an MCP reply` from a tool server | The address is not the server's Streamable HTTP endpoint (often ending in `/mcp`; an address ending in `/sse` is the old transport, not supported). |
| A tool server works in Claude Code but not in the built-in agent or Codex | It uses OAuth; the built-in agent and Codex (through FactorIA) need a key or header. See [External tools](ai-providers/AI_PROVIDERS_EXTENSIONS.md#external-tools-mcp-servers). |
