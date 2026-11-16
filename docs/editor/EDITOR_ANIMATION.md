Part of [EDITOR.md](../EDITOR.md): The model, particles and animation panels and the bone tools.

# Editor: animation

## Model panel

View > Model opens the Model panel; double-clicking a `*.model.json` in the Project panel opens that document in it. It edits ONE document at a time
and is a floating window the first time. The document is the source ([MODELING.md](../MODELING.md)): every edit that is kept runs the command an AI would
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
time ([PARTICLES.md](../PARTICLES.md), "Effect documents") and is a floating window the first time. Every edit that is kept runs the command an AI would call
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
(`*.anim.json`, [ANIMATION.md](../ANIMATION.md), "2D clips"). Select the entity that has the Animator, or any part below it: the
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
[ANIMATION.md](../ANIMATION.md), "3D bone clips") of a rigged model. Double-click a 3D `*.anim.json` in the Project panel and the panel opens
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
  returns the call that undoes it (`anim3d.restore` with the whole previous document and the clip's previous `provenance` record) and the panel puts it on the editor's undo
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
