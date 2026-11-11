# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

### Changes

- **Models and rigs for mobile (M101.8):** `model.game_ready`'s collider takes `part` (fit it to one named part, e.g. a pine's
  trunk instead of its canopy, also with `merge`), `radius` and `height` (override the fitted values). `rig.bake` takes
  `mergeParts`: the skinned parts that share a material become one submesh (same vertices, weights and bind pose, so the
  same pose), kept in the recipe; Kindlewatch's characters go from 75 to 38 draw calls and Gem Roller's scout from 30 to 18.

## 0.22.0

FactorIA 0.22.0 (M100) makes errors and tests something a game AI can trust. A test fails when the game fails: a
script that threw during it or an ERROR it logged turns it red, with the script, line and callback.
Script errors name the members that exist and the closest one, `factoria validate` checks scripts against the engine's
API and not only their syntax, and every message is printed once. New projects get an `AGENTS.md` and `CLAUDE.md` the
AI reads first, `factoria docs read` pages through a document by heading or line, and no MCP tool description passes
1536 bytes. Performance gates warn inside a band instead of failing on noise, the CI failures seen since October are fixed, and
`scripts/agent-cost.sh` measures what a game costs an AI CLI with no context.

### Changes

- **M100 polish, second wave:** `test.skip("name")` with no function is a pending test; a test run that logs over 20000
  errors says how many it dropped; `validate` finds `fa.call` inside a template's `${ }`, and reports what the session's
  teardown logs; `factoria docs read X --json` prints the `docs.read` result without a range flag; the feedback review
  scores `details` words of six letters or more (three at most); `skin3d.auto` and `project.export` say in their visible
  description that a bad part writes nothing and that `release` signs on Android.
- **For game authors and AIs (M100 polish):** `factoria test` and `validate` are steadier. Each test forgets the engine's
  once-per-run errors (a missing sound) so the result does not depend on test order or `--filter`; the errors of a run are
  collected in their own list, so a chatty test cannot push an earlier error out and pass green; errors logged by the
  per-test reset count; a run leaves the script system's known errors as it found them; `test.skip` checks its options.
  `validate` ignores `fa.call("project.x")` in comments and strings, sees `let a = 1, time = 2`, skips plural receivers
  (`levels.get("Intro")`), softens the mixed-colour text, and the member list of a read check puts the entity's own fields
  first. docs/SCRIPTING.md and docs/ANIMATION.md say what the code does.
- **For engine developers (M100 polish):** CLI, MCP and command details. `factoria docs read` words its errors with the
  CLI flags (`--contents`, `--heading`, `--start-line`), refuses `--start-line 0` or `--max-bytes 5` with the allowed
  range instead of clamping, and prints the `docs.read` result with `--json`. `factoria test` prints the fixed "an
  exception was thrown" sentence once, next to the first trace that has it, without cutting what follows it in a message
  (a watchdog explanation), and marks repeated errors only with "(same error as ...)". `factoria validate` keeps its
  stderr filter until the session is gone, shows the lines it held back when something other than a report ends it, and
  a log line is "already said" only by a report message of 24 characters or more (any path separator). The
  description-budget test counts bytes as sent and restores the project root with a guard; `project.export`,
  `agent.cost`, `feedback.report`, `nav.find_tile_path` and `skin3d.auto` were over the escaped budget and now cut at a
  sentence. `CommandRegistry::add` removes `FA_COMMAND_DETAILS` from a description that has `details` too and warns;
  the feedback review's related-command list scores `details` as well. The cancel-request wait in `mcp_http_test` is a
  safety net, not a known fix.

