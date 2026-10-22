# Debugging scripts

The logic of a game is JavaScript. When a behaviour misbehaves you have two ways to see inside it:

- **A person**: press F5 in VS Code. The game stops at your breakpoints; you see the call stack, `this`, the locals, step
  line by line, watch expressions, and type expressions in the debug console.
- **An AI**: the command `script.trace` runs the game headless and records the stack, the locals and any expressions
  every time a line runs. One call, one JSON answer. No UI needed. See [For AIs: `script.trace`](#for-ais-scriptrace).

Both work on the **project** (the folder with `factoria.json`), not on an exported game: an export holds bytecode and
cannot be debugged ([Limits](#limits)).

## Installing (one command)

```
factoria setup vscode
```

That is all. It copies the FactorIA extension, which is built into the `factoria` program (nothing is downloaded), to
`~/.vscode/extensions/oxtailgames.factoria-<version>/`, and also to VS Code Insiders (`~/.vscode-insiders`), VSCodium
(`~/.vscode-oss`) and Cursor (`~/.cursor`) when you have them. It records the path of the `factoria` that installed it, so
the extension starts exactly that one, and removes older versions of the extension. Restart VS Code once (or run
"Developer: Reload Window").

In the editor: File > Set Up This Computer... lists "Visual Studio Code debugger" with an Install button. An AI can do the
same with `setup_install {"component":"vscode"}` (it only copies files; `setup_status` reports `installed` or `missing`).

Install it again after updating FactorIA: the extension version is the engine's version, so `factoria setup` shows it as
missing until you do.

## Starting a session

New projects come with `.vscode/launch.json` holding three configurations. Open the project folder in VS Code, press
F5 (or pick one in the Run and Debug view):

| Configuration | Mode | What it runs |
|---|---|---|
| Play | `play` | The game in its window, like `factoria run`. Hot reload keeps working. |
| Headless (600 frames) | `headless` | 600 frames without a window, like `factoria run --headless`; optionally replaying an input file. Deterministic and fast: the best way to reproduce a bug. |
| Tests | `test` | The project's `tests/*.test.js`, like `factoria test`. Breakpoints work inside the tests and the behaviours they run. |

F5 in a folder with `factoria.json` and no `launch.json` plays the project. The three configurations are also offered
by "Add Configuration..." and in the Run and Debug dropdown.

### Launch attributes

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
  "stopOnEntry": false,           // stop at the first statement of the first script that runs
  "factoriaPath": ""              // the factoria executable to start (default: the one that installed the extension, else PATH)
}
```

| Attribute | Mode | Meaning |
|---|---|---|
| `mode` | all | `play`, `headless` or `test`. Default `play`. |
| `project` | all | The project folder. Default `${workspaceFolder}`. |
| `scene` | play, headless | Project-relative scene to start in, e.g. `scenes/level2.scene.json`. Default: the project's main scene. |
| `frames` | headless | How many fixed frames to run. |
| `input` | headless | An input replay file (for example the `input.json` that `play.report` points to: the session a person played, replayed under the debugger). |
| `tests` | test | Test files, e.g. `["tests/player.test.js"]`. Default: every `tests/*.test.js`. |
| `filter` | test | Only the tests whose name contains this text. |
| `stopOnEntry` | all | Stop at the first statement that runs. |
| `factoriaPath` | all | Full path of the `factoria` executable to use as the debug adapter (`factoria dap`). |

An unknown key or a bad value is refused with a message that names it and suggests the closest valid one ("did you mean
`headless`?"). Paths are absolute in VS Code; the debugger maps them to project-relative modules. A breakpoint in a file
outside the project stays unverified (grey) and says why.

## What you can do while debugging

### Breakpoints

Click the gutter of a `.js` file of the project. A breakpoint on a line that holds no statement (a blank line, a comment,
a `}`) moves to the next line that has one. Breakable lines are the lines where a statement starts.

- **Condition** (right-click the breakpoint > Edit Breakpoint > Expression): stops only when the JavaScript expression
  is true, evaluated in the scope of that line: `this.jumpSpeed < 100`, `dt > 0.05`.
- **Hit count** (Edit Breakpoint > Hit Count): stops on the Nth hit, e.g. `10`, `> 5` or `% 3`.
- **Logpoint** (right-click the gutter > Add Logpoint): prints a message to the debug console instead of stopping.
  Put expressions in braces: `vy={this.body.velocity.y} dt={dt}`.
- **`debugger;`** in your script always stops (when a debugger is attached; otherwise it does nothing).
- **Exception filters** (Run and Debug view, "Breakpoints"): *Uncaught exceptions* (on by default) stops where an exception
  is about to reach the engine; *All exceptions* also stops at the throw point of exceptions your code catches. The stop
  shows the stack at the throw, and the locals of those frames stay readable.

### Pausing and stepping

Pause (the toolbar) stops at the next statement, also inside an endless loop. Then:

- **Continue** (F5).
- **Step Over** (F10): the next statement of this function, or of the caller when this one ends.
- **Step Into** (F11): the next statement anywhere, including inside the function called on this line.
- **Step Out** (Shift+F11): the next statement after this function returns.

Stepping past the end of the last frame stops at the next JavaScript the engine runs (the next behaviour's callback),
like a browser debugger.

While the game is stopped the simulation is stopped too; when you continue, the next frame's `dt` is limited, so physics
does not jump.

### Variables, watch and the debug console

- **Variables**: *Locals* (parameters, `this`, `let`/`const`/`var` of the function and its blocks), one *Closure (name)*
  per enclosing function, and *Module* (the file's top-level names and imports). Objects expand: own properties
  (getters are shown as `(getter)` and not run), then `[[Prototype]]`; arrays page by index; `Map` and `Set` list their
  entries. Previews read like Node's: `Player {speed: 300, jumpSpeed: 620, …}`, `Array(3) [1, 2, 3]`,
  `ƒ onUpdate(dt)`. Entities, components and vectors are ordinary objects. A `let` that is not initialised yet shows
  `<uninitialized>`.
- **Edit a value**: double-click a variable (or "Set Value") to assign it. Assigning to a `const` reports the TypeError.
- **Watch** and **hover** evaluate any expression in the selected frame, and so does the **debug console** at the bottom:
  `this.body.velocity`, `world.findByTag("coin").length`, `let n = 2; n * 3`, `{a: 1}` (an object). Calling functions
  works. While the game is running (not stopped) the console evaluates in the global scope.
- `console.log` output and script errors appear in the debug console with the file and line they came from.

### Selecting a frame

Click a frame of the call stack: the Variables view, Watch and the console switch to that frame. Frames of other
behaviours that run later are not on the stack; the stack shows the JavaScript calls that lead to the current line.

## For AIs: `script.trace`

An AI cannot press F5, and a stateful chat with a debugger is slow. `script.trace` (MCP tool `script_trace`, `factoria
call script.trace`, the editor console) is the same facility as one call: it runs the project headless, and each time a
traced line runs it records where it is, the locals and the expressions you asked for. The run is deterministic (fixed
timestep, fake platform, in-memory storage), like `perf.measure`.

Input:

```jsonc
{ "points": [ { "file": "scripts/player.js", "line": 17, "condition": "this.body.velocity.y > 0",
                "watch": ["this.body.velocity", "dt"], "log": "" } ],
  "frames": 300, "input": "", "scene": "", "maxHits": 20, "depth": 1 }
```

| Field | Meaning |
|---|---|
| `points[].file` | Project-relative script, e.g. `scripts/player.js`. |
| `points[].line` | The line (1-based). It must start a statement; otherwise the error names the nearest lines that do. |
| `points[].condition` | Optional JavaScript expression; the point records only when it is true. |
| `points[].watch` | Expressions to evaluate and record at each hit. |
| `points[].log` | If non-empty, the point is a logpoint: it records this text (with `{expression}` parts evaluated) into `logs` and records no hit. |
| `frames` | How many fixed frames to run. |
| `input` | Optional input replay file (a recorded session) to play while tracing. |
| `scene` | Optional scene to start in (default: the main scene). |
| `maxHits` | Maximum hits recorded per point; then `truncated` is true. |
| `depth` | How far objects are expanded into JSON in `locals` and `watch` (0 = short previews only). |

Output:

```jsonc
{ "hits": [ { "point": 0, "frame": 12, "file": "scripts/player.js", "line": 17, "function": "Player.onUpdate",
              "stack": ["Player.onUpdate scripts/player.js:17"], "locals": {"dt": 0.0167, "this": {"speed": 300}},
              "watch": {"this.body.velocity": {"x": 0, "y": 0}, "dt": 0.0167} } ],
  "logs": [ { "frame": 12, "file": "scripts/player.js", "line": 17, "text": "vy=0" } ],
  "errors": [], "framesRun": 300, "truncated": false }
```

`hits[].point` is the index in `points`; `frame` is the frame it ran in; `stack` lists the calls, innermost first.
`errors` lists the script errors thrown during the run (with file and line), whether or not a point was involved.

### Example: why does the player not jump?

`scripts/player.js` of the 2d-platformer template has, in `onUpdate(dt)` (line 16): the move line (17), then
`if (input.pressed("jump") && this.entity.isGrounded()) {` (18) and `this.body.velocity.y = this.jumpSpeed;` (19). The
fields are `speed = 300` and `jumpSpeed = 620`.

1. Look at what the condition sees on line 18 on the frames where the jump action is pressed:

```
script_trace {"points":[{"file":"scripts/player.js","line":18,"condition":"input.pressed(\"jump\")",
                         "watch":["this.entity.isGrounded()","this.body.velocity","this.jumpSpeed"]}],
              "frames":120,"input":"<the input.json path that play_report gave>","maxHits":5}
```

2. Read `hits[*].watch`. If `this.entity.isGrounded()` is always `false`, the body never rests on anything. Follow the
   velocity over time with a logpoint, which is cheaper than hits with locals:

```
script_trace {"points":[{"file":"scripts/player.js","line":17,
                         "log":"x={this.body.velocity.x} y={this.body.velocity.y} grounded={this.entity.isGrounded()}"}],
              "frames":300,"maxHits":50}
```

   `logs` then holds one line per frame (up to `maxHits`).

3. If the jump line (19) runs but the player does not rise, check the field with a condition to keep the answer short:

```
script_trace {"points":[{"file":"scripts/player.js","line":19,"condition":"this.jumpSpeed <= 0",
                         "watch":["this.speed","this.jumpSpeed"]}],
              "frames":120,"maxHits":3}
```

4. Fix the code, then run the same call again: the answer shows the change. When it is right, keep it as a test
   ([SCRIPTING.md](SCRIPTING.md)).

Tips: start with `depth` 1 and few watches, widen only where needed; `maxHits` keeps answers small; a point in a
function that never runs gives `hits: []` and `framesRun` equal to `frames`, which itself tells you the line is not
reached (check the `scene` and the `input`). A point on a line without a statement is an error that lists the nearest
breakable lines; a file that is not a project module is an error with the closest script names.

## Under the hood

`factoria dap` is a Debug Adapter Protocol server on stdio, which is what VS Code starts. It runs the game on the main
thread (windows must be created there on macOS) with a debugger attached; the scripts it loads are compiled from a copy
of their source with hooks added before each statement (line numbers do not change). Only a debugging run does this; a
normal `factoria run`, a test run and an export are untouched. Other DAP clients (Neovim, Emacs, JetBrains with a DAP
plugin) can launch `factoria dap` with the same launch arguments.

## Limits

- **Exported games cannot be debugged** (they hold bytecode and no instrumenter). Debug the project.
- One thread: the game. Script time is slower while debugging (expect 2-4x).
- A breakpoint in a class field initializer, a computed key or a parameter default moves to the next statement.
- Stepping over an `await` continues in the caller; the rest of the async function stops again only on a breakpoint.
- Identifiers starting with `__fa_` are reserved while debugging: do not use them in your scripts.
- Code run through `script.eval` and the engine's own preludes are not debuggable; JSON modules neither.
- Not supported: attaching to the editor's running game, restarting a frame, stepping back, data breakpoints, column
  breakpoints.

## See also

[SCRIPTING.md](SCRIPTING.md) (behaviours and tests), [EDITOR.md](EDITOR.md) (the Setup window, the Console),
[CLI.md](CLI.md) (`factoria dap`, `factoria setup vscode`), [AI_GUIDE.md](AI_GUIDE.md).
