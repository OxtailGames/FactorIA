# The FactorIA editor

`factoria editor [project]` opens the visual editor (a Dear ImGui window, desktop builds). On Windows, `FactorIA-Editor.exe` (next to
`factoria.exe`) opens it with no console window, like any other program; drop a project folder on it to open that
project. Double-clicking `factoria.exe` opens it too, after a console flashes (with no arguments from a terminal,
`factoria` prints its help). The editor is **AI-first**: you do not edit the project by hand. You tell the built-in **AI Assistant**
what to build or change, watch the result in the viewport, and play it. It is a front end for the same
**commands** that the CLI, the MCP server and the AI tools use: it does not have a private way to change a project. Whatever the AI
does, you can also type in the Console (`scene.set_component {...}`) or call over MCP, and the result is the same.

## Opening and creating projects

Without a project the editor starts on the **Open or create a project** dialog (also File > New Project... / Open
Project...). Type a path or press **Browse...** for the system's folder dialog (Windows, macOS; on Linux it needs
`zenity` or `kdialog`): browsing to a project folder opens it at once. New projects go to `<Folder>/<Name>`; Folder
starts at your Documents folder. Recent projects, and projects found in the current folder,
are listed by name under the path; hover one to see its path (`~/.factoria/editor_recent.json`).

## Layout

The AI builds the game, so the window (maximized on Windows) is the game view and the AI chat: **Viewport** on the left, **AI Assistant** on the
right, and Console / Engine Feedback / Audio as tabs under the view. There is no panel for editing by hand (no entity tree,
property editor or asset browser, and nothing moves by dragging): describe the change to the AI, and use Undo to take back
what it did. View > Reset layout restores this layout (`~/.factoria/editor_layout2.ini` keeps yours).

| Panel | What it does |
|---|---|
| Toolbar | Play, Pause, Step, Stop; Save, Reload, Validate, Screenshot; Undo, Redo. |
| Viewport | The game as the engine renders it (post-effects such as `Camera.bloom` included). Click an entity to select it: the selection outline shows what you point at. |
| AI Assistant | The built-in agent: describe what to build or change (see AI_PROVIDERS.md for the providers). |
| Console | The log, and a command line: `name {json}` runs a command, `> code` runs JavaScript, `help` lists commands. |
| Engine Feedback | The project's `ENGINE_FEEDBACK.json`: what the AI found missing in the engine. |
| Audio | (View > Audio) the live `audio.log`. |

Play snapshots the scene and runs the game; Stop restores the snapshot, so edits made while playing are temporary. For that
reason the AI works in edit mode only: while the game runs (Play or Pause) its Run button is disabled ("game running: Stop it
to send"), and while it is working Play and Step are disabled until it finishes or you press Stop in the AI panel. The Console
still runs commands during play, to inspect or poke the running game. Ctrl+Z / Ctrl+Y
(toolbar and Edit menu too) undo and redo scene edits: the ones made by the AI and by commands typed in the Console. View >
Show colliders and Selection overlay toggle the collider boxes and the selection outline in the viewport.

## AI Assistant

The panel holds several conversations as **tabs**: **+** opens an empty chat, the **x** on a tab closes it (the chat stays
in History), and the title is the first message ("New chat" until then). Each tab has its own transcript, input, usage and
attachments; a message in a tab continues that tab's conversation (see `docs/AI_PROVIDERS.md`). One chat runs at
a time: Run is disabled in the other tabs while one works (hover it to see which). **History** lists the saved chats, newest
first; click one to reopen it as a tab (the next message resumes it) or Delete it from the list.

- **Roles:** your messages always go to the orchestrator role, which answers, plans and hands implementation work to
  the worker role and small mechanical edits to the fast role by itself. **Roles...** at the top of the panel picks the
  provider, model and effort of each role (the line next to it shows the current ones); Save writes them into `ai.json`
  and the next message uses them (see `docs/AI_PROVIDERS.md`, Roles). Its **Context** column caps how much of the
  conversation a session keeps (full, or 100k to 800k): past it the earlier part is summarized, so each message costs
  less. It works with Claude Code and the Anthropic API.
- **Pictures:** drop image files (png, jpg, jpeg, gif, webp) on the window, press Ctrl+V in the input with a picture on the
  clipboard, or press **Attach image...**. Pending pictures show above the input (remove one with its x); sent ones show
  in the transcript. Copies live in `.factoria/ai/attachments/`; other file types are refused with a message saying why.
  A big picture (a 4K screenshot) is scaled down to 1568 px on its long side, what the model looks at anyway, so it costs
  fewer tokens and stays under the API's 5 MB limit.
- **Usage** (above the transcript): Session (5h) and Week plan limits with the reset time, the model's Context, Tokens
  and the estimated Cost of the chat. Hover a line for details. The limits are the last ones the provider reported
  (kept in `~/.factoria/ai_limits.json`).
- **Selection:** the entity selected in the viewport (click it) is named to the AI in each message.
- Chats are saved in `.factoria/ai/chats/` after each answer and when a tab closes; the open tabs come back when the project opens.

## Selecting things

Clicking in the viewport selects the entity under the cursor; the selection is how you point at something ("make this one bigger").
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

While the game runs, clicks and keys go to the game instead (click the viewport to give it the keyboard).

## Scene files rebuilt on disk

A command that rebuilds the scene file that is open (`scene.import_ascii` with `path` set to it, from the AI or the Console) is
followed by a reload, so the viewport shows the result. Whatever was on screen before is one Ctrl+Z away, and commands that only write
files (`prefab.save`, `scene.format`, `scene.import_ascii` with `path`) neither take an undo step nor mark the scene as changed.

## View > Audio
The Audio panel shows `audio.log`: sequence number, frame, clip path, bus, volume, the entity that played it (`source`) and whether the
clip loaded. While the game runs it asks only for plays newer than the last one it saw (`after`). **Filter by path**, **Failed only**
and **Clear** keep it readable; a clip that failed to load (`ok: false`) is highlighted in red, because a wrong path is silent in the
game itself.

## Testing the editor

- `fa_test_editor` (ctest `editor`): the GPU-free logic: the Audio feed (`tools/editor/src/editor_tools.*`), picking geometry
  (`pick.cpp`), the reflected fields the AI edits, and what Save writes.
- `editor_autotest` and `editor_autotest_welcome` (ctest, need a display: `xvfb-run` on Linux): the real editor window. The autotest
  clicks the viewport and the View menu with injected mouse events, edits through Console commands, checks undo and redo, saved
  files, play / pause / step / stop, keyboard input reaching the game and a scripted AI session after every action, and saves window
  screenshots (`FA_EDITOR_AUTOTEST_OUT=<dir>`).
  Run it with `FA_EDITOR_AUTOTEST=1 xvfb-run -a -s "-screen 0 1600x900x24" build/dev/tools/editor/fa_editor_autotest`.
