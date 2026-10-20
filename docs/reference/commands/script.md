[Back to the index](../README.md)

# Commands: script

## `script.errors`

List script errors (load/runtime) and scene load problems.

Cleared by scene.load, scene.reload and script.reload. Example: script.errors {}

## `script.eval` (modifies state)

Evaluate JavaScript in the running game context (REPL) and return the value.

The last expression is returned as JSON. Example: script.eval {"code":"world.find('player').get('Transform').position"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | JavaScript source. |

## `script.reload` (modifies state)

Re-import script modules edited on disk and restart the behaviours (the world is kept).

scene.load and scene.reload already re-import every module whose file changed (by modification time) and clear the script errors; use this to do the same without reloading the scene (entity state is kept, onStart runs again), or with `force` to re-import every module even if no file changed. Example: script.reload {}

| Argument | Type | Required | Description |
|---|---|---|---|
| `force` | boolean | no | Re-import all modules, not only the changed ones. Default false. |

