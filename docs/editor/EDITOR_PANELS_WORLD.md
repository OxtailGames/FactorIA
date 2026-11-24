Part of [EDITOR.md](../EDITOR.md): The world panels: lightmap, terrain, cells, scene settings and graph. The asset panels are on [Editor: panels](EDITOR_PANELS.md).

# Editor: world panels

## Lightmap panel

View > Lightmap bakes the open scene's lightmaps: the same bake as the `lightmap.bake_start`, `lightmap.bake_status` and `lightmap.bake_cancel`
commands (docs/rendering/RENDERING_LIGHTING.md, "Baking"), on a job thread, so the editor keeps drawing and you can keep working.

- **Options.** Texels per meter (16 is a good start; 64 is sharp and 16 times heavier), Samples (gather rays per texel: 16 is a draft, 64 is
  smooth), Shadow samples, Page size, Sky (`auto`, `environment`, `gradient`, `ambient`, `none`) and the Manifest path (empty: next to the
  scene, `scenes/main.lightmap.json`). Each has its tooltip.
- **Start and Cancel.** Start is disabled while a bake runs and while the game plays. The bar shows the phase (geometry, layout, prepare,
  rasterize, trace, denoise, dilate, writing), the percentage and, after a few seconds, the time left; Cancel stops it within a moment and no
  file is changed.
- **The result.** A finished bake lists its pages (file and size), the texels, the meshes, the rays and the time, the skipped entities with
  their reason, and the warnings (a physical sky that fell back to the gradient, a Tube light baked as a rectangle).
- **Light probes.** The bake also bakes the `LightProbeGroup` entities of the scene (phase `probes`) and the result says how many probes there are and how many lie inside geometry (ignored). **Show probes** draws them in the 3D viewport: a sphere per probe coloured by the light it baked (grey before the first bake or after the group was edited, a red cross for a probe inside geometry); `LightProbeGroup.showGizmo` hides one group (docs/rendering/RENDERING_LIGHT_PROBES.md). View > Show light probes is the same switch. At most 2048 probes are drawn in all (a stride over every group, so a big scene shows a sample) and probes behind the camera are not drawn. When groups were edited after the bake, the panel shows an orange line "N light probe groups changed since the last bake" (the same groups are grey in the viewport): bake again to refresh them.
- **The scene.** The panel starts the bake without `apply` and then sets `SceneSettings.lightmaps` through the editor's own edit path: one undo
  step, the scene marked as changed (Save keeps it). It does not set it when another scene was opened meanwhile or the game is running; the
  panel says so and where the files are.
- **Errors.** A refused start (no mesh to light, a bad option, a manifest outside the project, a bake already running) or a failed one (a file
  that is open in another program cannot be replaced on Windows) is shown in the panel with what to change; nothing is half written.

## Terrain tool

View > Terrain tool opens a panel (a tab next to Inspector) and, while one of its three modes is on and an entity with a `Terrain`
component is selected, the viewport paints on the terrain instead of selecting and moving: the gizmo is off and a click and drag is a
brush stroke. Click the mode again to leave it. It works in edit mode only (the brush changes the scene; Stop the game first). The
tool is the editor's face of `terrain.sculpt`, `terrain.paint` and `terrain.holes` (docs/BIG_WORLDS_TERRAIN.md, "Terrain"): every stroke is
those commands, so a script or the AI can do the same.

- **Sculpt.** Raise, Lower, Smooth, Flatten. Raise and Lower take an `amount` in metres (the change at the middle of the brush for
  one stamp at full strength; the stamps are a quarter of the radius apart, so the ground under the brush gets several). Hold Ctrl
  (Cmd on a Mac) while you stroke to do the other one (Raise lowers, Lower raises). Flatten levels to the height under your first click (the
  default) or to a height you type; **Pick from the terrain** (or Alt+click) takes that height from the ground under the next click.
- **Paint.** The layers of `Terrain.layers` as a list with their albedo texture's thumbnail and file name; pick one and stroke. A
  terrain with no layers says to add them in the Inspector. The first stroke makes the splat map and sets `Terrain.splatMaps`.
- **Holes.** Cut or Fill (Ctrl, Cmd on a Mac, swaps them). The first cut sets `Terrain.holes`. A brush smaller than a cell can miss every cell. The brush aims at the surface as if no cell were cut, so a hole can be aimed at and filled again.
- **Brush.** Radius in metres (never more than half the terrain or about 900 texels of the plane the mode edits: the heights and holes for Sculpt and Holes, the splat map for Paint, which can be finer), strength 0 to 1 and falloff 0 to 1 (1 fades from
  the middle to the edge, 0 is a hard edge). With the mouse over the viewport: `[` and `]` make the radius smaller and bigger, Shift+`[`
  and Shift+`]` change the strength, Esc takes the stroke you are drawing back.
