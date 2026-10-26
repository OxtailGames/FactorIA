[Back to the index](../README.md)

# Commands: script

## `script.errors`

List script errors (load/runtime) and scene load problems.

Cleared by scene.load, scene.reload and script.reload. Example: script.errors {}

## `script.eval` (modifies state)

Evaluate JavaScript in the running game context (REPL) and return the value, or call an exported function of a module.

The last expression is returned as JSON. Example: script.eval {"code":"world.find('player').get('Transform').position"}. With `module` (a project path such as scripts/game/rules.js) and `call` (the name of an exported function, "default" for the default export) it imports the module and returns what the function returns, passing `args` (a JSON array) as its arguments; it needs no scene, so a pure module (no engine state) can be run on its own. An async function is awaited if it settles without time passing. Example: script.eval {"module":"scripts/game/rules.js","call":"price","args":["wood",3]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `code` | string | no | JavaScript source. Required unless `module` is given. |
| `module` | string | no | Project path of a script module to import (scripts/game/rules.js); use with `call`. |
| `call` | string | no | Name of the exported function of `module` to call ("default" for the default export). |
| `args` | array | no | Arguments (JSON values) for the call. |

## `script.reload` (modifies state)

Re-import script modules edited on disk and restart the behaviours (the world is kept).

scene.load and scene.reload already re-import every module whose file changed (by modification time) and clear the script errors; use this to do the same without reloading the scene (entity state is kept, onStart runs again), or with `force` to re-import every module even if no file changed. Example: script.reload {}

| Argument | Type | Required | Description |
|---|---|---|---|
| `force` | boolean | no | Re-import all modules, not only the changed ones. Default false. |

## `script.trace`

Since 0.2.0.

Debug scripts: run the game headless and record the stack, locals and watch expressions each time chosen lines run.

The way to find out WHY a script misbehaves without an IDE. Runs the project headless for `frames` fixed steps (a second engine in this process, fake platform, in-memory storage, fixed dt: the same input gives the same answer) with the scripts instrumented, and at each traced line records what is there instead of stopping. A point is {file, line, condition?, watch?, log?}: `file` a project-relative script, `line` a line that starts a statement (an error names the nearest ones when it does not), `condition` a JavaScript expression that must be true for the point to record, `watch` expressions evaluated at every hit, `log` a message with {expression} parts that turns the point into a logpoint (it writes into `logs` and records no hit; cheaper than a hit with locals). Returns {hits: [{point (index in points), frame (0-based fixed frame), file, line, function (e.g. Player.onUpdate), stack (innermost first, "fn file:line"), locals: {name: value}, watch: {expression: value}}], logs: [{frame, file, line, text}], errors (script errors raised during the run, scene problems, conditions that threw), framesRun, truncated}. Values are JSON: numbers, strings and booleans as such; objects are expanded `depth` levels (0 = a short preview string, 1 = the fields as JSON with nested objects as previews); an expression that throws gives "<error: ...>". After `maxHits` hits of a point it stops recording and `truncated` is true. A point in code that never runs gives no hits (check `scene` and `input`). Debugging slows the scripts 2-4x. See docs/DEBUGGING.md. Example: {"points":[{"file":"scripts/player.js","line":17,"condition":"dt > 0","watch":["this.body.velocity"]}],"frames":120,"maxHits":5}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `points` | array | yes | The lines to trace. |
| `frames` | integer | no | How many fixed frames to run. Default 300. |
| `input` | string | no | Project-relative input replay JSON (a recorded session, play.report gives the path) applied during the run. |
| `scene` | string | no | Start scene (default: the project's mainScene). |
| `maxHits` | integer | no | Hits (or log lines) recorded per point; one more sets truncated and the point stops recording. Default 20. |
| `depth` | integer | no | How far objects in locals and watch are expanded into JSON (0 = previews only; nested objects beyond the depth are previews). An object shows at most 100 entries. Default 1. |