- **For engine developers (M100 polish):** CI and the cost measure. A `_perf` test that only warns (inside the band, or over
  the time budget but under the fail slack) is now listed in the job summary and as an annotation by
  `scripts/ci-perf-warnings.sh`; the fail slacks are unchanged and docs/PERFORMANCE.md says what the band does not fail (a
  sustained 3x, a leak of about 30 MB). The ci.yml concurrency group includes the event and the `perfBaselines` tick, the
  baselines build is parallel, and PERFORMANCE.md says the dispatch job runs only from a workflow file on the default branch.
  `scripts/agent-cost.sh`: the CLI gets a throw-away HOME with a token or `--isolated-home` (else a warning and a note in the
  result), `claude --version` is recorded, `factoria` commands with absolute, `~` or `..` paths are denied and audited, Ctrl-C and
  the wall-clock cap end the CLI's whole process group, the final `play.auto` has its own cap (`--final-seconds`), and
  `scripts/agent-cost-selftest.sh` (ctest `agent_cost_script`, plus `agent_cost_policy`) proves it with a fake CLI. `agent.cost`:
  tokens come from the CLI's result line (`stepTokens` keeps the step sum), menu and win screens are not levels, `notCaught`
  looks only at game output, and a failure without an error code counts under `none`.
- **For engine developers (M100 polish):** the review points of M100.6, M100.7, M100.9 and M100.10 that were not blocking.
  The ROADMAP test finds an entry's cite with `find` and boundary checks instead of a regex per entry, and reads every
  `ENGINE_FEEDBACK.json` below `examples/`; ROADMAP counts 30 open entries in M101 (KW/FB-0019 and KW/FB-0020 are
  closed, CC/FB-0057 named in M101.10) and notes the perf counters and the E2 flake as open; `feedback/done/` files say
  "Left open when it closed (archived)"; a test fails when CHANGELOG.md holds two minor versions (patches of the newest stay).
  The README "Version x.y" and the Spanish note are a step of the release (CLAUDE.md, docs/ARCHITECTURE.md), and the
  Spanish test accepts its own "Versión x.y" or skips. The examples' `AGENTS.md` come from the current template and their
  `CLAUDE.md` is `@AGENTS.md`. The feedback sharing warnings say to retry when the file is closed.
- **For engine developers (M100.10):** bookkeeping of the review. docs/ANIMATION.md has a dawn recipe, a `tween` of
  `world.settings` (sky, ambient light, fog), kept true by a script test (KW/FB-0019 closed). `feedback/ROADMAP.md`
  keeps only open work and decisions; finished milestones are one file each in `feedback/done/` (index in
  `feedback/done/README.md`, replacing ROADMAP_DONE.md). CHANGELOG.md keeps `## Unreleased` and the newest minor version
  with its patches (the release workflow reads it there); older minor versions are in `changelog/0.<n>.md`.
- **For engine developers (M100.6):** the feedback loop cannot fall behind silently. The doctest case "feedback/ROADMAP.md counts and names what the examples have open" (`tools/common/tests/feedback_roadmap_test.cpp`, ctest `tooling`) runs `feedback collect` over `examples/*` and fails when `feedback/ROADMAP.md`'s count line differs or an open entry is named nowhere below "# Next engine milestones" (it says which ids, the line to add and the regeneration command). A new example needs a row in the test's prefix table. CLAUDE.md's finishing steps mention it; the ranked list in ROADMAP.md is regenerated (it still listed a closed perf entry and lacked CC/FB-0057, the missing HDR glow, which is now triaged under M101).
- **For game authors and AIs (M100.5):** output once. `factoria validate` captures the engine's log while it opens the
  project and folds load errors and warnings into its report, each once, instead of printing them on stderr as well
  (with `--json`, stdout is only the JSON and stderr stays empty). `factoria test` prints the same failure trace once
  and marks the other tests "(same error as ...)"; the fixed "an exception was thrown inside the test"
  sentence is printed once per run, after the first trace that has it; `--json` still has every case's own message.
- **For game authors and AIs (M100.8):** no MCP tool description passes 1.5 KB any more, counted as the client receives it
  (JSON escaped: a quote or a newline is two bytes; 96 commands were over it;
  `tilemap.generate` was 7.4 KB, `assets.animate_svg` 7.4 KB, `feedback.report` 6.2 KB). `tools/list` sends the essentials,
  and the description ends with "More (the rest of this description): docs_commands {"name": ...}", the section of the docs
  reference where the rest is (the text is the same, only moved). `factoria commands <name>` and `commands.describe` carry it
  as `details`. A test walks the whole registry and fails, naming the command, when a description passes the budget.
- **For engine developers (M100.8):** `CommandInfo::details` holds what does not fit in `description`; a description may
  end its short part with `FA_COMMAND_DETAILS` (core/command.h) for commands a helper builds. See docs/ARCHITECTURE.md,
  "Commands (the tool system)".

