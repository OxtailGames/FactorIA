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
are listed by name under the path; hover one to see its path.

The recent list (up to 8, most recent first) lives in `~/.factoria/editor_recent.json`, outside the engine's install
folder, so it survives updates and reinstalls. The editor reads it once when it starts, even when it starts straight on
a project (`factoria editor <dir>`, the restart after an update). Every time a project opens, the editor re-reads the
file, puts that project first and writes the merge, so it never drops entries it did not show and two editors open at
once do not erase each other's history. Paths are compared normalised (absolute, no trailing slash), so one project is
listed once. A project whose folder has no `factoria.json` any more (deleted, or on a drive that is not mounted) is
hidden from the dialog and from File > Recent Projects but stays in the file, and shows again when the folder comes back.
When the list is full, such missing projects are the first to go, so they never push out projects that are still
there. Otherwise only **Delete...** in the dialog removes a project from the list. The autotest never reads or writes the file.

The window title names the engine version and the open project, `FactorIA 0.1.3 — My Game` (just `FactorIA 0.1.3` on
the Open or create a project dialog). The version is the one `factoria version` prints; the right end of the menu bar
shows it too on Windows and Linux (`FactorIA 0.8.1`; hover it for the build fingerprint), and on macOS **FactorIA > About
FactorIA** shows it with the build fingerprint.

## The menu bar

On **Windows and Linux** the menus (File, Edit, View, Play, AI, Help) are a bar at the top of the editor window, with a
clickable **Export Game** item after Help and the engine version at the right end.

On **macOS** they are in the Mac's own menu bar at the top of the screen, like any Mac app, and the window has no bar of
its own:

- **FactorIA** (the app menu): **About FactorIA** (the engine version and the build fingerprint), **Settings...**
  (Cmd+, opens AI Settings), Services, **Hide FactorIA** (Cmd+H), Hide Others, Show All and **Quit FactorIA** (Cmd+Q;
  the unsaved-changes dialog still asks). Quit is not in File on a Mac.
- **File, Edit, View, Play, AI** and **Help** have the same items as on the other systems. **Export** is a menu of its own
  (a system menu bar cannot hold a clickable item) with **Export Game...** (Cmd+E). **Window** (Minimize Cmd+M, Zoom) comes
  before Help. The version text of the in-window bar is not there: About and the window title show it.
- Shortcuts are the Mac's: Cmd+S saves the scene, Cmd+Z undoes, Cmd+Shift+Z redoes (Ctrl+S, Ctrl+Z and Ctrl+Y on the
  other systems). They work with the menus closed, and while a text box (the AI message, a name in the Inspector) has the
  keyboard they go to the box instead, so Cmd+Z undoes your typing and not the scene.
- A click on a menu item does its work at the start of the next editor frame, never inside the system's menu event.
  Hovering an item shows the same tooltips as the in-window bar. **Open Scene** and **Recent Projects** are read only
  when you open them.