- **The cursor.** A ring of the brush's radius lies on the terrain under the mouse, following its relief (yellow for sculpt, blue for
  paint, red for holes); a second, fainter ring inside it shows where the effect is at full strength (radius times one minus falloff).
- **A stroke is one undo step.** While the mouse is down the stamps (one every radius / 4 along the path) go to the terrain as the mouse
  moves, so you see the ground change. They are sent as a few command calls that share ONE step of the terrain's own history
  (`continueStroke`): a call per frame would push the 64 steps of that history out in a second. When you let go the editor records one
  undo entry that runs `terrain.undo` (Ctrl+Z; the whole stroke goes back, sample for sample) and `terrain.redo` (Ctrl+Shift+Z, Ctrl+Y),
  and marks the scene as changed. A stroke stops at 20000 stamps.
- **Saving.** The terrain's files (heightmap, holes image, splat maps) are not in the scene file; Save writes them after it. If one
  cannot be written (a folder where the file goes, a file open in another program) a toast says which and why, nothing is marked as
  saved and every edit is still in memory. Closing the editor, reloading the scene and opening another one ask first when a terrain has
  edits not written yet, even if the scene itself is clean (a terrain changed by a command from the Console or the AI counts too).
- **Undo, Play and Stop.** Ctrl+Z of another edit (a moved entity) reloads the scene from a snapshot; a terrain with unsaved
  edits or history is kept across that. Play gives the game its own copy of those terrains: what the game does to the ground, holes and
  splat maps is gone at Stop, which gives back exactly what the editor had, history included. A terrain edit from the Console, the AI or
  MCP (`terrain.sculpt`, `paint`, `holes`, `generate`) is one undo entry too, like a stroke. The terrain keeps 64 steps / 256 MB:
  when it lets go of its oldest step, the editor takes that step out of the oldest terrain entries of the undo list (an entry
  that also holds other edits keeps them) and a toast says how many. A `terrain.undo` run by hand (Console, MCP) takes the
  terrain's own newest step without touching the undo list, so Ctrl+Z and the terrain can disagree afterwards: use one or the
  other. Every terrain undo of the list carries the number of its step (the steps the terrain let go, plus its depth), so the editor drops
  exactly the steps the terrain let go: neither a call by hand, nor the list trimming its own oldest entries, makes it drop a step
  that still works. Undo of the first holes or paint
  stroke also takes the `Terrain.holes` or `Terrain.splatMaps` path it set back (a file already written stays on disk, unused). Esc gives
  back the unsaved state the stroke found. A click that misses the terrain keeps it selected and the tool on.

The brush itself (settings, stamps along the mouse path, the ring, the ray to the ground) is the editor's shared `brush.h`, which the
other viewport brush tools use too.

## Cells panel

View > Cells edits the cells of a streamed world (docs/BIG_WORLDS_STREAMING.md, "Editing a streamed world"). It works when the open scene has a
`StreamedWorld` whose index can be read, in Edit mode: while the game plays it only says so.

- **Nothing streams in Edit mode.** The engine is paused, so no anchor loads or unloads a cell: a cell is in the scene only when you load it, and an
  edited cell is never lost by the distance to the camera. The editor has no free camera, so "around the view" means around the scene's camera
  (the one the viewport draws through).
- **The list** shows every loaded cell and the nearest ones of the index (at most 200 rows, nearest first): the cell, its state (not loaded, loaded with
  its entity count, unsaved, "(new)" when Save will add it to the index) and the distance to it. Load puts the cell in the scene under its root entity
  `cell_<i>_<j>`; Unload removes it (a cell with unsaved changes asks: Save and unload, Discard changes and unload, Cancel); Select selects the root,
  which the Hierarchy and Inspector then show and the grid draws thicker.
- **Load around the view** loads the cells within N cells of the camera (the drag box, 0 to 8; 0 is the cell under the camera), nearest first. One click loads at
  most 64 cells and says how many more were in range; at most 256 cells are loaded at once. **Unload clean** unloads every loaded cell without unsaved changes.
  **Read the index again** reads the index file again (a tool changed it); the loaded cells stay loaded.
