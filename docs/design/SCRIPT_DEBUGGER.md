# Design: the script debugger (DAP)

Status: **accepted** (2026-10-22). Closes the M20 item "A script debugger: breakpoints and stepping in QuickJS behind a
Debug Adapter Protocol server, for VS Code" and its acceptance criterion "An integration test drives the DAP server over
stdio and stops at a breakpoint in a template behaviour" (feedback/ROADMAP.md, M20). Written against `main` at
`379ade0`. The contract between the packages is `engine/script/include/fa/script/debugger.h`.

This is a design document for engine developers. Game makers and AIs read `docs/DEBUGGING.md` (package E).

## The problem in one paragraph

A game's logic is JavaScript run by QuickJS-ng (v0.17.0, `external/quickjs`). When a behaviour misbehaves, today's
tools are `console.log`, `script.eval`, tests and the profiler. A human wants what every other engine gives them: F5 in
VS Code, a breakpoint in `scripts/player.js`, the game stops there, the stack, `this`, the locals, step over, step in,
watch an expression, a conditional breakpoint, a logpoint. An AI wants the same facts without a UI: "run 300 frames and
tell me `this.body.velocity` every time line 17 runs". QuickJS-ng has no debugger API (no breakpoints, no stepping, no
frame or scope inspection), its interrupt handler only fires at calls and backward jumps, and `external/` must not be
edited.

## Decisions (summary)