`FA_EDITOR_NATIVE_MENU=0` makes the macOS editor draw the in-window bar instead, as on the other systems (the editor
autotest does this by itself: it clicks the bar with injected mouse events).

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
silently. The editor starts again through the launcher you pinned, so the Dock or taskbar keeps one FactorIA icon: on macOS
a helper waits until the old editor has quit and then runs `open ~/Applications/FactorIA.app --args <project>` (no `--args` on
the start screen), so the new editor takes the pinned Dock icon (a second instance started while the old one is still
quitting would get an icon of its own), when that app is the launcher of this `factoria`
(`factoria setup launcher`; the editor rewrites an older one at start), also when a newer FactorIA installed over the running editor wrote it, on Windows `FactorIA-Editor.exe` next to
`factoria.exe` (also with no project open); on Linux the `.desktop` entry's `StartupWMClass=FactorIA` groups the new window with it. With no such
launcher (a development build, a launcher of another `factoria`) or if starting it fails, it runs `factoria editor <project>`
directly. A rebuild of the same commit, a file with no identity (a build outside git) or an unreadable file never shows the
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
| Toolbar | Play, Pause, Step, Stop; Save, Reload, Validate, Screenshot; Undo, Redo; Select, Move, Rotate, Scale (the gizmo mode, see [Gizmos](#gizmos); shown only while an entity is selected, the Q W E R keys work regardless). Screenshot saves a PNG into the hidden `.factoria/screenshots/` of the project; its toast has a **Show in Finder / Explorer / file manager** button (the toast stays longer and does not vanish while the mouse is over it), and File > Open Screenshots Folder opens the folder (creating it if missing). The F9 mark screenshots of a play session go into the play session's own folder and are read by the AI panel's Attach last play session. |
| Hierarchy | The entity tree: select, drag to reparent, right-click for create / duplicate / rename / active / delete, search by name or id. |
| Inspector | The selected entity's components, one widget per field, Add Component. |
| Viewport | The game as the engine renders it (post-effects such as `Camera.bloom` and `Camera.colorFilter` included). Click an entity to select it: the selection outline shows what you point at; the gizmos move, rotate and scale it ([Gizmos](#gizmos)). Its title shows the mode, game size and zoom (`EDIT  1280x720  50%`); Play focuses it, so keys reach the game without a click (unless you are typing in another panel). |
| AI Assistant | The built-in agent: describe what to build or change (see AI_PROVIDERS.md for the providers). |
| Project | The project's files: folder tree, filter, search, thumbnails; drag files onto the Inspector and the Viewport ([Project panel](#project-panel)). |
| Console | The log (each line starts with the computer's local time `HH:MM:SS.mmm`; hover it for the date, the frame and the seconds since start), and a command line: `name {json}` runs a command, `> code` runs JavaScript, `help` lists commands. |
| Engine Feedback | The project's `ENGINE_FEEDBACK.json`: what the AI found missing in the engine. The panel keeps its size however long an entry is: only the entries table and the text of the selected entry scroll. An entry that is not open moves to `ENGINE_FEEDBACK.archive.json` by itself (when the project opens and when you change its status in the panel). Three buttons: **Add feedback** (a form that records an entry), **Send feedback** (shares open entries with the engine developers, [Sharing feedback](#sharing-feedback)) and **Retrospective** (looks back at the project's recorded AI runs, files at most three efficiency entries with one short call of the fast role, and says what it did; it costs a model call, see [Retrospective](AI_PROVIDERS.md#retrospective)); the table has a share column. A line under the buttons adds up what the open efficiency entries' fixes would save per game. |
| Audio | (View > Audio) the live `audio.log`. |
| Profiler | (View > Profiler) where the time of a frame goes while the game plays. |
| Level generator | (View > Level generator, a window) makes a level from a sample you drew, tries other seeds and keeps one ([Level generator](#level-generator)). |
| Animation | (View > Animation, a tab next to Console) the clips of the selected entity's Animator as a dopesheet or curves, with record mode ([Animation panel](#animation-panel)). |
| Bone tools | (View > Bone tools, a tab next to Inspector) draw a bone chain, bind a sprite, paint weights, drag IK targets ([Bone tools](#bone-tools)). |

Play snapshots the scene and runs the game; Stop restores the snapshot, so edits made while playing are temporary. For that
reason the AI works in edit mode only: while the game runs (Play or Pause) its Run button is disabled ("game running: Stop it
to send"), and while it is working Play and Step are disabled until it finishes or you press Stop in the AI panel. The Console
still runs commands during play, to inspect or poke the running game. Ctrl+Z / Ctrl+Y
(toolbar and Edit menu too) undo and redo scene edits: the ones made by the AI and by commands typed in the Console. Undo does
not touch files; to take back a whole AI run, scripts included, use Revert ([Revert an AI run](#revert-an-ai-run)). View >
Show navmesh draws the walkable cells of every NavMesh3D (green; red where a moving obstacle blocks; blue on a walkable moving body, Collider3D.navWalkable) and its off-mesh links (NavLink3D: a yellow line, with an arrowhead when one-way) (docs/NAVIGATION.md). Show colliders and Selection overlay toggle the collider boxes and the selection outline in the viewport. With a 2D camera, Selection overlay also draws the bones of the selection (docs/ANIMATION.md, "Bones and IK"): a thin kite from the origin to the tip of every `Bone2D` on the selected entity and below it, and of the bones a selected sprite's `SpriteSkin` names; the selected bone itself is yellow, the rest cyan. The overlay only shows them; moving them is done with the Transform gizmos or the Inspector, and drawing, binding and weight painting are in View > Bone tools ([Bone tools](#bone-tools)).

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

The transcript follows new output only while it is scrolled to the bottom: scroll up to read and it stays where you are
while the agent keeps working, with a **Jump to latest** button in its corner that goes back to the bottom (and following
starts again, as it does when you scroll down yourself or send a message). The message box is three lines high; drag the
grip just above it to make it taller (it grows upwards) or shorter, and double-click the grip to go back to three lines.
The height is kept with the layout.

- **Roles:** your messages always go to the orchestrator role, which answers, plans and hands implementation work to
  the worker role, small mechanical edits to the fast role, the art to the artist role and the sound to the audio role
  by itself. The `artCritic` and `reviewer` roles never run unless you ask (see **Reviews** below). **AI > Roles...**
  (the **Roles** tab of the AI settings window) picks the provider, model and effort of each of the seven roles, listed with readable names in three
  groups (Orchestration and code: Orchestrator, Worker, Fast; Art and audio: Artist, Audio; Critics and reviewers: Art
  critic, Reviewer; hover **AI > Roles...** to see the current ones). Each role has an **Enabled** checkbox: untick one you do
  not want to use and the orchestrator does that work itself (nothing is delegated to it; for the Art critic and the
  Reviewer, the review buttons still work but run on the orchestrator's model). The orchestrator's box is ticked and cannot
  be changed. Save writes them into `ai.json`
  and the next message uses them (see `docs/AI_PROVIDERS.md`, Roles). The **Model** column is a dropdown of the models
  the provider really offers, fetched when the project opens; **Refresh models** asks again (new releases show up), and
  **Other...** types a name that is not listed (see `docs/AI_PROVIDERS.md`, Choosing a model). **Revert** drops the
  changes made since the last Save. **AI > Roles...** is disabled until `ai.json` has been read. Its **Context** column caps how much of the
  conversation a session keeps (full, or 100k to 800k): past it the earlier part is summarized, so each message costs
  less. It works with Claude Code and the Anthropic API.
- **AI > AI Settings...** (the **AI** menu of the menu bar, next to File, Edit, View and Help; on macOS also **FactorIA > Settings...**, Cmd+,; there is no button for it in
  the panel) opens a window with four tabs. **Roles** (the first) is the role table above, and **AI > Roles...** opens
  the window on it. The **External tools** tab lists the MCP servers the AI may use (a service such as Scenario): a form
  to add one (name, address or program, key), a **Test** button that connects and lists its tools, **Paste JSON** for a
  `.mcp.json` snippet from Claude Code, and **Remove**; **Save** keeps every other key of `ai.json` (see `docs/AI_PROVIDERS.md`,
  "External tools (MCP servers)"). The **Extensions** tab lists the plugins, skill folders and hooks the AI agents load, with
  on/off per role, **Trust this project** for a project's programs, and a **Hooks** section at its end: every saved hook
  handler (entry, event, matcher, type, command or module) with where it runs (every provider, the engine's own events for every caller,
  or Claude Code only), and the **Recent runs** of this editor (time, event, what it matched, handler, result `ok` / `block` /
  `failed` in red, milliseconds; the tooltip has the error, reason, output and exit code) with a **Clear** button
  (`docs/HOOKS.md`). The **Assets** tab is for what the AI makes besides
  code and where it finds it. **Asset generation** picks, for each kind (Image, Sound, Music, Voice, 3D model), the provider
  that makes it (only providers that can make that kind, or **None**, which leaves it to the procedural commands), the model
  and, for Voice, the voice id, with a status per row (key found, or what is missing); a masked box stores an API key in your
  `ai.json` (your own file outside any project; an environment variable is safer and the window names it), and
  `asset-command` takes a program and its arguments. **Asset sources** lists the websites the AI should look at for images
  and textures, 3D models, audio, fonts and other assets (a domain or an address, and an optional note), and **Use only these
  sites** forbids searching anywhere else (enforced for Claude Code; for other providers it is an instruction). **Save**
  rewrites only those parts of `ai.json` and the next message uses them (see `docs/AI_PROVIDERS.md`, "The AI settings
  window" and "Asset sources").
  **With a project open** the window is titled "AI settings - This project: <name>" and edits that project's own settings,
  `<project>/.factoria/ai/settings.json`, instead of `ai.json`; without a project it says "Your defaults" and edits `ai.json`.
  The Roles tab has a **From** column and the Assets tab one per row and category: **This project**, **Your defaults** or
  **Built in**. **Reset** on a row that says This project takes that value out of the project's file, **Reset tab to my defaults**
  does it for the whole tab, and **Save as my defaults** writes the values you see to your `ai.json` (every project starts from
  them; the project's file keeps only what still differs). **Save** writes only what differs from your defaults into the project's
  file and the next message uses it. A file that came with a copied project and is not accepted yet shows an orange box at the top
  of the window: what it would change, **Accept**, **Ignore** (work with your settings; **Review it** brings the box back) and
  **Delete the file** (it asks first and forgets the acceptance); Save and Reset wait while the box is shown, and a Save after Ignore asks
  before it replaces the file and keeps it as `.factoria/ai/settings.replaced.json`. A file that cannot be accepted shows its error and no Accept. The
  External tools, Extensions and Token savers parts stay your own (`ai.json`) and say so. Switching project reloads what the window
  shows. On a small window the rows scroll sideways and the buttons wrap onto the next line, and the orange box scrolls inside the window
  instead of pushing the tabs off it. When `ai.json` or the project's file changes behind the window (an AI's `ai.settings.set`, another
  program) or after Accept, the window shows the new values and keeps the rows you had changed and not saved.
  (`docs/AI_PROVIDERS.md`, "This project's settings in the window")
  The **Extensions** tab ends with a **Skills** table: one row per skill the AIs can read (FactorIA's own, yours in
  `~/.factoria/skills` and the project's `skills/`), with an On box, where it comes from, what it is for, one box per role and a
  status. Switching a box adds a skill entry (`docs/SKILLS.md`) and **Save** writes it; a project skill with the name of an
  engine skill shows the engine one as `Replaced`.
- **Reviews:** at the top of the panel, above the chat tabs (they are not about one chat), **Review:** has an **Art critique** and a **Game review**
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
- **Usage:** the plan limits (Session (5h) and Week, with the reset time) belong to the provider, not to a chat, so they
  sit at the top of the panel above the chat tabs, with the provider problems ("No AI provider is configured", an unreadable
  `ai.json`) and the review row. Under the tabs, above the transcript, are the chat's own Context, Tokens and **API cost est.**
  Hover a line for details. The cost is what the same tokens would cost on the provider's pay-per-token API; with a
  subscription (Claude Code / Codex sign-in) none of it is charged on top of the plan, and the line says "(not billed on a
  subscription)": only the plan limits matter there. Tokens and Cost move while the agent works: every model call
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
  the CLI process has disappeared for 10 seconds while the run goes on. "Disappeared" is confirmed with a direct question to
  the operating system (is that pid still running) and only counts while the run has produced no event for 10 seconds: a
  process the list does not show, or a run that still reports, is never stopped for it.
- **Why a run was cancelled:** every cancel records its cause. The session transcript's `end` event
  (`.factoria/ai/sessions/*.jsonl`) has `"cause"` (`user_stop` the Stop button, `stuck_stop` the Stop of the stuck warning,
  `watchdog_process_gone`, `activity_check_process_gone`, `project_closed`, `editor_closing`, `editor_restart`, `run_ended`)
  and an `error` such as `cancelled: the user pressed Stop`. The chat shows the same text, and the `ai_run` call of an
  orchestrator whose worker was cancelled fails with it, so neither the user nor the orchestrator has to guess.
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
engine is available as the commands `checkpoint.create`, `checkpoint.list`, `checkpoint.diff`, `checkpoint.read` and `checkpoint.restore`.
`checkpoint.read {id, path}` returns one file as it was at a checkpoint (text inline; a binary as base64, or any file into `out`)
without restoring anything, and `checkpoint.restore {id, paths:[...]}` puts back only the listed files, with the same safety checkpoint.

## Sharing feedback

The engine developers can read the gaps your game found in the engine (docs/ENGINE_FEEDBACK.md, "Sharing with the engine
developers"). Nothing leaves the computer until a person chooses, and only here or in the terminal (`factoria feedback
sharing`): no command, MCP tool or script can set the mode, so an AI cannot turn sharing on.

**The consent dialog.** While the mode is unset, the editor asks once: when you open a project that has feedback entries,
or when the first entry with a `share` text is written. It says in plain words what is sent (the sanitized share text,
category, severity, effort, who wrote it, whether it was reviewed, the engine version, the operating system and a random
installation id) and what never is (the game's name, files, paths, scene, entity and script names, your code and assets, the
entry's own text, your name). Under that, the next report exactly as it would leave this computer, built from the entries
that wait now (`feedback.share_preview`; nothing is sent by showing it). The buttons are **Always**, **Ask me each time** and
**Never**; a discreet **Decide later** closes it for this session and asks again the next time the editor starts. Once you
choose, it does not come back (change your mind in Feedback Settings). The dialog is not shown in a build without a feedback
server address, where there is nothing to send.

**Feedback Settings** (File > Feedback Settings...):

- **Mode** (titled **Default** while a project is open): Always, Ask me each time, Never. This is what every project follows
  unless it has its own choice.
- **This project: <name>** (only with a project open): **Follow default**, **Always**, **Ask me each time** or **Never** for this
  project alone, and a line that says which mode applies now and where it comes from. The choice is kept in your own
  `feedback-sharing.json`, keyed by the project folder's path, never inside the project (a copied or downloaded project does not inherit it and follows the
  default); moving the folder drops it back to the default. The four choices wrap onto more lines in a narrow window. Changing the
  project's choice acts on its waiting items: Ask puts queued ones back to waiting, Never drops them (entries marked skipped), and
  Follow default applies the default to them, except that it never answers yes for what waited (a note says so when the default is Always: those entries stay in Send feedback until you confirm them). After Never, a batch whose upload had already started finishes (the notice says so); nothing after it is sent. A default of Always or Never never touches a project that has its own choice. The Engine Feedback panel's "sharing:" label, the consent dialog,
  Send feedback, the outbox and the sending all use the project's mode. The outbox line says how many items are not sent because
  their project is Never. The consent dialog (shown while no mode is chosen at all) sets the default; ask mode's question is
  per project, because the waiting entries and the Review notification belong to the project's feedback file.
- **Installation id** and **Reset id**, which makes a new random one (the old reports stay with the old id). The settings, the outbox and
  the lock they share with the terminal and the MCP server never make the window wait: when another program is changing them, the
  action says so (a notification, or the row of Send feedback) and nothing is changed; try again a moment later.
- **GitHub (optional)**: **Sign in with GitHub** shows the code to type, the address and **Open in browser**; the window finishes by
  itself when you authorize (**Cancel** stops it), then shows your login and **Sign out**. Signing in only makes your reports
  count as verified; no GitHub permission is requested.
- **Outbox**: how many entries wait to be sent and how many wait for your answer, the next retry time and the last error of
  an entry that could not be sent, the last attempt, and **Send now**, which sends what is due without waiting for the
  retry time.

**Send feedback.** The **Send feedback** button of the Engine Feedback panel opens a window with every entry that would be sent:
open, not sent yet and not refused by the server (an entry sent before is listed again only when its `occurrences` went up, at
most 3 sends). Each row has a checkbox, checked by default, and the exact text that leaves the computer, with the names of your
game already cut out: the entry's `share` when an AI wrote one, otherwise a text made from the entry's title, what is missing and
suggestion. An entry too short to make a text from is listed unchecked and disabled, with the reason. You never write a share
text. **Send** stores the text in each checked entry, queues it and sends it at once; the rows then say *Sent*, why the server
refused one, or that it waits in the outbox for a retry. An unchecked entry is marked `skipped` and comes back unchecked the
next time. **Cancel** (or the window's X) sends and changes nothing.

When an AI provider is set up (docs/AI_PROVIDERS.md), each text that was not reviewed before is checked in the background while
the window is open (`ai.review_feedback` on the "fast" model, with the text of the row as the candidate): the row says
*checking with AI...*, then either *Checked by AI* (when the check rewrote the text in engine terms, the row shows the rewrite and
that is what is sent) or the reasons it did not pass, with the row unchecked. Send waits for the checks of the checked rows. With
no model set up there is no check and no message. Nothing is stored until you press Send.

The consent dialog (see above) comes first when no mode is chosen yet and you press Send feedback. With **Never** the button is
disabled: turn sharing on in File > Feedback Settings. In **Always** mode an entry that already has a `share` text (an AI wrote
it) is queued and sent as it is recorded, as before; entries without one wait for Send feedback. In **Ask me each time** mode,
when entries with a `share` text wait for your answer, a notification with a **Review** button opens this same window.

**Add feedback.** The **Add feedback** button opens a form: category, severity, title, what is missing, the workaround you used and,
optionally, a suggested engine change. **Add** checks the form, records the entry in `ENGINE_FEEDBACK.json`, selects it and closes
the form; **Cancel** (or the X) closes it and keeps nothing. There is no share text to write. When the engine already has what the
form says is missing ("No one-way platforms": `Collider2D.oneWay` exists), **Add** does not record it: the form stays open and says what
exists and where it is documented (docs/ENGINE_FEEDBACK.md, "The check before filing"). A bug report (it exists but does not work as
documented) and a request for an extra option on an existing component are recorded.

**The Engine Feedback panel.** The table is as tall as its rows need, up to two thirds of the panel, and scrolls inside when there are
more. It has a **share** column: *not sent*, *waiting* (queued or waiting for your answer), *sent*, *rejected* (hover for the reason:
the sanitizer, the server or the limits) and *skipped* (left out of a Send). The selected entry is shown read-only, with its share
state and the **status** box: changing it to anything but `open` moves the entry to the archive file.

**Rejected entries, closed entries, the entry window.**
- The engine rejects an open entry that says the engine lacks something it has when the project opens, and tells you with a
  notification; the entry is closed as `rejected` with the reason (what exists and where it is documented) and moves to the archive. The
  engine developers can reject a report you sent as well: the editor asks the server about every 30 minutes while sharing is on, and
  the entry closes as `rejected` with their reason and a *declined* share state.
- The **closed** checkbox adds the archived entries to the table (the status filter does too when you pick a closed status). A closed
  entry that has a reason shows `*` after its status: hover for who decided (the engine, the engine developers, you) and why.
- Picking **rejected** in the status box of an entry asks for the reason first (a text box, up to 500 characters, OK disabled while it
  is empty); Cancel keeps the status. A person who reopens an entry that the engine rejected is not overridden: the engine never rejects it again.
- **Double-click a row** to open the entry in its own window: every field (also the ones the table does not show: workaround files,
  notes, reporter, the reason of a rejection, the share text and the server's answer), wrapped, scrolling when it is long. The window
  moves and resizes like any floating window, several can be open at once (one per entry), and each has the status box, **Copy**
  (the whole entry as JSON on the clipboard), **Delete** and **Close**. While an entry has a window, the strip under the table does not
  repeat these buttons.
- **Delete** asks "Delete this entry?" first and then removes it from the file or the archive for good (command `feedback.delete`).
  It is enabled for a closed entry and for an open one the engine developers declined; an open entry that nobody has answered is
  somebody's question and stays (hover the disabled button for why). Its id is not used again.

## Exporting the game

**Export Game** in the menu bar (next to the Help menu; on macOS the **Export** menu, Cmd+E; or File > Export Game...) opens the **Export game** window: a button per platform (Windows,
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

## Level generator
View > Level generator makes a new level from a small one you drew (the command `tilemap.generate`, AI_GUIDE.md section 9.8) and
shows it as a plan of coloured cells, one colour per tile (brighter for the tiles the sample marks as solid, a yellow dot where
a prefab such as a coin or an enemy would be placed; hover a cell for its glyph and tile). Nothing in the scene changes until
you keep a level.

1. **Sample.** Select an entity with a Tilemap (Hierarchy or Viewport) and press **Use the selected Tilemap**, or type the
   project-relative path of a level file (`{"rows": [...], "legend": {...}}`, the format of `scene.import_ascii`; a legend with
   prefabs brings spawn points, coins and enemies into the generated level). The level is made only of the patterns of the sample.
2. **Level.** Its size in cells and a **Seed**. **Previous seed**, **Next seed** and **Random seed** (a far seed, the same chain
   every time) generate at once (so do the + / - buttons of the Seed box and Enter in it; typing alone does not start a generation); the numbers under the buttons say how many attempts and dead ends the seed took, and the
   seeds you tried are buttons (an x marks a seed that made no level) so you can come back to one. The same sample, options and
   seed give the same level on every computer. Model, window `n`, `symmetry` and "wraps around its edges" are the arguments of
   the command; **More options (JSON)** takes the rest (`constraints`, `reachability`, `maxAttempts`...), merged over them. It cannot
   override what the window owns (`sample`, `size`, `seed`, `model`, `n`, `symmetry`, `periodic`): the window refuses such a key and says which field to use.
3. **Keep.** **Keep in the scene** builds the shown level in the open scene with `scene.import_ascii`, as the entity named in
   **Entity id** (to the right of the sample when the sample is an entity; the sample's tileset, tile size and solid tiles are
   copied) and one entity for every spawn point, coin or enemy of the sample: one undo step, and keeping again replaces the
   entity and its objects. It needs the editor in edit mode (a button that is greyed out says why when you hover it). **Save level file** writes the rows and legend as a level file instead
   (`levels/generated.json`, one row per line): `factoria call scene.import_ascii @levels/generated.json` builds it, `scene.ascii_edit`
   edits it by hand, and it can be the sample of the next generation. Save never replaces a file without asking: when the path
   already exists (a scene, `factoria.json`, `assets.json`, the sample itself...) a **Replace <file>?** window offers Replace or
   Cancel, and only Replace overwrites it; the Project panel lists a newly written file at once.

A generation runs in pieces of about 4 ms of each frame, so the window and the viewport keep drawing; **Cancel** stops it, closing
the window stops it (so does collapsing it or hiding its tab, and picking another sample), and loading another scene ends it quietly with a grey note instead of an error (a job belongs to the scene that started it; the last good level stays). A mistake (a
size out of range, extra options that are not JSON, a sample that cannot be found, a level the sample cannot make) is shown in red
with how to fix it, and the last good level stays on screen. The window calls the same commands as the Console
(`tilemap.generate_start` / `generate_step` / `generate_cancel`, `scene.import_ascii`, `fs.write`), so what it shows is what a script
or the AI gets for the same arguments.

**Autotest.** Section R3 of `fa_editor_autotest` imports a small level, selects it, presses Use the selected Tilemap and Generate, steps
the seed with Next and Previous seed (the first level comes back row by row), Keep (the Tilemap entity has the right size, tile size
and solid tiles, one undo step), Save level file (the file parses; saving again over it opens the Replace window, Cancel leaves the file,
Replace overwrites it) and Ctrl+Z. It is in the first shard. `fa_test_editor` covers the
model (`tools/editor/src/level_gen_model.*`) against a headless engine.

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
- **Let the AI play**: **Play > Let the AI Play** (or the button of the same name in the **Play sessions** window, **Play > Play Sessions...**)
  runs `play.auto` ([DEBUGGING.md](DEBUGGING.md#let-the-game-play-itself)) on the project as saved on disk: a bot plays it from the start,
  faster than real time, and finds what is stuck or broken. The window has the game seconds the bot may play (5 to 600, 60 by default)
  and a box for the pictures. The bot runs in a `factoria` process of its own (the editor keeps the GPU), so the editor never waits: the
  window shows the time elapsed and the last line the bot printed, and **Cancel** stops it (a cancelled run writes no session). It needs
  the `factoria` program next to the editor, or the one `FA_FACTORIA_EXE` names; if it is not found the window says so and nothing runs.
  The menu item is disabled while the game plays or a run is going. When the run ends a toast says how it ended (won, lost, timeout,
  stuck, broken...) and how many problems it marked, and **Open report** selects the session in the window.
- **Play sessions window**: lists the sessions of `.factoria/sessions/`, newest first. A session the AI's bot played is marked **AI** and
  shows how it ended; one you recorded is not. Click a row for its report (how it ended, score, phases, performance, marks and notes), with
  **Attach to the AI chat** and, for a run of the bot, **Copy replay command** (the command that plays the bot's input again). The list is read
  again when the window opens, when a session is written (Stop, or the end of a run) and with **Refresh**.
- **Attach last play session** (AI panel) picks the last session YOU played. A session of the AI's bot is attached only when you have
  none of your own, and then the editor says so (a toast, and a note in the message: "This is a session the AI's bot played with
  play.auto, not one the user played."), so the AI does not take its own bot's run for what you saw. The Play sessions window has an
  **Attach** button for the selected session, auto or not.
- **For AIs and tools**: `play.sessions` lists the recent sessions, `play.report` returns one (the latest by default) with the replay path and a `profile` section: where the time went over the session (per engine system, per script behaviour class, GPU, memory; PERFORMANCE.md).
  The report says how to replay it: `factoria run --headless --frames <n> --input .factoria/sessions/<name>/input.json`.
- **Sessions played by the bot**: `play.auto` ([DEBUGGING.md](DEBUGGING.md#let-the-game-play-itself)) writes the same folder with `"source": "auto"`
  (phases, score, how it ended, the problems it found as marks). `play.report` and `play.sessions` read both kinds.

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
- **Sprite sheets.** Select a picture that has a `sheet` entry in `assets.json` and a strip appears under the file list: a menu
  of its clips ("(all frames)" first) and the chosen clip playing, frame by frame at the clip's `fps`, the way a
  `SpriteAnimator` plays it (same code: padding and a non-looping clip's last frame included), with the frame number and
  range. A picture without a `sheet` entry shows no strip.
- **Right-click** a file: **Show in Finder** (Explorer, file manager), **Copy path**, **Delete...** (asks first, then `fs.delete`;
  it is not an Undo step, the file is gone from disk).

## Image panel

View > Image opens the Image panel; double-clicking a `*.image.json` in the Project panel opens that document in it
([IMAGES.md](IMAGES.md)). It is a floating window the first time (1100 x 720; dock it like any panel) and edits ONE document at a time.
Every edit runs the same `image.*` command an AI would call (`image.layer.*`, `image.paint`, `image.select`, `image.edit`) and the
brush, fill and transform use the code of `fa/tooling/image_paint.h`, so a stroke, a fill or a selection made with the mouse is the
same pixels the command writes. The picture on the canvas is drawn by the one compositor (`composite_image_document`), never a second
one. An edit writes the document (and the layer's PNG) as it happens; the baked picture next to the document is written only by
**Save** (the toolbar shows "baked", or "not baked (stale)" and so on), like `image.save`.

- **Toolbar.** The document (a menu of the project's `*.image.json`), **New** (a name and a square size: `image.create` makes `assets/<name>.image.json` with a white background layer),
  **Save**, **Reload** (re-reads the files; the panel also re-reads them by itself when they change on disk and no gesture is
  running), **Fit**, **1:1**, a zoom percentage, **Grid** (a pixel grid from 800% up) and **Checker** (the transparency
  checkerboard).
- **Canvas.** The wheel zooms around the pointer, Ctrl+wheel (a trackpad pinch) too; Shift+wheel and a sideways wheel pan, and so do
  the middle button or Space + left drag. Above 100% the picture is drawn with nearest-neighbour sampling, below it smoothed. The
  selection is outlined with marching ants (they crawl up to 3000 edges, stand still above that, and a selection of more than 60000
  edges is shown as a tint only); **Tint** shows it as a tint as well.
- **Tools** (left column, shortcut in brackets): Move (V), Brush (B), Eraser (E), Fill (G), Picker (I; Alt+click picks with any
  Brush, Eraser and Fill), Rectangle and Ellipse selection (M, Shift+M), Lasso and Polygon selection (L, Shift+L; a click on the first
  point, a double click or Enter closes a polygon, Esc drops it), Magic wand (W) and Transform (T). `[` and `]` change the brush size. The options bar above the canvas has
  the brush colour, size, hardness and opacity, the wand's tolerance and contiguous switch, and the selection operation.
- **Painting** draws on the selected layer, inside the selection if there is one, as one undo step per stroke. On an `indexed` layer
  the brush paints palette indices only (hardness and opacity do not apply). A locked layer or a layer that is not `pixels` or
  `indexed` is not painted on (the status line says why). The right mouse button paints, erases and fills with the secondary colour
  (X swaps the two).
- **Pixel-art tools** (a document with a palette). The **Grid** box draws the pixel grid from a zoom of 800% (a stronger line every 8
  pixels, or at the tile size in a tile document) and the tools that work on one pixel (Fill, Picker, Magic wand) outline the pixel
  under the mouse; the picture is always drawn with nearest-neighbour filtering when zoomed in. The **Tiled** box shows the picture
  repeated 3 x 3 so the seams show (a `tile` document opens with it on; the tools still work on the middle copy). A document that
  has a `tileset` layer gets a **Terrain preview** under the layer list: a small map painted with the sheet's tiles, each one chosen
  from its neighbours by the same autotile rules the `Tilemap` uses.
- **Palette bar** (under the canvas, for a document with a palette). A swatch: left click = primary colour (white frame), right
  click = secondary colour (orange frame). **+** adds a colour at the end (hex and optional name, `image.palette`), **Edit** changes
  the primary colour (every pixel that uses it changes with it), **<** and **>** move it (`image.palette.move`: the pixels follow
  it), **Remove** deletes it (`image.palette.remove`: its pixels take the secondary colour, or become transparent when the secondary
  is the same colour) and **Swap** swaps primary and secondary. Each is one undo step and is off while the game plays.
- **Selections.** Plain drag replaces the selection, Shift adds, Alt subtracts and Shift+Alt intersects (the same as the operation
  menu). All (Ctrl+A), None (Ctrl+D), Invert, Grow, Shrink and Feather are buttons of the options bar. The selection is the stored
  selection `image.select` writes, so a command sees it too.
- **Provider pictures.** Under the layer list, **Inpaint selection...** and **Generate layer...** ask for a prompt and make what
  `image.inpaint` and `image.generate_layer` make ([IMAGES.md](IMAGES.md), "Pictures from a provider"): the plan (provider, selection,
  size) is made first, so a mistake shows in the window before anything is paid for; the provider call runs on its own thread (the
  panel stays usable, a line shows the seconds and a **Cancel** button) and the picture is added as one undo step, selected, as a new
  `provider` layer masked by the selection. The two are off, with a tooltip saying why, when no image provider is configured, the
  configured one cannot inpaint, there is no selection (Inpaint) or the game is running. An answer that arrives after another document
  was opened is dropped with a message instead of being added to it.
- **Transform** shows a box with eight handles around the selected pixels (or the whole layer without a selection): drag a handle to
  scale, inside the box to move, outside it to rotate; Shift keeps the aspect ratio or snaps the angle to 15 degrees. The numeric
  fields of the options bar do the same by value, and the **Nearest** box chooses hard pixel edges (on by default in a document with a
  palette) or smooth ones. **Apply** (or Enter) runs `image.edit` once, **Cancel** (Esc) drops it. It works on the pixels of a
  `pixels` layer only; for another kind the status line says to convert the layer first.
- **Layers** (right column, top layer first): a kind badge, an eye (visible), a padlock (locked), the name (double-click to rename),
  a triangle that opens or closes a group; drag a row to reorder it or to drop it into a group; **+ Add** (pixels, indexed, fill,
  gradient, text, group, adjustment), **Duplicate** and **Remove**. The lock and the open/closed state of a group are kept for this
  editor session only, by layer name: they are not in the document. Procedural, svg and provider layers are added with the Console
  (`image.layer.add`); once there they can be selected, reordered, hidden and have their opacity, blend mode and offset edited.
- **Layer inspector.** Visible, clip, opacity, blend mode, offset, and the fields of the layer's kind (colour, text, gradient angle).
  Under it the **Adjustments** and **Effects** lists: add one by type, remove, reorder, and edit each field. A slider previews on the
  canvas while it is dragged, writes nothing until it is released and is then one undo step. The curve and stops fields (`curves`,
  `gradientMap`) are typed as JSON text.
- **Frame timeline** (under the palette bar; a pixel-art document shows it even with one frame). One button per frame, **Add**
  (an empty frame after the current one; the first one makes the picture an animation), **Duplicate**, **Delete**, **<** and **>**
  (move the frame) and a duration box in milliseconds (Enter applies): they run `image.frame.add`, `.remove`, `.move` and `.set`, one
  undo step each. **Play** shows the frames one after the other for their durations: only the frame shown changes, nothing is
  written, and a click on the canvas stops it. **Onion skin** draws the frames before (red) and after (blue) faint under the current
  one; the boxes set how many on each side (0 to 8), how strong the nearest ghost is and whether the frames wrap around. It is a
  preview the bake never has ([IMAGES.md](IMAGES.md), "Onion skin"). Switching frame only changes what the panel shows and where
  painting goes.
- **Undo and redo** are the editor's (Ctrl+Z, Ctrl+Shift+Z, Edit menu): each stroke, selection, layer edit, adjustment edit and
  transform is one step, and one slider drag is one step. An undo puts back the files the edit changed (the document, the PNGs of
  the layers, the stored selection) from a table the panel keeps in memory; a step of another document opens that document first. The
  editor's stacks hold only a pointer to the step, so the files are not part of a scene's undo history on disk.
- **Speed.** While a stroke, a slider or a transform is live, the shared compositor draws the document with the changing layer taken
  from memory instead of its PNG on disk, and nothing is written until the gesture ends. The layers under the one being edited are
  composited once and reused for every frame of the gesture (the layers above it, and the whole picture when the edited layer is
  clipped or the onion skin is on, are drawn each time). The status line shows the last composite time in ms.

## Vector panel

View > Vector opens the Vector panel; double-clicking a `*.svg` in the Project panel opens that drawing in it, and **Edit in Vector
panel** in the Image panel's inspector opens the svg layer of the selected layer ([IMAGES.md](IMAGES.md)). It is a floating window the first
time (1100 x 720) and edits ONE drawing at a time. SVG is the document: every edit that is kept runs the `vector.*` command an AI would
call (`vector.add`, `vector.nodes`, `vector.transform`, `vector.set`, `vector.boolean`, `vector.reorder`, ...), so the SVG keeps its ids,
groups, transforms and untouched text exactly as [VECTOR.md](VECTOR.md) says, and a person and an AI can take turns on the same file.
The picture on the canvas is the engine's own SVG rasterizer (`vector_rasterize`, the one `assets.rasterize_svg` uses), never a second
renderer. While a handle, a slider or a box is being dragged the canvas shows the same command run with `dryRun` on the text in memory;
nothing is written until the mouse is released, and then the edit is ONE undo step. Edits are written to the file as they happen (the
toolbar's **Save** says so); for an svg layer of an image document the edits go into the layer without baking, and **Save + bake**
(`image.save`) bakes the document's PNG. The panel reads the file again by itself when it changes on disk (an AI, the Console, the Image
panel) and no gesture is running.

- **Toolbar.** The drawing (a menu of the project's `*.svg`), **New** (a name and a square size: writes `assets/<name>.svg` with a `viewBox`),
  **Save**, **Reload**, **Fit**, **1:1** and a zoom percentage, then the snapping switches **Grid**, **Points** and **Guides** and **Snap...**
  (the grid size and the guides). Grid snaps to a grid of that size in drawing units; Points snaps to the nodes, bounding-box corners and
  centres of the other shapes and to the canvas corners and centre (a point wins over the grid and the guides); Guides are vertical and
  horizontal lines added in **Snap...** by their position. Snapping applies to the Pen, the shape tools, node drags and moving shapes.
- **Canvas.** The wheel zooms around the pointer, Shift+wheel and a sideways wheel pan, and so do the middle button or Space + left drag.
  The drawing is drawn as a texture of the visible part (plus a margin, at most 4096 px a side) that is made again when the drawing
  changes or, after the view stops moving for a few frames, when it no longer covers the view or the zoom changed; while the view moves
  the old picture is stretched. The status line shows the selection's size, the zoom and the milliseconds the last read and picture took.
- **Tools** (left column, shortcut in brackets): Select (V), Node (A), Pen (P), Rectangle (R), Ellipse (O), Line (L) and Shape (S).
  Below them the style new shapes start with (fill, an optional line, its width and, when the project has a style palette in
  `assets.json`, the palette's swatches).
- **Select.** A click picks the topmost unlocked shape at the current group level (a click on a shape inside a group picks the group; a
  double click on a group goes into it, a double click on empty space or Esc with nothing selected leaves it). A drag from empty space is a marquee: left to right picks the
  shapes it contains, right to left the shapes it only touches; Shift adds and toggles. The selection's box has eight handles (drag to
  scale, Shift keeps the aspect ratio, Alt scales from the centre), a drag outside a corner rotates (Shift snaps to 15 degrees) and a drag
  inside moves (Shift locks to an axis). The arrow keys nudge by 1 drawing unit, with Shift by 10. Moving, scaling and rotating write a
  `vector.transform` on the selection (the shapes keep their ids and get a `transform`, their nodes are not rewritten). Esc during a drag cancels it and changes nothing.
- **Pen.** A click adds a corner, a drag adds a curve node (the out handle follows the mouse, the in handle is its mirror), a click on the
  first node closes the path, Enter or a double click ends an open path, Esc drops it. A click on the end node of an open path continues
  it from there (from its start, the new nodes are added before the first one and the path keeps its direction). A path needs two nodes.
  The result is `vector.add` (a new path) or `vector.nodes` with `append` (a continued one).
- **Node.** Shows the anchors and handles of the selected shapes. Drag an anchor or a handle; Alt while dragging a handle breaks the link
  to the other handle; a double click on a segment inserts a node there; a double click on a node switches corner and smooth;
  Shift-click and a marquee select several nodes, Delete removes them and the arrow keys push them (1 unit, 10 with Shift). When several shapes are selected a drag moves the selected
  nodes of the shape that was grabbed. The **Nodes** row has Add node, Delete, Corner, Smooth, Symmetric, Break, Join, Close and Reverse:
  each is a `vector.nodes` op (move, handle, insert, delete, convert, break, join, close, reverse, append).
- **Rectangle, Ellipse, Line, Shape.** Drag a box (Shift makes it square or a circle, Alt draws from the centre; Shift on a Line snaps the
  angle to 45 degrees). **Shape** drags out one of the `vector.shape` kinds chosen in the tools column (star, gear, polygon, arrow,
  bubble, ribbon) with `parametric: true`: the element keeps `data-fa-shape` and `data-fa-args`, and the inspector shows its parameters
  (points, inner ratio, teeth, sides, tail...) as live fields that call `vector.shape` with `replace`. Editing its nodes makes it a plain path.
- **Actions.** Rows of buttons above the canvas, each one command and one undo step: **Shapes** (Union, Subtract, Intersect, Exclude =
  `vector.boolean`; Group, Ungroup, Front, Back), **Path** (Offset..., Simplify..., Smooth..., Mirror..., Outline = `vector.stroke_to_path`),
  **Arrange** (Align..., Distribute...) and **Style** (House style = `vector.style`, To palette, Shade... = `vector.shade`). The
  buttons that need numbers open a small popup with the command's own arguments. A button that cannot act (too few shapes selected)
  is greyed; a command that fails shows its message with the fix in a toast and the status line, and changes nothing.
- **Layers** (right column, in drawing order, the top one first): the elements of the SVG as a tree of groups and shapes, each with an eye
  (hide = `display="none"`), a padlock (lock = `data-locked="true"`: the canvas does not pick or move it), its id (double-click to rename: it
  updates the `href` and `url(#...)` that point to it) and a triangle that opens or closes a group. Click selects (Ctrl, Cmd or Shift toggle a row of the same group level);
  drag a row onto another to reorder it or drop it into a group (`vector.reorder` with `parent` and `before`, which compensates the
  transforms of the old and new group so the picture does not change). Elements with no id show their selector in grey; an edit gives
  them an id first (`vector.assign_ids`, in the same undo step), or **Give them ids** names every one.
- **Inspector** (below the layers): the position and size of the selection (typing moves or scales it), Flip H, Flip V and Rotate 90,
  fill and stroke (a colour popup, **none**, and, when the project has a palette, its swatches: the exact palette colour is written),
  stroke width, opacity and fill rule, and the parameters of a parametric shape. A slider previews on the canvas while it is dragged
  and is one undo step when released; a colour is one step when its popup closes. With several shapes selected it edits them all (the fields show the first one's values).
- **Keys** (while the panel has the keyboard): V A P R O L S pick the tool, Delete and Backspace delete the selection, Ctrl+A selects
  everything at the group level, Ctrl+D duplicates (a copy 10 units down and to the right), Ctrl+G and Ctrl+Shift+G group and ungroup,
  Home fits the view, Esc drops the pen path, then the node selection, then the shape selection, then leaves the group. Ctrl+S saves.
- **Undo and redo** are the editor's (Ctrl+Z, Ctrl+Shift+Z, Edit menu), the same stacks as the Image panel's: each edit is one step, and
  an undo puts the files the edit changed back from a table the panel keeps in memory (so a file written byte for byte is restored
  byte for byte); a step of another drawing, or of an svg layer, opens it first. The stacks hold only a pointer to the step.
- **Speed.** A drawing of 600 paths, measured in a Release build on an Apple M-series Mac (the `vector_tests` case "a drawing of several
  hundred paths" prints the times on every run): open and read in about 2 ms, a drag step (the command run with `dryRun` on the text in
  memory) in about 1 ms, the edit written to the file in about 2.5 ms and a 1024 x 1024 picture of the drawing in about 21 ms. A Debug
  build is ten to twenty times slower. The status line shows the last read and picture times. The hit test, the marquee and the snapping
  use the scene read once per edit (bounds and flattened outlines), not the SVG text.

## Sound panel

View > Sound opens the Sound panel; double-clicking a `*.sfx.json`, a `*.audio.json`, a `.wav` or an `.ogg` in the Project panel opens
that sound in it. It edits ONE sound at a time and is a floating window the first time. The documents are the source ([SOUND.md](SOUND.md)):
every edit that is kept runs the command an AI would call (`sfx.tweak` for the knobs, `sfx.edit` for any other field and for adding,
removing and moving list items, `sfx.preset`, `sfx.family`, `audio.edit` for the steps of an audio document, `audio.create` for a
new one), so a person and an AI can take turns on the same file and an edit is ONE step of the editor's Undo. The sound you hear is the
engine's own offline renderer (`render_sound` in `fa/tooling/audio_view.h`, which calls `render_sfx` and the audio document renderer that `sfx.render` and `audio.render` use), never a second synthesizer.
Edits are written to the document as they happen and the picture and the sound follow after a short pause (the render runs on a worker
thread and the last request wins); **Save + bake** writes the WAV (`sfx.render`, with `variants` when the patch has variations, or
`audio.bake`) and its recipe. A plain `.wav` or `.ogg` is shown read-only, with **Make an audio document from this**. The panel reads
the file again by itself when it changes on disk and no gesture is running.

- **Toolbar.** The sound (a menu of the project's patches, documents and recordings), **Save + bake**, **Replace foreign file** (bake
  over a WAV the engine did not make; off by default), **Reload**.
- **Waveform.** Drag to select a range, Shift-drag or middle-drag to pan, the wheel to zoom (Shift + wheel scrolls), click to place the play cursor.
  **-**, **+**, **Fit** and **To selection** zoom too. The playhead moves while it plays. A **Spectrogram** (frequency against time) can
  be shown under it, and the measurements (length, LUFS, peak, true peak, centroid, dominant band) are listed from the rendered samples.
- **Transport.** Play / Stop (Space while the panel has focus), **Loop** and **Selection** (play only the selected range). Playback goes
  through the engine's audio mixer; on a machine with no audio device the null device is advanced by the panel so the playhead still runs.
- **Macros.** One knob per macro of the patch (`brightness`, `tail`, ...) with the macro's doc as tooltip; drag up and down (Shift for fine steps, double click for 0); the
  edit is debounced and kept as one `sfx.tweak` undo step.
- **Inspector.** Every field of the patch, taken from `schemas/sfx.schema.json`, so a new field of the format appears with its
  description, minimum, maximum and default as the tooltip. Lists (layers, oscillators, effects, modulators, variations) can be
  added to, removed from and reordered. **Start from a preset** replaces the patch; **Make a UI family** runs `sfx.family` with the
  `ui` preset (click, hover, confirm, cancel, error, ...).
- **Variants and A/B.** The variations of a patch are listed with a play button each; two of them can be put in slots A and B and
  heard in turn. **Same loudness** matches their levels by the measured LUFS so the louder one does not win. **Swap** exchanges the slots.
- **Audio documents.** The chain of steps is a list: add a step of any type, move it up or down, switch it off, hear the chain up to
  it, remove it, and edit its fields. A `loop` step shows two draggable markers on the waveform, the loop start and the loop end.
  The source and the output are shown with the recipe's freshness.

**Autotest.** Section K3 of `fa_editor_autotest` opens a patch, drags a macro knob (one undo step, a brighter centroid), plays and stops,
selects and zooms the waveform, adds variations and compares A and B with and without level matching, undoes and redoes, saves
(the variant WAVs exist), then builds an audio document, adds a step, moves and enables it, drags the loop end marker, undoes it
and saves again (`loopEnd` in `assets.json`).

## Music panel

View > Music opens the Music panel; double-clicking a `*.song.json` in the Project panel opens that song in it. It edits ONE song at a time and
is a floating window the first time. The document is the source ([MUSIC.md](MUSIC.md)): every edit that is kept runs the command an AI would
call (`music.edit` for notes, drum grids, sections, layers, tracks, buses and the master; `music.chord`, `music.arpeggio`, `music.bassline` and
`music.drums` for the helpers, `music.mix` for the loudness), so a person and an AI can take turns on the same file and an edit is ONE step of
the editor's Undo. The sound you hear is the engine's own: the song is rendered by the same code a game's `MusicPlayer` uses
(`music_render_source`, the live mode) and played through `MusicTransport`, so what the panel plays with its intensity slider is what
`entity.music.setIntensity` plays in the game. Edits are written to the song as they happen and **do not bake**; a few frames after a change
the song is rendered again on a worker thread (the last request wins) and the next Play hears it. **Save + bake** runs `music.render`
(the mix and, when the song declares layers, one stem per layer) and records the recipe. The panel reads the file again by itself when it
changes on disk (an AI's edit, another editor) and no gesture is running; the undo steps stay.

- **Toolbar.** The song (a menu of the project's `*.song.json`), **Save + bake** (Ctrl+S while the panel has the keyboard), **Replace foreign file**
  (bake over a WAV the engine did not make; off by default), **Reload**, and the last edit's name ("Undo: Mute arp").
- **Transport.** Play / Stop (Space), the **section** menu, **Play section** (starts at the first pass of that section: a section is the granularity of
  play-from-here), **Loop** (the section plays again and again), the **intensity** slider with **Calm** (0), **Tense** (0.5) and **Intense** (1) buttons, and the
  gain of each layer as a row of bars. The position reads `bar 3 beat 2  00:05.4  loop`; a playhead runs through the roll and the grid while it plays. On a
  machine with no audio device the null device is advanced by the panel so the playhead still runs. Edits wait while it plays: Stop first.
- **Piano roll.** The tracks' patterns as notes on a keyboard. Click and drag on empty space to **draw** a note (it takes the snap length and stretches as you drag),
  drag a note to **move** it (with the other selected notes), drag its right edge to **resize** it, right click or Delete to **delete**, Shift-click to add to the
  selection. **Snap** (1/4 to 1/32 and triplets) and the **velocity** a new note gets are in the roll's toolbar, **Scale** shades the rows outside the song's key and mode,
  **-/+** zoom and **Up/Down** an octave. A **velocity lane** under the roll sets a note's velocity by dragging its bar. A drag is a working copy: letting go makes ONE `music.edit set_pattern`
  with the notes as a list, so it is ONE undo step. The playhead of the pattern shows when the track plays it. The pattern menu, **New pattern**, **Remove pattern** and the bars
  **-/+** change the pattern; **Insert chord** (a name such as `Am7`) adds the chord's notes at the yellow cursor, **Arpeggio** and **Bass line** replace the pattern with a
  generated one over a progression.
- **Drums.** A kit track's patterns as a grid: one row per lane, one cell per step. A click on a cell steps it through hit, accent, ghost note and empty, a right click clears it; the step value
  (`4` to `32` and triplets) and the bars are set above it, **Add lane** / **Remove last lane**, **Clear**, and **Generate** a groove in a style (`music.drums`, with a tom fill).
- **Arrangement.** The sections in order with their kind, the **repeat** count (**-** / **+**), **up** / **down**, **remove**, **play**, and **Add section**; under each, what every
  track plays there (the pattern names, `a a b*2`, or `rest`) and a **muted** box that silences the track in that section only. **Layers** lists the song's layers with the intensity each fades in at
  and the tracks in it; **Add layer** makes one.
- **Mixer.** One strip per track: volume, pan, **M**ute, **S**olo, its sends to the buses, its effects chain (add and remove any effect the engine has, with every field
  and its range from `audio_step_types()`), and the instrument. **Buses** with volume, mute and effects; the **master** with the song volume, the limiter and its ceiling, the
  loudness target (`style`, `off` or a LUFS number) and **Measure loudness** (`music.mix`: LUFS and peak of the whole mix).

A change a command refuses (an unknown pattern, a bar that does not add up) is shown in the panel's status line with the command's hint and the file stays as it was. Dragging a
number (volume, pan, a repeat) is one edit when the mouse is released, not one per frame.

**Autotest.** Section M3 of `fa_editor_autotest` opens a layered song, draws a note by dragging on the roll, moves it, deletes it with a right click and walks
Undo and Redo through the editor's stack, clicks a snare into the drum grid, raises a section's repeat and mutes a track in the mixer (each one undo step), plays and
checks that the playhead moves, fades the top layer in and out with the Intense and Calm buttons, loops a section, and saves (the mix and the stems exist).

## Model panel

View > Model opens the Model panel; double-clicking a `*.model.json` in the Project panel opens that document in it. It edits ONE document at a time
and is a floating window the first time. The document is the source ([MODELING.md](MODELING.md)): every edit that is kept runs the command an AI would
call (`model.edit` with `set`, `add` and `remove`), so a person and an AI can take turns on the same file and an edit is ONE step of the editor's Undo.
Edits are written to the document as they happen and **do not bake**; **Save** (Ctrl+S while the panel has the keyboard) runs `model.bake`. The viewport draws
the mesh the document evaluates to with the same software renderer as `model.preview` (the code is shared, `model_view.h`); a few frames after a change the
document is evaluated again on a worker thread (the last request wins) and the previous picture stays until the new one is ready. The panel reads the file
again by itself when it changes on disk and no gesture is running; the undo steps stay.

- **Toolbar.** The document (a menu of the project's `*.model.json`), **Save**, **Overwrite** (bake over a `.glb` no document made; off by default), **Reload**.
- **Operation tree.** Every node in document order, indented by depth, with a checkbox for `enabled` (off leaves the node and what is below it out of the
  model). Picking a node highlights its part in the viewport and lists its parameters. **Add** (an operation of the catalog) adds a node into the picked group
  or modifier, else at the end of the top level; **Remove** takes the picked node out. The part list under the tree picks a part directly; the viewport does
  not pick by clicking.
- **Viewport.** Drag to orbit, wheel to zoom, **Shaded** / **Wire**, **Figure** (the 1.8 m reference figure) and **Reset view**. The highlighted part is orange and a
  back face is dark red.
- **Parameters.** The fields of the picked node from `model.info {}`: a slider (with the field's range) for a number or integer, a checkbox, a slider per axis
  for a vector, a combo for a choice, a text box for a string, and a reset button per field that removes it (back to its default). Fields with no widget
  (lists of points, nested documents) are listed read-only with the `model.edit` call that changes them. Dragging a slider changes a copy the viewport follows;
  letting go makes ONE `model.edit set`.
- **Check.** Runs `model.check` on the file and lists the findings with their severity; hovering one shows how to fix it and picking one highlights its first part.

A change a command refuses (a value out of range, an unknown field) is shown in the panel's status line with the command's hint and the file stays as it was.

**Autotest.** Section N3 of `fa_editor_autotest` opens a model document and checks that the viewport drew its mesh, picks a node (its part is highlighted), clicks a
slider (one `model.edit`, one undo step) and walks Undo and Redo through the editor's stack, picks a part in the list, adds a node, switches it off and removes it,
orbits the view with the mouse, shows the figure and runs Check, and saves (the `.glb` exists). It is in the shortest shard.

## Particles panel

View > Particles opens the Particles panel; double-clicking a `*.vfx.json` in the Project panel opens that effect in it. It edits ONE effect document at a
time ([PARTICLES.md](PARTICLES.md), "Effect documents") and is a floating window the first time. Every edit that is kept runs the command an AI would call
(`vfx.edit` with `set`, `add`, `remove` and `move`; **New** runs `vfx.create`), so a person and an AI can take turns on one file, and an edit is ONE step of the
editor's Undo. Edits are written to the file as they happen; there is nothing to bake, so Ctrl+S does nothing here. A change the commands refuse (a part that
starts after the effect ends, a command that is not allowed) shows its message and the hint, and the file stays as it was. The panel reads the file again by itself
when it changes on disk and no drag is running; the undo steps stay. While the game runs, the panel plays and shows but does not edit.

- **Toolbar.** The effect (a menu of the project's `*.vfx.json`), **New** (writes `assets/vfx/effect.vfx.json`, or the next free `effectN`, with one burst
  emitter), **Play** and **Pause**, **Restart**, **Loop** (starts again a moment after the last particle is gone), **Reload**, the preview's **Speed** (0.1 to 2) and
  **Seed**, the canvas **Zoom** and a **Grid**. Space plays and pauses while the panel has the keyboard. The row of buttons wraps on a narrow window.
- **Timeline.** A ruler in seconds over one bar per part: orange for an emitter (from `at` for its `duration`), yellow for a light, a blue diamond for a sound and a
  purple one for a command; a grey line marks where the effect ends. The red playhead is the **time scrubber**: press or drag on the timeline and the preview is
  built again up to that moment with the same seed, so a moment always shows the same particles. Scrubbing pauses the preview; Play goes on from there. A click on a
  part's row selects it.
- **Preview.** The effect played by the same timeline (`update_vfx`) and the same particle simulation (`ParticleSim`) a game runs, in a scratch world with no
  renderer: dots with the renderer's size, colour and alpha formulas, and lights as glows. It steps by a fixed 1/60 s from the start every time it is built, so the
  preview is repeatable. Dragging the playhead, a slider or the seed never freezes the editor: a later moment goes on from the state the preview has, an earlier one or an
  edit starts again, and each frame does a bounded share of the steps (240 at most, fewer when there are many particles), so the particles shown can lag the playhead
  for a few frames; the readout says "catching up to" the moment asked for. Where the preview ends up does not depend on how many frames it took. What it does not show: ribbon trails, textures and flipbooks (a dot stands for the quad), and additive blending (it draws as normal).
  Sounds and commands are not run, so a preview never shakes the editor or plays a clip; they only appear as markers on the timeline. The mouse wheel zooms.
- **Parts.** The list with **+ Emitter**, **+ Light**, **+ Sound** (the first audio file of the project; pick the clip in the inspector) and **+ Command**, and **Up**,
  **Down** and **Remove** for the selected part (an effect has 1 to 16 parts).
- **Inspector.** The effect's `doc` and `duration` (left out, it lasts until the last part ends), the **Problems** of the file with their pointers and hints, and the
  selected part: its name, `at`, `duration`, `offset`, the light's or emitter's fields from the same reflection the Inspector uses (the descriptions are the tooltips;
  the common ones first, the rest under **All other fields** with a filter), the sound's clip, volume, pitch and bus, a command's name (a list of the allowed ones) and
  arguments. A field the document does not set shows its default dimmed, and the small **x** next to a set field removes it from the document (back to its default).
  A light part with no `light` object has an **Add light settings** button.
- **Gradient and curve editors.** `colorGradient` and `trailGradient` are a colour bar: click it to add a key (it gets the colour the bar already had there, so the
  picture does not change), drag a key along it, and set the selected key's position and colour (alpha included) or remove it. `sizeCurve`, `speedCurve`,
  `alphaCurve`, `trailWidthCurve` and a light's `fade` are a graph: click to add a key, drag one (it stays between its neighbours), type its time and value, pick the
  interpolation (linear, smooth or step), remove it or clear them all. At most 16 keys each. A drag shows the change in the preview as it goes and writes ONE
  `vfx.edit` when the mouse is let go, which is one undo step.

**Autotest.** Section P3 of `fa_editor_autotest` presses New (the file exists and opens with its one emitter), checks that the preview has live particles, pauses, drags
the playhead over the timeline and back to the same pixel (the same time and the same particles), drags a gradient key and a curve key (the file on disk and ONE undo
step each), adds a second curve key, adds a light part and removes it, then walks five Undos back to the file as New wrote it, four Redos and four Undos again. It runs
at the macOS CI window size too (`FA_EDITOR_AUTOTEST_SIZE=1024x642`). It is in the first shard.

## Animation panel

View > Animation (a tab next to Console; the View menu reopens it) edits the 2D clips of an entity's `Animator`
(`*.anim.json`, [ANIMATION.md](ANIMATION.md), "2D clips"). Select the entity that has the Animator, or any part below it: the
panel edits the nearest `Animator` up the tree and keeps it while you select other parts of the same character. An entity with
no Animator offers **Add an Animator to it**. The panel works in edit mode only; while the game runs it says so.

- **Clips.** The menu lists `Animator.clips`. **New clip** asks for a name, a length and a loop flag, writes
  `anim/<name>.anim.json` (`anim.create_clip`) and lists it in `Animator.clips` (a scene edit): two undo steps. The second line
  shows the file, its length (`anim.set_clip`), its loop flag and **Add event**.
- **Time.** The ruler shows seconds and, zoomed in, the frames of the **fps** the panel offers (12, 24, 30, 60; clips are in
  seconds, the fps only sets the grid). With **Snap** on, scrubbing, dragging and recording land on whole frames. Ctrl+wheel
  zooms, Shift+wheel or the middle button pans, **Fit** shows the whole clip. Click or drag the ruler to **scrub**: the entity is
  posed at the playhead in the viewport. A pose is a preview only: saving the scene, Undo snapshots and Play write the rest
  values, never the pose. Left / Right step one frame, Home goes to 0, Space plays. **Play** previews the clip in the viewport
  (loop and speed are the panel's own; nothing runs in the engine, so scripts and physics do not).
- **Dopesheet.** One row per part, with a row per animated field below it; a part's row folds. Click a key to select it, Shift-click
  adds or removes it, drag on empty space for a box. Drag selected keys to move them (the ghost shows where they land; one
  `anim.move_keys` and one undo step when you let go); Alt-drag scales their spacing around the first one. Esc during a drag
  drops it. Delete removes the selected keys (or the selected event). Ctrl+C / Ctrl+V copy keys and paste them at the playhead,
  keeping their spacing. Right-click a key: **Linear**, **Step**, **Bezier**, **Easing** (every `tween()` curve), Copy, Paste,
  Delete (`anim.set_interp` and friends).
- **Curves.** The **Curves** check shows the selected tracks as curves instead of the dopesheet: drag a key point to change its
  value and time, and the tangent handles of a `bezier` key to shape the curve.
- **Events.** Markers on the lane under the ruler. **Add event** (at the playhead) or a right click on empty lane (at that
  time) asks for a name, or for game feel actions: the popup has a `feel` JSON box (an action object or an array) with a preset
  button per action (hit-stop, shake, flash, push, squash, spawn, sound) and writes an event with a `name`, `feel` or both.
  Click selects a marker (a nameless event shows its actions), drag moves it (`anim.move_event`), double click or right click
  renames it, edits its `feel` or deletes it, Delete removes the selected one.
- **Onion skin.** With **Onion** on, the viewport draws the sprites of the animated entity in the poses before (red) and after
  (green) the playhead, faded; the numbers set how many poses on each side and how many frames apart.
- **Record mode.** **REC** turns it on: the viewport gets a red frame and a `REC` label, and the button and the status line of
  the panel say so. While it is on, moving, rotating or scaling a part with the gizmo, or changing an animatable field in the
  Inspector (a number, vector, colour, bool, enum or asset that the scene saves), writes a key at the playhead (`anim.set_keys`)
  instead of changing the rest value; the part keeps its rest value in the scene. A track the clip lacks starts with the old
  value at 0 s, so the part stays as it was until the new key. A field a clip cannot drive, and a change to a part that is not
  below the Animator, are ordinary edits. One gizmo drag is one undo step; Esc during the drag takes the key back out. Outside
  record mode, editing a field the current clip drives changes the rest value, and the pose (which wins while the panel poses
  the entity) hides it: turn record mode on to key it, or move the playhead off the clip's keys.
- **Undo.** Every edit is a command (`anim.*`), so it is on the Console and visible to an AI, and it is in the same Undo /
  Redo list as scene edits (Ctrl+Z). A clip file is not part of the scene: editing it does not mark the scene as changed, and
  the file on disk is already written. Save is for the scene.

### 3D bone clips

The mode switch at the top of the panel (**2D clips** / **3D bone clips**) turns it into the editor of a 3D clip (`factoria.anim3d/1`,
[ANIMATION.md](ANIMATION.md), "3D bone clips") of a rigged model. Double-click a 3D `*.anim.json` in the Project panel and the panel opens
it in this mode; a 2D clip still opens in the other one. The panel opens as a floating window, large enough for the four parts: the
bone list, the viewport, the inspector and the dopesheet. It edits ONE clip at a time, with the rig the clip names (choose another in the rig
menu to pose it with a different baked `*.rig.glb`). Nothing here needs a scene or an Animator, and no 3D clip edit marks the scene as changed.

- **Viewport.** The skinned model posed at the playhead, drawn by the software renderer of `model.preview` (the same picture on
  every machine, in a headless run too), with the rig's bones over it. Drag on empty space (or with the right button) to orbit, the wheel
  zooms, **Ortho** and **Reset view** change the camera, **Bones** and **Mesh** hide a layer. Scrubbing (a click on the ruler), the
  frame buttons and **Play** pose the model; Space plays and stops.
- **Picking a bone.** Click its row in the bone list (the number is how many keys the clip has on it) or its joint in the viewport.
- **Rotate tool.** The picked bone gets three rings (X red, Y green, Z blue) about the axes of its parent's frame, the frame its
  rotation numbers are measured in; a root bone, and any bone the clip gives a position track, gets arrows (a translation) too. Drag a ring and the model follows live. Letting go
  writes ONE key at the playhead (`anim3d.set_keys`) and selects it: one undo step however long the drag. Esc during the drag drops it.
  With **Snap** on, the key lands on a whole frame of **fps**.
- **IK tool.** For a hand or a foot (a bone with two bones above it) the viewport shows a target handle and a pole handle: dragging
  the target moves the end of the limb there with a two-bone solver, dragging the pole turns the bend of the elbow or knee. A head
  or a neck gets a look-at target. The drag poses the chain live; letting go keys the bones the solver moved at the playhead in one
  `ik3d.key` call and one undo step.
- **Pose buttons.** **Key rotation** and **Key position** pin what the clip gives for the picked bone now (a key that changes
  nothing), as a starting point for a later edit. **Mirror pose** (`anim3d.mirror_pose`) keys the pose at the playhead mirrored
  left/right: *swap* exchanges both sides, *left to right* and *right to left* copy one side onto the other; **to** keys the result
  at another time, which is how the second half of a walk is made from the first.
- **Dopesheet.** The ruler, a lane for the clip's events and one row per bone and channel (`rot`, `pos`, `scl`) under the
  bone list's order. Click a key to pick it (Shift-click adds or removes), drag to move the picked keys (one `anim3d.move_keys`, one
  undo step; a move past the end lengthens the clip), Delete or **Delete keys** removes them. The interpolation menu (**linear**,
  **step**, **bezier** and every `tween()` easing, `anim3d.set_interp`) applies to the picked keys. A double click on empty row space keys
  the current pose of that track at that time. Ctrl+wheel zooms, Shift+wheel pans, **Fit** shows the whole clip, **Only the picked
  bone** hides the other rows. Bars under the ruler mark the contacts the clip declares.
- **Inspector.** *Bone* shows the picked bone's current rotation and position; *Key* edits the picked key's numbers (committed when
  the field loses focus, `anim3d.set_keys`); *Clip* sets the duration, loop and ground speed (`anim3d.set_clip`); *Events* lists the clip's
  events: add one at the playhead, rename, move (also by dragging its marker in the lane), edit its data and its game feel actions as JSON (`feel`, an object or an array; a wrong one is shown in red and nothing is
  written), remove (`anim3d.add_event` / `set_event` / `remove_event`).
- **Generate a clip** (`anim3d.generate`) takes a kind (`walk`, `run`, `idle`, ...), the output file and optional parameters as a JSON
  object, writes the clip and opens it; Undo deletes it again. **Retarget to another rig** (`anim3d.retarget`) makes the clip for
  another baked rig. Both refuse to replace an existing file unless **replace the file if it exists** is on.
- **Filmstrip and weights.** **Filmstrip** (`anim3d.preview` with `yaws` [-70, 0, 90]) draws the clip at six times from three angles into
  the **Animation sheets** window; **Weights** (`skin3d.preview` of the rig document next to the baked rig, the picked bone only or
  one colour per bone) shows how the mesh is skinned. A sheet is a picture made when the button was pressed: the window warns when
  the clip has changed since, and only the button redraws it. The weights need the `*.rig.json` the rig was baked from.
- **Undo.** Every write is a command (`anim3d.*`, `ik3d.key`), so it appears on the Console and an AI can make the same edit. Each
  returns the call that undoes it (`anim3d.restore` with the whole previous document) and the panel puts it on the editor's undo
  stack with the scene edits (Ctrl+Z): a key, a drag, a generated clip are each one step. The clip file on disk is already written;
  the panel reads it again when it changes outside the panel (a command from the Console, the AI, a script).

**Autotest.** Section O3 of `fa_editor_autotest` generates a humanoid rig and a walk, opens the clip in the panel (viewport drawn, bones over it), picks a bone in the list and in the view, drags a rotation ring (one key, one undo step, the hand moved), Mirror pose, Undo and Redo through the editor's stack, moves and deletes a key in the dopesheet, drags an IK handle, scrubs the ruler and plays, draws the filmstrip and the weights, and runs Generate with its Undo and Redo. It is in the fifth shard.

## Bone tools

View > Bone tools (a tab next to Inspector) is for the 2D view: with a perspective main camera it says so. Pick one tool; while it
is on the viewport clicks belong to it and the gizmo handles are off (click the tool again to leave it). Every edit is one command
with one Undo step.

- **Draw chain.** Select the entity the bones hang from (a character's root, or the last bone of a chain to extend it), then click
  the joints in the viewport from the root to the tip. A rubber band shows the next bone. **Finish chain** (or Enter) makes the
  bones with `bones.create`, named `<prefix>_1`, `<prefix>_2`...; Esc or **Cancel** drops the points. The first bone is selected
  afterwards.
- **Bind a sprite to bones.** Select the sprite, pick the root bone (the sprite follows it and every bone below it; **Use the
  selected bone** copies the selection) and the mesh columns and rows, then **Bind sprite to bones** (`skin.bind`). The picture does
  not change: the bind pose is recorded.
- **Weights.** With a skinned sprite selected, the mesh vertices show as dots coloured by the weight of one bone (blue none, red
  all); selecting a bone of the skin in the Hierarchy picks it, or use the menu. Drag over the sprite to paint with the brush:
  **Add** raises the bone's weight by the strength, **Set** gives it exactly that weight, **Smooth** blends the vertices toward
  their neighbours; radius is in the sprite's units. A drag is one undo step (`skin.set_weights`). A skin still on automatic
  weights is turned into explicit ones by the first stroke, or by **Start from automatic weights**.
- **IK targets.** A diamond marks the target of every `IK2D` that has one; drag it to move the target entity (`Transform.position`,
  one undo step) and the chain solves at once. The solved bone rotations stay in the scene: they are the bones' own
  `Transform.rotation`, so Undo takes them back and a clip that drives those bones overrides them again when it plays.

## The program icon

The editor's window icon (Windows, Linux) and its macOS Dock icon are the PNGs in `tools/editor/icon/`, embedded in the
editor; `factoria.exe` and `FactorIA-Editor.exe` carry the same sizes in `tools/cli/windows/factoria.ico`. They are made from
the sources in `tools/editor/icon/src/`: the artwork (`factoria_art.png`, 1024 px) for 32 px and up, and a simplified
drawing (`factoria_small.svg`, rendered to `factoria_small.png`) for 16 and 24 px, where the artwork turns into a blur. After
changing a source run `python3 tools/editor/icon/make_icons.py` (needs Pillow) and commit what it writes (it also
writes the AppImage's `platforms/linux/factoria.png`).

The program's name is FactorIA everywhere the system shows one: the editor renames itself in the macOS Dock (the
`factoria` executable is not an app bundle, so macOS would show its file name), the Windows exes carry it in their
version resource (`tools/cli/windows/factoria.rc`), and the editor window's Linux `WM_CLASS` (`AppDesc::appName`) is
`FactorIA`, as the AppImage's `StartupWMClass`.

The icon of a game is its own (`factoria.json` `icon`, docs/EXPORTING.md), not this one.

## Testing the editor

- `fa_test_editor` (ctest `editor`): the GPU-free logic: the Audio feed and the Profiler view (`tools/editor/src/editor_tools.*`), picking geometry
  (`pick.cpp`), the Project panel's tree, filter and sort (`project_browser_model.*`), the reflected fields the AI edits, the Particles panel's curve and gradient key edits, document edits and undo steps and its seeded preview (`particle_*.cpp`), what Save writes, the window title, the program icon (`app_icon.*`: every window size and the Dock icon decode), and the Export window's logic
  (`export_job.*`: the options each platform's button exports with, the rows' checks, the export on its worker thread, its
  progress lines and cancelling), the Platform settings window's logic (`platform_settings.*`: the working copy, Save and
  Revert, validation, icons, the Android toolchain, the keystore command and creation) and the Set Up This Computer window's
  logic (`setup_job.*`: which setup fixes which Export row, an install on its worker thread with its progress, cancelling,
  the license loader and the cached status), all with an injected `fa::SetupContext` (a fake downloader and process runner and
  a temporary home): no test touches the network or your `~/.factoria`.
- `editor_autotest_1` to `editor_autotest_5` and `editor_autotest_welcome` (ctest, need a display: `xvfb-run` on Linux, the desktop session on macOS and Windows; on Windows a screen of at least 1600x900): the real editor window. The autotest
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
  can never freeze the window for good; before it does, it prints the UI thread's stack to stderr (`fa::watched_thread_stack`),
  which names the call that never returned. A failed MSVC Debug check (an STL assertion, `abort()`) prints its message and
  stack and ends the run with exit code 3 instead of a dialog that waits for a click, and on Windows an access violation or
  stack overflow prints its name, address and stack before the run ends (Windows would end it silently). While it runs the editor ignores the real mouse, keyboard and focus changes (using
  the computer or switching apps does not disturb it). On macOS its window stays above the others (a covered window
  draws nothing to take a screenshot of) but out of your way: see-through, without a Dock icon, clicks reach the windows
  below and the app you were using keeps the keyboard, so you can go on working while ctest runs it.
  `FA_EDITOR_AUTOTEST_SHOW=1` shows the window, to watch a run. `FA_EDITOR_AUTOTEST_SIZE=1024x642` runs it in a smaller
  window, the size of the macOS CI runner's display. A step on a widget that is drawn but scrolled out of its window
  scrolls the window to it and runs again on the next frame; only a widget that scrolling cannot bring in fails.
  A manual end-to-end check of the CMake button: `FA_EDITOR_AUTOTEST_REAL_CMAKE=1` makes the autotest run one script only: it
  presses **Install** of the CMake component and lets it download and unpack the real CMake (about 50 MB from Kitware) into
  the autotest's own `factoria_home`; ctest never sets it.
  Run it with `FA_EDITOR_AUTOTEST=1 xvfb-run -a -s "-screen 0 1600x900x24" build/dev/tools/editor/fa_editor_autotest`
  (macOS: `FA_EDITOR_AUTOTEST=1 build/macos-debug/tools/editor/fa_editor_autotest`; Windows: set `FA_EDITOR_AUTOTEST=1` and run `fa_editor_autotest.exe` from the repository root; `FA_EDITOR_AUTOTEST=welcome` for the other).
  The process exits with 1 if any check failed (`autotest_result.json` lists them). ctest splits the autotest into five
  entries (`editor_autotest_1` to `_5`, a few sections each, see below) that `ctest -j` runs at the same time, each in its
  own window, temp project and output folder (`<build>/test-output/editor/autotest_<n>`). On Windows they share the ctest
  resource lock `editor_autotest`, so one runs at a time beside the other tests (five editors at once on the CI runner's
  software D3D11 ran past their timeout). Each entry has a 300 s timeout.

The AI's commands run on the editor's main thread, but never for long at a time: queued commands share about 10 ms per frame, and `game.step` with many frames and `project.test` run in slices (frames / one test file per UI frame) so the window stays responsive while the AI works. The results are the same as a single call.

### Run only some sections

The autotest is a list of sections, each a letter (`tools/editor/src/autotest_sections.h`): S (the start: select, edit, undo,
play, AI marshaling, viewport click and keys), T (toolbar Screenshot and its Show-in-file-manager toast button), A (Audio panel), A2 (Profiler panel), B (commands that
rebuild the open scene file), C (pick bounds and the selection outline), D (bloom), E (Ctrl+V into the AI input), F (AI text:
wrapping, right-click menu), G (delete a project), H (Export window), I (Platform settings), J (Set Up This Computer), K
(custom material), L (hand editing in the Hierarchy and the Inspector), M (transform gizmos), N (Project panel), O (the CLI
agent through the MCP endpoint), P (revert an AI run), Q (the AI panel while an agent is silent or a worker outlives the orchestrator's turn:
the stuck warning, Check activity, the detached worker and its single continuation), R (a program updated on disk: the Restart notice,
its button state and Not now), U (the layout: a floated panel, a moved tab, a wider column and a closed panel survive reopening the project and a visit to the welcome screen; Reset layout), V (AI reviews: the buttons, a read-only reviewer, the saved report, Send to orchestrator), B2 (the Animation panel: New clip, keys written in record mode by a gizmo drag, a key moved and its Undo, an easing from the context menu, an event, an event with a game feel action from a preset button, scrubbing that poses without changing the scene, the onion skin), C2 (the bone tools: a chain drawn by clicks, a sprite bound, weights painted as one undo step, an IK handle dragged, the overlay following the selected bone), Y (recipes: a stale badge and a banner when a source is saved, Regenerate from the toolbar and the banner, Not now, a deleted source), X (the AI settings window against a scratch `ai.json`: routes, a key, sites, a bad site stopping Save, Remove stored key), Q2 (the AI settings of the open project: a copied file waiting for Accept with Ignore and Review it, switching between two projects showing their own roles, Reset of one row, Save as my defaults, a project Save and the Assets tab's own route and sites with their Resets, an invalid file showing its error and no Accept, the confirmations of Delete the file and of Save over an ignored file with its backup, and `ai.settings.set` through a run's registry (refused for MCP with scope `user`, reloading the windows when it changes `ai.json`); it works on a scratch `ai.json` set with `FACTORIA_AI_CONFIG`), D2 (the External tools tab of that window: a server added with the form, Test, a pasted Claude Code JSON, Save keeping the other keys of `ai.json`, Remove), Z (sprite sheets: the Project panel previews a sheet's clips, the Inspector lists them and one click sets `SpriteAnimator.clip`) and W (two AI chats at once against a scripted model: both finish with their own answers, the
same-file warning in both, the third chat held back by `maxConcurrentRuns`, Revert of one run keeping the other's files, Stop of one run) and E2 (feedback sharing against a fake transport: the consent dialog and its preview, the Send feedback window (Send feedback with no mode chosen, the checked rows, unchecking one, Send, Cancel, the AI check against a scripted model that passes, rewrites and fails, a row that cannot be sent), the Add feedback window (Add and Cancel), a closed entry moving to the archive, the Feedback Settings sign-in and Send now, and a mode for this project alone (Always, Never, Follow default, written in the user's file and never inside the project); it never touches the network and writes its settings under `<FA_EDITOR_AUTOTEST_OUT>/share_config`), E3 (the Extensions tab of the AI settings: a plugin folder and pasted hooks added, a role switched off, Save keeping the other keys, a project's hooks needing the trust and a changed file dropping it), S2 (its Token savers section: switches and judge saved in `ai.json` keeping the other keys, the proposals of a project's runs, AGENTS.md and the tool groups changed only by Load up front / Add to AGENTS.md, No thanks), R2 (the Feedback panel's Retrospective button against a scripted fast-role model and a hand-made transcript: an efficiency entry filed with its measured saving, the message and the saving line, and a second click finding nothing new), K2 (the Skills table of that tab: the engine's and the project's skills listed, a role and an On box switched, Save keeping them as skill entries, and a role then being offered exactly the skills left on for it) H2 (its Hooks section: the saved hooks with where each runs, three real runs listed as ok, failed and blocked, Clear) E4 (rejected feedback: the engine rejecting an entry that says `Collider2D` has no one-way option, closed listing the archive, a double click opening an entry in a window, the status box asking for the reason, Copy, Delete asking first, ids not reused, and the engine developers' verdict from a fake server; it shares the clipboard with E, F and N, so it runs in their shard) and F2 (its TokenEconomizer section against a fake Claude Code CLI: the confirmation that runs nothing, the install, the entry added to `ai.json` keeping the other keys, Save, and only the entry offered when the plugin is already installed), and L3 (the Image panel's pixel-art tools: the grid and the Tiled preview, a palette colour added with its Undo and Redo, the primary and secondary colours painting with the two mouse buttons, a frame added with its onion skin and the ghost count, Play and Save baking the PNG) and I2 (the Image panel: a document created and opened, a brush stroke, a rectangle selection, a transform applied from its handles, an adjustment previewed then committed, six undos and six redos, Save baking the PNG whose pixels the section reads back, and Inpaint selection... against the fake provider adding a masked provider layer that Undo takes away), J2 (the Vector panel: an svg opened, a path drawn with the Pen with a dragged curve and closed on its first node, an anchor moved and made smooth with the Node tool, a marquee and Union, Undo and Redo through the editor's stack back to the original file byte for byte, then an image document's svg layer opened with Edit in Vector panel, an ellipse drawn into it, undone, and Save baking the PNG) and K3 (the Sound panel: a patch opened, a macro knob dragged as one undo step, play and stop, a waveform selection and zoom, A/B of variants with matched levels, Undo and Redo, Save baking the variants, an audio document with a step added, moved and enabled, the loop end marker dragged and Save baking `loopEnd`) and M3 (the Music panel: a layered song opened, a note drawn, moved and deleted on the piano roll with Undo and Redo through the editor's stack, a drum hit, a section repeat and a mute in the mixer, play with a moving playhead, the intensity buttons fading the top layer in and out, a looped section, and Save baking the mix and the stems) and N3 (the Model panel: a model document opened, its mesh drawn, a node picked and its part highlighted, a slider clicked as one undo step with Undo and Redo through the editor's stack, a part picked, a node added, switched off and removed, the view orbited, the figure and Check, and Save baking the .glb) and R3 (the Level generator window: a drawn level as the sample, Generate, Next and Previous seed bringing the same level back, Keep building it as one undo step, Save level file and the Replace question) and O3 (the Animation panel's 3D mode: a generated walk opened on its rigged model, a bone picked in the list and in the view, a rotation ring dragged as one undo step, Mirror pose, a key moved and deleted in the dopesheet, an IK handle dragged, scrubbing and Play, the filmstrip and the weights sheet, Generate with Undo and Redo) and P3 (the Particles panel: New, the playing preview, the time scrubber dragged and the same moment showing the same particles, a gradient key and curve keys dragged as one undo step each, a part added and removed, Undo and Redo through the editor's stack). While you work on one part of the editor, run only the sections that cover it:

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
