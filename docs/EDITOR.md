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

The window title names the engine version and the open project, `FactorIA 0.1.3 — My Game` (just `FactorIA 0.1.3` on
the Open or create a project dialog). The version is the one `factoria version` prints.

## Updates

The downloaded editor checks GitHub Releases when it opens. When a newer version is out, the **FactorIA update**
window shows the release notes of every version newer than yours and blocks the editor until you choose: **Update**
downloads it, replaces the files next to `factoria` and reopens the editor on the open project; **Not now** keeps this
version until the next start. Builds from source never check (they have no `FA_UPDATE_REPO`), and neither does the
Linux AppImage (a read-only mount: download the newer one). Details:
[GETTING_STARTED.md, Updates](GETTING_STARTED.md#updates).

**Updated on disk.** Files copied over the installation without the updater leave the running editor on the old code. The
editor looks at its own `factoria` file (size and modification time) every 5 seconds and when its window gets focus, and
once the file has changed it reads the build identity (version and commit fingerprint) written in it. If that is another
build than the one running, a notice appears at the bottom of the window, and the editor stays usable:

> FactorIA was updated on disk (0.3.0 build f530fda3e543 -> 0.4.0 build 1a2b3c4d5e6f). Restart the editor to use it.

**Restart** quits (the unsaved-changes dialog still asks) and reopens the editor on the same project, the way the updater
does; the chats of the AI Assistant (`.factoria/ai/chats/`) come back with their tabs. **Not now** hides the notice until the
file changes again. Restart is off, with the reason in its tooltip, while an AI run is in progress (or a worker still runs),
a play session runs, an export or a Set Up This Computer install runs, or a keystore is being created: nothing is stopped
silently. A rebuild of the same commit, a file with no identity (a build outside git) or an unreadable file never shows the
notice. The AI can ask with the read-only command `engine.update_status` (`running`, `onDisk`, `restartDue`, and under `editor`
whether the notice shows and what blocks Restart). While the updater above installs a release, this notice stays quiet.

## Layout

The AI builds the game, so the window (maximized on Windows) is the game view and the AI chat: **Hierarchy** over **Inspector** on the left,
the **Viewport** in the middle, **AI Assistant** on the right, and Console / Project / Engine Feedback / Audio / Profiler as tabs
under the view. You can also edit by hand with the Hierarchy and the Inspector, by dragging gizmos in the Viewport (below) and by
dragging files from the Project panel ([Project panel](#project-panel)). Use Undo to take back what it or you did. View > Reset layout restores this layout.

The editor keeps your layout in `~/.factoria/editor_layout2.ini`: where panels sit, their sizes, floating panels, tabs moved to
another dock, and which panels are open (a panel closed with its X, or one opened from the View menu, stays that way). It is
written a few seconds after a change and again when the editor closes or another project opens, and read when the editor starts,
so the layout is the same after reopening the editor or switching project. Reset layout also reopens the default panels (Audio and
Profiler stay closed). Two editors open at once share the file: the last one to close writes it.

| Panel | What it does |
|---|---|
| Toolbar | Play, Pause, Step, Stop; Save, Reload, Validate, Screenshot, Export; Undo, Redo; Select, Move, Rotate, Scale (the gizmo mode, see [Gizmos](#gizmos); shown only while an entity is selected, the Q W E R keys work regardless). Screenshot saves a PNG into the hidden `.factoria/screenshots/` of the project; its toast has a **Show in Finder / Explorer / file manager** button (the toast stays longer and does not vanish while the mouse is over it), and File > Open Screenshots Folder opens the folder (creating it if missing). The F9 mark screenshots of a play session go into the play session's own folder and are read by the AI panel's Attach last play session. |
| Hierarchy | The entity tree: select, drag to reparent, right-click for create / duplicate / rename / active / delete, search by name or id. |
| Inspector | The selected entity's components, one widget per field, Add Component. |
| Viewport | The game as the engine renders it (post-effects such as `Camera.bloom` and `Camera.colorFilter` included). Click an entity to select it: the selection outline shows what you point at; the gizmos move, rotate and scale it ([Gizmos](#gizmos)). Its title shows the mode, game size and zoom (`EDIT  1280x720  50%`); Play focuses it, so keys reach the game without a click (unless you are typing in another panel). |
| AI Assistant | The built-in agent: describe what to build or change (see AI_PROVIDERS.md for the providers). |
| Project | The project's files: folder tree, filter, search, thumbnails; drag files onto the Inspector and the Viewport ([Project panel](#project-panel)). |
| Console | The log (each line starts with the computer's local time `HH:MM:SS.mmm`; hover it for the date, the frame and the seconds since start), and a command line: `name {json}` runs a command, `> code` runs JavaScript, `help` lists commands. |
| Engine Feedback | The project's `ENGINE_FEEDBACK.json`: what the AI found missing in the engine. Opening the project moves its closed entries to `ENGINE_FEEDBACK.archive.json`; "Show archive" lists them again and "Archive closed" moves them on demand. |
| Audio | (View > Audio) the live `audio.log`. |
| Profiler | (View > Profiler) where the time of a frame goes while the game plays. |

Play snapshots the scene and runs the game; Stop restores the snapshot, so edits made while playing are temporary. For that
reason the AI works in edit mode only: while the game runs (Play or Pause) its Run button is disabled ("game running: Stop it
to send"), and while it is working Play and Step are disabled until it finishes or you press Stop in the AI panel. The Console
still runs commands during play, to inspect or poke the running game. Ctrl+Z / Ctrl+Y
(toolbar and Edit menu too) undo and redo scene edits: the ones made by the AI and by commands typed in the Console. Undo does
not touch files; to take back a whole AI run, scripts included, use Revert ([Revert an AI run](#revert-an-ai-run)). View >
Show navmesh draws the walkable cells of every NavMesh3D (green; red where a moving obstacle blocks; blue on a walkable moving body, Collider3D.navWalkable) and its off-mesh links (NavLink3D: a yellow line, with an arrowhead when one-way) (docs/NAVIGATION.md). Show colliders and Selection overlay toggle the collider boxes and the selection outline in the viewport.

**Materials and textures reload live.** The editor watches `materials/`, `shaders/` and `assets/` for the files the renderer
rebuilds in place: a `*.material.json`, a shader snippet (`*.surface.glsl`, which reloads every material that uses it), a
texture, font or model. Save one (the AI with its file tools, or you in your own editor) and the viewport shows it within
a fraction of a second, in edit mode and while the game runs; nothing reloads or resets, and Undo is not involved (these are
files, not scene edits). Scenes, scripts and string tables are not watched by the editor: it manages them itself (the
Reload button, Save, and what the AI's commands change). A broken snippet keeps drawing the last version that compiled
and logs ONE error with `file:line` and the quoted line, once per save: it shows in the Console and in `game.logs` /
`game.state` (`recentLogs`), where the AI reads it, and `renderStats.materialFallbacks` lists a material that never
compiled (it is drawn magenta). Changing a material's `materialParams` is a scene edit like any other: it is undoable.
Compiling a snippet needs sokol-shdc: the factoria downloads carry it next to `factoria`; a factoria built from source
gets it with `factoria setup shaders` ([SHADERS.md](SHADERS.md)). The
[Inspector](#hierarchy-and-inspector) edits a MeshRenderer's `material` and `materialParams` and shows a build error under
the material field.

## Gizmos

Select an entity and drag handles in the Viewport to move, rotate or scale it. While an entity is selected the toolbar
has four buttons (tooltips name the key); the keys work while the Viewport is hovered or focused and no text box has the
keyboard:

| Mode | Key | Handles |
| --- | --- | --- |
| Select | Q | None: a click selects, as always. |
| Move | W (default) | One arrow per WORLD axis (X red, Y green, Z blue only with a perspective camera) and a square at the centre that moves freely (2D: the XY plane; 3D: the plane facing the camera). |
| Rotate | E | 2D (orthographic camera, or a screen-space entity): one ring around Z. 3D: three rings around the entity's LOCAL axes. |
| Scale | R | One handle per LOCAL axis ending in a box, and a centre box for uniform scale. A factor never goes below 0.01, so a drag cannot reach 0 or flip the sign. |

A click on a handle starts a drag and does not change the selection; a click anywhere else selects as before. Handles keep
their size in screen pixels at any zoom and light up under the mouse. **Hold Ctrl (Cmd on macOS) while dragging to snap the value**: move to
whole world units with an orthographic camera and 0.25 with a perspective one, rotate to 15 degrees, scale to 0.1.
**Esc while dragging** puts the start value back and leaves no Undo step. They work for 2D and 3D scenes and for screen-space
(HUD) entities, whose values are design pixels. The gizmo works in world space and writes the entity's LOCAL values, so a
child of a rotated or scaled parent follows the mouse.

Every change is a `scene.set_component` call on `Transform` through the same path as the Inspector: one drag is ONE Undo
step, the scene is marked dirty, Save writes the values, and a value the command refuses stops the drag and shows the
message. Handles are drawn while the game is in edit mode or paused (a paused drag edits the running game, adds no Undo
step and is lost on Stop, like the Inspector); while the game plays there are none, because the input goes to the game.
Not here yet: panning or zooming the view independently of the game camera, selecting several entities, a local/world
axis switch.

## Hierarchy and Inspector

Hand editing uses the commands the AI uses (`scene.set_component`, `scene.set_parent`, `scene.spawn`, `scene.destroy`...), so
every change is an Undo step (a drag is one step), marks the scene dirty, and Save writes it to the scene file. Both panels
are in the View menu.

**Hierarchy.** Roots and children with their names and ids. Click an entity to select it (the viewport outline follows,
and a click in the viewport scrolls the tree to the entity). Drag an entity onto another to make it a child
(`scene.set_parent`: it keeps its place on screen) or onto the empty space under the tree to make it a root; a cycle is
refused with the reason. Right-click: Create empty child, Duplicate (the entity and its children get new ids), Rename,
Active, Move to the top level, Delete (also the Del key). **+** and the right-click menu of the empty space create a
top-level entity. The search box keeps the entities whose name or id contains every word typed.

**Inspector.** One collapsing header per component of the selected entity (hover the header for the component's
description, the x removes it; Transform and EntityInfo stay). One row per field, built from reflection: tick box for
bool, drag for numbers (the field's range limits the drag; click a number to type it), vectors and rects as one drag per
number, a colour picker, a drop-down for enums and for entity references (by id), a text box plus a file list for assets
(only files of the right type), and a multi-line text box for free-form JSON (`Script.props`...) that is applied when you
click away and refuses invalid JSON, showing the parse error. Hover a name for the field's doc string and range. Read-only
fields (the entity id) are disabled and runtime-only state is not shown. A value the command refuses (outside the range)
changes nothing and its message shows under the field. **Add Component** lists the components the entity lacks.

**MeshRenderer.** `material` is a file list of `*.material.json`. `materialParams` is typed by the material's `material.info`:
one widget per param (drag with its `min`/`max`, vectors, a colour picker), an `*` and a **Reset** button when this entity
overrides the default (written with `scene.set_component` and `merge: true`). Under the material field a material that does
not compile shows its error with the snippet's file and line; it disappears when the material builds again. Texture params
of a material are not editable here yet (use the Console or the AI).

**While the game plays** both panels edit the running game; an orange note says the edits are lost on Stop (and they add no
Undo step).

## AI Assistant

The panel holds several conversations as **tabs**: **+** opens an empty chat, the **x** on a tab closes it (the chat stays
in History), and the title is the first message ("New chat" until then). Each tab has its own transcript, input, usage and
attachments; a message in a tab continues that tab's conversation (see `docs/AI_PROVIDERS.md`). Several chats can run at the
same time, up to `limits.maxConcurrentRuns` (default 3, `ai.json`; `docs/AI_COSTS.md`): each has its own agent, live progress,
usage, **Stop** and Revert point (see "Several chats at once" below). A tab with a run shows a `*` before its title. Run is
disabled in a chat that is already running, and in the others once the limit is reached (hover it to see why). **History**
lists the saved chats, newest first; click one to reopen it as a tab (the next message resumes it) or Delete it from the list.

- **Roles:** your messages always go to the orchestrator role, which answers, plans and hands implementation work to
  the worker role, small mechanical edits to the fast role, the art to the artist role and the sound to the audio role
  by itself. The `artCritic` and `reviewer` roles never run unless you ask (see **Reviews** below). **Roles...** at the
  top of the panel picks the provider, model and effort of each of the seven roles (hover it to see the current ones); Save writes them into `ai.json`
  and the next message uses them (see `docs/AI_PROVIDERS.md`, Roles). The **Model** column is a dropdown of the models
  the provider really offers, fetched when the project opens; **Refresh models** asks again (new releases show up), and
  **Other...** types a name that is not listed (see `docs/AI_PROVIDERS.md`, Choosing a model). **Roles...** is disabled
  until `ai.json` has been read. Its **Context** column caps how much of the
  conversation a session keeps (full, or 100k to 800k): past it the earlier part is summarized, so each message costs
  less. It works with Claude Code and the Anthropic API.
- **Reviews:** next to **Roles...**, at the top of the panel, **Review:** has an **Art critique** and a **Game review**
  button (and **Reviews...**, below), then a **Reviewers** count (1 to 5 reviewers, each with a different point of view,
  one after another) and an optional focus ("the shop screen"); a narrow panel moves the count and focus to a line of their
  own. Pressing
  one opens a confirmation (what runs, how many reviewers, the role's model, the focus); **Start** starts read-only
  agents that look at and play the game (they read `REVIEW.md` first) and give an opinion with a score from 0 to 10 and
  sub-scores. Each reviewer works in a chat tab of its own, titled "Art critique" or "Game review", where
  you see what it does. They cost tokens, so nothing starts them but you: the orchestrator cannot. A reviewer is one more run: it counts
  toward the limit of chats at once (`limits.maxConcurrentRuns`), and the orchestrator's chats keep working while it does. The
  buttons are disabled while the game runs (the reviewers start it themselves) or that limit is reached. Stop in the review's
  tab ends the review and the reviewers after it. When a review is ready, the **AI
  reviews** window opens (also from **Reviews...**) with every saved review of the project, newest first, with its score,
  persona and game version, and the text of the selected one. **Send to orchestrator** posts that report as your message
  into the active orchestrator chat (a new one when the active tab is a review's own) so it plans the fixes and delegates
  them; **Copy** puts the text on the clipboard. Nothing is sent unless you press it. The reviews are files in
  `.factoria/ai/reviews/` (`docs/AI_PROVIDERS.md`, Reviews).
- **Pictures:** drop image files (png, jpg, jpeg, gif, webp) on the window, press Ctrl+V in the input with a picture on the
  clipboard, or press **Attach image...**. Pending pictures show above the input (remove one with its x); sent ones show
  in the transcript. Copies live in `.factoria/ai/attachments/`; other file types are refused with a message saying why.
  A big picture (a 4K screenshot) is scaled down to 1568 px on its long side, what the model looks at anyway, so it costs
  fewer tokens and stays under the API's 5 MB limit.
- **Usage** (above the transcript): Session (5h) and Week plan limits with the reset time, the model's Context, Tokens
  and the estimated Cost of the chat. Hover a line for details. Tokens and Cost move while the agent works: every model call
  adds its usage (the worker's too, each agent counted on its own and summed) and the cost is the engine's running estimate
  from its price table until the CLI reports its own total, which replaces it when the agent finishes. Claude Code reports
  a message's output tokens early, so "out" can lag until the end. The plan limits are the last ones the provider reported in
  this run of the editor; Claude Code reports them once per message (after its first model call), so they do not move while
  it works (the tooltip says "As of HH:MM"). `limits.maxCostUsd` / `limits.maxTotalTokens` see the live numbers: a CLI agent
  is stopped as soon as it crosses them.
- **Selection:** the entity selected in the viewport (click it) is named to the AI in each message.
- **Claude Code** runs its own loop in a child process, but its tools are the editor's: the editor serves MCP on a loopback
  port (`http://127.0.0.1:<port>/mcp/<token>`) and the MCP config it writes for the CLI points there. Its tool calls run on
  the editor's main thread like an API provider's, so its edits show in the viewport as it works, each is a Ctrl+Z step,
  and Play waits for it. Codex still uses a `factoria mcp` process of its own (see `docs/AI_PROVIDERS.md`, CLI agents in
  the editor).
- **A run that is going shows its pulse** under the transcript: `running 4 min | last activity 12 s ago | <last thing it
  did>`. A CLI agent's sub-agent (the orchestrator's `ai_run`) streams into the chat as it works, each step indented under
  the `ai_run` call, so a long delegation is not a silent wait.
- **"The agent may be stuck":** after `limits.stuckAfterSeconds` (default 180, `ai.json`, 0 turns it off; `docs/AI_COSTS.md`)
  without any event from the agent, a warning appears with two buttons. **Stop** cancels the run and a worker it started.
  **Check activity** looks, without touching anything, at the agent's CLI process and everything below it (is it alive, CPU
  used over the last seconds, child processes such as a shell command), the tool call it waits for and for how long, the
  files that changed in the project in the last 2 minutes, and its last event. It writes a chat line starting with
  "Activity check:" with a verdict (a plain `Still working: ...` or `Looks stuck: ...`, followed by the evidence) and
  keeps the warning quiet for another `stuckAfterSeconds`. A model thinking for a long time looks like a stuck agent
  (alive, idle, no tool), so the verdict says to press Stop if you do not want to wait. It reads the CPU and process
  list through the operating system (`/proc` on Linux, `libproc` on macOS, the toolhelp snapshot on Windows); where a
  figure is not available the check skips it and still reports the rest. An API provider has no process, so the verdict
  there covers only the tool call, the files and the last event. The panel also stops a run by itself, with a message, when
  the CLI process has disappeared for 10 seconds while the run goes on.
- **Worker still running:** if the orchestrator's turn ends while an `ai_run` is still going (Claude Code cut the call off, for
  example), the panel says "Worker still running: the orchestrator's turn ended, its report will continue the chat" and keeps
  showing the worker's live steps. Play stays blocked. When the worker finishes, its report goes into the chat and the
  editor sends it to the orchestrator as a new message of the same conversation (Claude Code `--resume`), once. **Stop**
  stops the orchestrator and the worker, and sends no continuation.
- Chats are saved in `.factoria/ai/chats/` after each answer and when a tab closes; the open tabs come back when the project opens.

### Several chats at once

Each chat that runs has its own agent thread (and, for Claude Code, its own MCP endpoint), so its transcript, status line,
stuck warning, **Check activity**, usage and **Stop** are the chat's alone: Stop in one tab ends that run and its worker and
leaves the other chats going. A worker that outlives its orchestrator's turn (see above) is also per chat. The commands of all
the runs share the editor's main thread, one after another, and the Undo history gets each command's step in the order they ran.
`limits.maxCostUsd` and `limits.maxTotalTokens` apply to each run on its own; the plan limits (Session, Week) are shared by all
chats, since they are the provider's.

- **Play and the scene:** while any run is going Play waits, and the note names the chats working ("The assistant is changing
  the scene (chat "Add a coin" and "Fix the menu")").
- **The same file in two chats:** when two chats that run at the same time change the same project file (a script, or the open
  scene), both transcripts get an amber note: `Chat "Fix the menu" is running at the same time and also changed
  scripts/menu.js. ...`. The editor sees a file changed through the editor's commands, through Claude Code's own Write / Edit
  tools, and, when a run ends, through the checkpoint (a file a shell command wrote is credited to the run that has no other
  claim on it). Each pair of runs is told once per file. Two runs writing the same
  file is not prevented: the later write wins, and the note is there so you check the result.
- **Revert with several chats:** each run has its own checkpoint, taken when it started. Reverting a run while no other chat's
  run overlapped it works as before (the whole checkpoint goes back). If another chat's run was going at the same time (or ran
  after it), only the files this run changed go back, and the dialog lists the files both runs changed, and names the chats
  still running. **Revert, keep their changes** puts back the files only this run changed and leaves the listed ones, and
  the open scene when the other chat edited it too, as they are now; **Revert including those files** also takes them back to
  how they were before this run, losing the other chat's changes to them. Undo revert of a revert that kept someone's files
  restores only the files that revert wrote. A run saved by an older editor has no start time and is treated as if it ran alone.
  Revert stays disabled in a chat that is running.

### Revert an AI run

Before every run the editor takes a **checkpoint**: a copy of every file of the project (scripts, tests, scenes, assets;
not folders starting with `.`, `node_modules` or a top-level `build/`) plus the open scene as it is in memory. When the
run ends and it changed something, the transcript shows **"This run changed N files"** with a **Revert** button (and the
list of files, and whether the open scene changed). Revert asks for confirmation, then puts every file back, deletes the
files the run created, and puts the scene back as ONE Undo step (Ctrl+Z brings the run's scene back). Scripts are
reloaded. The item then reads "Reverted ..." with an **Undo revert** button, which restores the state the project had just
before the Revert (nothing is lost: Revert makes its own safety checkpoint first). **Edit > Revert Last AI Run** does the
same for the newest run. The button works after a restart too (the item is saved with the chat), and it is available only
in edit mode with no AI run in progress. The next message you send tells the AI that you reverted, so it reads the files
again instead of assuming its changes are still there. Revert covers files, not what lives outside the project folder.
It does not replace git: use git for long-term history.

Checkpoints live in `.factoria/checkpoints/` (each distinct file content is stored once; the newest 30 checkpoints are kept)
and use disk space, mostly for big assets. To clear them, delete that folder; the editor never needs it back. They are
never exported or bundled (folders starting with `.` are skipped), and the template `.gitignore` lists `.factoria/`. The same
engine is available as the commands `checkpoint.create`, `checkpoint.list`, `checkpoint.diff` and `checkpoint.restore`.

## Exporting the game

**Export** in the toolbar (or File > Export Game...) opens the **Export game** window: a button per platform (Windows,
macOS, Linux, Android, iOS, Web) that runs the same export as `factoria export` and the `project.export` command. Each
platform's row says what the export writes, or why it cannot run on this machine (no player built for that OS, no
mobile players or engine checkout, a missing `id`, an output folder that already holds a folder of that name no
export wrote) and how to fix it; for another OS's desktop export, **Choose
player...** picks a `factoria_player` built there. Pick the output folder (default `<project>/build/export`), press a
platform, and the report shows the output folder (**Show in Finder** / Explorer), warnings and next steps. Android and
iOS exports are a Gradle / Xcode project (or, with the Android format APK / AAB, a built app) and the next steps say
how to finish them.

- **Platform settings...** at the top of the window, and a small **Settings...** button on each platform's row, open the
  Platform settings window (below) on that platform's tab.
- **Set up buttons**: a row that cannot run because this computer lacks something FactorIA can install shows the button
  that installs it: **Install Android build tools**, **Download Windows player** (or macOS / Linux: the other OS's
  player), **Download mobile libraries**, **Install CMake**, **Open App Store (Xcode)**. Details:
  [Setting up this computer](#setting-up-this-computer).
- **Android format**: the Android row has a **Format** menu (APK, Android App Bundle, Gradle project only). It saves
  `export.android.format` in `factoria.json` right away, like the AI would, and leaves any other unsaved edit of the
  Platform settings window alone.
- **While it runs**, the window shows the export's progress line and a **Cancel** button; the build output (Gradle can
  take minutes) scrolls below it. A cancelled export says so in the report.
- **The report** names the **Format** and, when the export produced a single file (an APK or AAB), the **Artifact** with
  **Show in Finder** (the file selected in Finder / Explorer) and **Copy path**.
- **Release** makes a release build; hover it to see what changes for each platform (for Android, an APK or AAB signed
  with the keystore of the Android tab).

Details: [EXPORTING.md, From the editor](EXPORTING.md#from-the-editor).

## Setting up this computer

An export needs things that are not part of FactorIA: a JDK and the Android SDK, the players of the other operating
systems, CMake, Xcode. You never install them by hand: File > Set Up This Computer... opens the **Set up this computer**
window, the editor's front for `factoria setup` ([EXPORTING.md, Setting up this computer](EXPORTING.md#setting-up-this-computer)).
It runs the very same code (`fa::setup_install`), so what a button installs is what `factoria setup` and the `setup.install`
command install.

- **The window** lists the components (the AppImage tools of a Linux export and the shader compiler, which the downloads carry and a source build gets, are installed with `factoria setup appimage` and `factoria setup shaders`, not from here yet; **Visual Studio Code debugger** copies the FactorIA extension into VS Code in one click, so F5 in a project debugs its scripts: [DEBUGGING.md](DEBUGGING.md)), each with its state (**Installed**, **Partly installed**, **Not installed**,
  **Not needed here**), what was found, the paths, what is missing and how big the download is, and one button:
  **Install** (or **Reinstall** when it is installed already), or **Open App Store** for Xcode, which a program cannot
  install. **Show in Finder** opens the folder everything is installed into (`~/.factoria`, or `$FACTORIA_HOME`); **Check
  again** looks at the computer again (it never downloads anything). Nothing is downloaded until you press a button, and
  nothing needs an administrator password, `PATH` or the registry.
- **While it runs** (on its own thread; the editor keeps working) the window shows what it is doing, a progress bar with the
  percentage of the download, **Cancel** (it stops the download and installs nothing half-way) and a collapsible **Log**.
  When it finishes you get a toast, and the window shows the report: what was installed, warnings, the numbered next steps
  (**Copy report** copies it), or the error and how to fix it. The Export window's rows and this window read the computer
  again by themselves.
- **Set up buttons where the problem shows up**: the Export window's rows and the Platform settings tabs offer the setup
  that fixes what the row says is missing, in plain words: **Install Android build tools** (no JDK 17+ or Android SDK),
  **Download Windows / macOS / Linux player** (another OS's player), **Download mobile libraries** (prebuilt Android/iOS
  without the engine source), **Install CMake** and **Open App Store (Xcode)** (the iOS row, also when it is ready: the
  Xcode project it writes needs both). A row that is ready, or not ready for a reason a setup cannot fix (a missing `id`,
  a folder in the way), shows none. Platform settings > General has **Set Up This Computer...**.
- **The Android SDK license** is a legal agreement between you and Google, so **Install Android build tools** (here and in
  the window) first opens a dialog with the full license text in a scrollable box. **I accept** stays disabled until you
  tick **I have read the license above and I accept it**; **Decline** closes the dialog and installs nothing. Only
  **I accept** starts the install (with the license accepted); FactorIA never accepts it for you, and nothing is
  downloaded before. If the text cannot be loaded (no network) the dialog says so and offers **Try again**.
- **The home folder is also yours to inspect**: `~/.factoria/android`, `players/<version>`, `tools/cmake`; remove a
  folder to uninstall it.

## Platform settings

File > Platform Settings... opens the window that edits what an export needs besides the game: the icon and, per
platform, the fields of its app (see [EXPORTING.md, Platform settings](EXPORTING.md#platform-settings) for what each
field does). It is a form over exactly what `factoria.json` holds in `icon` and `export` (and `~/.factoria/export.json`
for This computer), checked by the same code `factoria validate` and the export use, so what you can enter here is what
the AI can write in the file and the reverse.

- **Tabs**: **General** (the game icon, and the game's own name, id, version, orientation and resolution, read-only:
  ask the AI or edit `factoria.json` to change those), **Windows**, **macOS** (category menu, minimum macOS version,
  copyright), **Linux** (the `.desktop` categories, added from a menu or typed), **Android** (format, version code,
  minSdk / targetSdk, permissions, adaptive icon, signing, and This computer) and **iOS** (icon background colour,
  Team ID, build number). A field left empty uses the default, and its box shows what that default is.
- **Icons** have a preview next to the path, **Choose...** and **Clear**, and a line that says what the file is
  (`1024 x 1024 px`) or what is wrong with it (not found, not an image, not square, too small, in a folder the export
  does not ship such as `build/`). A platform's own icon falls back to the game icon and says so. A picture chosen from
  outside the project is copied into `<project>/assets/` (icons must be inside the project) and the setting names the
  copy; a different file that already has that name gets `-2`, `-3`... and nothing is overwritten.
- **Save / Revert**: the window edits a working copy. **Save** writes `factoria.json` (only `icon` and `export`: every
  other key, the order and the formatting stay as they are) and, if you changed it, `~/.factoria/export.json`. **Revert**
  reads both files again. Fields with a wrong value are marked in red with the error and the fix; Save waits until they
  are fixed. Closing the window with unsaved edits asks: **Save and close**, **Discard** or **Keep editing**; opening
  another project drops them. If `factoria.json` changes on disk (the AI wrote it, or you did), the window reads it again by
  itself, or, when you have unsaved edits, asks whether to **Reload** or **Keep my edits**. A hand-edited file with wrong
  values still opens: the errors are listed at the top and the fields show what could be read.
- **Android signing**: the keystore file (project-relative or absolute) with **Choose...**, the key alias, and the
  passwords' status (set by the `FACTORIA_ANDROID_KEYSTORE_PASSWORD` / `FACTORIA_ANDROID_KEY_PASSWORD` environment
  variables, saved on this computer, or not set: the password itself is never shown). A release build without a
  keystore fails (an app signed with the debug key is one Google Play rejects); to try one on a phone with the debug key,
  export from the command line with `--allow-debug-key`.
- **Create keystore...** makes a signing key with the JDK's `keytool` (a PKCS12 keystore with one key valid for about 27
  years; the password is handed to `keytool` through its environment, never as an argument): choose the file (default
  `keys/upload.keystore`), alias, password, your name or studio, and optionally organization and country. It can keep
  the password on this computer and add the keystore to `.gitignore`. The new keystore fills the signing fields (press
  **Save** to keep them). Back up the file and its password: Google Play needs the same key for every update of the app.
- **This computer** (Android tab; saved in `~/.factoria/export.json`, never in the project): the JDK and Android SDK
  folders (empty = look for them), what was found or what is missing and how to install it (**Check again** after
  installing; or **Install Android build tools**, which installs them for you), and **Remember them on this computer** for the signing passwords. Without it the passwords are not kept
  anywhere: set the environment variables when you build a release.

## Selecting things

Clicking in the viewport selects the entity under the cursor; the selection is how you point at something ("make this one bigger").
The outline of the selected entity comes from the engine's own geometry (`fa/scene/bounds.h`), the code behind
`entity.bounds()` in scripts, so what the editor outlines is what a script measures:

- a **Sprite** or **Shape2D** is its size box placed by `pivot` (a triangle with pivot `[0.5, 0.3333]` keeps its whole box around
  the entity); a **diamond** is outlined by its size box and, thinner, by its four tips; **Text** by the laid-out text box;
  a **Tilemap** by its rows (or `width` x `height`) times `tileSize`, from its top-left corner (an isometric one by the box around its diamonds and the tile images; the editor has no tile painting tool, `tilemap.set_tile` and `scene.import_ascii` write the tiles);
- **rotation and scale** are applied: the outline and the click area are the turned box, not the box around it;
- an entity with several visuals (a Sprite and a Text) is selectable on any of them, the highest `layer` wins;
- **screen-space** items (`space: "screen"`, the HUD) are outlined and picked on the screen with their `anchor`, which
  `entity.bounds()` does not do (it returns `null` for them);
- entities that draw nothing get a small handle, colliders their collider box.

While the game runs, clicks and keys go to the game instead (click the viewport to give it the keyboard).

## Scene files rebuilt on disk

A command that rebuilds the scene file that is open (`scene.import_ascii` with `path` set to it, or `scene.ascii_edit` on the level
file that builds it, from the AI or the Console) is followed by a reload, so the viewport shows the result. Whatever was on screen
before is one Ctrl+Z away, and commands that only write files (`prefab.save`, `scene.format`, `scene.ascii_edit`,
`scene.import_ascii` with `path`) neither take an undo step nor mark the scene as changed.

## View > Audio
The Audio panel shows `audio.log`: sequence number, frame, clip path, bus, volume, the entity that played it (`source`) and whether the
clip loaded. While the game runs it asks only for plays newer than the last one it saw (`after`). **Filter by path**, **Failed only**
and **Clear** keep it readable; a clip that failed to load (`ok: false`) is highlighted in red, because a wrong path is silent in the
game itself.

## View > Profiler
While the game plays (Play), the Profiler panel shows a graph of the last frames, the milliseconds each engine system takes
(physics, scriptsUpdate, render...), a table of script behaviour classes sorted by milliseconds per frame (with the script
path and calls per frame), the GPU time, and memory (process, JavaScript heap, textures, audio, entities). Numbers are smoothed
over a few frames. The GPU shows `n/a` with the reason where the graphics backend has no timer queries (PERFORMANCE.md,
"Finding what is slow"). The profiler only runs while the panel is open or a play session records, so a closed panel costs
nothing. Edit mode shows nothing: nothing runs.

## Play sessions

Every Play .. Stop is recorded, so the AI can see what you saw. Nothing to switch on.

- **While you play**: the editor records (with the engine's `input.record` recorder, docs/DEBUGGING.md "Recording and replaying input") the input it feeds the game, the frame times, and the warnings and errors that are logged.
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
- **For AIs and tools**: `play.sessions` lists the recent sessions, `play.report` returns one (the latest by default) with the replay path and a `profile` section: where the time went over the session (per engine system, per script behaviour class, GPU, memory; PERFORMANCE.md).
  The report says how to replay it: `factoria run --headless --frames <n> --input .factoria/sessions/<name>/input.json`.

## Project panel

View > Project (a tab next to Console; the View menu reopens it). A folder tree on the left (**Project** is every file; hidden
folders, `build`, `node_modules`, `dist` and `export` are left out) and the files on the right: a thumbnail for pictures, a
badge (`WAV`, `JS`, `SCN`, `PFB`, `MAT`...) for the rest. Hover a file for its path, type and size.

- **Type filter** (all, texture, audio, font, mesh, script, scene, prefab, material; the same types as `assets.list` and the
  Inspector's file lists, one classifier: `asset_type_of`) and **search** (case-insensitive part of the path; a search looks
  through the whole project, not only the chosen folder). **Sort** by name, type or size.
- The listing is cached: the panel does not read the disk every frame. It reads again on **Refresh**, when you click into the
  panel and after the editor itself writes or deletes a file (a command that changes files, such as `fs.write`, `fs.delete`,
  `prefab.save` or `scene.save`, from you, the Console or the AI; or Save). A file another program adds shows up on Refresh.
- **Drag a file** (the payload `FA_ASSET` is its project-relative path). Onto an Inspector file field: only a file of the field's
  type is taken (a picture on `Sprite.texture`; a sound there is refused) and it is written like picking it from the list.
  Onto the Viewport: a `.prefab.json` is spawned with `scene.spawn {prefab, position}` and the new entity is selected (one Undo
  step). The position is the world point under the mouse: in 2D on the z = 0 plane; in 3D where the mouse ray meets the
  ground plane (y = 0), and 10 units in front of the camera when it misses it (the ray points up or the ground is farther than
  1000 units). Other types do nothing on the Viewport (the tooltip says only prefabs).
- **Double-click** a `.scene.json` to open it (with the same "Unsaved changes" question as File > Open Scene).
- **Right-click** a file: **Show in Finder** (Explorer, file manager), **Copy path**, **Delete...** (asks first, then `fs.delete`;
  it is not an Undo step, the file is gone from disk).

## Testing the editor

- `fa_test_editor` (ctest `editor`): the GPU-free logic: the Audio feed and the Profiler view (`tools/editor/src/editor_tools.*`), picking geometry
  (`pick.cpp`), the Project panel's tree, filter and sort (`project_browser_model.*`), the reflected fields the AI edits, what Save writes, the window title, and the Export window's logic
  (`export_job.*`: the options each platform's button exports with, the rows' checks, the export on its worker thread, its
  progress lines and cancelling), the Platform settings window's logic (`platform_settings.*`: the working copy, Save and
  Revert, validation, icons, the Android toolchain, the keystore command and creation) and the Set Up This Computer window's
  logic (`setup_job.*`: which setup fixes which Export row, an install on its worker thread with its progress, cancelling,
  the license loader and the cached status), all with an injected `fa::SetupContext` (a fake downloader and process runner and
  a temporary home): no test touches the network or your `~/.factoria`.
- `editor_autotest_1` to `editor_autotest_4` and `editor_autotest_welcome` (ctest, need a display: `xvfb-run` on Linux, the desktop session on macOS and Windows; on Windows a screen of at least 1600x900): the real editor window. The autotest
  clicks the viewport and the View menu with injected mouse events, edits through Console commands, checks undo and redo, saved
  files, play / pause / step / stop, keyboard input reaching the game, a scripted AI session, and the fake Claude Code of the AI
  tests (`tools/ai/tests/fixtures`, needs curl) editing the scene through the editor's MCP endpoint, the Export window
  (it exports the game for the machine it runs on and checks the report) and the Platform settings window (tabs, edits,
  Save / Revert, closing with unsaved changes, the Create keystore window) and the Set Up This Computer window (it lists
  the five components, the Export rows show the right Set up button, a setup that cannot download shows its report, "I accept" of
  the Android license waits for its checkbox) and the Project panel (filter, search, a prefab dropped on the Viewport and Ctrl+Z, a picture dropped on a texture field, Delete) and a custom material (needs sokol-shdc, `SOKOL_SHDC`; without it that part records a SKIP, or fails with `FA_REQUIRE_SHDC=1` as on CI):
  a `materialParams` edit from the Console changes the viewport and Undo brings the picture back, a snippet rewritten on disk
  changes it without a reload (in edit mode and while playing), and a broken snippet keeps the last picture and logs one
  error with `file:line` that `game.logs` returns. The autotest keeps this computer's settings in
  `<FA_EDITOR_AUTOTEST_OUT>/export_config.json` (`FACTORIA_EXPORT_CONFIG`) and its `FACTORIA_HOME` in
  `<FA_EDITOR_AUTOTEST_OUT>/factoria_home`, never in your `~/.factoria`. **It never installs anything**: its setup context
  can neither download nor run a program, and no step presses "I accept". It checks the window title and the result after
  every action and saves window screenshots (`FA_EDITOR_AUTOTEST_OUT=<dir>`). A click only lands on a widget whose centre is
  shown in its window (a widget scrolled out of view, even half, fails the check instead of hitting what is under it), and a
  watchdog thread ends the process with exit code 86 when the editor draws no frame for 60 seconds, so a stuck GPU or UI call
  can never freeze the window for good. While it runs the editor ignores the real mouse, keyboard and focus changes (using
  the computer or switching apps does not disturb it). On macOS its window stays above the others (a covered window
  draws nothing to take a screenshot of) but out of your way: see-through, without a Dock icon, clicks reach the windows
  below and the app you were using keeps the keyboard, so you can go on working while ctest runs it.
  `FA_EDITOR_AUTOTEST_SHOW=1` shows the window, to watch a run. `FA_EDITOR_AUTOTEST_SIZE=1024x642` runs it in a smaller
  window, the size of the macOS CI runner's display.
  A manual end-to-end check of the CMake button: `FA_EDITOR_AUTOTEST_REAL_CMAKE=1` makes the autotest run one script only: it
  presses **Install** of the CMake component and lets it download and unpack the real CMake (about 50 MB from Kitware) into
  the autotest's own `factoria_home`; ctest never sets it.
  Run it with `FA_EDITOR_AUTOTEST=1 xvfb-run -a -s "-screen 0 1600x900x24" build/dev/tools/editor/fa_editor_autotest`
  (macOS: `FA_EDITOR_AUTOTEST=1 build/macos-debug/tools/editor/fa_editor_autotest`; Windows: set `FA_EDITOR_AUTOTEST=1` and run `fa_editor_autotest.exe` from the repository root; `FA_EDITOR_AUTOTEST=welcome` for the other).
  The process exits with 1 if any check failed (`autotest_result.json` lists them). ctest splits the autotest into four
  entries (`editor_autotest_1` to `_4`, a few sections each, see below) that `ctest -j` runs at the same time, each in its
  own window, temp project and output folder (`<build>/test-output/editor/autotest_<n>`).

The AI's commands run on the editor's main thread, but never for long at a time: queued commands share about 10 ms per frame, and `game.step` with many frames and `project.test` run in slices (frames / one test file per UI frame) so the window stays responsive while the AI works. The results are the same as a single call.

### Run only some sections

The autotest is a list of sections, each a letter (`tools/editor/src/autotest_sections.h`): S (the start: select, edit, undo,
play, AI marshaling, viewport click and keys), T (toolbar Screenshot and its Show-in-file-manager toast button), A (Audio panel), A2 (Profiler panel), B (commands that
rebuild the open scene file), C (pick bounds and the selection outline), D (bloom), E (Ctrl+V into the AI input), F (AI text:
wrapping, right-click menu), G (delete a project), H (Export window), I (Platform settings), J (Set Up This Computer), K
(custom material), L (hand editing in the Hierarchy and the Inspector), M (transform gizmos), N (Project panel), O (the CLI
agent through the MCP endpoint), P (revert an AI run), Q (the AI panel while an agent is silent or a worker outlives the orchestrator's turn:
the stuck warning, Check activity, the detached worker and its single continuation), R (a program updated on disk: the Restart notice,
its button state and Not now), U (the layout: a floated panel, a moved tab, a wider column and a closed panel survive reopening the project and a visit to the welcome screen; Reset layout), V (AI reviews: the buttons, a read-only reviewer, the saved report, Send to orchestrator) and W (two AI chats at once against a scripted model: both finish with their own answers, the
same-file warning in both, the third chat held back by `maxConcurrentRuns`, Revert of one run keeping the other's files, Stop of one run). While you work on one part of the editor, run only the sections that cover it:

```bash
FA_EDITOR_AUTOTEST=1 FA_EDITOR_AUTOTEST_SECTIONS=K,M build/macos-debug/tools/editor/fa_editor_autotest
```

The ids are separated by commas or spaces, in any case; an unknown one stops the run before a window opens, with the list of
sections. Every section starts from the same state: the clean 2D fixture as the open scene (no unsaved changes, no undo
history), the autotest's windows closed, `factoria.json` as it was, the mouse parked. So a section passes or fails alone as it
does in the full run, whatever the sections before it did. `FA_EDITOR_AUTOTEST=1` without `FA_EDITOR_AUTOTEST_SECTIONS` still
runs all of them in one window.

At the end the autotest prints what each section cost (frames, seconds, failures) and writes the same list under `sections`
in `autotest_result.json`. The ctest entries group the sections by those frames, about the same number per entry; E, F and N
share one because they use the system clipboard. A new section goes in `kAutotestSections` and in one of the
`editor_autotest_entries` of `tools/editor/CMakeLists.txt`: configuring fails if a section is in no entry or in two.

A few sections are for iterating only: before a push, build every target and run the full `ctest` (every
`editor_autotest_*` entry), as for any other change.