| # | Question | Decision | Main alternative and why not |
|---|---|---|---|
| D1 | How execution stops at a line | **Source instrumentation**: a debugged run compiles each project module from a copy of its source with a hook call before every statement and a frame record around every function body. Only text is inserted, never a newline: line numbers do not change, columns are mapped back. | Patching QuickJS (an `OP_debugger` per line, a frame walker): `external/` must not be edited, and keeping a patched fork of a fast-moving interpreter costs more than the whole debugger. The interrupt handler: fires only at calls and backward jumps, knows no line, no scope. |
| D2 | How locals are read | One **closure per frame** created by the instrumented code, `(__fa_x) => eval(__fa_x)`: a direct eval in the frame's scope, so reading, assigning and calling all work, with the TDZ and shadowing JS itself applies. The instrumenter writes the table of names each scope declares, so the Variables view knows what to ask for. | Reading QuickJS's internal variable slots: not public API, changes between versions. |
| D3 | What parses the source | **acorn** 8.15.0 (MIT, one JS file, about 230 KB), vendored in `external/acorn/` and run in its own QuickJS runtime by `fa_tooling`. Players never contain it. | A hand-written statement scanner in C++: ASI, regex literals, template literals and destructuring make it a second JS parser, and it would be wrong in the corners. |
| D4 | Where the debugger runs | The **script runtime** (`fa_script`) runs the hooks, keeps the frame stack and pauses by blocking the script thread inside `DebugClient::paused`. The instrumenter is passed in (`ScriptInstrumenter`, a `std::function`), like `EngineConfig::shaderCompiler`, because `fa_runtime` cannot depend on `fa_tooling`. | The instrumenter inside `fa_script`: acorn would ship in every exported game. |
| D5 | Protocol and transport | **DAP over stdio**: `factoria dap`, started by VS Code. A new module `tools/dap` (`fa_dap`) holds the transport-independent server; the CLI wires it to stdin/stdout and runs the game on the main thread. | A WebSocket/TCP port: VS Code's simplest and most portable adapter is an executable on stdio, and no port can collide or be firewalled. |
| D6 | What a session can launch | `mode`: **play** (the game in its window, like `factoria run`), **headless** (N frames, optional input replay, like `factoria run --headless`) and **test** (the project's `tests/*.test.js`, like `factoria test`). | Attaching to the editor's in-process game: the game runs on the editor's UI thread, so a pause would freeze the editor. Left open (see the end). |
| D7 | What AIs get | A **command `script.trace`**: a headless run with tracepoints; each hit records the stack, the locals and watch expressions as JSON; logpoints collect lines of text. Reachable from MCP, `factoria call` and the editor console like every command. | Making AIs speak DAP: a stateful, chatty protocol for a UI; an AI wants one call with one answer. |
| D8 | How VS Code gets the adapter | A plain-JS **VS Code extension** in `tools/vscode/` (debug type `factoria`, defaults without a launch.json), embedded in `factoria` and installed in one click by a new setup component **`vscode`** (`setup.install {"component":"vscode"}`, `factoria setup vscode`, the editor's Setup window). | Publishing to the VS Code Marketplace: an account, a review, and a version that drifts from the installed engine. Can be added later; the embedded copy always matches the binary. |

## The instrumented code (contract between packages A and B)

The instrumenter receives `(file, source, moduleId)` and returns `InstrumentedScript {code, info}`
(`fa/script/debugger.h`). All names it introduces start with `__fa_`; a project identifier with that prefix is a
mistake the docs warn about. Insertions never contain a newline. `info.shifts` records every insertion (line, original
column, length in bytes) so `ScriptDebugInfo::original_column` maps error and stack columns back.

Columns everywhere are **1-based UTF-8 byte columns**: what QuickJS reports (`s->mark - s->eol` in its tokenizer).
acorn counts 0-based UTF-16 units, so the instrumenter converts.

### Module prologue

Inserted at offset 0 (after a UTF-8 BOM or a `#!` line, if any). `import` declarations may follow statements at module
top level, so this is valid before them:

```js
var __fa_d = globalThis.__fa_dbg, __fa_h = __fa_d.h, __fa_f = __fa_d.m(MID, (__fa_x) => eval(__fa_x)); function __fa_i() { __fa_d = globalThis.__fa_dbg; __fa_h = __fa_d.h; return __fa_d; }
```

`m` pushes the module frame (named `(module)`) and keeps its closure as the **Module** scope of every frame of the file.

The names are `var` and `__fa_i` is a hoisted function because of import cycles: another module can call a function of
this file before its prologue has run. Function frame prologues therefore start with `(__fa_d || __fa_i())`, which
initialises `__fa_d` and `__fa_h` on that early call (the module-level `__fa_f` stays undefined then; functions use their
own `__fa_f`). A hook always runs after its function's `e`, so `__fa_h` is set by then.

### Statement hooks

Before every statement of a statement list (Program, BlockStatement, SwitchCase consequent, StaticBlock, function
bodies), except import declarations, function declarations (hoisted: a hook would lie about order), empty statements
and directives:

```js
if (__fa_h(__fa_f, K)) __fa_d.p(__fa_f, K, (__fa_x) => eval(__fa_x));
```

- `K` is the statement's index in `info.statements` (line, column, innermost scope).
- `h` is the **fast path**, a native function: it records the frame's position and returns true only when the runtime
  wants to stop here (a breakpoint on this line, a step that ends here, a pause request, stop on entry). Only then is
  the closure created and `p` called: `p` stops (or logs, or evaluates a condition) with the exact scope of the
  statement.
- A statement that is the single body of `if`/`else`/`for`/`for-in`/`for-of`/`while`/`do`/`with` is wrapped in braces
  first (`if (c) { HOOK stmt }`), so the hook stays inside the branch.
- A labeled statement gets its hook before the label, never between the label and its loop (`continue outer` would
  break). Exported declarations (`export const`, `export default class`) get the hook before `export`.
- `debugger;` keeps its hook and gains a forced stop: `__fa_d.b(__fa_f, K, (__fa_x) => eval(__fa_x)); debugger;`
  (QuickJS ignores the keyword itself).

Breakable lines are the lines that have a hook. A breakpoint on another line moves to the next breakable line.

### Function frames

Every function with a block body (declarations, expressions, arrows, methods, getters, setters, constructors,
generators, async functions) becomes, inside its own braces and after its directive prologue:

```js
{ let __fa_f; try { __fa_f = (__fa_d || __fa_i()).e(FID, (__fa_x) => eval(__fa_x)); BODY } catch (__fa_c) { throw __fa_d.c(__fa_f, __fa_c); } finally { __fa_d.x(__fa_f); } }
```

- `e` pushes a frame record for function `FID` (`info.functions`) and keeps the closure: it is created inside the
  `try` block, so it sees the parameters, `this`, `arguments` and the body's own `let`/`const` (in their TDZ until
  declared). Callers' frames show their locals through it.
- `c` sees every exception that leaves the function (it rethrows the same value, so stacks are unchanged): it can stop
  for "all exceptions" (the first frame that sees it) or "uncaught" (see the runtime), and it records the throw point.
- `x` pops the frame and anything stale above it.
- An arrow with an expression body becomes a block body: `(a) => { FRAME-PROLOGUE HOOK return EXPR; FRAME-EPILOGUE }`,
  so `list.filter((e) => e.alive)` can be stepped into. Its hook's statement is the expression.
- Class field initializers and computed keys are not instrumented. Class static blocks have statement hooks but no
  frame of their own (they run inside the frame that evaluates the class).

### Catch clauses

To stop on caught exceptions ("all"), a user `catch (e) {` becomes `catch (e) { __fa_d.k(__fa_f, e);`; a bare
`catch {` becomes `catch (__fa_k) { __fa_d.k(__fa_f, __fa_k);`. A destructuring catch parameter is left alone (that
exception is still seen by `c` if it leaves a function).

### Debug info

- `statements`: `{line, column, scope}` per hook.
- `functions`: `{name, line, column, endLine, scope}` per frame. Names: a declaration's name; class methods, getters,
  setters and static methods `Class.method`; a constructor `Class`; an anonymous default-exported class `default`;
  `const f = () => {}` and `f: function () {}` take `f`; `obj.prop = function () {}` takes `prop`; otherwise
  `(anonymous)`.
- `scopes`: `{parent, kind, names}`; scope 0 is the module (imports first, then top-level declarations). A function
  scope holds its parameters (destructuring included) and, for a non-arrow function, `this` first; `var` goes to the
  nearest function scope; `let`/`const`/`class`/block functions to their block; a `for (let ...)` head to a block
  scope of the loop; a catch parameter to a `catch` scope. The body's `let`/`const` belong to the function scope here
  (the `try` block the instrumenter adds is not a user scope).

### What is never instrumented

Bytecode modules (exported games), the engine's own preludes (`<factoria>`), JSON modules, code run through
`script.eval`/`ScriptSystem::eval`. A module whose source does not parse is compiled as written: QuickJS reports the
syntax error as usual.

## The runtime (package B, `fa_script`)

### Turning it on

`EngineConfig::scriptDebugger` (`std::shared_ptr<ScriptDebugger>`). When it is set, the engine hands it to its
`ScriptSystem` before `init`. `ScriptSystem` then installs `globalThis.__fa_dbg` (natives `m h p e c x k b`, plus
whatever helpers the implementation wants in an embedded `debugger.js` prelude), and `Impl::load_module` passes the
source of every project `.js` module through `debugger->instrumenter()(file, source, moduleId)` before `JS_Eval`.
`moduleId` increases per load, so a hot reload (`?v=N`) gets a fresh id and fresh debug info while old closures of the
previous version stay valid. The `file` is the project-relative path without `?v=`.

### Frames

The shadow stack is a vector of frame records owned by C++ (a JS object of a private class with an opaque pointer and a
`gc_mark` for its closure, so a suspended generator's record is collected with it). It heals itself:

- `h`/`p` on a frame that is not on top: drop everything above it if it is on the stack, else push it (an async
  function or generator resuming).
- `x` truncates to the frame below the one that ends.
- The stack is reset to empty whenever the host enters JS from an empty JS stack (`Impl::call` with no guard active,
  each job of `run_jobs`): a callback killed by the 2 s timeout skips `finally`, and stale records must not survive.

`stack()` lists the records top first; each has its file, function name, the line and column of its last hook, its
closure (the statement closure of the paused frame, the entry closure of the others) and the module closure.

### Stopping

- Breakpoints are per file and line, with condition, hit condition and log message. `ScriptDebugger` holds them under a
  mutex; the script thread copies them when an atomic generation counter changes, so `h` never locks.
- Steps compare frame depths: **step in** stops at the next hook anywhere; **step over** at the next hook at the same
  depth or shallower; **step out** at the next hook strictly shallower. Stepping off the end of the last frame stops
  at the next JS the engine runs (the next behaviour's callback), as browser debuggers do.
- **Pause** (`request_pause`): an atomic flag; the next `h` returns true. Statement hooks are inside loops, so an
  endless loop pauses too.
- **Exceptions**: "all" stops in `k` or in the first `c` that sees an exception (one stop per exception object). It is
  "uncaught" when `c` runs in the outermost frame of the current host call: the exception is about to reach the engine.
  The stop shows the stack recorded at the throw point (closures keep those frames' scopes readable).
- `debugger;` (`b`) always stops.
- Stop on entry: at the first hook of the run.

While paused, the script thread is inside `DebugClient::paused`. The timeout guards are set aside for the pause and come
back shifted by its length (`push_guard` deadlines are wall-clock); each `evaluate` runs under its own guard
(`callbackLimit`). Hooks never stop again while paused: an evaluated expression that calls instrumented code just runs.
The next frame's `dt` is already clamped (`kMaxFrameDt` in engine.cpp), so physics does not jump.

### Inspecting

- `scopes(frame)`: "Locals" (the names of the scopes from the statement's scope up to its function scope; for a caller
  frame, its function scope), one "Closure (name)" per enclosing function, "Module" (scope 0). Each name is read through
  the frame's closure; a TDZ ReferenceError shows as `<uninitialized>`, a shadowed outer name is left out.
- `variables(ref)`: own properties (string keys, enumerable or not, getters shown as `(getter)` without running them),
  then `[[Prototype]]`; arrays and typed arrays page by index; Map and Set list their entries. Previews like Node:
  `Player {speed: 300, jumpSpeed: 620, …}`, `Array(3) [1, 2, 3]`, `ƒ onUpdate(dt)`. Engine wrappers (entities,
  components, vectors) are ordinary JS objects and need nothing special.
- `evaluate(frame, expr)`: the frame's closure with `(` + expr + `)` first, then expr as statements (so `{a: 1}` is an
  object and `let y = 2; y * 3` works). Frame 0: global eval.
- `set_variable(ref, name, value)`: a scope variable through the closure (`name = (value)`), a property through the
  object. Assigning to a `const` reports the TypeError.
- Errors recorded while debugging get their columns mapped back (`original_column`), so carets stay right. `console.*`
  output and recorded script errors are also sent to `DebugClient::output` with the file and line of the top frame.

### Cost

Debug runs only: a native call per statement (the closure is created only at a stop), a closure and a `try/finally` per
function call, and QuickJS keeps every variable of an instrumented function in a heap scope because of `eval`.
Expected 2-4x slower script time; normal runs are unchanged (no `scriptDebugger`, no instrumentation).

## The DAP server (package C, `tools/dap` + `factoria dap`)

`fa_dap` (`tools/dap`, depends on `fa_tooling`): message framing (`Content-Length: N\r\n\r\n` + JSON, both ways),
`DapServer` (requests in, responses and events out through a sink, no I/O of its own) and a `DebugClient`
implementation. `tools/cli/src/cmd_dap.cpp`: the `factoria dap` subcommand. stdout carries only protocol; logs go to
stderr and, as `output` events, to VS Code's debug console.

### Threads

- A reader thread parses stdin and handles what needs no script thread: `initialize`, `launch` (stores the
  arguments), `setBreakpoints`, `setExceptionBreakpoints`, `configurationDone`, `threads` (one thread, id 1, "Game"),
  `pause`, `disconnect`/`terminate`.
- The **main thread** waits for `configurationDone`, then runs the game the launch asked for, with a `ScriptDebugger`
  in its `EngineConfig` (instrumenter: `fa::instrument_script` from package A). macOS needs windows on the main thread.
- While paused, `paused()` (main thread) waits on a queue the reader fills: `stackTrace`, `scopes`, `variables`,
  `evaluate`, `setVariable`, `source` run there; `continue`/`next`/`stepIn`/`stepOut` return from `paused()`.
- `evaluate` while running is queued to the next `poll()` and answered with `ScriptSystem::eval`.
- When the game ends: `exited` {exitCode} and `terminated`. `disconnect` calls `request_terminate`.

### Capabilities and launch arguments

`supportsConfigurationDoneRequest`, `supportsConditionalBreakpoints`, `supportsHitConditionalBreakpoints`,
`supportsLogPoints`, `supportsEvaluateForHovers`, `supportsSetVariable`, `supportsTerminateRequest`,
`exceptionBreakpointFilters` `uncaught` (default on) and `all`.

```jsonc
{
  "type": "factoria", "request": "launch", "name": "Play",
  "mode": "play",                 // "play" | "headless" | "test"
  "project": "${workspaceFolder}",
  "scene": "",                    // play/headless: the scene to start in (default: the project's main scene)
  "frames": 600,                  // headless: how many frames
  "input": "",                    // headless: an input replay file
  "tests": [],                    // test: files (default: every tests/*.test.js)
  "filter": "",                   // test: only tests whose name contains this
  "stopOnEntry": false
}
```

Unknown keys and bad values get an error response that teaches (`did_you_mean` for keys and modes). Paths in DAP are
absolute; the server maps them to project-relative module names (case-insensitively on Windows and macOS). A file
outside the project gets unverified breakpoints with a message saying why.

### The integration test

`tools/cli/tests/dap_test.py` (ctest `cli_dap`): makes a project from the `2d-platformer` template, starts
`factoria dap`, launches `headless`, sets a breakpoint on `scripts/player.js` line 17 (first line of
`Player.onUpdate`), and checks: `stopped` with reason `breakpoint`; the top frame is `Player.onUpdate` at line 17;
Locals has `dt` and `this`; `evaluate` of `this.speed` is `300`; `next` stops at line 18; a logpoint prints its
message; `continue` after clearing breakpoints runs to the end with `exited` code 0 and `terminated`. Plus `fa_dap`
doctest cases for framing and request validation, and a test mode run that stops in a template test.

## `script.trace` (package D, `fa_tooling`)

```jsonc
// in
{ "points": [ { "file": "scripts/player.js", "line": 17, "condition": "this.body.velocity.y > 0",
                "watch": ["this.body.velocity", "dt"], "log": "" } ],
  "frames": 300, "input": "", "scene": "", "maxHits": 20, "depth": 1 }
// out
{ "hits": [ { "point": 0, "frame": 12, "file": "scripts/player.js", "line": 17, "function": "Player.onUpdate",
              "stack": ["Player.onUpdate scripts/player.js:17"], "locals": {"dt": 0.0167, "this": {"speed": 300}},
              "watch": {"this.body.velocity": {"x": 0, "y": 0}, "dt": 0.0167} } ],
  "logs": [ { "frame": 12, "file": "scripts/player.js", "line": 17, "text": "vy=0" } ],
  "errors": [], "framesRun": 300, "truncated": false }
```

A headless run like `perf.measure` (fake platform, memory storage, fixed dt) with a `DebugClient` whose `paused`
records the hit and returns `Continue` at once. A point with `log` is a logpoint. `depth` limits how far objects are
expanded into JSON (0 = previews only); `maxHits` per point, then `truncated`. A point on a line without a statement is
an error naming the nearest breakable lines; a file that is not a project module, an error with `did_you_mean`. Script
errors of the run are listed in `errors`.

## The VS Code extension and its setup (package E)

- `tools/vscode/`: `package.json` (debugger type `factoria`, its launch attributes as above, initial configurations
  Play / Headless / Tests, snippets), `extension.js` (a `DebugAdapterDescriptorFactory` returning
  `DebugAdapterExecutable(<factoria>, ["dap"])`; a `DebugConfigurationProvider` that fills `mode: play` and the
  workspace folder when F5 is pressed without a launch.json in a folder with `factoria.json`), `README.md`. No build
  step, no npm dependencies.
- Embedded in `fa_tooling` and installed by the setup component `vscode`: copies the extension to
  `~/.vscode/extensions/oxtailgames.factoria-<version>/` (and to the Insiders, VSCodium and Cursor extension folders
  that exist), writes the absolute path of the running `factoria` into it so the extension finds the right binary,
  and removes older versions. `setup.status` reports `installed` when the copy matches this binary's version. The
  editor's Setup window lists it with its Install button like the other components.
- New projects get `.vscode/launch.json` with the three configurations (the templates).
- `docs/DEBUGGING.md` (embedded): install, launch modes, breakpoints, conditions, logpoints, exceptions, the debug
  console, `script.trace` for AIs, limitations. Linked from SCRIPTING.md, EDITOR.md, CLI.md and AI_GUIDE.md.

## Packages

| Package | Contents | Depends on |
|---|---|---|
| A | acorn in `external/acorn/` (VERSIONS.md, LICENSE, `third_party_components()`), `fa/tooling/script_instrument.h` `instrument_script`, its JS, tests | the contract |
| B | the runtime in `fa_script` (`ScriptDebugger`, hooks, frames, stopping, inspecting, guards, error columns), `EngineConfig::scriptDebugger`, tests on hand-instrumented sources | the contract |
| C | `tools/dap`, `factoria dap`, `cli_dap` | A, B |
| D | `script.trace` | A, B |
| E | the VS Code extension, setup component `vscode`, template launch.json, `docs/DEBUGGING.md` and links, CLI.md | the design |

A, B and E run in parallel; C and D after A and B are merged.

## Limits (documented in DEBUGGING.md)

- Exported games cannot be debugged (bytecode, no instrumenter). Debug a project, not an export.
- Only one thread: the game. Script time is slower while debugging.
- A breakpoint in a class field initializer, a computed key or a parameter default is moved to the next statement.
- Stepping over an `await` continues in the caller; the rest of the async function stops again only on a breakpoint.
- Identifiers starting with `__fa_` are reserved while debugging.

## Left open

- Attaching to the editor's running game: needs the game off the editor's UI thread, or a pause that keeps the editor
  drawing. A separate M-item if users ask.
- Restart frame, step back, data breakpoints, column breakpoints.
- Publishing the extension to the VS Code Marketplace / Open VSX.
