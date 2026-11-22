# The FactorIA editor

`factoria editor [project]` opens the visual editor (a Dear ImGui window, desktop builds). On Windows, `FactorIA-Editor.exe` (next to
`factoria.exe`) opens it with no console window, like any other program; drop a project folder on it to open that
project. Double-clicking `factoria.exe` opens it too, after a console flashes (with no arguments from a terminal,
`factoria` prints its help). The editor is **AI-first**: you do not edit the project by hand. You tell the built-in **AI Assistant**
what to build or change, watch the result in the viewport, and play it. It is a front end for the same
**commands** that the CLI, the MCP server and the AI tools use: it does not have a private way to change a project. Whatever the AI
does, you can also type in the Console (`scene.set_component {...}`) or call over MCP, and the result is the same.

## Pages

The reference is split by topic (every heading keeps its name, so `docs.read editor --heading <name>` finds it on its page):

- [The AI Assistant and feedback](editor/EDITOR_ASSISTANT.md): The AI Assistant panel and the Sharing feedback window.
- [Updates, export, setup and platform settings](editor/EDITOR_SETUP.md): Updates, exporting, Play on Phone, setting up the computer, platform settings, the program icon and scene files rebuilt on disk.
- [Profiler, level generator, review and play sessions](editor/EDITOR_REVIEW.md): The audio and profiler views, the level generator, the review window and play sessions.
- [Project, image, vector, sound, music and graph panels](editor/EDITOR_PANELS.md): The asset panels: project, image, vector, sound, music and the material graph.
- [Foliage tool](editor/EDITOR_FOLIAGE.md): The brush that paints and erases the instances of a Foliage.
- [Model, particles, animation and bone tools](editor/EDITOR_ANIMATION.md): The model, particles and animation panels and the bone tools.
- [Testing the editor](editor/EDITOR_TESTING.md): The editor autotest: sections, environment variables and how to add a check.

## Opening and creating projects

Without a project the editor starts on the **Open or create a project** dialog (also File > New Project... / Open
Project...). Type a path or press **Browse...** for the system's folder dialog (Windows, macOS; on Linux it needs
`zenity` or `kdialog`): browsing to a project folder opens it at once. New projects go to `<Folder>/<Name>`; Folder
starts at your Documents folder. Recent projects, and projects found in the current folder,
are listed by name under the path; hover one to see its path.

### The Examples tab

The dialog's second tab lists the **example games** of the version you have installed: title, what the game shows, the size of
its download, a green "downloaded" mark when its zip is already in the cache, and the docs to read first (hover a row for their
paths). The download carries no examples, so the list comes from the GitHub release of your version, through the same functions as
`project.examples` and `project.create {example}` (docs/CLI.md).

- **Opening the tab** shows the saved copy of the list at once (it only reads the disk) and refreshes it on a worker thread, so a
  slow or missing connection never freezes the window. A refresh that fails keeps the saved list and says why in a banner with
  **Retry**; with no saved copy (first run, offline) the tab shows the error, what to do and **Retry**. Closing the dialog cancels
  a refresh still running and ignores whatever it brings; the list is read again the next time the tab opens. The tab is never
  loaded while you stay on the Projects tab.
- **Create**: click a row, then give the **Name** (the new folder, proposed from the example's name: `block-push`, or
  `block-push-2` when that folder is not empty) and the **Folder** (the same one New project uses, Documents at first), and press
  **Create project**. The project is made in `<folder>/<name>` on a worker thread with a progress line and **Cancel** (which stops
  the download and leaves nothing); the download is checked against the release's size and SHA-256 before it is unpacked, and a
  failure shows its message and hint under the button and leaves no folder behind. On success the project opens, as it does from
  New project. A folder that exists and is not empty is refused before anything is downloaded.

The projects of the Projects tab no longer include a `~/FactorIA/examples` folder (no package creates one): a clone of the
repository still lists its `examples/` when the editor starts in it.

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
- **Copy, Cut and Paste of entities have no key shown in the system menu**: binding Cmd+C there would take the key from
  the Animation panel and the other panels that use it. The keys work all the same while the Hierarchy or the Viewport has
  the keyboard (see "Copy, cut, paste and duplicate"); hovering the item says so.
