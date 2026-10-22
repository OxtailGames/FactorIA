# FactorIA for VS Code

Debug the JavaScript of a FactorIA game: breakpoints, conditions, logpoints, stepping, the Variables view, watch
expressions and the debug console. Press F5 in a project folder (the one with `factoria.json`).

The extension is a thin launcher: the debugger itself is `factoria dap`, inside the `factoria` executable.

## Install

```
factoria setup vscode
```

(or File > Set Up This Computer... in the editor). It copies this extension to
`~/.vscode/extensions/oxtailgames.factoria-<version>/` (and to VS Code Insiders, VSCodium and Cursor when they are
installed), records which `factoria` installed it and removes older versions. Restart VS Code once.

## Use

New projects come with `.vscode/launch.json`: **Play** (the game in its window), **Headless (600 frames)** and
**Tests** (`tests/*.test.js`). F5 with no launch.json plays the project. Every launch attribute (`mode`, `project`,
`scene`, `frames`, `input`, `tests`, `filter`, `stopOnEntry`, `factoriaPath`) is described in `docs/DEBUGGING.md`, which
`factoria docs debugging` prints.

`factoriaPath` picks another `factoria` for one configuration; by default the extension runs the one that installed it,
else `factoria` on the PATH.

Exported games cannot be debugged (they hold bytecode): debug the project.