- **Save cells** writes each unsaved cell to its own file, and the index only when a cell was added or a saved cell's height range (3D: follows its entities, up or down) or listed
  `sizeBytes` changed; the toolbar's Save and Ctrl+S do the same, together with the open scene. Deleting the root of a cell with unsaved changes
  keeps it unsaved and empty ("root deleted" in the list): Save writes it with no entities, Undo brings it back. An entity whose position is now in another cell is written into that cell (see "Editing a streamed
  world": no command is needed for it). A failure (a path outside the write rules, a cell file that is not in the index) changes nothing and the panel
  says why. Save reads the index file again just before it writes it and keeps the `hlod` entries it finds there (what `world.bake_cell_hlods` wrote
  while the cells were open); when that file cannot be read, the editor's copy is written over it and the report says so in a note.
- **Show the grid** draws the cells in the viewport on the plane of the world: green loaded, orange with unsaved changes (the label gets a `*`), grey not
  loaded; the selected entity's cell is thicker. The Inspector says "Cell i,j" for an entity in a loaded cell, with the unsaved mark, and "Save moves it
  there" when its position is in another cell.
- **Undo** works across cells: the editor's snapshots include the loaded cells, and undoing back to the saved state clears the unsaved mark. **Play** streams
  by distance as the game does and **Stop** brings the cells you had loaded back, with their changes.

**Autotest.** Section W2 writes a 2D world of three cells into the project, loads the one under the camera and checks that nothing else streams, edits an
entity (only its cell turns unsaved), saves (only that file is written, not the index), moves an entity across the border and saves (it moves to the other
cell's file), plays (the game streams by distance) and stops (the same cells are back, clean).

## Scene settings panel

View > Scene settings opens a window with the settings of the open scene, the ones the file keeps under `settings` and the
Inspector never shows because they belong to no entity (`SceneSettings`, listed by `docs.components`). The fields come from the
component's reflection, in groups (Sky, Fog, Lighting, Physics, Music, Output; a field added to `SceneSettings` later lands in
"Other" and is never hidden), each with its doc as a tooltip, drawn by the same widgets as the Inspector.

- **Sky material.** `skyMaterial` is a picker of the project's `*.material.json` files. Under it the panel says what the material is
  (a sky one, another kind that cannot draw the sky, a file that cannot be read, a build error the renderer reported) and, for a sky
  material, shows one control per param typed by `material.info`, each with a Reset that removes its override
  ([SHADERS.md](../SHADERS.md), "Sky materials"). The reflections and the ambient light of the meshes keep following `skyColor` and `horizonColor`.
- **Reset.** A field that differs from its default shows a **Reset** next to it; one click writes the default back.
- **Undo.** Every edit is `scene.set_component` on `SceneSettings` (no `id`; `skyMaterialParams` merges), so it is ONE step of the
  editor's Undo and Redo in order with the other panels' edits (a drag of a colour or a number is one step), and a refused value
  (a wrong type, an unknown setting) changes nothing and leaves no step. An AI or a script calls the same command.

**Autotest.** Section Q3 of `fa_editor_autotest` (at 1024x642 too) opens the panel from the menu, picks a sky material, sees its params
typed, sets one and takes it back with the param's Reset, takes the material back with the field's Reset, walks the four steps back
with Undo and forward with Redo, and checks that a refused value leaves no step. The panel's rules (`scene_settings_model.*`) have
unit tests in `scene_settings_tests.cpp`.

## Graphics settings window

View > Graphics opens a window with the graphics settings a run of the project starts with, the keys `render.graphicsPreset`,
`render.upscaler` (`mode`, `quality`, `sharpness`) and `render.dynamicResolution` (`enabled`, `targetMs`, `minScale`, `maxScale`) of `factoria.json` ([UPSCALING.md](../UPSCALING.md), "Graphics presets"). It is a
form over a working copy, like Platform settings: **Preset** and the upscaler's **Mode** and **Quality** are combos of the engine's
own names, **Sharpness** a slider (greyed out while the mode is `stretch`), each with its doc as a tooltip. The **Dynamic resolution** group is a checkbox (**Enabled**), a **Target (ms)** drag (0 shows "display refresh") and the **Min scale** and **Max scale** sliders, greyed out while it is off; the editor's own viewport never uses it, only a run of the game does.

- **Checks.** The values go through the code that loads the project and the `render.upscaler` and `graphics.preset` commands, so a
  wrong one is marked in red with its JSON pointer (`/render/upscaler/mode`, `/render/dynamicResolution/minScale`) and the engine's sentence with a "did you mean", and
  **Save** stays disabled. A `factoria.json` whose values are wrong when the window opens shows the error at the top.
- **Save / Revert.** **Save** writes only those three keys (the text of the file is patched: every other key, the order and the
  formatting stay); a value at its default (`custom`, `stretch`/`native`/0.5) removes its key and an empty `render` object goes with
  them. **Revert** reads the file again. If the file is not valid JSON, Save refuses and writes nothing.
- **No preview.** The editor has no preview of render settings (a preset or a mode in the viewport): Save, then Play to see them. The
  player's own choice at run time is the menu kit's Graphics tab ([MENUS.md](../MENUS.md), the Graphics tab).

**Autotest.** Section Q4 of `fa_editor_autotest` opens the window from the menu, picks a mode and a preset with real clicks on the
combos, Saves and reads `factoria.json` back with the engine's own reader, turns the dynamic resolution on, sets a misspelt mode and a minimum scale above the maximum (each named with its pointer, Save
disabled and refused) and Reverts. The rules (`fa/tooling/graphics_settings.h`, shared with the command `project.graphics`) have unit tests in `tools/common/tests/graphics_settings_test.cpp`.