- **For game authors and AIs (M100.9a):** performance gates no longer need baselines refreshed for noise. `perf.measure` and `run --json` report `cpuMsMedian` (next to `cpuMsAvg`, `cpuMsP95` and `cpuMsMax`) and `slowestFrames`, the five slowest frames as `[{frame, ms}]`, and `perf.check` names them in its message. `perf.check` enforces the counters (`drawCalls`, `entities`, `triangles`, `lights`) exactly, on every machine, and the median and p95 frame time and peak memory only past a wide band: inside it the status is `warn` and nothing fails, past it (`max(baseline * 6, baseline + 10 ms)` for times, `max(baseline * 1.5, baseline + 32 MB)` for memory) a time fails in CI and memory always. The average and the maximum are reported, not gated, because one slow frame decides them. Tolerance keys: `cpuMedian` (`cpuAvg` is still read as its old name), `cpuFail`, `cpuFailSlackMs`, `memoryFail`, `memoryFailSlackMB`; the defaults of `drawCalls`, `entities`, `triangles`, `lights` and `countSlack` are now 0. `rows` of the result have `warnLimit` and `warned`, and `limit` is where the metric fails. A baseline without `cpuMsMedian` (every file written before) uses its average. A baseline entry with `"provisional": true` enforces only the counters. docs/PERFORMANCE.md, "The band".
- **For engine developers (M100.9b):** the CI failures seen on `main` and in PR 208 since 2026-10-31, read from their logs. (1) The `ios` job downloads the app of `ios-build` in a loop and used to spin until its 20 minutes ran out when that job ended without an app (2026-11-04: GitHub found no macOS runner for `ios-build` and it was cancelled after 15 minutes); the loop now reads the build job's conclusion on every turn and stops with an error that names it. That outage itself is GitHub's and no code can fix it. (2) `editor_autotest_5` (PR 208, 2026-11-10) did not time out: section T2 checked "the window offers Start again" in a fixed number of frames right after a blocking HTTP request that takes seconds on a loaded VM; it now waits for that state. (3) The Windows autotest failure of section E2 (2026-11-01) ran a test version older than the feedback file lock of 2026-11-06 and did not come back; `write_entry_shared` now logs a warning when it cannot read or save the file, where it skipped silently. (4) The cancel case of `mcp_http_test` for a client without event streams (Windows, 2026-11-10, no 204 and 127 s) left no trace of what the client saw and cancelled as soon as the command had started; it now waits (60 s safety net) until the session has the request in flight, and when the 204 check fails it prints the cancel's status, the wait and the reply's first bytes. No bug in the server was found for it; only a CI run confirms whether it comes back. In the editor autotest a `wait_until` that expires used to go on silently: a wait that sets `atWaitWhat_` fails with "waited 60 s for <what>" and the others log a warning with the script frame.
- **For engine developers (M100.9a):** `PerfSample` has `cpuMsMedian`, `slowestFrames` and `provisional`, `PerfTolerance` the two-limit fields and `PerfCheckRow` `warnLimit` and `warned` (`fa/tooling/perf.h`); `Engine::run` fills `perf.cpuMsMedian` and `perf.slowestFrames` of its report. `scripts/perf-baselines.sh` measures every file of `tools/cli/tests/perf` on the machine it runs on, and running the CI workflow by hand with `perfBaselines` ticked (`workflow_dispatch`) does it on a Linux, a Windows and a macOS runner and uploads the entries as the artifacts `perf-baselines-<os>`. The `kindlewatch` Linux and macOS entries are `provisional` until that run measures them.
- **For game authors and AIs (M100.2):** a test fails when the game fails. A test during which a game script threw (a callback, an event handler, a promise, a module's top level) or the engine logged an `ERROR` (a sound that is not there, a refused command) now fails with the first such error, its file and line as its message, whatever its assertions said; before, only the test's own exceptions and assertions counted, and a script error showed up in the log while every test passed. `console.error` is not an error. A test about an error says so: `game.expectErrors(/pattern/)` inside it or `test(name, fn, { expectErrors: [/pattern/] })`; an expected error that is never logged fails too. `factoria test` counts these failures in its summary (`loggedError` on the case in `--json`) and its exit code follows. A script error is logged again for each test that causes it (it used to be logged once per file). The tests of every example and template pass under the rule.
- **For game authors and AIs (M100.3):** script errors name what exists. In `test`, `run`, `mcp` and the editor, reading a member that an `Entity`, a namespace of `"factoria"` (`input`, `world`, `audio`, `ui`, ...) or an `expect(...)` matcher does not have throws with the closest name and the member list (`'input' has no 'axs'. Did you mean 'axis'?`) instead of giving `undefined` and failing a line later; symbols, `then`, `toJSON` and the members of every object pass, writes are untouched, an entity field the game wrote (`entity.hp = 3`) reads back, and `session` (the game's own bag) stays open. The check sits behind the object, so a member that exists costs nothing (800 000 entity reads: 256 ms against 247 ms with no check); the exported player has none. "This player may be older than the game's engine" is said only by an exported player, where it can be true; an error that is "not a function" now gets the method-name hint before that advice, and a missing import or method names the closest export or method. A component name with the wrong case (`entity.get("transform")`) works and logs one warning per name with the exact spelling; an unknown name (`entity.get("NoSuch")`) lists the closest names and the number of components. `tween` with an `ease` name that does not exist rejects names like `constructor` too.
- **For engine developers (M100.3):** `ScriptSystem::set_exported_player(bool)` and `EngineConfig::exportedPlayer` (set by every exported player in `player/main.cpp`) tell the script layer whether it runs in a shipped game; the prelude's `N.exportedPlayer` switches the read checks off.
- **For game authors and AIs (M100.7):** The README states the engine version it is at, and a test compares it (and the Spanish README's note) with
  `CMakeLists.txt`.
- **For game authors and AIs (M100.7):** New projects get `CLAUDE.md` as the one line `@AGENTS.md` instead of a second copy of the guide. Projects made
  earlier keep their `CLAUDE.md` untouched (there is no `project.update` yet to rewrite it).
- **For game authors and AIs (M100.7):** `factoria docs read <name>` takes `--contents` (the headings with line numbers), `--heading`, `--start-line`, `--max-lines` and `--max-bytes` like the `docs.read`
  command and prints the paging hint (next call and contents) on stderr when it cuts.
- **For game authors and AIs (M100.7):** The MCP server's instructions and the generated `AGENTS.md` tell the AI to read `ai-guide` by section, never whole.
- **For game authors and AIs (M100.4):** `factoria validate` checks scripts against the engine, not only their syntax. Each issue is `file:line:column` with a "did you mean": a name imported from `"factoria"` or `"factoria:test"` that does not exist (error), a member that the engine's own objects do not have (`physics.raycats`, `ns.member` after `import * as ns from "factoria"`; error), a literal component name in `entity.get/add/has/remove` that is not a component or differs only in case (warning), and a `fa.call("project.<name>")` in a game script when a module under `tools/` defines the command, which an export leaves out (warning with the line; `factoria export` gives the line too). Every script is also loaded the way the game loads it (`ScriptSystem::check_load`), so a module whose top level throws is an error with its own file and line. A colour array that mixes a channel over 1 with a channel at most 1 (`[255, 255, 255, 1]`, read as 0..255, an alpha of 1/255) is a warning with its JSON pointer and both readings, and the colour shape message says that 0..255 is read when any channel is over 1. docs/SCRIPTING.md, "What `factoria validate` checks in a script".
- `scripts/agent-cost.sh` measures what a game costs an AI with no context: it starts an AI CLI (Claude Code) in an empty folder with
  only the installed `factoria` on the PATH and a fixed brief ("a platformer with three levels"), records the transcript and reports
  it with the new command `agent.cost`: steps, tokens and minutes to the first playable build, the engine errors the AI met and
  the script errors no test caught. Results go to `feedback/agent-cost/<version>-<cli>.json`; the numbers and how to run it
  (it spends quota) are in docs/AI_COSTS.md. The measured AI runs confined (a copy of the engine, a throw-away HOME, a short
  allow-list of `factoria` subcommands, caps on turns, dollars and wall-clock time); "reached the last level" means a `play.auto`
  that ended "won" with at least three distinct phases.
