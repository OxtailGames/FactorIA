# The FactorIA editor

`factoria editor [project]` opens the visual editor (a Dear ImGui window, desktop builds). On Windows, `FactorIA-Editor.exe` (next to
`factoria.exe`) opens it with no console window, like any other program; drop a project folder on it to open that
project. Double-clicking `factoria.exe` opens it too, after a console flashes (with no arguments from a terminal,
`factoria` prints its help). It is a front end for the same
**commands** that the CLI, the MCP server and the AI tools use: it does not have a private way to change a project. Whatever a
menu entry does, you can also type in the Console (`scene.import_ascii {...}`) or call over MCP, and the result is the same.

## Layout

| Panel | What it does |
|---|---|
| Toolbar | Play, Pause, Step, Stop; Save, Reload, Validate, Screenshot; Undo, Redo. |
| Viewport | The game as the engine renders it (post-effects such as `Camera.bloom` included), with the selection outline. Click to select, drag to move (Ctrl snaps to 8). |
| Hierarchy | The entity tree: drag to reparent, double-click to rename, right-click for the entity menu. |
| Inspector | Every component of the selected entity, generated from the engine's reflection (see below). With nothing selected: the scene settings. |
| Assets | The project's files. Double-click a scene to open it. |
| Console | The log, and a command line: `name {json}` runs a command, `> code` runs JavaScript, `help` lists commands. |
| Audio | (View > Audio) the live `audio.log`. |
| AI Assistant, Engine Feedback | The built-in agent and the project's `ENGINE_FEEDBACK.json`. |

Play snapshots the scene and runs the game; Stop restores the snapshot, so edits made while playing are temporary. Ctrl+Z / Ctrl+Y
undo and redo scene edits (also the ones made by commands and by the AI).

## Selecting things

The outline of the selected entity comes from the engine's own geometry (`fa/scene/bounds.h`), the code behind
`entity.bounds()` in scripts, so what the editor outlines is what a script measures:

- a **Sprite** or **Shape2D** is its size box placed by `pivot` (a triangle with pivot `[0.5, 0.3333]` keeps its whole box around
  the entity); a **diamond** is outlined by its size box and, thinner, by its four tips; **Text** by the laid-out text box;
  a **Tilemap** by its rows (or `width` x `height`) times `tileSize`, from its top-left corner;
- **rotation and scale** are applied: the outline and the click area are the turned box, not the box around it;
- an entity with several visuals (a Sprite and a Text) is selectable on any of them, the highest `layer` wins;
- **screen-space** items (`space: "screen"`, the HUD) are outlined and picked on the screen with their `anchor`, which
  `entity.bounds()` does not do (it returns `null` for them);
- entities that draw nothing get a small handle, colliders their collider box.

## Inspector

The inspector has no hand-written code per component. Each field of the engine's reflection becomes a widget by its kind (checkbox,
number, vector, colour, enum list, entity picker, asset picker, JSON box), and:

- hovering a field name or value shows its **doc string**, its type and its range;
- **ranges are respected**: dragging and typing both stay inside them (`Camera.bloomIntensity` 0..10, `bloomRadius` 1..128);
- a `0` that means "work it out" says so: `Tilemap.columns` shows `0 (derived: 4 from the tileset)`, `Text.maxWidth` shows
  `0 (no wrapping)`;
- fields documented as "Only used when `flag` is true" (the `Camera.bloom*` fields) are greyed while the flag is off, but stay editable;
- every edit is one undo step (consecutive edits of the same field are merged).

## Menu entries that run engine commands

### Save as prefab (hierarchy right-click, or Edit > Save as prefab...)
Saves the entity and its children as a prefab file with `prefab.save {id, path}`. The dialog suggests `prefabs/<id>.prefab.json`.
If the file already exists the command refuses (`already_exists`) and the dialog asks before it retries with `overwrite: true`.
After a save the dialog lists the **notes** the command returns: what the file does not carry (the root's position, ids, `tilemap:`
tags, references to entities outside the saved tree). The Assets panel refreshes and selects the new file. It works while the game
runs too, to keep something you built there.

### File > Import ASCII level...
A window around `scene.import_ascii`: one box for the `rows` (monospaced, one row per line), one for the `legend` JSON, one for the
`tilemap` fields and a folded one for the other arguments (`entity`, `position`, `anchor`, `replace`).

- **Arguments from a file** loads a `levels/*.json` argument file into the boxes.
- **Target: scene file** builds `path` (optionally starting from `from`, a base scene with the camera and HUD) and touches nothing else.
  If `path` is the scene open in the editor, the editor reloads it afterwards so the viewport shows the level. With unsaved changes it
  asks first: *Save first, then import* (the import builds on what you saved), or *Import, keep my edits undoable* (Ctrl+Z brings back
  the scene as it was on screen). Nothing is dropped silently.
- **Target: running scene** changes the scene you are editing, like any other edit (one undo step; not while the game runs). *Also save the
  scene file* writes it right away: the editor is allowed to, whereas for other callers the command refuses (`unsafe_save`) while the
  running scene is only the project's default `mainScene`.
- **Preview** is a dry run: it writes nothing and shows how many objects would be placed, the map size, the warnings (an unused legend
  glyph, a missing tileset) and, for a wrong map, the error with its row and column and a suggestion. In running-scene mode it checks
  the map against the saved scene file.

### File > Format scene files...
Runs `scene.format`: first `check: true`, then a confirmation that lists the scene and prefab files whose layout is not the canonical
one, then the real run. Only whitespace changes (values and key order stay). A file that is not valid JSON is listed with its line and
column and left alone. Scenes that the editor itself saves already are canonical, so this is for files edited by hand.

### View > Audio
The Audio panel shows `audio.log`: sequence number, frame, clip path, bus, volume, the entity that played it (`source`) and whether the
clip loaded. While the game runs it asks only for plays newer than the last one it saw (`after`). **Filter by path**, **Failed only**
and **Clear** keep it readable; a clip that failed to load (`ok: false`) is highlighted in red, because a wrong path is silent in the
game itself.

## Testing the editor

- `fa_test_editor` (ctest `editor`): the GPU-free logic: the command wrappers (`tools/editor/src/editor_tools.*`), picking geometry
  (`pick.cpp`), the inspector's reflection rules.
- `editor_autotest` and `editor_autotest_welcome` (ctest, need a display: `xvfb-run` on Linux): the real editor window. The autotest
  clicks through the UI with injected mouse events (right-click an entity, File menu entries, dialog buttons), checks the files and
  the world after every action and saves window screenshots (`FA_EDITOR_AUTOTEST_OUT=<dir>`).
  Run it with `FA_EDITOR_AUTOTEST=1 xvfb-run -a -s "-screen 0 1600x900x24" build/dev/tools/editor/fa_editor_autotest`.