## Graph panel

View > Graph opens the Graph panel, which edits the node graph of ONE `*.material.json` ([SHADERS.md](../SHADERS.md), "Node graphs"). Open a material in it by
double-clicking a `.material.json` that has a `graph` in the Project panel, by **Edit graph** under a material field of the Inspector, or with the file menu in
its toolbar. **New graph material** writes `assets/materials/graph.material.json` (or the next free `graphN`) with an empty graph (just the output node), and a material
with no graph offers **Start a graph in this material**. The panel reads and writes the same JSON an AI writes, and **Save** runs the command an AI would call
(`material.graph.generate`: it writes the graph and the shader snippet, with `graphHash`), so a person and an AI can take turns on one file. Nothing is written
before Save; the toolbar's status line says when there are unsaved edits and what state the snippet is in (in sync, the graph changed, edited by hand, unreadable with the reason as its tooltip, ...). Switching
to another material with unsaved edits asks first ("Discard the graph changes?"). A file that someone else changed on disk (an AI, a script, another editor) is looked at again
when you press Save: the panel does not replace it but asks "The file changed on disk" with **Overwrite** (the graph as edited replaces the file), **Reload** (the file as it
is, your edits gone) and **Cancel** (nothing is written, the unsaved graph stays). **New graph material** makes the material file whole or not at all: it is written under a
temporary name and published only if the name is still free, and when the snippet cannot be written the material file it made is removed again, so a failed New leaves nothing behind
and never replaces a file made meanwhile (on a volume with hard links; on one without, a look and a rename leave a very small window). If the name of the snippet the material would get (`shaders/<name>.surface.glsl`) is already taken by a hand-written file, the next free name is used for both. Closing the material (or opening another) clears the Params and Textures forms and their messages.
The combo next to **New graph material** picks the kind: `mesh` (the default), `sprite` (a 2D item: `assets/materials/sprite_graph.material.json`, `"kind": "sprite"`, the snippet `shaders/sprite_graph.fragment.glsl`; the output has `color`, `rgb`, `alpha` and `vertexOffset` and starts with a colour) or `post` (a full-screen pass: `assets/materials/post_graph.material.json`, `"kind": "post"`, the snippet `shaders/post_graph.post.glsl`; the output has `color` and `rgb`, and the graph starts as `post.scene` linked into `rgb`, the picture unchanged).
The kind of an open material is the file's `kind`: a sprite or post graph's palette leaves out the nodes of the other kinds (a sprite lacks `fresnel`, `triplanar`, `parallax`, `texture.normal`, `normal.world`, `view.dir`, `position.view`, `vertex.color`, `position.world`; a post pass has the `post.*` nodes instead), and a search that matches a node of another kind (by name, category or description) says what to use instead.

- **Canvas.** Nodes are boxes with their input ports on the left and output ports on the right, coloured by type (float, vec2, vec3, vec4). Drag a node to move it
  (all the selected ones move together; the position is saved as the node's `pos`). Press on a port and drag to another port to link them; dragging from an input
  that is already linked picks that link up and moves it, and dropping on empty canvas removes it. A link that would add a problem `material.graph.validate` reports (a cycle, a type that does not fit) is not made and the
  checker's sentence is shown. Click a link to select it (Delete
  removes it). Drag on empty canvas to select with a rectangle, Shift or Ctrl/Cmd click to add to the selection. The mouse wheel zooms around the pointer (30 % to 250 %);
  right-drag or middle-drag pans. **Fit** (or F) frames the graph.
