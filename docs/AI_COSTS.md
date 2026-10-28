# What making a game with AI costs

Making a game with an AI costs tokens, and tokens cost money or plan quota. This guide says what a whole game cost in a
real run (measured, not guessed), what makes a run cheap or dear, how to put a ceiling on it and where to see what was
spent. Prices are the ones FactorIA carries (**as of 2026-10-20**, the table in [AI_PROVIDERS.md](AI_PROVIDERS.md#costs));
they change, so your provider's invoice is what counts.

## 1. What costs money

**LLM tokens.** Every step the AI takes (read a file, edit a scene, run a test) is one request to the model. A request is
billed in four kinds of tokens:

| Kind | What it is | Sonnet 5.5 price per 1M |
|---|---|---|
| input | new text the model reads this step | $2 |
| output | what the model writes (text, tool calls, thinking) | $10 |
| cache write | the context stored so the next step can reuse it | $2.50 (5-minute cache); $4 (1-hour cache) |
| cache read | the stored context read again | $0.20 |

(Opus 5.5 is $4 input / $20 output / $0.20 cache read; Haiku 5.5 is $0.10 / $0.50 / $0.01. A cache write costs 1.25 times
the input price for a 5-minute cache and twice the input price for a 1-hour cache; Claude Code writes the 1-hour kind, and
the live estimate prices each kind as the message reports it (`cache_creation.ephemeral_1h_input_tokens`). The engine's
table is for prompts up to 100K tokens; see section 2 for why that matters.)

You pay for tokens in one of two ways:

- **Per token (API key).** The provider bills each request. FactorIA's built-in agent (`anthropic`, `openai`, ...) counts
  the tokens and estimates the cost as it goes, so it can stop at a limit you set (section 4).
- **A subscription plan (Claude Code, Codex).** You pay the plan, not the tokens. The plan allows a number of tokens per
  5-hour window and per week; when a window is full you wait for it to reset. The cost shown is an estimate at API prices,
  useful to compare runs, not a bill. Plan limits are shared by every chat and every program that uses the plan.

**Asset generation.** Pictures, sounds, music, voices and 3D models made by an asset provider are billed per call by that
provider. FactorIA does not know those prices and `limits.maxCostUsd` does not cover them
([AI_PROVIDERS.md](AI_PROVIDERS.md#asset-providers)). The `fake` provider costs nothing: build the whole flow with it, look at
the first real result, and only then generate a batch.

## 2. What a game cost

These numbers come from building **Lantern Keep** (`examples/lantern-keep` in the FactorIA repository), a complete 2D
platformer with menus, saves, achievements, accessibility options, store setup and two extra languages. Six Sonnet 5.5
workers built it, one package each, on 2026-10-19. What the numbers are:

- A **Claude Code subscription run**: each worker followed the game's generated `AGENTS.md` and read `factoria docs`.
  Nothing was billed per token; the dollar figures price the same tokens at the API rates above, for comparison.
- The six workers only. The orchestrator that planned and reviewed them is not included.
- The workers also built and tested the engine checkout (the game lived inside it), and that part is in these numbers. A
  game maker working in an installed project spends a bit less than this.
- A "step" is one request to the model (one assistant message in the transcript).

| Package | Steps | Minutes | Average context per step | Cache read | Cache write | Output (est.) | Cost at API rates |
|---|---|---|---|---|---|---|---|
| P1 core game, English and Spanish, menu kit | 105 | 34 | 244k | 25.2M | 398k | 55k | $6.58 |
| P2 save slots, level select | 37 | 12 | 96k | 3.4M | 129k | 25k | $1.25 |
| P3 achievements, stats, leaderboards, shop | 65 | 22 | 133k | 8.4M | 199k | 37k | $2.55 |
| P4 accessibility and assist options | 79 | 22 | 131k | 10.1M | 191k | 32k | $2.82 |
| P5 shipping setup | 83 | 16 | 135k | 11.0M | 205k | 27k | $2.98 |
| P6 German and Arabic, final pass | 97 | 23 | 165k | 15.8M | 267k | 46k | $4.28 |
| **Total** | **466** | | | **73.9M** | **1.39M** | **222k** | **$20.47** |

P2 to P5 ran at the same time, so the wall-clock time of the whole game was about 90 minutes.

What the table says:

- **A whole finished game cost about $20 at API rates, in 466 steps.** About 72% of that is cache reads ($14.77), 17%
  cache writes ($3.47) and 11% output (about $2.22); fresh input is nothing. The AI mostly *reads*.
- **Output is an estimate, and the totals are a floor.** Claude Code's transcripts do not record the final output
  count of a step (they keep the count from the start of the stream, a few tokens) and do not store thinking at all,
  although thinking is billed as output. So output is estimated from what the model wrote (tool calls and text) at 3.75
  characters per token (3.5 to 4 moves the total by about $0.1) and thinking is not counted. The real figure is higher.
- **A step costs about $0.03 to $0.06 (est.)**, and a package $1 to $6 (30 to 105 steps). The first package, which makes
  the game from nothing, costs the most because its context grows to a quarter of a million tokens.
- **The prompt limit of the price table is exceeded.** The engine's prices are for prompts up to 100K tokens; P1 averaged 244k
  per step and P6 165k. If your provider charges more above 100K, the real API price of these runs is higher than the
  figures here. Together with the uncounted thinking, treat them as a floor for API billing and as a size comparison for plans.
- Per kind of task (from these six packages, and from simple arithmetic on them, not a promise): a **new feature that
  touches one system** (saves, a shop, accessibility options) is 40 to 80 steps and $1 to $3; **a whole new game core**
  is about 100 steps and $6; a **small fix** that needs a look, one edit and one test run is a handful of steps, a few cents
  to a few tens of cents (steps x context x $0.20 per million, plus one cache write). A level or a content-only change
  falls in between and depends on how much the AI must read first.

The jam-sized examples (`sky-hopper`, `neon-swarm`, `gem-roller`, `block-push`) were built by sessions whose transcripts
could not be told apart from the rest with confidence, so there is no second data point yet.

**How this was measured, to repeat it.** Claude Code keeps every session as a `.jsonl` file under
`~/.claude/projects/<project folder>/`, and subagent runs under `<session>/subagents/agent-*.jsonl`. Each assistant line
has `message.usage` (`input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`) and
`message.model`. Find the file whose first user message names the package, count each distinct `message.id` once (a message
can be written several times while it streams), sum the three input fields (`input_tokens` and the two cache fields), and price them with `builtin_pricing` in
`tools/ai/src/types.cpp` (`input x in + output x out + cache read x read + cache write x write`, per million tokens). `output_tokens` there is not
the final count, so estimate output instead: add the characters of every `text` block and of every `tool_use` `input`
(as JSON) and `thinking` block in those lines (each line counted once, by `uuid`), and divide by 3.75. Thinking blocks
are empty in these files, so thinking is missing from the result.

## 3. What drives the cost

**Context size times number of steps.** Each step sends the whole conversation again. The cache makes that 10 times cheaper
than new input ($0.20 against $2 per million for Sonnet) but it is not free, and it is where almost all the money goes. A task
that takes twice the steps in a context twice as large costs four times as much.

- **Long chats.** A chat that has been going for hours carries everything said so far in every step. Open a new chat tab for
  a new task (AI panel, [EDITOR.md](EDITOR.md)); the project files are the memory, not the chat. The built-in agent does not
  trim its history ([AI_PROVIDERS.md](AI_PROVIDERS.md#conversations-and-resume)).
- **Compaction.** `maxContextTokens` on a role (at least 100000, **Roles...** in the editor, **Context** column) caps how
  much conversation a session keeps: past it, the earlier turns become a summary and each step reads less. It works with
  Claude Code and the Anthropic API ([AI_PROVIDERS.md](AI_PROVIDERS.md#roles)).
- **Screenshots.** A picture is tokens too. FactorIA scales big pictures to 1568 px on the long side, which is what the
  model looks at anyway ([EDITOR.md](EDITOR.md)). Take a screenshot where you need to see something, not after every edit.
- **Roles.** Your messages go to the orchestrator (Opus, the dearest model). It plans and reviews, and hands the work to
  the worker (Sonnet, half the price of Opus) and small edits to the fast role (Haiku, a fortieth of Opus). Let it delegate: do not pick `--role orchestrator` for work a worker can do. `--no-delegate` turns that off, so only
  use it when you want everything done by one model.
- **Effort.** `effort` (`low` to `max`, per role) is how much the model thinks, and thinking is output at $10 per million.
  The defaults are `medium` for the worker and `xhigh` for the orchestrator.
- **Clear tasks.** "Add a coin counter on screen" costs less than "make it better": a vague task makes the AI read and try
  more before it acts. Point it at the files and the doc to use (`factoria docs read finishing`).

## 4. How to cap it

Put limits in your user-level `ai.json` (`~/.factoria/ai.json`, on Windows `%APPDATA%\factoria\ai.json`):

```json
{ "limits": { "maxTurns": 40, "maxCostUsd": 5, "maxTotalTokens": 20000000 } }
```

| Limit | Meaning | Default |
|---|---|---|
| `maxTurns` | model requests per role in one run | 40 |
| `maxCostUsd` | estimated dollars for the whole run, delegated work included (0 = unlimited) | 0 |
| `maxTotalTokens` | tokens of all kinds for the whole run, cache reads included (0 = unlimited) | 0 |
| `maxConcurrentRuns` | how many chats of the editor's AI panel can run at the same time (1 to 8); each run has its own `maxTurns`, `maxCostUsd` and `maxTotalTokens`, so the spending adds up across the runs, and the plan limits (Session, Week) are shared | 3 |
| `stuckAfterSeconds` | the editor's AI panel warns after this many seconds without any sign of activity from the agent (not a cost limit: it never stops anything, see [EDITOR.md](EDITOR.md)); 0 = never warn | 180 |

On the command line, `factoria ai run "<task>" --max-turns 20 --max-cost 2` overrides the first two for that run. The
command `ai.run` takes `maxTurns` and `maxCostUsd` too. There is no flag for `maxTotalTokens`: it is only in `ai.json`.
Count it with the cache: P1 above used 25.6M tokens.

**When a limit is reached** the agent stops before its next request (a request already sent finishes). The run ends with
an error that says which limit and how to raise it (`Stopped after 40 turns`, or `Cost budget reached ($5.012000 >= $5.000000)`),
and its stop reason is `max_turns` or `budget`. Nothing is undone: the edits already made stay in the project. Split the
task or raise the limit and ask again; in the editor, a follow-up message continues the same conversation.

These limits belong to FactorIA's built-in agent (API providers). **Claude Code and Codex run their own loop**, so FactorIA
does not enforce `maxTurns`, `maxCostUsd` or `maxTotalTokens` on them. With a subscription the ceiling is the plan: the
5-hour and weekly windows. The editor shows how full they are, and you can always press Stop.

Asset providers are not covered by any limit. Cap those at the provider (a spending limit on its account).

## 5. How to see what you spent

- **In the editor**, the usage lines above the AI transcript: **Session (5h)** and **Week** (plan windows, with the time
  they reset), **Context** (tokens in the window now), **Tokens** (in / out / cache) and **Cost** of the chat, marked `est.`
  ([EDITOR.md](EDITOR.md), [AI_PROVIDERS.md](AI_PROVIDERS.md#usage-display)). For a subscription, the cost is the CLI's own
  figure, and plan percentages are what the provider reports.
- **While it runs**, Tokens and Cost in the editor grow with every model call, including a delegated worker's, instead of
  jumping at the end. Until the CLI's own total arrives the cost is the engine's estimate (price table or the provider's
  `pricing`); the CLI's figure replaces it when the agent finishes. The plan windows (Session, Week) are reported by Claude
  Code once per message, so they update when the next message starts. The limits of section 4 are checked against these live
  numbers: a Claude Code or Codex run is stopped when it crosses them (`"stopReason": "budget"`), not after the fact.
- **On the command line**, `factoria ai run` ends with a line such as `--- done: end_turn, 41 turns, 1830000 tokens, ~$0.55`. With `--json` each event carries `costUsd`.
- **In the transcripts**, one file per run in `<project>/.factoria/ai/sessions/<time>-<role>.jsonl` (a delegated worker has
  its own, `<time>-worker-1.jsonl`). The built-in agent writes one line per model request with `"kind": "assistant"`, a
  `usage` object (`inputTokens`, `outputTokens`, `cacheCreationTokens`, `cacheReadTokens`) and `costUsd`. Claude Code and Codex
  transcripts only hold the text and tool calls (`"kind": "usage"` lines carry no numbers); for those, use the editor's
  display.

An AI (or a script) adds up a project's built-in agent runs like this:

```python
import glob, json
tokens = cost = 0
for path in glob.glob(".factoria/ai/sessions/*.jsonl"):
    for line in open(path, encoding="utf8"):
        row = json.loads(line)
        if row.get("kind") == "assistant":
            tokens += sum(row["usage"].values())
            cost += row["costUsd"]
print(tokens, "tokens, about", round(cost, 2), "dollars")
```

Run it after a session, or ask the AI to run it and report. For API providers outside the engine's price table, add
`"pricing"` to the provider in `ai.json` or `costUsd` stays 0 and only token limits apply
([AI_PROVIDERS.md](AI_PROVIDERS.md#costs)).

## Short version

- A finished game of Lantern Keep's size was about 470 steps and $20 at API rates (a floor), with Sonnet workers; most of it is
  re-reading context.
- Keep chats short, one task per tab; let the orchestrator delegate; screenshots only where needed.
- Set `limits.maxCostUsd` and `maxTurns` for API runs, and watch Session and Week for subscription runs.
- Generate assets with `fake` first; each real asset call is billed by its provider.