- A click on a menu item does its work at the start of the next editor frame, never inside the system's menu event.
  Hovering an item shows the same tooltips as the in-window bar. **Open Scene** and **Recent Projects** are read only
  when you open them.

`FA_EDITOR_NATIVE_MENU=0` makes the macOS editor draw the in-window bar instead, as on the other systems (the editor
autotest does this by itself: it clicks the bar with injected mouse events).

## Layout

The AI builds the game, so the window (maximized on Windows) is the game view and the AI chat: **Hierarchy** over **Inspector** on the left,
the **Viewport** in the middle, **AI Assistant** on the right, and Console / Project / Engine Feedback / Audio / Profiler as tabs
under the view. You can also edit by hand with the Hierarchy and the Inspector, by dragging gizmos in the Viewport (below) and by
dragging files from the Project panel ([Project panel](editor/EDITOR_PANELS.md#project-panel)). Use Undo to take back what it or you did. View > Reset layout restores this layout.

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
| Viewport | The game as the engine renders it (post-effects such as the bloom and the colour filter of a `PostProcess` included): there is no second editor camera, so a perspective camera that clears shows the sky of the scene (the gradient, or `skyMaterial`) exactly as the game does, and a camera with `lighting: "studio"` shows its `clearColor` instead, with the scene's lights and fog left out, here too. Click an entity to select it: the selection outline shows what you point at; the gizmos move, rotate and scale it ([Gizmos](#gizmos)). Its title shows the mode, game size and zoom (`EDIT  1280x720  50%`); Play focuses it, so keys reach the game without a click (unless you are typing in another panel). |
| AI Assistant | The built-in agent: describe what to build or change (see AI_PROVIDERS.md for the providers). |
| Project | The project's files: folder tree, filter, search, thumbnails; drag files onto the Inspector and the Viewport ([Project panel](editor/EDITOR_PANELS.md#project-panel)). |
| Console | The log (each line starts with the computer's local time `HH:MM:SS.mmm`; hover it for the date, the frame and the seconds since start), and a command line: `name {json}` runs a command, `> code` runs JavaScript, `help` lists commands. |
| Engine Feedback | The project's `ENGINE_FEEDBACK.json`: what the AI found missing in the engine. The panel keeps its size however long an entry is: only the entries table and the text of the selected entry scroll. An entry that is not open moves to `ENGINE_FEEDBACK.archive.json` by itself (when the project opens and when you change its status in the panel). Three buttons: **Add feedback** (a form that records an entry), **Send feedback** (shares open entries with the engine developers, [Sharing feedback](editor/EDITOR_ASSISTANT.md#sharing-feedback)) and **Retrospective** (looks back at the project's recorded AI runs, files at most three efficiency entries with one short call of the fast role, and says what it did; it costs a model call, see [Retrospective](ai-providers/AI_PROVIDERS_EXTENSIONS.md#retrospective)); the table has a share column. A line under the buttons adds up what the open efficiency entries' fixes would save per game. |
| Audio | (View > Audio) the live `audio.log`. |
| Profiler | (View > Profiler) where the time of a frame goes while the game plays. |
| Post-processing | (View > Post-processing, a window) the post-processing stack of a camera: every effect in the order it runs with its switch, whether this renderer draws it, its fields and where each value comes from (the camera's own PostProcess or a volume), a button per look (neutral, cinematic, retro, noir, dreamy, vivid, horror) and **Stack off (A/B)** to compare with the game drawn without post-processing. Edits go through `postprocess.set` / `postprocess.apply_preset` to the camera or to a volume you pick, one undo step each ([docs/RENDERING.md](RENDERING.md), "Reading and changing the stack"). |
| Level generator | (View > Level generator, a window) makes a level from a sample you drew, tries other seeds and keeps one ([Level generator](editor/EDITOR_REVIEW.md#level-generator)). |
| Animation | (View > Animation, a tab next to Console) the clips of the selected entity's Animator as a dopesheet or curves, with record mode ([Animation panel](editor/EDITOR_ANIMATION.md#animation-panel)). |
| Bone tools | (View > Bone tools, a tab next to Inspector) draw a bone chain, bind a sprite, paint weights, drag IK targets ([Bone tools](editor/EDITOR_ANIMATION.md#bone-tools)). |
| Scene settings | (View > Scene settings, a window) the scene's own settings (`SceneSettings`: sky colours, the sky material and its params, fog, ambient light, gravity, music, colour space) in groups, every change one undo step ([Scene settings panel](editor/EDITOR_PANELS.md#scene-settings-panel)). |
| Lightmap | (View > Lightmap, a window) bakes the scene's baked lights, its sky, its lit meshes and its light probes into lightmaps on a job thread: the bake options, a progress bar with the phase, Cancel, the pages, texels and probes of the result, a Show probes toggle for the probe gizmo and teaching errors; a finished bake sets `SceneSettings.lightmaps` as one undo step ([Lightmap panel](editor/EDITOR_PANELS.md#lightmap-panel)). |
| Terrain tool | (View > Terrain tool, a tab next to Inspector) brushes on the selected `Terrain`: sculpt (raise, lower, smooth, flatten), paint a layer, cut and fill holes; radius, strength, falloff, a cursor ring on the ground, `[` `]` for the radius; a stroke is one undo step and Save writes the terrain files ([Terrain tool](editor/EDITOR_PANELS.md#terrain-tool)). |
| Foliage tool | (View > Foliage tool, a tab next to Inspector) a brush on the selected `Foliage`: add or remove instances (Ctrl swaps them), radius, density and mesh, Scatter all and Clear (it asks first), a cursor ring on the terrain; a stroke is one undo step, Esc takes it back ([Foliage tool](editor/EDITOR_FOLIAGE.md#foliage-tool)). |
| Cells | (View > Cells, a window) edits the cells of a streamed world in Edit mode, where nothing streams by distance: load the cells around the camera or the ones you pick, see which have unsaved changes (also drawn as a grid in the viewport), unload, select a cell's root, and Save writes only the changed cells (an entity moved across a border goes to the other cell's file) ([Cells panel](editor/EDITOR_PANELS.md#cells-panel)). |
| Graph | (View > Graph, a window) the node graph of a material: nodes and links on a canvas, a searchable palette, a live lit preview (param sliders that change only the preview with Set as default, a Compare with the saved version, a compiler error painted on its node), the problems list, Save runs `material.graph.generate` ([Graph panel](editor/EDITOR_PANELS.md#graph-panel)). |

Play snapshots the scene and runs the game; Stop restores the snapshot, so edits made while playing are temporary. For that
reason the AI works in edit mode only: while the game runs (Play or Pause) its Run button is disabled ("game running: Stop it
to send"), and while it is working Play and Step are disabled until it finishes or you press Stop in the AI panel. The Console
still runs commands during play, to inspect or poke the running game. Ctrl+Z / Ctrl+Y
(toolbar and Edit menu too) undo and redo scene edits: the ones made by the AI and by commands typed in the Console. Undo does
not touch files; to take back a whole AI run, scripts included, use Revert ([Revert an AI run](editor/EDITOR_ASSISTANT.md#revert-an-ai-run)). View >
Show navmesh draws the walkable cells of every NavMesh3D (green; red where a moving obstacle blocks; blue on a walkable moving body, Collider3D.navWalkable) and its off-mesh links (NavLink3D: a yellow line, with an arrowhead when one-way) (docs/NAVIGATION.md). View > Show light probes draws the probes of every LightProbeGroup (a sphere coloured by the light it baked, grey before a bake or after the group was edited, a red cross inside geometry); the Lightmap panel's Show probes is the same switch ([Lightmap panel](editor/EDITOR_PANELS.md#lightmap-panel)). A selected RealtimeGI draws, in a perspective view, the box its probes fill (green) and a marker per probe (a filled green dot once captured, a grey ring while it waits for its first capture; at most 2048, a stride beyond that); probes inside geometry are not marked, `render.gi_grid` lists them. Show colliders and Selection overlay toggle the collider boxes and the selection outline in the viewport. With a 2D camera, Selection overlay also draws the bones of the selection (docs/ANIMATION.md, "Bones and IK"): a thin kite from the origin to the tip of every `Bone2D` on the selected entity and below it, and of the bones a selected sprite's `SpriteSkin` names; the selected bone itself is yellow, the rest cyan. The overlay only shows them; moving them is done with the Transform gizmos or the Inspector, and drawing, binding and weight painting are in View > Bone tools ([Bone tools](editor/EDITOR_ANIMATION.md#bone-tools)).

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

## Undo entries

Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z (the toolbar and the Edit menu) walk two stacks of steps, at most 100 each and 256 MB of memory
in all (the oldest steps go first). A step is one of three kinds:

- **Command steps** hold two short lists of commands: what Redo runs and what Undo runs (the inverse, built from the scene just
  before the edit). They store no copy of the scene, so a hundred of them cost less than one copy of a big scene. These edits are
  command steps: an Inspector field (typing, dragging, a checkbox, a color, a material param, an animator clip), a rename or the
  active box in the Hierarchy, a Transform gizmo drag (one entity or a group), adding a component and removing one from the
  Inspector, and the structural edits: creating an entity (`scene.spawn`, also from the Project panel's drops), deleting one or
  a multi-selection, Duplicate, Cut and Paste (`scene.paste_entities`), dragging an entity onto another parent
  (`scene.set_parent`), creating a bone chain (`bones.create`), and a terrain edit (a brush stroke or
  `terrain.sculpt|paint|holes|generate` from the Console, the AI or MCP: `terrain.undo` / `terrain.redo`,
  [Terrain tool](editor/EDITOR_PANELS.md#terrain-tool)). Undo of a set sets the old value of exactly the fields the edit
  named (a component the entity did not have is removed again), and Undo of a removed component adds it back with every field it
  had. Undo of a destroy pastes the entity back with its components and its whole subtree under the SAME ids, in the same parent
  and at the same sibling index, with the references that pointed at it from outside the subtree (a Joint, a UI target) set
  again, and a prefab instance comes back linked to its prefab with its overrides (`prefab.overrides` shows the same ones).
  Undo of a spawn or a paste destroys the created entities, and Redo creates them again with the same ids. Undo of a
  reparent puts the old parent, the old index and the exact old local Transform back (not a recomputed one), so a widget that
  was nudged inside a layout Panel returns with its nudge and the layout pass recomputes the slot. One drag, or a value typed over
  a moment, is ONE step: the same edit within 0.8 s replaces the newest step's Redo and keeps its Undo, so Undo goes back to the
  value before the drag. An edit that several entities share (a field of a multi-selection, a group drag, deleting or reparenting
  a selection, Paste of several entities) is still one step. The Console and the AI panel go through the same path: a command
  that has an inverse is a command step. A step is applied whole or not at all: when one of its commands fails, the scene is put
  back as it was, the step is dropped and a toast names the command and its message. One exception: the order of the top-level
  entities is the order they were created in (it is the order of `entities[]` in the scene file, and it decides which of
  two top-level entities that tie in layer or depth is drawn first), and commands can only create an entity last. So
  deleting a top-level entity that has other top-level entities after it is a snapshot step; deleting the last one, or a
  child at any depth, is a command step. A subtree deeper than 64 levels is a snapshot step too (Undo pastes the entity
  back, and a paste refuses text nested deeper). A multi-selection delete is one step of one kind: a snapshot as soon as one of
  its entities needs it. Moving an entity under another parent and back keeps its place, so a reparent is always a command
  step; one that changes nothing (to the parent and place the entity already has) is no step at all.
  Known limits: (1) an entity that Undo brings back goes to the end of the component pools, so two entities that tie in
  drawing order (same Sprite layer and y) can swap which one is drawn first in the edit view until the next Play or reload; the
  scene file keeps its order. (2) Several commands under ONE key (the Console's lines of one frame, one AI call) are one step
  when the first of them takes a snapshot, but two steps when a command step comes first and a snapshot step after it: undo
  them one after the other. Only the Hierarchy picks the kind for a whole selection.
- **Snapshot steps** hold the whole scene. What is left takes one because its change is too large or is not a scene edit
  through a command with an inverse: deleting a top-level entity that is not the last one (see above); `scene.import_ascii` (the Level generator's Keep) and `scene.ascii_edit`, which
  replace many entities at once; `script.eval` (the Console's `>` line), whose effect cannot be known; `prefab.revert` and
  `prefab.apply`, which rewrite instances or the prefab file; `skin.*` weight edits (bone tools painting weights and
  auto-weights) and other commands without an inverse; asset file commands of the Project panel (`fs.*`,
  `assets.regenerate`); and an AI revert (it restores the scene the AI started from). Animation clip edits are document steps
  of the clip (`$clip`), not scene snapshots. A snapshot step and a command step never merge into each other, even with the
  same key.
- **Document steps** belong to a panel (clip, image, drawing, sound, effect, song, model); the panel undoes them.

Both stacks are cleared when another scene is opened or reloaded. Play and Stop keep them: the entities keep their ids. Undo and Redo
are off while the game runs (Play, Pause): edits then change the running game, add no step and are lost on Stop. A refused edit
adds no step and keeps the Redo list. While an animation is posed, the step is built from the rest values, not the pose, and Undo
and Redo put the pose off and on again around the step.

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
Not here yet: panning or zooming the view independently of the game camera, a local/world
axis switch. With several entities selected the gizmo moves, rotates or scales all of them about the primary
([Selecting things](#selecting-things)).

## Hierarchy and Inspector

Hand editing uses the commands the AI uses (`scene.set_component`, `scene.set_parent`, `scene.spawn`, `scene.destroy`...), so
every change is an Undo step (a drag is one step), marks the scene dirty, and Save writes it to the scene file. Both panels
are in the View menu.

**Hierarchy.** Roots and children with their names and ids. Click an entity to select it (the viewport outline follows,
and a click in the viewport scrolls the tree to the entity). Drag an entity onto another to make it a child
(`scene.set_parent`: it keeps its place on screen) or onto the empty space under the tree to make it a root; a cycle is
refused with the reason. Right-click: Create empty child, Duplicate (the entity and its children get new ids), Copy, Cut,
Paste (see "Copy, cut, paste and duplicate"), Rename, Active, Move to the top level, Delete (also the Del key). **+** and the right-click menu of the empty space create a
top-level entity. The search box keeps the entities whose name or id contains every word typed.

**Inspector.** One collapsing header per component of the selected entity (hover the header for the component's
description, the x removes it; Transform and EntityInfo stay). One row per field, built from reflection: tick box for
bool, drag for numbers (the field's range limits the drag; click a number to type it), eight toggles (layers 0 to 7, lit = in the mask; they wrap into rows of 4 or 2 in a narrow Inspector) above the number for every `lightLayers` mask (Sprite, Shape2D, Tilemap, Light2D, ShadowCaster2D; a click flips one bit and keeps the others, also of each entity of a multi-selection; the number reaches layers 8 to 31 and -1 for all), vectors and rects as one drag per
number, a colour picker, a drop-down for enums and for entity references (by id), a text box plus a file list for assets
(only files of the right type), and a multi-line text box for free-form JSON (`Script.props`...) that is applied when you
click away and refuses invalid JSON, showing the parse error. A number array longer than 512 elements (a big tile map, the vertices of a sprite mesh of more than 128 points) shows only its length, not its numbers: the Inspector rebuilds its JSON every frame, so edit such a field with `scene.set_component`, a script or the file. Hover a name for the field's doc string and range. Read-only
fields (the entity id) are disabled and runtime-only state is not shown. A value the command refuses (outside the range)
changes nothing and its message shows under the field. **Add Component** lists the components the entity lacks. With
several entities selected the Inspector shows what they share ([Selecting things](#selecting-things)).

**MeshRenderer.** `material` is a file list of `*.material.json`. `materialParams` is typed by the material's `material.info`:
one widget per param (drag with its `min`/`max`, vectors, a colour picker), an `*` and a **Reset** button when this entity
overrides the default (written with `scene.set_component` and `merge: true`). Under the material field a material that does
not compile shows its error with the snippet's file and line; it disappears when the material builds again. Texture params
of a material are not editable here yet (use the Console or the AI). **Render cost** under the fields says what the entity's material costs the renderer
(the answer of `render.material_cost`, asked about twice a second, never computed by the editor): a summary line ("transmission (+6 passes); 6 extra passes
in all") and the active features, each with its note as a tooltip. [Transmission and the cost view](rendering/RENDERING_TRANSMISSION.md).

**Prefab instances.** An entity a prefab file made (a scene entry with `prefab`, `scene.spawn {prefab}`, a prefab dropped on the
viewport) shows its prefab under its name: the path, and `Part of prefab <path> (<root id>)` for something below the root. The
Inspector asks `prefab.overrides` for it and marks what differs from the file: the label of an overridden field is blue (hover
it: the prefab's value is in the tooltip), a component header says `(N overridden)` or `(added to the instance)`, and a line
under the name counts the overrides. Where the instance stands (the root's `Transform.position`) is never an override.
Everything below goes through the commands, so the Console and the AI can do the same:

- **Revert to prefab** (right-click an overridden field; right-click a component header for the whole component; **Revert all**
  in the instance's header for everything of the selected entity and below, added components and children included) calls
  `prefab.revert`. It is one Undo step, and all or nothing: when one part cannot be put back, none is. A component the
  instance removed is not drawn (the entity no longer has it): the header names it (`Removed from the prefab: ...`) and Revert
  all gives it back.
- **Apply to prefab** (the same menus; **Apply all** asks first) calls `prefab.apply`: the value is written into the prefab
  file, which keeps its own structure (nested prefabs and the parts you did not touch stay) but is written back in the
  engine's own JSON layout, like a saved scene (its indentation and line endings are normalized, so the first Apply of a
  hand-formatted file changes every line), and every other instance of that
  prefab in the open scene gets the same change, except where it overrides that very value. Apply looks at every instance of
  the prefab in the scene, so it takes longer with hundreds. A child you added under an
  instance becomes a part of the prefab (and of every other instance). Undo puts the open scene back, not the prefab file
  (use version control for that), and the editor says so when you do it: after the Undo the instances show the difference
  against the file as overrides, so Revert them or Apply again. A component the instance removed is deleted from the prefab
  file (and from the other instances, even from one that overrides some of its fields: the toast and the command's `notes` name
  it); a prefab child the instance removed cannot be listed (the children are paired by position, so the rest would be
  matched with the wrong parts), so such an instance is refused, like one with a child added under a part of the prefab, with
  the reason; a read-only prefab file is refused too, and `prefab.overrides` marks what the file has no place for
  (`applyBlocked`). Apply is greyed out while the game plays (the running game's values are not the scene's, and the file is
  written for good), with the reason in its tooltip; Revert stays. Instances of the prefab that sit inside another prefab are
  updated after `scene.reload`.

**While the game plays** both panels edit the running game; an orange note says the edits are lost on Stop (and they add no
Undo step).

## Selecting things

Clicking in the viewport selects the entity under the cursor; the selection is how you point at something ("make this one bigger").

Inside the editor the selection is a set (`tools/editor/src/selection.h`): an ordered list of entity ids (the `World::id_of` strings,
so it survives an undo or a scene load) and one primary, the id selected last. `Editor::selected()` and `selected_id()` are the
primary, so everything that works on one entity (the Inspector, the gizmos, the AI's "this") is unchanged; `Editor::selection()` is
the set. The set has `replace`, `add`, `toggle` (Ctrl-click), `range` (Shift-click, over the ids in the order the Hierarchy
lists them), `remove`, `clear` and `prune`. `Editor::selection()` prunes the set (it drops the ids whose entity no longer
exists) only in Edit: while the game plays or is paused it destroys and loads entities that come back on Stop, so the set keeps
its ids and every reader skips one that is gone (`selected()` is empty when the primary is). Code that only draws uses
`selection_peek()`, which reads without changing it. Ctrl+click on the primary removes it and the last id left becomes the
primary (the removed row stays the anchor of the next Shift click). Copy and paste build on this set (M98.7).

**Selecting several entities** (Ctrl is Cmd on macOS):

- **Hierarchy:** a click selects one row; **Ctrl+click** toggles a row; **Shift+click** selects the rows from the last row
  clicked without Shift to this one, in the order the tree shows them (rows hidden inside a collapsed parent are not in that
  order); **Ctrl+Shift+click** adds that range. Selected rows are highlighted and the primary has a yellow bar. Right-click on
  a row that is not selected selects it; on a selected row it keeps the selection. A click on empty space clears the selection
  (not with Ctrl or Shift held). Dragging a selected row drags the whole selection (the preview says "N entities"): the
  entities keep their order, and one whose ancestor is also selected is skipped because it moves with that ancestor.
  **Duplicate (N)** and **Delete (N)** in the right-click menu, and the Del key, act on the whole selection and are ONE Undo
  step each (the children of a selected entity are copied or deleted with it, once). The copy of the primary becomes the
  primary.
  Copy, Cut and Paste work on the whole selection too (next section).
- **Viewport:** a click selects the entity under the cursor; **Ctrl+click** toggles it, **Shift+click** adds it. Dragging
  on empty space draws a **marquee**: it selects the entities whose outline (the picked bounds below) it covers completely
  (a 3D mesh with a corner of its box behind the camera is never covered: that corner has no place on the screen; with
  several cameras on the screen, the camera under the centre of the marquee decides what is drawn and what is behind it)
  and replaces the selection; with **Shift** it adds them, with **Ctrl** it toggles each. A plain click on empty space clears
  the selection. Every selected entity is outlined: the primary in yellow, the others in orange.
- **Gizmos:** the handles sit at the primary's world position, which is the pivot (there is no other pivot setting). Move,
  rotate and scale apply to every selected entity relative to that pivot, as ONE Undo step: move shifts all by the same world
  offset, rotate turns their positions about the pivot and their own rotation by the same angle, scale scales their offsets
  from the pivot and their own scale by the same factor. An entity whose ancestor is also selected is skipped, since it
  follows that ancestor. Esc puts every entity back. While the animation recorder is on, a multi-selection has no handles
  (a clip key belongs to one entity). A selection that mixes screen-space (HUD) entities, which move in design pixels, with
  world entities has no handles either (one offset cannot mean both), and a toast says so; edit their Transform in the
  Inspector.
- **Inspector:** the header reads "N entities" and shows the components EVERY selected entity has. A field with the same
  value everywhere shows it; one that differs shows "—". Editing a field writes it to all the entities as ONE Undo step and
  leaves their other fields as they are (editing `rotation` keeps each entity's own `position`). Free-form JSON and
  `materialParams` that differ between the entities cannot be edited in this mode. A component only some of the entities have
  is listed as not shared and is not editable. **Add Component** lists the components at least one entity lacks, with
  "(k of N)", and adds the component to every selected entity that lacks it (one Undo step); the x of a header removes the
  component from all of them. When one entity refuses an edit, the ones before it keep the change (it is still one Undo
  step) and the message says "Changed k of N entities" (Add Component and the x of a header say it too). In a number that
  differs ("—") typing the primary's own value writes it to all the entities once you press Enter, or leave the box (Tab, a
  click outside) after changing its text; Esc restores the text in the box (a value already written while typing stays).
- **AI Assistant:** "this" and "it" mean the primary; the context names it and lists the ids of the others (the first 20,
  `scene.list_entities` has the rest), and "these" and "them" mean all of them. No command or flag changed: commands still
  take entity ids.

## Copy, cut, paste and duplicate

**Edit > Copy / Cut / Paste / Duplicate** and the Hierarchy row menu act on the selected entities. The keys are **Ctrl+C**,
**Ctrl+X**, **Ctrl+V** (Cmd on macOS) while the **Hierarchy** or the **Viewport** has the keyboard in Edit mode, and no text box
does (a text box copies and pastes its own text; the Animation, Image and other panels keep these keys for themselves). With
nothing selected Copy and Cut do nothing.

- **Copy** puts the selected entities, each with all its children, on the **system clipboard** as JSON text (the command
  `scene.copy_entities`). An entity whose ancestor is also selected is copied with that ancestor, once. Nothing in the scene
  changes and no Undo step is recorded. The text holds components, children and the links of prefab instances to their prefabs,
  and no path of this machine, so it can be pasted into another scene, another project or another editor, kept in a note, or
  handed to an AI (`scene.paste_entities`).
- **Paste** (the command `scene.paste_entities`) creates what the clipboard holds **next to the primary**: under the
  primary's parent, or at the top level when the primary is a root or nothing is selected. It is ONE Undo step. The pasted
  entities become the selection, and the copy of the entity that was the primary when you copied is the new primary. Every pasted
  entity gets an id free in the scene: its old id when that is free (pasting into another scene), else the next number
  (`coin_3` becomes `coin_4`). If the clipboard holds text that is not copied entities, the editor says so and changes nothing.
  After a **Cut** the selection is empty, so a Paste goes to the top level (not to where the cut entities were): select an
  entity first to paste next to it, or Undo the Cut.
- **Cut** is Copy and then Delete, as ONE Undo step: Undo brings the entities back, and the text stays on the clipboard until
  you copy something else.
- **Duplicate** is a Copy and a Paste in one go: each copy goes under the same parent as its original, named "<name> copy",
  with a new id, and the copies become the selection (the copy of the primary stays the primary). It does not touch the
  clipboard.

**References.** An Entity field (a Joint's `connected`, for example) that names an entity inside the copied set names the
**copy** after a paste or a Duplicate, so a copied pair stays a pair. A field that names an entity outside the set (a joint to
a wall that was not copied) keeps naming it when the scene you paste into has an entity with that id (so Duplicate keeps it),
and is **cleared** when it has not; the editor counts the cleared references in its message, and `scene.paste_entities` lists
each one in `cleared` (`entity`, `component`, `field`, `target`). Runtime state (velocities, animation time) is not copied, and
a field an animation drives is copied at its rest value. Only Entity fields are remapped: an entity id written inside a
Json field (a script's `props`, for example) is copied as it is.

A copy must fit the system clipboard the editor asks for (1 MB of text). A bigger one is refused with a message that says its
size, and **Cut then deletes nothing**: copy fewer entities, or use `scene.copy_entities` from a script or the MCP tools.

The outline of the selected entity comes from the engine's own geometry (`fa/scene/bounds.h`), the code behind
`entity.bounds()` in scripts, so what the editor outlines is what a script measures:

- a **Sprite** or **Shape2D** is its size box placed by `pivot` (a triangle with pivot `[0.5, 0.3333]` keeps its whole box around
  the entity); a **diamond** is outlined by its size box and, thinner, by its four tips; **Text** by the laid-out text box;
  a **Tilemap** by `width` x `height` times `tileSize`, from its top-left corner (an isometric one by the box around its diamonds and the tile images; the editor has no tile painting tool, `tilemap.set_tile` and `scene.import_ascii` write the tiles);
- **rotation and scale** are applied: the outline and the click area are the turned box, not the box around it;
- an entity with several visuals (a Sprite and a Text) is selectable on any of them, the highest `layer` wins;
- **screen-space** items (`space: "screen"`, the HUD) are outlined and picked on the screen with their `anchor`, which
  `entity.bounds()` does not do (it returns `null` for them);
- entities that draw nothing get a small handle, colliders their collider box.

While the game runs, clicks and keys go to the game instead (click the viewport to give it the keyboard).
