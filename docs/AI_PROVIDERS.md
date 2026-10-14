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
> its MCP server (`factoria mcp --project <dir>`); it never reads, stores or
> forwards subscription credentials or tokens.

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
`<project>/.factoria/ai/mcp-claude-code.json` (no secrets in it).

### B) ChatGPT subscription (Codex CLI)
1. `npm i -g @openai/codex`
2. Run `codex` once (or `codex login`) and sign in with ChatGPT.
3. Use provider `codex`. FactorIA runs
   `codex exec --json -m <model> -c mcp_servers.factoria.command="factoria" -c 'mcp_servers.factoria.args=["mcp","--project","<dir>"]' -`,
   with the prompt on standard input. Codex starts a **fresh session every message**: FactorIA does not resume it,
   so a follow-up in the editor chat does not remember the earlier messages (the transcript on screen does).

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
(`inputPerMTok`, `outputPerMTok`, ...), `maxRetries`, `timeoutSeconds`.

Built-in providers exist without being listed: `anthropic`, `openai`,
`openrouter`, `gemini`, `groq`, `deepseek`, `ollama`, `lmstudio`, `claude-code`,
`codex`. Listing one overrides only the fields you give.

## Roles

| Role | Job | Default (Anthropic) |
|---|---|---|
| `orchestrator` | plans, reviews, delegates with the `agent_delegate` tool | `claude-opus-5-5`, effort `xhigh` |
| `worker` | implements features and fixes | `claude-sonnet-5-5`, effort `medium` |
| `fast` | small mechanical edits | `claude-haiku-5-5`, effort `max` |

Each role is `{provider, model, effort?, maxTokens?}`. `effort` is one of
`low|medium|high|xhigh|max` and is always sent explicitly to Anthropic. For
`openai-compatible` providers it is ignored unless `"sendReasoningEffort": true`
(then mapped to `low|medium|high`). When a role uses a CLI provider, that CLI
runs its own loop and `agent_delegate` is not offered.

`factoria ai run "task"` / the `ai.run` command / the editor AI panel use the
`orchestrator` role unless told otherwise (`role`, `provider`, `model` options).

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
  Plan limits are shared by all chats, so the last values are kept per provider in `~/.factoria/ai_limits.json`
  and shown before the next message (a dim "Plan usage updates after the first message." while there are none).
* **Context**: tokens in the model's context window now (the last request, not the sum of the run), for example `47k / 1M`.
* **Tokens** (in / out / cache) and **Cost** of the chat. Cost is an estimate (`est.`): the CLI's own number for subscription
  plans, which are not billed per token.

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
when they provide it. Set `limits.maxCostUsd` to cap a run.

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
| MCP server `factoria` failed | `factoria` puts its own directory first on PATH for the agents it starts, so this only happens when `factoriaCommand` names another binary: fix it or set it to an absolute path. |
| `No Anthropic credentials found` | Set `ANTHROPIC_API_KEY` or log in with `ant auth login`. |
| `No API key for provider 'openrouter'` | `export OPENROUTER_API_KEY=...` (see table above). |
| `No model configured for role ...` | Set `roles.<role>.model` for non-Anthropic providers. |
| HTTP 401/403 | The key is wrong or lacks access. HTTP 404: wrong model name or `baseUrl`. |
| HTTP 429 / 529 | Rate limit or overload; FactorIA retries automatically, then gives up with the message. Check credits. |
| Tool-call errors with a local model | The model needs tool-calling support; try a larger/instruct model. |
| Corporate proxy / TLS | Set `HTTPS_PROXY`; for a custom CA set `SSL_CERT_FILE` / `CURL_CA_BUNDLE`. |
| Invalid `ai.json` | The error lists the JSON pointer (e.g. `/roles/worker/effort`) and allowed values. |
