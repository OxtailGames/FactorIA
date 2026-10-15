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

## Updates

The downloaded editor checks GitHub Releases when it opens. When a newer version is out, the **FactorIA update**
window shows the release notes of every version newer than yours and blocks the editor until you choose: **Update**
downloads it, replaces the files next to `factoria` and reopens the editor on the open project; **Not now** keeps this
version until the next start. Builds from source never check (they have no `FA_UPDATE_REPO`), and neither does the
Linux AppImage (a read-only mount: download the newer one). Details:
[GETTING_STARTED.md, Updates](GETTING_STARTED.md#updates).

## Layout

The AI builds the game, so the window (maximized on Windows) is the game view and the AI chat: **Viewport** on the left, **AI Assistant** on the
right, and Console / Engine Feedback / Audio as tabs under the view. There is no panel for editing by hand (no entity tree,
property editor or asset browser, and nothing moves by dragging): describe the change to the AI, and use Undo to take back
what it did. View > Reset layout restores this layout (`~/.factoria/editor_layout2.ini` keeps yours).

| Panel | What it does |
|---|---|
| Toolbar | Play, Pause, Step, Stop; Save, Reload, Validate, Screenshot; Undo, Redo. |
| Viewport | The game as the engine renders it (post-effects such as `Camera.bloom` included). Click an entity to select it: the selection outline shows what you point at. Its title shows the mode, game size and zoom (`EDIT  1280x720  50%`); Play focuses it, so keys reach the game without a click (unless you are typing in another panel). |
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
  and the next message uses them (see `docs/AI_PROVIDERS.md`, Roles). The **Model** column is a dropdown of the models
  the provider really offers, fetched when the project opens; **Refresh models** asks again (new releases show up), and
  **Other...** types a name that is not listed (see `docs/AI_PROVIDERS.md`, Choosing a model). **Roles...** is disabled
  until `ai.json` has been read. Its **Context** column caps how much of the
  conversation a session keeps (full, or 100k to 800k): past it the earlier part is summarized, so each message costs
  less. It works with Claude Code and the Anthropic API.
- **Pictures:** drop image files (png, jpg, jpeg, gif, webp) on the window, press Ctrl+V in the input with a picture on the
  clipboard, or press **Attach image...**. Pending pictures show above the input (remove one with its x); sent ones show
  in the transcript. Copies live in `.factoria/ai/attachments/`; other file types are refused with a message saying why.
  A big picture (a 4K screenshot) is scaled down to 1568 px on its long side, what the model looks at anyway, so it costs
  fewer tokens and stays under the API's 5 MB limit.
- **Usage** (above the transcript): Session (5h) and Week plan limits with the reset time, the model's Context, Tokens
  and the estimated Cost of the chat. Hover a line for details. The limits are the last ones the provider reported in
  this run of the editor; they show after the first message.
- **Selection:** the entity selected in the viewport (click it) is named to the AI in each message.
- **Claude Code** runs its own loop in a child process, but its tools are the editor's: the editor serves MCP on a loopback
  port (`http://127.0.0.1:<port>/mcp/<token>`) and the MCP config it writes for the CLI points there. Its tool calls run on
  the editor's main thread like an API provider's, so its edits show in the viewport as it works, each is a Ctrl+Z step,
  and Play waits for it. Codex still uses a `factoria mcp` process of its own (see `docs/AI_PROVIDERS.md`, CLI agents in
  the editor).
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

## Play sessions

Every Play .. Stop is recorded, so the AI can see what you saw. Nothing to switch on.

- **While you play**: the editor records the input it feeds the game, the frame times, and the warnings and errors that are logged.
- **F9 marks a problem** (the toolbar shows "F9 marks a problem" while the game runs). The game pauses on that frame, a screenshot is taken
  and a small window asks for a one-line note. **Enter** saves the mark and the game continues; **Esc** discards it.
- **On Stop** the session is written to `.factoria/sessions/<yyyymmdd-hhmmss>/`:
  `session.json` (scene, duration, frames, frame time avg/p95/max and frames over 16.7 / 33 ms, the 10 slowest frames with entity count and
  render stats, warnings/errors, marks), `input.json` (the input in the replay format of `factoria run --headless --input`) and
  `mark-<n>.png`. Frame numbers are the same in all of them. `input.json` also keeps each frame's time and fixed-step count (`timing`), so the
  headless replay runs the very same frames: it is exact even when the editor ran slower or faster than the fixed rate. Mouse wheel and typed
  text are not recorded.
- **Tell the AI**: after Stop, if the session has marks or errors, the AI Assistant panel shows a line with an **Attach** button. The
  **Attach last play session** button next to **Attach image...** does the same at any time: it adds a short summary (performance, errors, your
  notes) to the message and the mark screenshots as pictures.
- **For AIs and tools**: `play.sessions` lists the recent sessions, `play.report` returns one (the latest by default) with the replay path.
  The report says how to replay it: `factoria run --headless --frames <n> --input .factoria/sessions/<name>/input.json`.

## Testing the editor

- `fa_test_editor` (ctest `editor`): the GPU-free logic: the Audio feed (`tools/editor/src/editor_tools.*`), picking geometry
  (`pick.cpp`), the reflected fields the AI edits, and what Save writes.
- `editor_autotest` and `editor_autotest_welcome` (ctest, need a display: `xvfb-run` on Linux, the desktop session on macOS; not
  registered on Windows, which has no window read-back for the screenshots yet): the real editor window. The autotest
  clicks the viewport and the View menu with injected mouse events, edits through Console commands, checks undo and redo, saved
  files, play / pause / step / stop, keyboard input reaching the game, a scripted AI session, and the fake Claude Code of the AI
  tests (`tools/ai/tests/fixtures`, needs curl) editing the scene through the editor's MCP endpoint. It checks the result after
  every action and saves window screenshots (`FA_EDITOR_AUTOTEST_OUT=<dir>`).
  Run it with `FA_EDITOR_AUTOTEST=1 xvfb-run -a -s "-screen 0 1600x900x24" build/dev/tools/editor/fa_editor_autotest`
  (macOS: `FA_EDITOR_AUTOTEST=1 build/macos-debug/tools/editor/fa_editor_autotest`; `FA_EDITOR_AUTOTEST=welcome` for the other).
  The process exits with 1 if any check failed (`autotest_result.json` lists them).

The AI's commands run on the editor's main thread, but never for long at a time: queued commands share about 10 ms per frame, and `game.step` with many frames and `project.test` run in slices (frames / one test file per UI frame) so the window stays responsive while the AI works. The results are the same as a single call.