- **Add nodes.** A right click on empty canvas opens the **palette**: every node of the library (`material.graph.nodes`) with a search box (it has the keyboard when it opens;
  type and press Enter) and each node's doc as a tooltip. The node appears where you clicked. **Add node** in the toolbar does the same at the centre of the view.
- **Keys** (while the canvas is hovered): Delete or Backspace removes the selection (the output node cannot be removed), Ctrl/Cmd+A selects all, C, X and V copy, cut and paste
  nodes with the links between them (the text goes on the system clipboard, so it pastes into another material), D duplicates, S saves.
- **Inspector** (the right side, under the preview). For the selected node: its type and doc, a combo for `param` and `texture` nodes that lists the material's own params
  and textures (a new one made in the Params or Textures list below is offered at once), the constant of each unlinked input (a number, a vector or a colour), shown
  dimmed with the default when the node does not set it, **Cut** for a linked input, and **Delete node** and **Duplicate**. A selected link shows its ends and **Cut link**. A drag on a number is one undo step.
- **Problems.** The list `material.graph.validate` gives for the document as it is now, each with its JSON pointer and the fix; a click selects the node or link it names.
- **Preview.** A lit sphere, cube or quad drawn with the material the graph would generate (what is being edited, not what is saved), using the engine's renderer. After an edit it
  waits a fraction of a second, then compiles on a worker thread and shows the picture, so dragging a slider never freezes the editor. **Animate** turns the shape so the lighting and
  `time` change. The preview compiles through sokol-shdc ([SHADERS.md](../SHADERS.md), "Compiler"): without it the panel says so and the rest still works. The files it writes (the
  material and snippet it compiles and the copies the renderer loads) are in `.factoria/material-preview/`, which a new project's `.gitignore` leaves out with the rest of `.factoria/`;
  deleting the folder is safe, the next edit makes it again. Each preview (the one on the canvas and the saved copy for Compare) stages its compile in files of its own
  (`stage-<id>.*`), and changing project or quitting the editor waits at most two seconds for a compile in flight before it lets the worker finish alone (closing the panel does not destroy the preview). Files a worker left behind when the editor quit (`stage-*`, `saved-stage-*`) are deleted by the next preview once they are a few minutes old, and the errors of a compile name the material or the snippet, not the stage file. The shader compile is cached in `.factoria/shader-cache`; when that result cannot be saved (a full disk, a read-only
  folder) the preview shows an error and does not compile on the editor's thread.
  - **Params.** Each param of the material (`params`; the ones the generator adds itself are left out) has a slider, a drag box or a colour editor under the preview. Moving one
    changes the PREVIEW only (`MeshRenderer.materialParams` of the scratch entity): the file is not touched, nothing compiles again, the name turns amber with "(preview only)", and
    **Reset** puts that one back. **Reset values** resets all. The values go away when another material is opened or the param is removed. **Set as default** writes the value as
    the param's `default` in the material file (`material.param.set_default`, one set of code with the Console and an AI) at once, without saving the graph's other unsaved edits,
    and is one undo step (Undo writes the old default back; it refuses when the file's default is not the one the step expects).
  - **Making, renaming and deleting params and textures.** **+ Param** and **+ Texture** open a small form (name; type, default and optional range, or the sampler; a doc line) and
    **Create** writes the entry into the material file at once through `material.param.create` / `material.texture.create`, the commands an AI calls, so the same checks apply (a name
    the material already has, a GLSL word, `fa_` or the `gn_` prefix of the graph's helper functions, a default outside the range: the sentence appears in the form and nothing is
    written). Every row has **Rename** and **Delete**. Rename (`material.param.rename`, `material.texture.rename`) writes the new name into the file and points the nodes that read
    the old name at the new one, saved or not; scenes and prefabs that set a param by name in `MeshRenderer.materialParams` are NOT changed. Delete (`material.param.delete`,
    `material.texture.delete`) is refused while a node of the graph as it is now reads the entry: the message names the nodes and the panel selects them, so you point them at another
    entry or delete them first. The commands themselves can also remove those nodes (`force: true`, for an AI that means it); the panel never does, because a click that deletes nodes
    nobody chose is not what the button says. A file whose shader snippet is the one the graph generated (state "in sync") gets its snippet generated again, so it never names a param
    that is gone; a hand-edited snippet is left alone (the toolbar keeps saying so). Each of the three is ONE undo step, in order with the graph's own edits (Undo and Redo run the
    inverse command: they write the file again, and refuse with the command's sentence when it cannot run, e.g. the name was taken or removed by an AI meanwhile). The preview
    compiles again once the edits stop, because a new or removed param changes the material's uniforms. When the command says something the panel would otherwise hide (the
    snippet was not written again and why, or a hand-written snippet that still uses the old name), the sentence is shown in amber under the list instead of being dropped.
    Undo of a delete puts the entry back at the place it had (the `index` the command returned), not at the end.
  - **Kinds.** The preview draws the three kinds a graph can be made for, each its own way. A `mesh` material is drawn on the sphere, cube or quad. A `sprite` material is drawn on a flat 2D quad (a `Sprite` with the material and its params, on the material's first default texture or a grey checker), and the shape buttons are replaced by a note. A `post` material is drawn as the only entry of `PostProcess.customPasses` of a camera over a small scene (a floor and four lit shapes at different depths, over a sky), four frames in a row so `post.history` has a frame before it; the project's own post effects are not applied. Its shape buttons are replaced by a note and the **Try on scene camera** button (enabled once the material is saved), which adds the material to the `customPasses` of the camera that draws the scene as one undo step. A `sky` or `compute` material is not drawn, and the panel says why (a sky needs the scene around it, a compute material draws nothing) instead of drawing something wrong. The autotest section G3 draws the mesh, the sprite and the post preview (a post graph with a node added must change the picture) and tries the material on the scene camera.
  - **Compare.** The **Compare** check box draws the last SAVED version of the graph (the file as it was read or saved) next to the current one, with the same shape and the same param
    values, so you see what the edits changed. The saved version compiles on its own worker. A graph that was never saved (a draft) says so. A save, a reload and a new default make a
    new saved version.
  - **Errors.** A graph with problems, or a compiler error, keeps the last picture and shows the message. The generator keeps a map from every line of the snippet to the node that
    wrote it, so when the compiler complains about such a line (its message names the line of the generated snippet) that node is painted red on the canvas with the message under it
    (and in its tooltip); a line no node wrote (a helper, a brace) or an error of the material file stays only in the panel, whole.
- **Save and the hand-edit rule.** If the snippet on disk is not what the graph last wrote (edited by hand, or never generated), Save asks "Overwrite the shader snippet?":
  **Overwrite** passes `force`, **Cancel** changes nothing. If the file changed on disk after the panel read it, Save says so before it overwrites it.
- **Undo.** Every edit that is kept (a node added, moved or removed, a link, a constant, a paste) is ONE step of the editor's Undo and Redo, in order with the other panels' edits.
  Undo changes the open graph, not the file: Save writes it. (The params and textures steps and "Set as default" are the exception: they are written to the file at once, and so are their
  undo and redo.) A link dropped on the input it already feeds, a drag that ends where it began, and a rename to the same name make no step. While a node or link is being dragged the checker
  does not run again for every mouse move: the problems list and the red marks are those of the graph as it was when the drag began, and update when the mouse is released.
- **The file changed behind the panel.** The panel looks at the file every few frames. A change with nothing unsaved is read again ("The file changed on disk and was read again");
  with unsaved edits the toolbar says so and **Reload** takes the file. A file that lost its `graph` (its shader became hand-written) is said ONCE, and the panel keeps its graph as a
  draft (Save writes it back into the file) instead of reading the file again at every look.

**Autotest.** Section G3 of `fa_editor_autotest` (at 1024x642 too) writes a dissolve material with a one-node graph, opens it, adds three nodes from the palette (a right click
and the search box), drags four links with the mouse, sets two constants, waits for the preview and checks that it drew pixels (a skip when there is no renderer or no
sokol-shdc, unless `FA_REQUIRE_SHDC=1`), checks that a sky material is not drawn (the reason is shown), that a param override redraws the preview without touching the file or
compiling again, that **Set as default** writes the file as one undo step (and Undo and Redo write it back and forth) and that **Compare** draws the saved version beside the current one,
checks that a link the checker refuses gives its sentence, saves (the material and the snippet exist), edits the snippet by hand and checks
that Save asks, that Cancel changes nothing and that Overwrite writes it, then undoes and redoes every step. The model (`graph_model.*`) has its own unit tests (`graph_tests.cpp`).
