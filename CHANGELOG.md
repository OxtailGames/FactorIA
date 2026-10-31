# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

## Unreleased

### Changes

- The built-in AI agent (API providers) no longer sends the definitions of all 186 commands on every step (about 320 KB, around 85k tokens, before any conversation). It gets the core commands in full (files, docs, scene editing, running and looking at the game, validating and testing, scripts, `feedback_report`, `assets_list`, `assets_import`), the commands of its role's tool groups in full, and a catalog in the system prompt: one line per other command. Two loop tools reach those: `tool_describe` returns the full definition of commands and `tool_call` runs one under its own name (the chat and the events show the command). A wrong call to a catalog command comes back with its input schema. The tool list is fixed for the whole run, so the prompt cache keeps working. On the scripted task of `tools/cli/tests/tool_catalog_test.cpp` (real command registry, no model) a step sends 62 KB instead of 324 KB; the numbers and the reasons are in docs/AI_COSTS.md and docs/AI_PROVIDERS.md ("Tool groups and the catalog"). A registry whose left-out definitions add up to under 6000 bytes is still offered in full. Read-only roles (`artCritic`, `reviewer`) see only the read-only commands in the catalog and cannot reach any other one through `tool_describe` / `tool_call`.
- `roles.<role>.toolGroups` in `ai.json` (new): command categories (`assets`, `anim`, `ui`...), command names or `"all"` that a role always gets in full. Default: the artist loads `assets`, the audio role `assets` and `audio`; `["all"]` brings back every command in full.
- Claude Code 2.1.312 already defers the tools of MCP servers behind its own tool search; FactorIA sets nothing for it (docs/MCP.md, "Tool definitions and Claude Code").

### New

- Extensions for the CLI agents: an `extensions` section in your `ai.json` and a project file `.factoria/extensions.json` (no keys in it) load plugins (a folder, a `.zip`, or a Claude Code `name@marketplace` you installed), skill folders and hooks (Claude Code's `hooks` shape) into the AI runs, each entry with `roles` and `enabled`. Claude Code gets one `--plugin-dir` per plugin, the skills as a plugin FactorIA writes for the run, and the hooks in a private `--settings` file, both deleted when the run ends; `inheritUserPlugins: false` starts it with `--setting-sources project,local` (it drops all your user-level Claude Code settings, permissions and env included). Codex is given none and the run says so; a generic CLI takes them through the new `{plugin_dirs}` and `{settings}` placeholders; the API providers (anthropic, openai-compatible) do not use extensions yet and `ai.extensions` and the run say so. Mistakes are reported with the JSON pointer, a fix and "did you mean". Guide: docs/AI_PROVIDERS.md, "Extensions".
- A project's plugins and hooks run only after you trust the project once (AI settings > Extensions > Trust this project, no command can grant it); the trust is kept per project path and file hash in `ai-trust.json` next to `ai.json` and ends when the file changes. The project's skills (text only) load without it.
- Claude Code in `-p` mode skips its own workspace-trust dialog, so a downloaded game's `.claude/settings.json` or `settings.local.json` used to take effect in AI runs without asking: it runs programs (hooks, `enabledPlugins`, `extraKnownMarketplaces`, `statusLine`, `apiKeyHelper`...) and widens what the AI may do (any `env`, such as a base URL or `BASH_ENV`; `permissions.allow` rules; a `defaultMode` other than `default`; `additionalDirectories`). The same project trust now covers them (hash of both files): until you trust the project, Claude Code starts without the `project` and `local` setting sources (`--setting-sources user`, or an empty list with `inheritUserPlugins: false`), so the rest of those files is not applied either. The run output, `ai.extensions` (`claudeSettings`, `projectSettingsSkipped`) and `factoria ai doctor` say what was skipped and how to trust the project; a setting FactorIA does not know counts too (listed as `unknown setting KEY`, the name only), so only keys known to be harmless load without the trust; the deny-rule report still reads the files.
- Deny rules on FactorIA's own tools (`mcp__factoria`, `mcp__factoria__*`, `mcp__factoria__<tool>`) in the project's `.claude/settings.json` or `settings.local.json` are reported in the run output, in `factoria ai doctor` and in `ai.extensions`, with the file, the rule and how to restore the tool.
- The command `ai.extensions {role?}` (read-only) shows the entries, what stops each from loading and what every role's provider receives; `factoria ai doctor` has an Extensions section and a `--project DIR` flag.
- The editor's AI settings window has an **Extensions** tab next to External tools: add a plugin or skill folder (for you or only for the project), paste hooks JSON, switch roles on and off per entry, Trust this project, and Save.
- `ai.tool_plan {role?, catalog?}`: which commands a role gets as tools in full and which only as catalog lines, with estimated sizes.
- Where the context goes: each model call of the built-in agent records the estimated split of its request (system prompt, command catalog, tool definitions, conversation) in the session log; `ai.session_timeline` returns it as `context` (per step and totals), and the Context bar of the editor's AI panel shows it in its tooltip.

## 0.9.0

FactorIA 0.9.0 (M44) brings what a 3D book needs, found by the user's game Roguestory: scripts build and deform meshes in code (`mesh.create`, `mesh.update`, `mesh.save` to a `.glb`) with vertex colors, a camera can draw live into a texture that a model shows (`Camera.renderTarget`, `"target:<name>"`) and the pointer reaches the buttons on it through the mesh, `render.captureTexture` photographs any part of the world off-screen at a scale you choose, world Text can be sized in meters and lit, a project tool always runs the code on disk, and AI session logs carry times that `ai.session_timeline` turns into a timeline.

### New

- Render targets: a `Camera` with `renderTarget: "book"` and `renderTargetSize: [w, h]` (1..4096) draws live into the texture `"target:book"` every frame instead of the screen, 2D or 3D. The id goes wherever a texture path does: `MeshRenderer.texture`, `normalMap` and texture `materialParams`, `Sprite.texture`, `Panel.texture`, `Button.icon`. A target is drawn before the cameras that sample it, so a screen on a model is never a frame behind. A camera that sees the surface showing its own target gets the missing-texture checker there and one error that says how to fix it; two targets that show each other work, each one frame late. A target camera is never drawn to the screen, `camera.main`, in `camera.all` or the audio listener. `RenderStats` has `renderTargets`. `factoria validate` accepts `target:<name>` in texture fields (and reports an empty or invalid name). Guide: docs/RENDERING.md.
- The pointer through a mesh: a mouse or finger over a `MeshRenderer` that shows a render target reaches the `Interactable` entities its camera sees, by the hit triangle's UV: hover, click, toggles and slider drags work on a flat quad, a curved model (cylinder, sphere, bent screen) and glTF models, and a slider drag goes on after the pointer leaves the mesh. A book with turning pages and working buttons needs no overlay. Limits (docs/RENDERING.md): the nearest page mesh wins and other 3D things in front do not block the pointer; a Sprite, Panel or Button that shows a target forwards no input; in a test aim with a screen position, not the id of a page entity.
- `render.captureTexture({ entity | rect, space: "world", scale })` draws a part of the world off-screen at `scale` pixels per world unit and returns a `Texture`: a hidden, covered or off-camera subject works, no frame has to be drawn first (it works in `onStart` and in tests), and the picture may be up to 4096 x 4096 (the whole-frame form keeps its 2048). The background is transparent and the colour is straight alpha. A request over 4096 is an error that names the largest scale that fits.
- Procedural meshes: `mesh.create({ positions, normals?, uvs?, tangents?, colors?, indices, submeshes? })` returns a `Mesh` whose `id` (`"mesh:N"`) goes in `MeshRenderer.mesh` (and `Collider3D.mesh`), so a script builds terrain, a deformed body or a generated tree without writing a glTF file. Missing normals and tangents are computed; `submeshes` give runs of the index list their own material. `mesh.update` replaces what is given and keeps the rest, reusing the GPU buffers while the data fits; `mesh.destroy` frees the mesh; `mesh.save(m, path)` writes a `.glb` (one primitive per submesh, materials, `COLOR_0`) that loads back as a normal asset; `mesh.exists` and `mesh.list` ask what is alive. The same operations are the commands `mesh.create`, `mesh.update`, `mesh.destroy`, `mesh.save`, `mesh.list` and `mesh.info`.
- Bounds, frustum culling, shadows, the editor's picking, outline and selection and `Collider3D` convex and mesh shapes use the real geometry; the inspector shows a procedural mesh's vertex and triangle counts. A `Collider3D` on a mesh rebuilds its shape on every update. Meshes are released when a scene loads; an id that is destroyed, from an older scene or unknown gives an error that says so, and an entity that still names it draws the placeholder box. Limits: 256 meshes, 1 048 576 vertices and 6 291 456 indices each.
- `factoria validate` rejects a `mesh:N` id in a scene or prefab (the mesh would not exist when the file loads).
- Vertex colors are drawn: `colors` of `mesh.create`/`mesh.update` (rgb or rgba per vertex) multiply the submesh material's base color like glTF `COLOR_0`, in every 3D path (lit, `unlit`, instanced batches, skinned, the shadow pass of `clip` materials, custom materials), and glTF models that carry `COLOR_0` are drawn with it too (before it was ignored). Custom material snippets read it as `i.vertex_color` and, in `vertex()`, `v.color`. A mesh without colors looks exactly as before. Each mesh vertex is 4 bytes larger (52 instead of 48) to carry the color as four normalized bytes.

### Changes

- `render.textureFromPNG` accepts pictures up to 4096 x 4096 (it was 2048), the size run-time textures could already have.
- `project.export` takes `player` like the CLI's `--player`: the desktop or web player to bundle, so an AI can export for another OS with a player built there.

### Text and sprites

- `Text.fontSize` (and `minFontSize`) go down to 0.001, so a world Text in a 3D scene can be sized in meters (a 7 cm title is `fontSize: 0.07`). The glyphs are still rasterized for the size they have on screen, so tiny world text stays sharp. docs/TEXT.md has a new section, "Text in a 3D scene", on how Text behaves under a perspective camera.
- New `Text.lit` (default false): a world Text is shaded by the scene's 3D lights and `SceneSettings.ambientLight` like a lit material (once per Text, at its origin; no shadows).
- New `Sprite.vertexColors`: a flat `[r, g, b, a, ...]` per grid vertex of a deformable sprite, multiplied with `color`. A scene or prefab whose length is not `(meshColumns + 1) * (meshRows + 1) * 4` fails to load with an error that names the length it needs; a script that writes a wrong length gets one warning and the colours are ignored.

### Fixes

- An entity destroyed during a frame (and its children) is no longer drawn in that frame: the renderer used to draw it until the end of the frame, so a group destroyed and rebuilt in one frame was drawn twice for one frame, and a `render.captureTexture` taken the next frame showed both. docs/SCRIPTING.md says which frame a capture shows.
- A project tool (`project_<name>`, from `tools/*.js`) now runs the code on disk: when its file, or a module it imports, was edited since it was loaded, the tool is re-imported before the call, as `script.eval {module}` does. This holds in the editor's MCP session, `factoria mcp` and `factoria call`. An object result also carries `toolVersion` (`file`, `hash` of the file as it ran, `loadedAt`), so a stale tool is visible.
- On Linux, the MCP server now tells the AI to restart the client (or `/mcp`) after it added the missing `"timeout"` to the project's `.mcp.json`: Linux stamps files with a clock a tick behind, so the write looked older than the server's start.
- An `.anim.js` module that runs out of memory with many small allocations now says "ran out of memory" and names the line, instead of "threw null": the runtime keeps room to build the error.

### AI

- Every event of `.factoria/ai/sessions/*.jsonl` carries `t` (UTC time with milliseconds). `tool_end` carries `ms` (how long the tool ran), a `thinking` event carries `ms` (the time since the event before it, so the duration is kept when the text is hidden), and the built-in agent's `assistant` lines carry `ms` (the model call) and its `tool_results` entries the tool name and `ms`.
- New read-only command `ai.session_timeline {session?, minGapSeconds?}` (newest session by default): the gaps longer than N seconds with what was going on (a tool, thinking, waiting for the model, waiting for the user) and totals per kind and per tool. A log from an older engine has no times and the command says so.

## 0.8.2

FactorIA 0.8.2 restarts the editor into the FactorIA icon you pinned in the Dock, instead of opening it as a second FactorIA icon next to it.

### Fixes

- Restarting the editor on macOS (the update notice's Restart) no longer leaves two FactorIA icons in the Dock: the editor used to start the new one with `open -n` while it was still quitting, and macOS gives a second instance of an app its own icon. A helper now waits until the old editor has quit and then opens `~/Applications/FactorIA.app` the way the Dock does (with `open -n` only if the old editor is still running after 30 seconds).

## 0.8.1

FactorIA 0.8.1 keeps one FactorIA icon in the Dock when an editor that is still open restarts after a newer FactorIA was installed over it.

### Fixes

- Restarting the editor (the update notice's Restart) after a newer FactorIA was installed over it on macOS no longer opens the new editor as a second Dock icon: the restart goes through `~/Applications/FactorIA.app` whenever that app opens this `factoria` and passes the project on, whichever version wrote it (an out-of-date one used to be skipped, so the editor started the bare program).

## 0.8.0

FactorIA 0.8.0 (M43) lets the AI use external tool servers (MCP) that you configure in the editor's AI settings, such as Scenario for generating game art: Claude Code, Codex, the generic CLI agent and the API providers all get them, and the AI calls them only when they help.

### New

- External tool servers: a top-level `mcpServers` object in your user `ai.json` (web services by address, with headers or a key from an environment variable, or programs on your computer) that the AI may use when it sees fit. Claude Code gets them through a generated `--mcp-config` (and `mcp__<name>` in `--allowedTools`), Codex through `-c mcp_servers...` (keys stay out of the argument list), the generic CLI agent through the `{mcp_config}` placeholder, and the API providers through a built-in MCP client (Streamable HTTP and stdio) whose tools appear to the model as `<server>__<tool>`. OAuth is not implemented: use a key. `docs/AI_PROVIDERS.md`, "External tools (MCP servers)".
- The AI prompt has an "External tools" section naming the servers that are connected for the run.
- Command `ai.tool_servers` (a server's state, or a connection test), and `factoria ai doctor` lists each server with what is wrong with it.
- AI settings > External tools tab: add or edit a server with a form, Test it, paste a Claude Code `.mcp.json`, Remove; Save keeps the other keys of `ai.json`. Editor autotest section D2.
- `fa::ChildProcess` in the core module (a program with piped stdin and stdout, for stdio MCP servers), with tests; the Windows version is not yet built or run.

## 0.7.5

FactorIA 0.7.5 stops the editor's AI watchdog from cancelling healthy agents on macOS and says why any run was cancelled.

### Fixes

- macOS: the editor's AI watchdog no longer stops a healthy agent with "process is gone". `process_tree` read the count `proc_listallpids` returns as bytes and kept only the newest ~50 of ~550 processes, so after a few minutes of an agent starting processes the orchestrator's own pid fell off the list. The list is sized from the count now. Before it stops a run for a missing process, the watchdog and Check activity also ask the OS directly (new `fa::process_alive`: `kill(pid, 0)`, or `OpenProcess` + `GetExitCodeProcess` on Windows) and never stop a run that produced an event in the last 10 seconds.
- A run that ends cancelled says why: the session transcript's end event has a `cause` (`user_stop`, `stuck_stop`, `watchdog_process_gone`, `activity_check_process_gone`, `project_closed`, `editor_closing`, `editor_restart`, `run_ended`) and an error such as "cancelled: the editor's watchdog thought the agent process was gone"; the chat's error line and the `ai_run` result of a cancelled sub-agent carry the same text.

## 0.7.4

FactorIA 0.7.4 makes the editor restart through the pinned launcher also from the start screen, so the Dock keeps one FactorIA icon.

### Fixes

- Restarting the editor from the update notice with no project open also goes through the pinned launcher, so the Dock or taskbar keeps one FactorIA icon (it used to start a bare `factoria editor` that showed a second one).

## 0.7.3

FactorIA 0.7.3 fixes a false error of `factoria validate` on glTF texture paths and makes the real ones say how to fix them.

### Fixes

- `factoria validate`: the error for a glTF/glb texture or buffer uri that points nowhere resolves the uri against the model's folder and names the real path (it used to name the model's own folder, which exists, and flagged uris such as
  `../../../assets/textures/x.png` that go up to the project root and back in, which load fine), says plainly when the uri climbs out of the project folder, and suggests the corrected uri when the file exists in the project.

## 0.7.2

FactorIA 0.7.2 keeps one FactorIA icon in the Dock or taskbar when the editor restarts after an update.

### Fixes

- Restarting the editor after FactorIA was updated (Restart, or the in-editor updater) no longer adds a second FactorIA
  icon next to the pinned one. On macOS the editor reopens through `~/Applications/FactorIA.app` (`open -n`) when that
  launcher is the one of this factoria, and the launcher now passes its arguments on, so the project is reopened; older
  launchers are rewritten at the next start. On Windows the restart runs `FactorIA-Editor.exe` when it is next to
  `factoria.exe`. On Linux the `.desktop` entry gets `StartupWMClass=FactorIA`, so the window groups with it.

## 0.7.1

FactorIA 0.7.1 fixes the editor's recent projects: the list survives updates, reinstalls and starting the editor
straight on a project.

### Fixes

- The editor no longer forgets its recent projects. Starting straight on a project (`factoria editor <dir>`, the
  restart after an update) used to overwrite `~/.factoria/editor_recent.json` with that one project, and File > Recent
  Projects was empty. The list is now read when the editor starts, merged with the file on every save, compared by
  normalised path, and entries whose folder is missing are hidden but kept (and are dropped first when the list is full).

## 0.7.0

FactorIA 0.7.0 animates characters built in parts: a keyframed clip (`*.anim.json`) moves the parts of an entity and the
Animator plays it by name, with cross-fades, layers, masks, events and the state machine; `Bone2D`, `SpriteSkin` and
`IK2D` bend a sprite with its bones and make a chain reach for a target; AIs make and check clips with `anim.*`,
`bones.create` and `skin.*` commands, and `factoria validate` checks every clip; the editor has an Animation panel
(dopesheet, curves, record mode, onion skin) and bone tools (draw a chain, bind, paint weights, drag IK targets); and
`assets.bake_sheet` bakes an Animator clip by name into a sprite sheet. Sky Hopper's hero is built in parts with bones,
clips and IK feet, and its crawler is baked from parts into a sheet.

Keyframed 2D clips

- `*.anim.json` (format `factoria.anim/1`, `schemas/anim.schema.json`) is a clip of keyframed tracks: each track drives
  one field (or one channel such as `rotation.z`, `color.a`) of the entity that plays it or of a child found by names
  (`"body/arm_l"`). Keys interpolate `linear`, `step`, `bezier` (in/out tangents, smooth when missing) or with any
  easing of `tween()`; numbers, vectors, colours and angles interpolate, bools, ints, enums, assets and rects step.
  Clip events (`{t, name, data}`) fire once per loop.
- The Animator plays these clips when it has no glTF `model`: `clips: {"walk": "anim/hero_walk.anim.json"}`. `play`,
  `speed`, `loop`, `time`, clip events, `anim.finished` and the state machine work as with glTF clips. A cross-fade lerps
  the fields, angles take the short way round and fields that only step switch at half the fade. A field the current
  clip does not drive goes back to where it rested.
- `layers` play more clips at once: `{name, clip | states, weight, mode: override | additive, mask: [paths], speed, loop}`.
  `entity.animator.setLayerWeight(layer, w)` and `playLayer(layer, clip, fade)` drive them from scripts, and
  `entity.animator.sample(clip, t)` poses the parts without playing.
- The driven fields are a runtime pose: `scene.save`, prefabs and the editor's Play/Stop write the rest value, not the
  pose. The Animator runs in the fixed step; `IK2D` runs right after it, before drawing.
- Clip files are cached by path and modification time and reloaded when they change. Errors name the file and the JSON
  pointer, and teach: a path gets "did you mean" over the names under the entity; a field that cannot be animated lists the
  ones that can; keys out of order or past `duration`, a value of the wrong type and two tracks on one channel are caught.

2D bones, skinned sprites and IK

- `Bone2D` (`length`, `minAngle`, `maxAngle`) turns any entity of the hierarchy into a bone: it runs `length` along the
  entity's +X axis and is posed through its Transform, so clips, tweens and scripts move it like any other entity.
- `SpriteSkin` (`bones`, `weights`, `bindPose`, `outline`, `outlineDetail`) bends the 2D mesh of the Sprite on the same entity
  (`meshColumns` x `meshRows`, or with `outline: true` a grid cut to the opaque pixels of the texture) with up to 4 bones per
  vertex from a bind pose recorded when the scene loads. `weights: "auto"` weights each vertex by its distance to the bones;
  an array gives your own. The vertices are deformed on the CPU into the existing 2D vertex stream: no new shader, and skinned
  sprites batch like mesh sprites. `entity.bounds()`, picking and the selection outline use the deformed mesh.
- `IK2D` (`target`, `chainLength`, `bend`, `weight`, `solver`: `twoBone` or `ccd`) turns the bones of a chain so the tip of its
  bone reaches the target, within the bones' angle limits. It runs every fixed step after the animators and before drawing, and is
  deterministic.
- `debug.bones(root?, color?)` draws the bones of an entity and its descendants (all bones without `root`); the editor's
  Selection overlay draws the bones of the selected entity. docs/ANIMATION.md, section "Bones and IK".
- A new fixture, `tools/cli/tests/fixtures/skinned-sprites` (50 skinned sprites, 10 with IK, one draw call), has a perf budget.

Commands for AIs: make clips and check them

- `anim.create_clip`, `anim.set_keys`, `anim.remove_keys`, `anim.move_keys`, `anim.set_interp`, `anim.add_track`,
  `anim.remove_track`, `anim.add_event`, `anim.move_event`, `anim.set_event`, `anim.remove_event` and `anim.set_clip` make and
  edit `*.anim.json` clips. Each checks the whole file with the loader's rules before writing, and returns `undo`, a call of
  `anim.restore` that puts the previous document back (or deletes a new file).
- `anim.list` describes an Animator's clips, `anim.pose` poses an entity at a time of a clip, `anim.filmstrip` draws a labelled
  grid of poses (with `onionSkin`) and `anim.check` reports `no_change`, `loop_jump`, `unknown_part`, `leaves_view` and
  `ik_out_of_reach` findings that say how to fix them.
- `bones.create`, `skin.bind`, `skin.auto_weights` and `skin.set_weights` (set, add, smooth) make a bone chain, skin a Sprite to it
  and paint its weights.
- `factoria validate` checks every `*.anim.json` and the clips each Animator names: a missing file, schema errors and tracks that
  resolve to no part of that entity.
- docs/AI_GUIDE.md, section 9.25.2: a character in parts, step by step; the artist role's prompt points to it.

Editor: the timeline and the bone tools

- View > Animation edits the 2D clips of the selected entity's Animator: a clip list with New clip, a dopesheet and a curve view
  (bezier tangent handles), a time ruler with scrubbing that poses the entity without touching the scene file, play / loop /
  speed, event markers, snapping to an fps the panel offers, and key editing (select, box, drag, scale, copy / paste at the
  playhead, delete, linear / step / bezier / easing from a context menu). Every edit is an `anim.*` command and one Undo step.
- Record mode (REC): moving, rotating or scaling a part with the gizmo, or changing an animatable Inspector field, writes a key at
  the playhead (`anim.set_keys`) instead of the rest value; the viewport gets a red frame. The onion skin draws faded poses before
  and after the playhead.
- View > Bone tools: draw a bone chain by clicking points in the viewport (`bones.create`), bind a sprite to bones (`skin.bind`),
  see the weights of one bone as coloured dots and paint them with a brush (add / set / smooth, `skin.set_weights`, one stroke =
  one Undo step), and drag the targets of IK2D chains. Editor autotest sections B2 and C2; docs/EDITOR.md.

Baking clips, and a character built in parts

- `assets.bake_sheet` clips take `clip`: `{"name":"walk","clip":"walk"}` plays that clip of the entity's Animator (a
  `*.anim.json` clip or a glTF animation) from time 0, with no cross-fade and the state machine off, and bakes it. `frames`
  defaults to the clip's duration times `fps` and `loop` to the clip's own. An unknown clip lists the clips with "did you
  mean", an entity with no Animator says what to add, and `clip` with `call` or `event` is rejected. The recipe in the
  provenance regenerates the sheet. docs/ASSETS.md, "Bake by clip name".
- Sky Hopper's hero is built in parts (child Sprites with pivots at the joints, Bone2D legs with IK2D feet placed by a raycast,
  a skinned scarf, idle/walk/jump `.anim.json` clips and an Animator state machine) and its crawler is baked from a rig into
  `assets/crawler_sheet.png`; docs/ANIMATION.md, "Example: a character built in parts (Sky Hopper)". Its perf budget grows from
  17 to 36 entities (the hero's 19 parts; 6 draw calls as before, the parts share one atlas).

## 0.6.0

FactorIA 0.6.0 draws animations with code and bakes them into sprite sheets: a JavaScript module or an animated SVG
becomes a sheet in one call (`assets.animate_svg`), an entity the engine draws is baked frame by frame
(`assets.bake_sheet`), every asset a tool made records its recipe so `assets.regenerate` makes it again when its source
changes, and `SpriteAnimator` plays a sheet's clips by name.

Animations drawn with code

- `assets.animate_svg` (MCP `assets_animate_svg`) bakes an animation you write as code into a sprite sheet PNG and its
  `sheet` entry of assets.json in one call. `source` is a project JavaScript module (`art/coin_spin.anim.js`) whose default
  export `frame({t, frame, frames, fps, progress, params, rng})` returns the SVG of each frame; it runs in a sandboxed
  QuickJS context (the language only: no engine bindings, no DOM, no timers, no files; imports of project files with a
  relative path), with a seeded `Math.random`, a fixed `Date`, a time limit per frame (`timeLimitMs`) and a memory limit.
  A mistake names the module, line, column and frame. `svg` (or a `.svg` source) is one SVG with SMIL animation
  (`<animate>`, `<set>`, `<animateTransform>`, `<animateMotion>` with `values`, `keyTimes`, `keySplines`, `begin` sync-bases,
  `repeatCount`, `fill="freeze"`...) sampled at every frame; what is not sampled is a warning that names the element.
- Every frame goes through the same rasterizer as `assets.rasterize_svg` (same `style`, `styleStrength` and `seed`), is
  snapped to an optional `palette`, and is laid out in `frameWidth` x `frameHeight` cells with a `padding` gutter and a
  `pivot` recorded in the sheet entry. `clips` makes several named clips from one module, one after another, each with its
  own `fps`, `loop` and `pivot`. The result returns the sheet as an image, its layout and warnings (frames that draw
  nothing, shapes on the edge of the cell, a loop whose last frame jumps from the first).
- The provenance of the sheet is `generated` (`ai` true unless you pass `ai: false`, `author` and `license`) with a
  `recipe`: the command, its arguments, and the module (and what it imported) with its SHA-256, so the sheet can be made
  again byte for byte.
- `assets.bake_sheet` bakes an entity the engine draws into a sprite sheet: a prefab, or an entity of a scene with its
  children, plays alone in a private world at the fixed step (Shape2D with gradients and strokes, sprites,
  SpriteAnimator, Tint, tweens, particles and scripts all run) and a frame is captured every 1/`fps` seconds. The cell is
  the box of everything drawn in any frame, so a growing burst is never cut, and the entity's origin is the same pixel
  in every frame (the sheet's `pivot`, which you can choose). `clips` bakes named clips, each started by a behaviour
  method (`call`) or a game event (`event`); `warmup`, `seed`, `scale`, `frameWidth` / `frameHeight` (fit the animation to a
  fixed cell), `background` and `padding` are options. The pixels are straight alpha with no dark fringes. It records the
  `sheet` entry, a `generated` provenance (`ai` taken from the prefab or scene) and the recipe, so `assets.regenerate` can
  make it again. It needs a GPU; when the process already uses its graphics device (the editor, MCP) it bakes in a child
  `factoria call`. Bake effects to save draw calls on mobile (docs/ASSETS.md, docs/AI_GUIDE.md).

Sprite sheets played by name, and checked

- `SpriteAnimator.clip` plays a named clip of the sheet of the sprite's texture (grid, `padding`, `fps`, `loop` and range come
  from the `sheet` entry; a numeric field you set still overrides). `mode` is `forward`, `reverse` or `pingpong`. A clip that
  does not loop sends the game event `clipEnded` `{id, clip}`. Scripts: `entity.spriteAnimator.play(name)`, `.clips`,
  `.clipInfo(name)` and `.on("clipEnded", fn)`. A wrong clip name is an error that lists the clips with "did you mean", also
  in `project.validate`.
- `padding` of a sheet is skipped by the animator, and the sheet's (or clip's) `pivot` is used when the Sprite has no pivot of
  its own (counted from the top-left in the sheet, flipped to the Sprite's bottom-left; `sheetPivot: false` opts out). The
  sheet entry reaches the game at run time and in exports.
- `assets.preview_sheet` (MCP `assets_preview_sheet`) draws a sheet as a labelled grid (frame numbers, cell edges, pivot,
  optional onion skin) and checks it: empty frames, ink on the edge of a cell, a jumping drawing, a loop that pops.
- Editor: the Project panel plays the clips of a selected sheet and the Inspector of a `SpriteAnimator` lists them (one click
  sets `clip`). Neon Swarm's kill effect is a sheet made with `assets.animate_svg` from `art/shockwave.anim.js`.

Assets

- The offline makers (`assets.rasterize_svg`, `assets.draw_icon`, `assets.draw_capsules`, `assets.generate_texture`,
  `assets.synth_sound`, `assets.generate_loop`, `assets.pack_atlas`, `assets.slice_sheet`) record a recipe in the asset's
  provenance: the command, the arguments that make the same bytes again (explicit seeds, project-relative paths) and the
  files it read with their hashes.
- New `assets.regenerate {path | all | stale, dryRun}` runs the recipe again and says what changed (pixels or bytes, size,
  sheet layout). `stale` makes again only the assets whose sources were edited. Provider-made assets have no recipe.
- `factoria validate` warns about a stale asset and about a recipe whose input no longer exists, with the exact
  `assets.regenerate` command in the hint.

Editor

- The Project panel marks stale made assets with a "stale" badge (red "no src" when a source is gone), has a Regenerate
  button (the selected asset, else every stale one) and a Regenerate item in the right-click menu. When a source of a made
  asset is saved a banner offers Regenerate or Not now.

## 0.5.0

FactorIA 0.5.0 makes the editor a proper Mac app: its menus are in the Mac's own menu bar.

Editor

- On macOS the editor's menus are in the Mac's own menu bar, like any Mac app: the FactorIA menu (About with the version,
  Settings... Cmd+, , Hide, Quit Cmd+Q), File, Edit, View, AI, Export (Export Game... Cmd+E), Window and Help. Shortcuts are
  Cmd+S, Cmd+Z and Cmd+Shift+Z, and go to a focused text box instead of the scene. Windows and Linux keep the bar inside the
  window. `FA_EDITOR_NATIVE_MENU=0` brings the in-window bar back on a Mac.

## 0.4.0

FactorIA 0.4.0 is about making a game with the AI inside the editor: several chats at once, roles you can turn on and
off with their own provider and model, reviews that run only when you ask, an agent that always says what it is doing,
art without an image provider and settings for it all in one AI menu. Agents see the game better (screenshots of a
region with zoom, filmstrips of an animation, a luminance profile to find seams) without filling the disk, and the 2D
renderer gains gradient stops, inherited tints and skewed or deformed sprites. The editor keeps your layout and old
engine feedback no longer piles up.

Editor version

- The right end of the menu bar shows the engine version (`FactorIA 0.4.0`); hover it for the build fingerprint.

Generated art (assets.rasterize_svg, assets.generate_texture)

- `assets.rasterize_svg` draws `clip-path` (a `<clipPath>` on a group or a shape, user-space units, transforms honoured),
  `mask` (luminance) and `<pattern>` fills (`patternUnits`, `patternContentUnits`, `patternTransform`: line hatching).
  Unsupported pieces (clipPath in bounding-box units, a pattern viewBox or stroke, a reference to a missing id) are named
  in `warnings`; filters, text, images and `<use>` are still not drawn.
- `assets.generate_texture`: the `fabric` weave is averaged per pixel when its threads are narrower than about 5 px, and
  its slubs and tones vary per crossing, so fine scales (0.2 to 0.3) no longer show a plaid of large light and dark
  blocks. Because of that, `fabric` textures regenerate slightly different at every scale (same seed, new pixels). New
  preset `linen` (also for bookcloth): a finer, even, low-contrast weave.
- **Changed default:** the darkened edge (`vignette`, 0.5 on `parchment`) is now a narrow, irregular worn border about
  3.5 percent of the short side wide instead of a wide uniform frame. New option `vignetteWidth` (a fraction of the
  short side) sets it; `0.17` gives the old width. Projects that regenerate their textures get a different edge;
  pictures already written do not change.

Screenshots for agents

- `game.screenshot` without `path` is now temporary: the result is marked `$image.temporary: true`, the MCP server and the
  AI assistant (editor, `factoria ai run`) attach the image and delete the file, and the engine removes old engine-named
  shots (`frame_*.png` in `.factoria/screenshots/`, older than 3 days or beyond the newest 200) when a project opens. A
  `path` keeps the file. Editor toolbar shots, F9 marks, `factoria run --screenshot*` and `factoria shot` are unchanged.
- `game.screenshot {region:[x,y,w,h], zoom}` shows part of the view magnified: a native re-render (sharp) up to 4x,
  nearest-neighbour above, to inspect seams, joins and gradient ends.
- `game.screenshot {frames, everyFrames, columns, region, zoom}` steps the game and returns one labelled contact sheet
  (a filmstrip) to judge an animation in one picture.
- New read-only commands `render.inspect` (brightness profile along a line with the hard steps in it) and `render.pick`
  (which entities and layers draw a pixel, topmost first; the same box geometry as the editor's click selection).
- The AI guide and the generated AGENTS.md tell agents to look closely before they trust a whole-view picture.

Assets

- `assets.generate_texture` `planks`: new options `plankCount`, `plankLength`, `gapWidth` and `gapDarkness`. Boards can run
  from side to side with no butt joint (`plankLength: 0`), and the defaults are now longer boards (one staggered joint
  per row) with a fine, softer seam, so a desk top seen from above no longer reads as a brick wall.
- `assets.rasterize_svg` has a `style` (`watercolor`, `ink`, `inkwash`, `paper`) with `styleStrength` and `seed`: a seeded,
  deterministic painterly post-process (wobbling edges, pooled pigment, granulation, a pen line, paper tooth) for
  storybook art without filters or hundreds of extra shapes in the SVG.

2D rendering

- `Shape2D.gradientStops` and `gradientEase`: a rectangle or circle gradient (linear or radial) can have up to 8 colour
  stops, `[[0, "#ff0000"], [0.5, [0, 1, 0, 0.5]], [1, "#0000ff"]]`, and an easing of its position (`linear`, `smoothstep`,
  `quadIn` ... `circInOut`, the names of the script tween easings), for sky bands, glows that fade softly and shadows without
  a visible edge. `color` / `color2` / `gradientAngle` work as before (no stops and `linear` = the old two-colour blend).
  The stops are baked into one row of a shared 256 x 256 ramp texture (up to 256 different gradients at once, the least
  recently used row is reused), so shapes with stops still batch together, the vertex stays 48 bytes and a gradient costs the
  same as the two-colour one. A malformed stop is skipped with one warning per scene.
- New `Tint` component: a colour and opacity multiplied into the entity and everything below it in the hierarchy, to fade or
  colour a group at once (a day/night wash, a hit flash, a menu fading in). It covers `Sprite`, `Shape2D` (gradient stops
  too), `Text` (rich-text colours and pictures too), `Tilemap`, `ParticleEmitter` and the screen-space UI widgets drawn by the
  renderer; not 3D meshes, lights, debug draw or the camera. Nested tints multiply. A scene with no `Tint` does no extra
  work: the parent walk happens only when at least one exists.
- `Sprite.skew` (degrees `[x, y]`, about the pivot, clamped to +-80) slants a sprite: an italic, a sign in the wind, a page in
  perspective. A sprite is deformable with `meshColumns` x `meshRows` (a grid of cells, at most 128 per side and 4096 cells)
  and `vertexOffsets` (a flat `[dx, dy, ...]` array, top row first, +y up; assign the whole array from a script each frame):
  a bent page, a flag or cloth is ONE entity and still one draw call. A deformable sprite ignores `slice`; `entity.bounds()`
  and editor picking follow the skew and the moved vertices.

AI panel

- A top-level **AI** menu (File, Edit, View, AI, Help) holds **AI Settings...** (moved out of the File menu; the panel's
  button is gone) and **Roles...**, which opens the same window on its **Roles** tab. The Roles window is now that
  tab (same table and Save, plus **Revert**); the current roles are in the tooltip of **AI > Roles...**. The panel's
  Roles... and AI settings... buttons are gone.
- What is global sits above the chat tabs of the AI Assistant: the "No AI provider is configured" box, the config
  error, the review row and the provider's plan windows (Session, Week). Context, tokens and cost stay under the tabs,
  with the chat.
- The cost reads **API cost est.** and says it is what the same tokens would cost on the pay-per-token API; with a
  Claude Code / Codex sign-in the line adds "(not billed on a subscription)": nothing is charged on top of the plan.
- **Export Game** is an item of the menu bar (the toolbar's Export button is gone; File > Export Game... stays).
- The Engine Feedback panel keeps its size with a long entry: only the entries table and the text of the selected entry
  scroll, no second scrollbar and no growing area.
- **AI Settings...** is a new window with two sections. **Asset
  generation** chooses which provider makes each kind of asset (image, sound, music, voice, 3D model), its model and voice,
  and an API key (stored in your `ai.json`, which is written readable only by you; an environment variable is still
  preferred), with a status per row. Before, the only way was to write the `assets` section of `ai.json` by hand.
  **Asset sources** lists the websites the AI should look at for images, models, audio and fonts, and **Use only these
  sites** keeps it from searching anywhere else: Claude Code is held to it (WebFetch of other sites denied, WebSearch off),
  other providers are told it. The new `assetSources` section of `ai.json` holds the lists.
- The "no provider" error of the asset commands now names the AI settings window as well as `ai.json`.
- The roles read with capitals and spaces (Orchestrator, Worker, Fast, Artist, Audio, Art critic, Reviewer) wherever the
  editor shows them, and the Roles window groups them in three sections: Orchestration and code, Art and audio, Critics
  and reviewers.
- Each role has an **Enabled** checkbox (`roles.<role>.enabled` in `ai.json`, default on). A role that is off is not used:
  the orchestrator does that work itself and its prompt says so; the Art critic and the Reviewer still run from the
  review buttons, on the orchestrator's model. The orchestrator cannot be turned off.
- The roles line is gone (hover **AI > Roles...** to see the current roles); the review buttons and the
  **Reviewers** count and focus moved up next to it, so the transcript gets two more lines.
- **Art critique** and **Game review** ask first: a dialog shows what runs, how many reviewers, the role's model and the
  focus, and **Start** runs it. Before, a click started the reviewers (and their token cost) at once.
- The live cost estimate of a Claude Code run prices its 1-hour cache writes at twice the input price, as the CLI's final
  total does; before, the estimate stayed well under the real cost while the agent worked and jumped when it finished.

Editor

- FactorIA has its own icon: a factory with an AI brain. It shows in the editor's title bar and taskbar (Windows, Linux),
  in the macOS Dock while the editor runs, on `factoria.exe` and `FactorIA-Editor.exe` in Explorer and the Start menu,
  and on the Linux AppImage.
- The program is called FactorIA wherever the system names it: the macOS Dock and Cmd+Tab (before: `factoria`, the
  executable's name), the Windows taskbar and Task Manager (the exes now carry a version resource), and Linux docks
  (the editor window's `WM_CLASS`, matched by the AppImage's `.desktop` entry).
- The toolbar's **Select / Move / Rotate / Scale** buttons show only while an entity is selected (Q W E R still switch the
  mode at any time).

Animation and scripting

- `await tween(...).finished` is safe after the entity is gone: a tween whose target entity or owning behaviour was
  destroyed, or whose scene was reloaded or unloaded, is dropped and `finished` never settles (before, it resolved
  `false` and the code after the `await` threw "entity ... was destroyed" as an unhandled rejection). `cancel()` still
  resolves `false`. New `this.tween(...)` and `this.wait(seconds)` on Behaviour (dropped with the entity).
- `tween.pauseAll()`, `tween.resumeAll()`, `tween.paused`, `tween.timeScale` and `Tween.seek(seconds)` to freeze, slow or
  scrub tweens; tweens already stand still under `game.pause` and move only with `game.step` (now documented and tested).

Tooling

- `checkpoint.read {id, path, out?}` returns one file as it was at a checkpoint (text inline, binary as base64, or any
  file written to `out`), and `checkpoint.restore` takes `paths: [...]` to restore only those files (unknown paths fail
  with a "did you mean" before anything changes).
- `storage.list` and `storage.clear {key | all}` (MCP `storage_list`, `storage_clear`) show and delete the game's save
  keys, in memory and in `.factoria/save/storage/`, so a stale save (a menu that shows "Continue") no longer needs a
  shell `rm`. SCRIPTING.md says what `project.test` does with storage: an empty in-memory one per test file, never the save folder.
- A tool file written while `factoria mcp` runs is listed and callable by the very next request (the folders were only
  looked at every 200 ms, and a request right after the write missed the new tool), and `script.eval {module, call}`
  re-imports a module edited on disk instead of running the code from before the edit.
- `project.test` resets the mouse to (0, 0) with no wheel before every test, as it already released keys, buttons and
  touches: where an earlier `game.click` or test left the pointer no longer decides what the first tests find hovered.

Fixed

- A `Shape2D` gradient whose `color` is fully transparent is drawn when `color2` is not: the ai-guide vignette recipe
  (`color: [0,0,0,0]`, `color2: [0,0,0,0.8]`) drew nothing. A shape is skipped only when every colour it uses has alpha 0.
- `world.spawn` of an entity whose Entity fields (`Interactable.knob` / `fill`) name children spawned afterwards no longer fails:
  the field is left empty with a warning and filled when the entity with that id appears (an id that never does is reported again
  after about 10 seconds of frames).
- `focusOnHover` also acts when a widget appears (or `focusOnHover` is switched on) under a resting pointer, not only when the
  pointer moves onto it, so focus and hover no longer disagree after a page turn. New `InteractableVisual.when: "highlighted"`
  (hovered OR focused).
- `scene.save` no longer writes the entities a script created at runtime (`world.spawn`, `world.spawnPrefab`, and their children)
  into the scene file: the script spawns them again on load, so they appeared twice (seen in Roguestory). The result lists what was
  left out under `skippedSpawned` with a hint, and `includeSpawned: true` bakes them in on purpose. The editor's Play/Stop snapshot
  and undo still include them. The duplicate-id warning on load now says a scene saved by an older engine may hold such entities.
- `factoria validate` no longer reports a built-in font set in a scene or prefab (`"font": "builtin:display"`, or one face
  such as `builtin:serif#bold`) as a missing project file; a misspelt one is named with a "did you mean" (seen in Roguestory).

Several AI chats at the same time

- The editor's AI panel can run up to 3 chats at once (`limits.maxConcurrentRuns` in `ai.json`, 1 to 8; before, one chat ran
  and Run was disabled in the others). Each chat has its own progress line, stuck warning, usage and **Stop**; stopping one
  leaves the others going. Play waits while any of them works, and says which chats.
- A review (**Art critique**, **Game review**) is one more run: it counts toward that limit and does not stop the other chats.
- When two chats that run at the same time change the same file (or the open scene), both transcripts get a warning that names the
  other chat and the file.
- Each run keeps its own Revert point. Reverting a run that other chats' runs overlapped puts back only the files that run
  changed and lists the files both changed: **Revert, keep their changes** leaves them, **Revert including those files** takes
  them back. The commands of several runs share the editor's main thread safely: Stop of one run no longer drops the others'
  queued commands, and two long commands (`game.step`, `project.test`) no longer overwrite each other's reply.

The AI panel's usage is live

- Tokens and cost in the editor's AI panel grow while the agent works, instead of jumping when it finishes: every model call of
  Claude Code (and each Codex turn) adds its usage, the cost is estimated with the engine's price table until the CLI's own
  total arrives. A delegated worker's spending shows live too and is no longer lost from the chat's totals or overwritten by the
  orchestrator's. The plan windows still update once per message (Claude Code reports them once); the tooltip says "As of HH:MM".
- `limits.maxCostUsd` and `limits.maxTotalTokens` apply to a Claude Code / Codex run as it goes: it is stopped when it crosses them.

Old engine feedback no longer piles up

- Closed entries of `ENGINE_FEEDBACK.json` (fixed-in-engine, wont-fix, duplicate) move to `ENGINE_FEEDBACK.archive.json` next to
  it when the editor opens the project and with the new command `feedback.archive` (CLI `factoria feedback archive`, MCP
  `feedback_archive`). Ids stay unique across both files, and a report that matches an archived fixed-in-engine entry reopens it
  with the note "reported again with engine X: regression?". `feedback list --archive` (`includeArchive`) shows the archive,
  `feedback collect` still counts it, the Engine Feedback panel has "Show archive" and "Archive closed", and exports leave the
  archive out.

The editor keeps your layout

- Which panels are open is saved with the layout (`~/.factoria/editor_layout2.ini`): a panel closed with its X, or one opened from
  the View menu, is the same the next time the editor opens or another project opens; before, only where the panels sit was kept
  and every closed panel came back. View > Reset layout also reopens the default panels. The editor autotest has a section (U)
  that floats, moves, widens and closes panels and checks they survive a reopen and a visit to the welcome screen.

More roles, and reviews that only run when you ask

- Four new AI roles in `ai.json`: `artist` (makes all the art), `audio` (sound, music, buses, mixing), and two read-only ones,
  `artCritic` and `reviewer`, which look at and play the game and give an opinion with a score from 0 to 10 and sub-scores. A
  role you do not list follows the provider you already use (a file with only `claude-code` roles keeps all seven on Claude
  Code, never an API key), and old files keep working. The Roles window, `factoria ai run --role`, `ai.run` and
  `agent_delegate` know the new names; the orchestrator delegates art to the artist and sound to the audio role.
- Reviews run only when you ask: the **Art critique** and **Game review** buttons of the AI Assistant (with a count of 1 to 5
  reviewers, each with a different point of view, and a focus), `factoria ai review art|game` and `ai.review`. The
  orchestrator cannot start them. Every review is saved in `.factoria/ai/reviews/` with its score, sub-scores and the game and
  engine version (`factoria ai reviews`, `ai.reviews`), the **AI reviews** window lists them, and **Send to orchestrator**
  posts a report into an orchestrator chat as your message so it can plan the fixes. Nothing is sent unless you press it.
- Read-only is enforced: the built-in loop offers a reviewer only tools that look and play, Claude Code runs with
  `--disallowedTools` for the editing tools and every FactorIA tool that changes something, and Codex with its read-only sandbox
  and `factoria mcp --read-only` (new: serves only the commands that look and play).
- A game is easier to review with a `REVIEW.md` (controls, goal, finished versus placeholder, how to reach every scene fast).
  The reviewers read it first, the AGENTS.md template and the AI guide ask for it, and `factoria export` leaves it out of the
  build.
- A Claude Code orchestrator no longer uses Claude Code's own `Agent` and `Task` sub-agents (they ran an unconfigured model
  outside FactorIA's roles, costs and live view, as seen in Roguestory): FactorIA starts it with them switched off and the
  prompt says to delegate with `ai_run`.

The AI agent is never silent

- When the editor's AI (Claude Code) hands a task to the worker, the worker's steps now stream into the chat as it works, and the
  panel shows how long the run has lasted and when the agent last did something. Before, a long delegation was a silent wait
  and Claude Code gave up on it after 5 minutes, so the worker's report never reached the chat.
- The MCP server reports progress (`notifications/progress`, with a heartbeat) on long calls over stdio and over the editor's
  HTTP endpoint, and the `.mcp.json` that `factoria new` writes carries a four-hour `timeout` for one tool call (add
  `"timeout": 14400000` to the server in an older project; `tool_timeout_sec = 14400` for Codex).
- After `limits.stuckAfterSeconds` (default 180, `ai.json`) without a sign of life, the panel warns that the agent may be stuck
  and offers **Stop** and **Check activity**, which looks at the agent's process, CPU, tool in flight, child processes and the
  project's recent file changes and says whether it is still working. A CLI process that disappears stops the run with a message.
- If the orchestrator's turn ends while the worker still runs, the panel says so, keeps showing its progress and, when the worker
  finishes, puts its report in the chat and continues the orchestrator's conversation by itself, once.
- `factoria ai run` prints the sub-agent's steps in the terminal (`  | worker > ...`), and `{"event":"progress"}` lines with `--json`.
- A FactorIA copied over the old one, without the in-app updater, is noticed. The editor shows "FactorIA was updated on disk
  (old -> new). Restart the editor to use it." with **Restart** (reopens on the same project, chats included) and **Not now**;
  Restart is off, with the reason, while an AI run, a play session or an export runs. `factoria mcp` restarts itself in place on
  Linux and macOS (same stdin and stdout, no disconnect, no lost request), sends `tools/list_changed` and says so in the next tool
  result; on Windows it says in the next tool result and a log message that the client must reconnect (`/mcp`). A client that
  started before `.mcp.json` changed is told once to restart or reconnect, and a missing `"timeout"` is added to the file. The
  new read-only command `engine.update_status` (MCP `engine_update_status`) reports it.

Art without an image provider

- `assets.generate_texture` (MCP `assets_generate_texture`) paints a material offline, seeded, with no provider and no key:
  `paper`, `parchment`, `wood`, `planks`, `leather`, `fabric`, `stone`, the noises `value`, `fbm` and `cellular`, and
  `gradient`, `radial` and `vignette`. `color`, `accent`, `scale`, `roughness`, `tileable` (no seam at the edges) and
  `normalMap` (also writes `<name>_n.png`) tune it; the provenance is `original`, CC0 (Roguestory/FB-0001).
- `assets.rasterize_svg` (MCP `assets_rasterize_svg`) turns an SVG, as text or a project file, into a PNG at the size you
  ask for, with the vendored nanosvg (zlib license): paths, basic shapes, gradients, strokes and transforms; no text,
  filters, masks, clip paths, `<use>` or CSS classes (named in `warnings`).
- The `no_provider` error of `assets.generate_image`, the sprite sheet and the other generators lists which configured
  providers can make that kind and which cannot (and why), the environment variables that would enable one, and the
  offline commands to use meanwhile. `assets.import` of an `.svg` points to `assets.rasterize_svg`.

Drawing and menus

- `Shape2D` gets rounded corners, soft edges and gradients, one entity each instead of stacks of translucent rectangles: `cornerRadius` (rectangle), `softness` (a blurred edge of that width on a rectangle or circle: drop shadows, vignettes, light pools) and `gradient` (`linear` with `gradientAngle`, or `radial`) from `color` to `color2`, dithered so it does not band. Everything defaults to off and plain shapes draw and batch as before (Roguestory FB-0003).
- Four more built-in fonts, all SIL OFL: `builtin:serif` (Crimson Text, with real bold, italic and bold italic), `builtin:hand`
  (Kalam, with bold), `builtin:blackletter` (UnifrakturMaguntia) and `builtin:display` (IM Fell English, with italic), for
  storybook and handwritten looks (Roguestory/FB-0002). They are files of `factoria` and the editor, not of the player: an
  export copies the ones a game names to `builtin-fonts/` and adds their licenses to `FACTORIA_NOTICES.txt`, so other games do
  not grow. `[i]...[/i]` joins `[b]` in rich text (italic face from `text.fonts` `"italic"` or the built-in family), and
  `[b]` / `Text.bold` use the built-in families' real bold faces. An unknown `builtin:` name now fails with the list of all of
  them (`docs/TEXT.md`, "Built-in fonts").
- New `Interactable` component: any entity made of sprites, shapes, text and children is a widget of the same focus, navigation and events
  as Button, Toggle and Slider, in world space (hit through the camera, following moving, scaled and turning parents) or on the
  screen. Hover, press, click, focus, arrows and d-pad, `Tab` / `Shift+Tab` (new default actions `ui_next` and `ui_previous`), confirm and cancel,
  `Panel.modal` scopes, `kind` toggle and slider (with a `knob` and a `fill` entity), and `InteractableVisual` children that show, hide or tint per state with no
  script. `ui.on` gets `hover`, `blur`, `press` and `release`; `game.click`, `ui.widgetAt`, `ui.rectOf`, `ui.focus`, `ui.state` and
  `ui.set_slider` find it by id. The recipe is in docs/MENUS.md, "Widgets from your own entities" (Roguestory FB-0006).

Watching the game and reading the docs over MCP

- Every log line carries the computer's time. The editor Console starts each line with `HH:MM:SS.mmm` (hover it for the date, the frame and the seconds since start); `game.logs` and `game.step`'s `newWarnings` give `wallTime` (ISO 8601 with offset), and the text and JSON stderr formats show it too.
- `game.click` (MCP `game_click`) clicks like a player: by UI widget `id`, screen `position` or `world` point it moves the mouse,
  presses, steps a frame, releases and steps another, so scripts see `input.mouse.pressed` then `released` and Buttons get their
  `click`. The AI guide and the generated AGENTS.md give the recipe (Roguestory/FB-0004).
- `docs.read` fits an MCP tool result by default (`maxBytes`, 40000): a cut page carries `contents` (headings with line numbers)
  and `next`, and `heading` reads one section. `docs.components` and `docs.commands` list names with a one-line summary by
  default; `name` returns one in full, `filter` narrows the list, `full` returns everything (Roguestory/FB-0005).

## 0.3.0

FactorIA 0.3.0 is about the games themselves: four more reference games (a 3D phone game, a couch co-op game, a management
game for the browser and a 3D story adventure) were made with the engine, and everything they asked for is in.
Split screen and actions per player, gamepads that come and go and the Steam Deck; tile paths, flow fields and behaviour
trees; lights with shadows from tiles; audio buses with effects, ducking and snapshots; a video player; drag and drop,
tooltips, rich text, buttons with icons, right-to-left languages and isometric tilemaps; tests that drive the UI like a
player; ads with consent, analytics and remote config; and players for the web, Android and iOS that are checked against
the engine they were built with.

Audio without a provider

- `assets.generate_voice` names the keys it needs (`ELEVENLABS_API_KEY`, `OPENAI_API_KEY`) when no provider is configured, and
  `silent: true` writes a silent clip of the line's length (or `seconds`) to test voice-dependent code (LL/FB-0601).
- `assets.generate_loop`: a seeded, seamless noise bed (wind, fire, clock) or chord drone, as WAV or Ogg. `assets.convert_audio`:
  WAV to Ogg Vorbis with an encoder built into the engine (long blocks, mono or stereo). Larkspur Lodge's beds and scores are made
  by calls kept in `assets/src/sound/*.json`; its `make_sound.py` is gone (LL/FB-0701).

Docs for what is already there

- A Button's `key` is a localization key, not a hotkey: the field's doc string (and COMPONENTS.md) says so and where a key press
  goes instead (an input action read with `input.pressed`) (LL/FB-0006).
- docs/MENUS.md, "Anchors and pivots": anchors count Y down, widget pivots count Y up, with a picture. `factoria validate` warns
  about a widget of a scene that lies completely outside the design size, naming it, the rectangle it covers and the fix
  (LL/FB-0007).
- `platform.*` in tests: the fake serves a request inside the call (also from an event handler), and the Promise settles in the
  next microtask; docs/PLATFORM.md and SCRIPTING.md say so, and a test pins it. `fake.achievements` lists only the ids that were
  touched (LL/FB-0504).
- docs/MOBILE.md, "Tablets and the iPad": `display.scaleMode: "expand"` shows more world on a 4:3 screen instead of black bars
  (LL/FB-0803, first half).

Hangul on the on-screen keyboard

- The menu kit's on-screen keyboard has an input-method hook, `IME` in `scripts/ui/keyboard.js`: per language, `{ compose(text, ch),
  decompose(text) }` say what the field's text becomes when a key is typed and when Delete is pressed. Korean's is built in: the keys
  are Hangul jamo (Shift gives the doubled ones), jamo make syllables (ㄱ + ㅏ = 가, 가 + ㄴ = 간, 간 + ㅏ = 가나) and Delete takes the
  last jamo away. `tests/slots.test.js` types a Korean slot name with the pad through the slot dialog (LL/FB-0905).

The menu kit: text speed and save slots

- `project.add_menu_kit` has a `textSpeed` part: a "Text speed" row (slow, normal, fast, instant) in the Options Audio tab, saved as
  `settings.textSpeed` in characters per second, with `settings.revealedCharacters(seconds)` for the dialogue box. `addOptionsRow()`
  of `scripts/ui/options.js` adds a row of the game to any Options section without editing the panel (LL/FB-0011).
- A `slots` part: five named slots and an autosave in `storage`, each a record with a counter, name, chapter, play time, picture and
  the game's data; a cloud copy with a higher counter replaces the local slot; damaged slots say why and can be deleted; and a
  save / load screen whose dialog names a save, with the on-screen keyboard for a gamepad player. It brings `core` and `keyboard`
  and its own `tests/slots.test.js` (LL/FB-0501).

Shipping checks: a sandboxed save, long recordings and the iPad

- The exported player takes `--persist-storage` with `--frames`, `--input`, `--dump-state` and `--screenshot`: `storage.*` and the
  save files go to the game's real user folder (the container of a sandboxed Mac App Store build) instead of memory, so a
  replay that presses Play and saves leaves a real file with no click (LL/FB-0801). `cli_larkspur_ship` does it for Larkspur Lodge.
- `--record-video` no longer grows with the length of the recording: on macOS every frame read back from the GPU was kept until
  the end of the run (4.4 GB for 25 s at 1080p); the memory is now flat (LL/FB-0802).
- The iOS player plays an input replay in its window when started with `FA_INPUT_REPLAY=<file>` and turns the screen with
  `FA_ORIENTATION=portrait|landscape` (iOS 16 or newer). `player.run_ios_sim` installs a Simulator build on an iPhone or an
  iPad simulator, starts it with both, waits for the replay to end, takes a screenshot and stops it (LL/FB-0803). Not run on a
  real iPad.

Listing data files

- Glob import of JSON data: `import tables from "../data/dialogue/*.json"` is an object of the parsed files directly in that
  folder, keyed by file name (`"ch1.json"`) in sorted order. `*` is allowed in the file name only. Editing a matched file reloads
  the importers; a file added while the game runs is seen on the next start. The export already packs every data file, so the
  glob finds the same files in `game.pak` and on the web. The generated typings declare `*.json` modules (LL/FB-0005).
- Larkspur Lodge reads its chapter tables with a glob import: a new chapter file needs no edit to a list.

Entity and scene lifetime

- `scene.generation`: a counter that changes on every scene load (`scene.load`, `scene.reload`, `game.load` in a test), a reload
  of the same scene included. A script that awaits a timeline, a preload or an answer keeps it and drops the result when it
  changed, which `scene.current` cannot tell on a reload (LL/FB-0602).
- `world.entities()` skips entities destroyed this frame, as `find`, `findAll` and `findByTag` already did, and the doc of
  `Entity.destroy` says when an entity is gone: lookups and ids at once, the handle (`alive`) at the end of the frame
  (LL/FB-0015). Larkspur Lodge's screens no longer prefix their ids with a build serial.

Tests that drive the UI like a player

- `game.tap(action)` taps the first key (or else the first gamepad button) bound to the action, so the UI and every action on
  that key see it: `game.tap("ui_submit")` presses the focused Button or Toggle (LL/FB-0009). An action with only a stick, the
  mouse or no binding is still held as the action.
- `game.checkLayout(options?)`, and `ui.check_layout {current: true}` for the command: measures the scene that runs now, with the
  panels a test has opened, without loading anything, and keeps the game state (LL/FB-0702, TM/FB-0063).
- `game.resetState()` also stops the music (`persist: true` included) and the voices; `{ audio: false }` leaves them (LL/FB-0704).
- The fake store applies `platform.stats.add` on the value it holds when it serves the request, so two adds in one frame both
  count; the call log shows one `stats.add` instead of a `stats.get` and a `stats.set`. A real store still gets a get and a set
  (LL/FB-0502).
- Larkspur Lodge drops its `tapKey("Space")` calls, its manual layout walk, its music reset and the pause between two saves.

A camera inside the UI, and studio lighting

- New widget `CameraView`: it draws a named Camera inside its rectangle, clipped by a ScrollList, layered like any widget and
  under a modal Panel's own widgets, so a 3D item, a portrait or a minimap needs no hole cut in the page. The pointer over it
  is the game event `ui.viewPointer` (`ui.on("viewPointer", fn)`: down, drag, up and the wheel, with `u`, `v`, `dx`, `dy`) so a
  script can turn what it shows; `pointerEvents`, `captureWheel`, `tint` and `resolution` tune it. docs/MENUS.md, "A camera inside
  the UI". Not yet: a render texture as the source (only cameras), and in a view no bloom, colour filter or debug draw.
- `Camera.lighting: "studio"` ignores the scene's lights, ambient, sky and fog and lights with a key, fill and rim of its own
  (`studioIntensity` scales them): an item looks the same on a stage far from the level and in a bright scene.
- `Camera.viewport` says which rectangle its fractions count (the game target, the design resolution grown by Expand), and
  `Camera.viewportSpace: "design"` counts them on the design area instead (LL/FB-0014). `RenderStats` has `views`.
- Larkspur Lodge's item view is a `CameraView`: no four bands around a hole, no darkened colours; the wheel zooms it.

Input routing: a consumed action, text input mode and the wheel under a modal

- `input.consume(action)`: later readers in the frame see the press as gone, for the action and for every action on the
  same key (Escape is `ui_cancel` and `pause`). The UI consumes `ui_submit` when it clicks a focused Button or Toggle and
  `ui_cancel` when a drag takes it or a `ui.on("cancel")` handler returns `true`, so Escape closes a dialog without also
  opening the pause menu (LL/FB-0008).
- `input.textInputMode`: true while a TextField has the focus (or a script set it); actions bound to printable keys read
  as up meanwhile, so typing P in a TextField does not pause. The menu kit's on-screen keyboard sets it, its
  `ui.on("cancel")` returns `true`, and `MenuStack.busy` resets when a scene builds a `MenuStack` (LL/FB-0503).
- `Panel.wheelPassThrough`: a modal Panel leaves the mouse wheel to scripts (LL/FB-0012).
- Larkspur Lodge drops its `MenuStack.busy` routing around the dialogue log, the screens and the save dialog.

Right to left: the UI mirrors itself and a Text has a direction

- `ui.mirrorRtl` (on by default; `"ui": { "mirrorRtl": false }` in factoria.json, `ui.mirrorRtl = false` in a script, the
  `ui.set_mirror_rtl` command): in a right-to-left language (`i18n.direction` rtl) the screen-space UI is mirrored by the
  engine. The `anchor.x`, `pivot.x` and `position.x` of every widget flip, a Toggle's box sits at the right of its label, a
  Slider runs from right to left (drawing, click and arrow keys), a Button's icon changes side, and the Text, Sprite and
  Shape2D below a widget go with it. `ui.rectOf`, `ui.state`, clicks and the editor's picking follow. A project that placed
  its widgets by hand for Arabic or Hebrew turns it off, or deletes that code (LL/FB-0903).
- A `CameraView` changes side with its layout but never shows a mirrored picture, and its `ui.viewPointer` `u`, `v`, `dx` and `dy` are not
  flipped.
- `UiBox.mirror` (`mirror: false` on any widget): the widget and everything below it keep the place they were authored in,
  for a map, a 3D view or a joystick.
- `Text.direction`: `auto` (default), `ltr` or `rtl`, the base direction of the paragraphs. `auto` with a localization
  key (`key` on a Text or a widget) takes the language's direction, so a Hebrew line that starts with a key name or a
  placeholder is right to left without a U+200F mark; `rtl` also makes `align: "start"` the right edge. The `visibleCharacters`
  reveal still follows the order of the text (LL/FB-0904). docs/LOCALIZATION.md, section 6.
- Larkspur Lodge lost `kit.mx` and the U+200F marks of `locales/he.json`.

A typewriter reveal and Korean that keeps its words

- `Text.visibleCharacters` (-1 = all, the default) draws only the first n characters of a Text, counted in grapheme clusters
  (a letter with its accents, an emoji sequence or a Hangul syllable is one). The text is laid out as a whole and then
  clipped, so the box keeps the size of the full line while it reveals; a right-to-left line appears from its right end
  (LL/FB-0004). docs/TEXT.md, "Typewriter reveal".
- `Text.wordBreak`: `auto` (default), `normal` or `keepAll`. A wrapped Korean line now ends at spaces and keeps its words
  whole by default; `normal` also breaks between Hangul syllables (the old behaviour), `keepAll` makes Chinese and Japanese
  break at spaces only too (LL/FB-0902). Chinese and Japanese without spaces still wrap between characters under `auto`.
- Larkspur Lodge's dialogue box lays its line out with `maxWidth` and reveals it with `visibleCharacters`: no hand-written
  wrapping, no blank lines padding the box.

Every hit of a ray, and colliders you can switch off

- `physics.raycast3dAll(origin, dir, maxDistance, opts)` and `raycast2dAll(from, to, opts)` return every collider the ray
  crosses, nearest first, up to `opts.maxHits` (default 32); the command is `physics.raycast_all`. No more casting again
  from just past each hit.
- `Collider3D.enabled` and `Collider2D.enabled` (default true), writable at run time: a disabled collider is skipped by
  raycasts, shape casts, overlaps, contacts and trigger events and left out of the NavMesh3D bake, and the component stays,
  so a door that opened can close again. The change takes effect at the next physics sync (once a frame, before scripts).

Glyph atlas that refills its texts

- The glyph atlas grows 1024 -> 2048 -> 4096 before it clears, and says so in the log. When it grows or clears halfway
  through a frame, the frame is gathered again, so no `Text` or UI label stays blank (LL/FB-0901). `RenderStats` has
  `glyphAtlasSize` and `glyphAtlasResets`. docs/TEXT.md, Limits.

Isometric tilemaps and cell picking

- `Tilemap.projection: "isometric"` draws diamond tiles (a 2:1 city or strategy map) as one batched mesh, row by row so the
  tiles nearer the viewer cover the ones behind them. `groundHeight` is the diamond's height (0 = `tileSize.y`) and
  `groundOffset` the pixels between the top of the tile image and the diamond's top corner, so a tile can be a block, a tree or
  a house taller than its ground. The entity's position is the top corner of cell (0, 0).
- Everything that reads a Tilemap follows the projection: `solidTiles` colliders are diamonds, `occludesLight` shadows follow
  the diamonds, `nav.findTilePath` returns the diamond centres and distances, `entity.bounds()` and the editor's outline and
  click area cover the diamonds, `scene.import_ascii` and `tilemap.set_tile` work as before, and the `anchor` of
  `scene.import_ascii` places an isometric map by its bounds.
- `entity.tilemap.cellAt(point)` (a `{col, row}`, or `null` outside the map) and `entity.tilemap.cellToWorld(col, row)` for both
  projections, and the commands `tilemap.cell_at` and `tilemap.cell_to_world`.
- The sprites section of the AI guide says how items of one layer are ordered (lower y on top, then creation order).
- Tidewater Market's ground (terrain, trees and roads, about 2600 sprites) is one Tilemap with a tileset per season: its game
  scene has 246 entities instead of 2826, the title 112 instead of 2712 and the stress scene 1029 instead of 4840. The title and
  stress scenes draw one call more, because the tileset is a second texture. The trees are part of the ground now, so a
  building covers the trees in front of it.

A CJK font subset from the locales

- `assets.subset_font {source, locales, keep, out, axes}` cuts a font down to the characters of `locales/<language>.json` (the
  languages of `localization.languages` by default; the same characters `factoria validate`'s glyph check asks a font for) plus
  ASCII, Latin-1, the full-width forms, CJK punctuation and `keep`. A variable font is pinned to one instance (`wght` 400 by
  default), the shaping tables stay, and the result lists the characters the source lacks. It uses HarfBuzz's subsetter (vendored in
  `external/harfbuzz`, linked by the tools only): no Python or fontTools. Tidewater Market's 17 MB Noto Sans SC becomes a 340 KB
  subset with the command, and its `make_subset.py` is gone. TEXT.md and LOCALIZATION.md no longer send you to `pyftsubset`.

A picture of the running game as a texture

- `render.captureTexture({ width, height, fit })` makes a `Texture` of the frame the player sees (HUD included) at the size
  asked, up to 2048 px a side: `fit: "cover"` (default) cuts the middle part with that aspect ratio out, `"stretch"`
  squeezes the whole frame in. A capture at the game's size has exactly the pixels of a screenshot. `texture.id` (`"runtime:3"`)
  goes in `Sprite.texture`, `Panel.texture` or `Button.icon`. `texture.toPNG()` gives the picture as Base64 text (`storage`
  keeps JSON), `render.textureFromPNG(text)` makes a texture of it again, `texture.destroy()` frees it; 32 textures at most.
  A run with no renderer gets a flat placeholder of the right size (`texture.placeholder`), so the saving code still runs.
  The pixels come from the readback each backend already had for screenshots. See SCRIPTING.md, "Render".
- Tidewater Market's save slots (and the autosave) show a real picture of the town at the moment of the save instead of the
  run-length map; an old save with no picture keeps the map. The pictures are not part of the cloud copy.

Web audio without the deprecated node

- The web player plays through an `AudioWorkletNode` fed from the main thread by messages (no threads or `SharedArrayBuffer` needed),
  with a `ScriptProcessorNode` only where worklets are missing: no deprecation warning in the console, a smaller buffer, and no
  underruns at 60 fps. Latency is measured in EXPORTING.md (TM/FB-0054).

Gendered strings and the kit's loading line

- A string table entry can have a gender, `{"text": "Ligera", "gender": "f"}` (`f`, `m` or `n`), and a sentence picks its
  form by it: a select entry is an object with `f`, `m`, `n` and `other` forms (`"ship_the": {"f": "la {name}", "m": "el
  {name}", "other": "{name}"}`), chosen by `args.gender`. `i18n.gender(key)` gives the gender of a string; `i18n.t` falls to
  `other` (warning once) when the gender or the form is missing. `factoria validate` warns about a select entry without a form
  the language uses and about a name that lost its gender; `i18n.export` and `i18n.import` (CSV and XLIFF) carry the forms
  (`ship_the#f`) and a `key#gender` row. docs/LOCALIZATION.md, section 5c, also says how to phrase around case.
- The menu kit's loading screen writes `i18n.t("loading.progress", {percent})` (the Text has no key), so "Cargando... 40%"
  is Spanish in Spanish. Games that copied the kit keep `loading.text` until they take the new `loading.js`, scene and strings.

A chart widget

- `Chart` draws `values` (one series, or several) as bars or lines inside a widget rectangle, in one batch: the axis is
  automatic (always including the `baseline`, zero by default) unless `min` / `max` are set, a baseline rule, `marks` (vertical
  rules at sample indexes), `colors` per series, and the axis maximum and minimum written in the language's number format.
  `slots` keeps each sample's width while a rolling series fills up. The sample under the pointer is reported: `ui.on("chartHover",
  (e) => ...)` gets `index`, `series` and `value` (`index` -1 when the pointer leaves), and `Chart.hoverIndex` / `hoverSeries`
  hold it. Tidewater Market's charts panel is two Charts instead of pools of rectangles and lines.

A choice card and modal panels

- `Panel.modal`: while the panel is active the mouse, the wheel and keyboard / gamepad navigation reach only its widgets (a
  focus scope). What is under it gets no hover, press, click, focus, tooltip or drop, the focus stays inside it,
  `ui.pointerOverUi` is true everywhere and the wheel is not passed on. The topmost modal panel (highest `layer`) is the scope.
- The menu kit has a `card` part: `Card` in `scripts/ui/card.js` with `prefabs/ui/card.prefab.json` is a modal card with a
  title, a wrapped rich-text body, choice buttons that each have a detail line, a choice greyed out with its reason shown, a
  result stage with Continue and a `holdClock` option (`game.paused` while it is open); mouse, arrows and pad. See MENUS.md.
- Tidewater Market's event and story cards are the kit's card; its draw calls and entities are the same.

Atlas packing while developing

- `assets.pack_atlas {folder, out, table, maxSize, padding}` packs a folder of images into one PNG and writes the frame table
  (`rect` and `pivot` per frame) that a Sprite's `region` and `pivot` read. Packing again keeps the frames whose size did not
  change where they were, so adding a picture changes one line of the table. docs/ASSETS.md says when the export's atlas
  groups are enough and when an atlas while developing is worth it. Tidewater Market uses it instead of its Python script.

A strategy camera

- Camera helpers for a 2D camera: `camera.zoomAt(screenPoint, factor, { min, max })` zooms towards the cursor (the world point
  under it stays under it), `camera.panBy(screenDelta)` moves the world with a drag, `camera.clampTo(rect, { margin })` keeps
  the view inside a rectangle (centred when it is smaller), and `camera.zoomOf()`, `camera.setZoom(zoom)` and
  `camera.orthoSizeFor(zoom, designHeight)` convert between pixels per world unit and `Camera.orthoSize`.
- The menu kit has a `cameraRig` part: `scripts/camera_rig.js`, a behaviour for the camera entity with drag pan, keys, edge
  pan, wheel zoom to the cursor between `zoomMin` and `zoomMax`, and a limit from `entity.bounds()` (`boundsEntity`). It
  ignores the wheel and new drags over the UI and the wheel a ScrollList took. `project.add_menu_kit` adds its `camera_*`
  input actions. The recipe is AI_GUIDE.md section 9.6.1.
- Tidewater Market drops `camera_math.js` and `camera_rig.js` for the kit's rig (`scripts/game/map_camera.js` adds its gamepad
  cursor and latched drag on top); its draw calls and entities are the same.

Buttons with an icon

- `Button.icon` (a texture), `iconRegion` (a sprite-sheet frame), `iconSize` and `iconPosition` (`left`, `top` or `alone`)
  draw an icon inside the button, so a click on the icon presses it. The label sits beside or under the icon, the pair
  centred; `alone` draws the icon only. `autoSize` grows the button to hold both and `autoShrink` shrinks the label to the
  room the icon leaves. Tidewater Market's build menu items are Buttons with the building as their icon.

Drag and drop

- `draggable` on any widget or Panel (`true`, or `{ "payload", "slop" }`) lets the player drag it with the mouse, a finger or
  a gamepad cursor (`ui.setPointer`). `ui.on("dragStart" | "dragOver" | "drop" | "dragCancel", fn)` reports the source, its
  payload, the pointer and the target (a widget, or `null` over the world). `ui.setDropTarget(widget, true | false | fn)` and
  `ui.setWorldDropTarget(...)` say what accepts, `ui.setDragImage(widget)` makes a widget follow the pointer, `ui.dragging`
  tells scripts a drag is on, `ui.cancelDrag()` ends it, and `game.drag(from, to)` drives it in tests. When a drag starts the
  press is dropped: the release makes no click, and a tooltip hides. `ui_cancel` cancels a drag instead of sending `ui.cancel`.
  Tidewater Market drops its own drag code for the worker chips.

Modifier chords in input bindings

- A binding takes modifiers: `"Ctrl+Z"`, `"Shift+MouseLeft"`, `"Ctrl+Shift+S"`, in `factoria.json` `input.actions`,
  `input.rebind` and `input.player(i).rebind`. `Ctrl`, `Shift`, `Alt` and `Super` name either side's key, and so do they in
  `input.keyDown` / `keyPressed` / `keyReleased`; `"Shift"` alone is a binding too. When one action binds `Z` and another
  `Ctrl+Z`, the chord wins: `Z` does not fire while Ctrl is held. Chords print back as `Ctrl+Alt+Shift+Super+input`.
  A bad chord is an error that says which part is wrong and what to write (`"Cntrl+Z"`: did you mean `Ctrl`), in
  `factoria validate` too.
- `input.lastPressed()` (and the player's) returns the chord when modifiers are held. A modifier pressed on its own is
  now reported when it is released, not when it goes down, so a "press a key" screen can record `Ctrl+Z`. The menu kit's
  Controls tab records and shows chords (and keeps mouse chords out of per-player bindings).
- Tests: `game.keyDown("Shift")` / `keyUp("Shift")` hold a modifier (the left key), `game.tapKey("Ctrl+Z")` taps a chord. The
  `game.input` command and replay files accept `Ctrl`, `Shift`, `Alt` and `Super` as key names too.
- Tidewater Market binds Ctrl+Z, Ctrl+Y (with the plain Z and Y it had) and Shift+click (a road or a demolish takes two
  clicks, as with the hold-free option) through the engine.

Tooltips

- `tooltip` on any widget or Panel (a localization key, `{ title, lines, args }`, or a function from
  `ui.setTooltip(entity, fn)` that returns the text when it shows). It shows after `ui.tooltipDelay` seconds of rest within
  5 pixels, beside the pointer and flipped to stay on screen, is styled by the new `"ui": { "tooltipDelay", "tooltipOnTouch",
  "tooltip" }` of `factoria.json` and stays off on touch unless the project turns it on.
- `ui.showTooltip(content, { x, y })` and `ui.hideTooltip()` for what is not a widget, `ui.setWorldTooltip(fn)` for a
  pointer over no widget, and `ui.tooltip` (also `tooltip` in `ui.state`) to read what shows. `ui.check_layout` reports a
  `tooltip` issue for an invalid or screen-sized tooltip. Docs: MENUS.md, SCRIPTING.md.
- Tidewater Market drops its own Tooltips class for the engine feature (TM/FB-0007).

The web's hide and close signals, and storage that scales

- A web export raises `suspend` when its tab is hidden and `resume` when it is shown again (`visibilitychange`), and `quit`
  when the page goes away (`pagehide`; it cannot be cancelled there). The save folder is copied to IndexedDB right after
  those handlers run, so a `storage.set` inside one is kept (before, only a 500 ms timer was scheduled). SCRIPTING.md
  ("Window close") lists which of `blur`, `suspend` and `quit` each platform raises; MOBILE.md and EXPORTING.md say what the
  web does (TM/FB-0021).
- `storage` writes one file per key in `<save folder>/storage/`, so a save rewrites its own key only. An older `storage.json`
  is read at the first start, split into key files and renamed `storage.migrated.json`. `storage.size(key)` gives the bytes
  of a key's file. `storage.set(key, value, {compress: true})` stores the value zlib-compressed. `storage.setAsync(key, value,
  options?)` returns a Promise and writes off the frame (a worker thread; between frames on the web); the writes still waiting are made after the
  `suspend` and `quit` handlers. Docs: SCRIPTING.md
  (storage) (TM/FB-0022).
- Tidewater Market writes its timer and season autosaves with `storage.setAsync` (compressed) and its blur, suspend and quit
  saves at once with `storage.set`.

Tile paths on a reusable grid, and flow fields

- `nav.createGrid({ width, height, cost?, origin?, cellSize? })` keeps a cost grid in the engine. `nav.findTilePath(grid,
  from, to)` takes it instead of the `{ width, height, cost }` array, with the same options and the same paths, but a call
  no longer converts the whole array and sweeps it for its cheapest cell, so a short route stops costing the size of the
  map. `grid.setCost(col, row, cost)` changes one cell (`getCost`, `setCosts`, `version` and `findPath` are there too).
  The array form works as before.
- `nav.flowField(grid, goals, { diagonals })` searches once from one or more goal cells: `field.stepToward(col, row)` gives
  the next cell toward the nearest goal in O(1), `field.distance(col, row)` the cost and `field.pathFrom(col, row)` the
  whole way. A field made before `grid.setCost` is rebuilt the next time it is asked.
- The `nav.flow_field` command is the stateless form (distances for the whole map, plus the next step and the path from a
  cell). In a debug build, 600 walkers on a 60 x 60 map for 75 ticks cost about 228 s with the array form, 8.2 s with the
  kept grid and 0.16 s with flow fields (a benchmark test prints it). Docs: NAVIGATION.md, PERFORMANCE.md.
- Tidewater Market's own distance fields are now `nav.flowField` over a `nav.createGrid` (TM/FB-0006).

Players for a development build

- `factoria setup webplayer` (and `setup.install {component: "webplayer"}`) builds the web player from the engine checkout
  `factoria` was built from: it uses an Emscripten SDK it finds (`$EMSDK`, `emcc` on `PATH`, the checkout's `.cache/emsdk`,
  `~/emsdk`) or fetches the pinned 6.0.10 into `.cache/emsdk`, runs the `web-release` preset and leaves the player in
  `build/web-release/player`, which `factoria export --platform web` prefers. An up-to-date player is not built again.
- `factoria setup players` on a development build whose version has no release no longer stops: it takes the players of the
  newest release, installs them under this version's folder and warns that their build fingerprint will not match, so an
  export that uses them needs `allowPlayerMismatch` (`--allow-player-mismatch`).
- docs/EXPORTING.md: the Emscripten setup under Web and "A development build: players from the checkout".

The export's size report, and the web page's icon

- Every export names the five folders that weigh most in what ships (`largestFolders` in `--json`) and warns when a `store/`,
  `screenshots/` or `src/` folder, at any depth, is packed, pointing at `export.exclude`.
- A web export lists the raw and about-gzip size of each file of the zip, the total, and how long the gzip total takes to
  download at 1, 5, 20 and 100 Mbit/s (`webFiles`, `webBytes`, `webGzipBytes`, `webDownloadSeconds` in `--json`).
- A web export links a `favicon.png` (64x64) made from the game's `icon` in `index.html`, instead of an empty icon; the
  page template has a new `{{favicon}}` placeholder. A game without an icon keeps the empty icon.

Rich text: bold, colours and icons inside a text

- `Text.markup: true` reads `[b]bold[/b]`, `[c:good]coloured[/c]` and `[icon:fish]` in the text, and so does the label of a
  `Button`, `Toggle`, `Slider` or `TouchButton` with `markup: true`. Wrapping (also between CJK characters), alignment,
  `maxWidth` and `autoShrink` work on the whole line, and `ui.measureText(text, { markup: true })` and `entity.bounds()`
  measure what is drawn. An icon is a rectangle of a project texture as tall as the line. The glyphs of a Text, of any
  colour and weight, are one batch; each texture that icons come from adds one more.
- The new `text` section of `factoria.json` names the colours (`text.colors`), the icons (`text.icons`: texture and pixel
  region) and the bold file of each font (`text.fonts`). `Text.bold` (and the same field of the widgets) draws a whole text
  bold. A font without a bold file is emboldened by the engine; `factoria validate` suggests adding one, and checks the
  section, the files it names and the markup of scene texts.
- Mistakes never hide the sentence: an unknown tag, a `[` without `]` or an unknown colour shows as written, with one
  warning per text. `ui.markupProblems(text)` lists them for a test. `[[` writes a literal `[`.

An interface size, Panel minimum and maximum sizes, and events for the size options

- `ui.scale` (0.5 to 3, default 1) makes the whole screen-space interface bigger or smaller: the size, offset, padding,
  spacing, margins and font size of every widget and of screen-space `Text`, `Sprite` and `Shape2D` are multiplied by it
  (`ui.textScale` comes on top for text), and anchors do not move. `ui.rectOf`, `ui.state` and the hit test are in screen
  pixels and follow it; `Panel.size` and `ui.measureText` stay in UI units. `"ui": { "scale": 1.25 }` in `factoria.json` is
  the start value (a project reload applies it only when the file changed), `ui.set_scale` is the command and `ui.state`
  reports `uiScale`. Screen-space particle emitters are not scaled. docs/TEXT.md, "Interface size".
- `Panel.minSize` and `Panel.maxSize` (0 = no limit on an axis) bound the size of a Panel, also one with `fit: true`.
- `ui.on("scale", fn)` and `ui.on("textScale", fn)` run once per change, with `{ value, previous }`, like
  `i18n.on("change")`.
- `ui.check_layout` takes `uiScales` and crosses them with the languages and text sizes. The menu kit's Options has an
  "Interface size" button (the sizes at which its panel fits), saved as `uiScale` in `settings.js`. Games that copied the
  kit copy `scripts/settings.js`, `scripts/ui/options.js`, `prefabs/ui/options.prefab.json` and the `options.uiScale`
  string of `locales/*.json`.
- Fixed: a `Text` with `maxWidth` and a centred or right-aligned `align` is drawn in a box of `maxWidth`, but its bounds (layout,
  `ui.state`, editor) were those of its widest line, so a right-aligned note in a right-to-left Panel was drawn off its
  rectangle. Its bounds are now the box it is drawn in; left-aligned text is unchanged.

Tooling: feedback merges, perf files of several scenes, and recording progress

- `factoria feedback collect` no longer merges two gaps whose titles only share a few words: a title that contains
  another needs four shared words, the `missing` text weighs in, an entry may list `distinctFrom` ids it never merges
  with, and the report prints each merged entry's similarity to its group.
- ctest runs every `<example>.perf.json` and `<example>-*.perf.json` file of an example, so a game with a title, a game
  and a stress scene keeps a budget for each (docs/PERFORMANCE.md).
- `factoria run --record-video` prints its progress (frames written of the total) on stderr while it records.
- PLATFORM.md says that `game.platform.calls()` shows a `stats.add` as a `stats.get` and a `stats.set`.

Audio: buses of your own, the voices that play, `onEnded`, and a listener zoom

- `factoria.json` `audio.buses` declares buses with a parent (`"ambience": { "parent": "sfx" }`). A bus scales the sounds
  played on it (`audio.play(clip, { bus: "ambience" })`), its parent scales it in turn, and it takes `audio.setVolume`,
  `audio.bus(name)` effects, ducking and snapshots like the built-in ones. `factoria validate` checks the names with a
  "did you mean". The built-in buses (`master`, `sfx`, `music`, `ui`) work as before.
- `audio.activeVoices()` lists the sounds that play now, and `audio.play(path, { onEnded })` calls back once when a sound
  finishes, is stopped with `audio.stop` or is dropped by a full mixer (not on `stopAll` or a scene load).
- `game.audioLog()` has an entry for every `audio.setVoiceVolume` on a playing voice (`kind: "setVoiceVolume"`, with
  `voice` and `fade`); `toContainPlayed` skips them.
- `AudioListener.zoom` (default 1) scales how far positional sounds reach: a zoom of 2 doubles the distance.

Script helpers: the rng state, running a module, did-you-mean, a shadowed method

- A generator from `rng.create` has a `state` (a 32-bit integer) you can read and assign, documented as stable like the
  algorithm: store it in a save and assign it to resume the same stream.
- `script.eval` takes `module` (a project path), `call` (an exported function) and `args`, and returns the function's
  result: `factoria call script.eval` runs a pure module with no scene.
- `didYouMean(word, choices)` is exported from `"factoria"`; docs/EXTENDING.md has a recipe for a project tool that
  validates the cross references of `data/*.json` with file, JSON pointer, hint and did-you-mean.
- A `Behaviour` field named `on`, `after`, `every` or `world` replaced that method without a word. The first instance of
  the class now logs one warning naming the field, and `factoria validate` reports it.

`ui.rectOf` and hidden parents; docs for what was already there

- `ui.rectOf(entity)` returns `null` for a widget or screen-space Text hidden by an inactive parent, as `ui.state` already
  left it out; it used to give the rectangle it would have had. The docs now say that a child of a hidden Panel keeps
  `active` true (ask `activeInHierarchy`), that a screen-space line's `size.y` points up, how a Panel's children are
  placed, how to press the focused widget in a test, and the test section of SCRIPTING.md uses `fa.call("ui.state")`.

A wrapped text measures its widest line; a Toggle's box follows the font size

- With a renderer a wrapped text was at least as wide as its `maxWidth`, so `ui.overflowed`, `ui.check_layout` and
  `autoShrink` flagged and shrank a short label for nothing, while headless measured the widest line. Both measure the
  widest line now, so a layout test and the window agree. A wrapped Text with a pivot or centre alignment is placed by that
  width, so it can sit a little differently than before.
- A Toggle's box is one line of its label high (`fontSize` at the player's text size, times 1.2, plus 4 px), no longer the
  widget's height minus 12: a two-line label or a taller toggle keeps the same box. `Toggle.autoShrink` and `minFontSize`
  fit the label into the room right of that box.

Web, Android and iOS players are checked against the engine build

- `factoria export` compared only a desktop player with its own build. It now compares the web player
  (`factoria_player.wasm`) and the prebuilt Android and iOS libraries too: a player of another build stops the export with
  the two builds and what to do (`factoria setup players`, the checkout's `build/web-release`, or `--allow-player-mismatch`).
  A web export with no `--player` takes the player whose build matches, the checkout's `build/web-release` before the
  installed one. A script that imports an export the player lacks, or calls a method of the engine's objects it lacks,
  now gets an error naming the module and the missing export and saying the player may be older than the game's engine.

A UI hit test, a virtual pointer, the consumed wheel and an empty focus

- `ui.widgetAt(x, y)` returns the topmost visible widget or Panel at a screen point (nothing for empty space or a row a
  ScrollList clips) and `ui.pointerOverUi` says whether the pointer is over one. A game with a gamepad cursor no longer
  scans the scene itself.
- `ui.setPointer(x, y, { down })` drives hover, press and click like the mouse, from the next frame on, until
  `ui.setPointer(null)`: for a gamepad cursor and for tests.
- A ScrollList with more content than it shows keeps the mouse wheel: `input.mouse.wheel` reads 0 that frame and
  `ui.wheelConsumed` is true, so a camera that zooms with the wheel needs no check of its own.
- `ui.focus(null)` holds until the next arrow / D-pad press: an open panel's `autoFocus` no longer takes the focus back
  on the next frame.

Web exports download the game's code once

- The page of a web export handed the downloaded wasm to the player through `Module.wasmBinary`, which Emscripten 6 no
  longer reads, so the browser fetched the 8 MB file a second time on every load. It now uses `Module.instantiateWasm`:
  one download, with the progress bar, and a plain error when the browser cannot compile it. Re-export a web game to get
  the new page.

Versions for the script API

- `tools/common/api_since.json` has a `"script"` section: each function, type and member of the scripting API says which
  release added it, taken from the `api.json` of every release tag. The typings (`types/factoria.d.ts`) and the
  scripting API part of docs/COMPONENTS.md carry it as `@since` for what came after 0.1.0, so `nav.findTilePath`,
  `bt`, `http.fetch` or `game.today` tell when they appeared.

Two more behaviour tree nodes, and a tile counter that sees every change

- `bt.parallel(...children)` (or `bt.parallel({ succeed: "any" }, ...children)`) ticks all children each tick and fails at
  the first failure; `bt.repeat(child, times?)` runs the child again after each success (once per tick), forever or `times`
  times. SCRIPTING.md, "AI: behaviour trees".
- `nav.tileVersion(tilemap)` now also counts writes that replace `tiles` as a whole (`tilemap.tiles = [...]`,
  `scene.set_component`, editor edits), not only `setTile`.

A smaller player

- The linker drops the engine code no game reaches: `-dead_strip` on macOS and iOS (the macOS player goes from 10.2 to
  9.1 MB without symbols), `--gc-sections` on Linux. Android, Windows and the web already did. A game plays the same: five
  levels of the reference games give the same world state and screenshot after 1200 frames. Sizes per platform:
  docs/EXPORTING.md, "Size of the player".

Burrow Brigade drops the workarounds M29 made unnecessary

- Burrow Brigade gives every torch, crystal and magma source its own Light2D (no pool of 16), writes fog and shift tiles with
  `tilemap.setTile`, copies and pastes through the system clipboard, keys its daily dig and board by the UTC day with
  `{day}`, and detects a Steam Deck with `game.device.steamDeck`. Its feedback entries are closed with what it kept and why.
  Its perf baselines count the real lights (entities 145, lights 20, `maxLights` 24).
- Burrow Brigade's Options > Video uses the window API: windowed, borderless window and full screen with
  `window.setMode`, and a monitor button (`window.monitors()`, `window.setMonitor`) where the platform has several
  monitors; an older save's full screen flag still works. A pad player keeps its pad's `padId`, and a pad that returns
  in another slot is followed (`gamepadConnected`).

Split screen: camera viewports

- `Camera.viewport` is the part of the screen a camera draws into: `[x, y, width, height]`, each 0 to 1, origin top-left, default
  `[0, 0, 1, 1]`. Every active camera with `primary: true` draws in ascending `depth`, each with its own scissor, culling, 2D lights
  and 3D lights, and `clear` per camera. Two or more cameras make a split screen (two or four players) or an inset. The UI and every
  `space: "screen"` item is drawn once over the whole screen; bloom and `colorFilter` run once with the lowest-`depth` camera's
  settings. A scene with a bad `viewport` fails to load, naming the entity and the field; a script that sets one live is clamped
  with one warning. At most 8 cameras are drawn. A scene with one full-screen camera renders as before. Before, only the
  lowest-`depth` primary camera drew: a scene with a second active `primary: true` camera now draws it too, over the first; set
  `primary: false` on a camera that must not draw.
- Scripts: `camera.all`, `camera.at(point)`, `camera.screenRay(point, camera?)`, and `camera.worldToScreen(v, camera?)` /
  `camera.screenToWorld(v, depth?, camera?)` take an optional camera (without one, a screen point uses the camera under it, so a click
  picks what the player under the pointer sees). `input.mouse.world` and a touch's `world` use that camera. The audio listener
  without an `AudioListener` is the first camera drawn. `game.renderStats()` counts per frame, over all cameras. Recipe: AI guide
  section 9.29. Known limit: screen-space `lit` visuals get only ambient light in a frame with several cameras.
- Burrow Brigade: Options > Video > "Split screen when players part" (off by default). On, miners can part and the screen splits into
  two to four views; off keeps the shared camera and the leash.

The exported player checks a build

- `factoria_player` (the exported game) takes `--input <replay>`, `--dump-state <file>` and `--screenshot <file>` together
  with `--frames N`: the game runs headless through the same code as `factoria run --headless --frames N`, plays the replay
  `input.record` writes, writes the world state after the last frame and a PNG of the last frame. Both equal what
  `factoria run` writes for the same replay and frame count. Exit codes: 0, 1 after a script error, 2 for a missing replay,
  an unwritable output or a missing `--frames`. New test `cli_player_replay`; EXPORTING.md has "Checking an exported build".

Tile pathfinding and behaviour trees

- `nav.findTilePath(map, from, to, {costs, diagonals, maxNodes, closest, allowBlockedGoal})` and the command
  `nav.find_tile_path`: deterministic A* over the cells of a `Tilemap` (solid tiles block, `costs` per tile index) or of a
  `{width, height, cost}` grid for games that keep their own map. Diagonals never cut corners; `closest` returns the nearest
  reachable cell. The result lists `cells` and the world `points` of their centres. `nav.tileVersion(tilemap)` counts the
  `setTile` writes so a script knows a kept path is stale. NAVIGATION.md, section 7.
- `import { bt } from "factoria"`: behaviour trees in plain JS (`Tree`, `sequence`, `selector`, `condition`, `action`,
  `wait`, `cooldown`, `inverter`, `succeeder`, `SUCCESS`, `FAILURE`, `RUNNING`), ticked by the script with its own `dt`.
  SCRIPTING.md, "AI: behaviour trees", and an enemies recipe in the AI guide (section 9.27).

Steam Remote Play guests and `platform.cloud.stat`

- New platform service `remotePlay`: `platform.remotePlay.sessions()` lists the guests connected through Remote Play
  Together (`[{ id, guestName, guestId, deviceName, formFactor, resolution }]`) and `platform.on("remotePlay", ...)` gets
  `{ status: "connected" | "disconnected", session }` as each comes or goes. The Steam plugin offers it when the Steam
  library has `ISteamRemotePlay`. A guest's controls arrive as one more gamepad; the engine does not say which pad is which
  guest. The fake store has `game.platform.remotePlayConnect(info)` and `remotePlayDisconnect(id)` (commands
  `platform.remote_play_connect` and `platform.remote_play_disconnect`).
- New `platform.cloud.stat(key)`: `{ exists: false }` for a missing key, else `{ exists: true, size, modified }` without
  returning the text (`modified` in Unix seconds, `null` on Apple, which keeps no time). Steam answers the file's time,
  Google Play the snapshot's last-modified time (it opens the snapshot to count the bytes), the fake a deterministic
  counter (`game.platform.set({ cloudClock })` sets it). To tell which save is newer keep a revision counter in the saved
  value; PLATFORM.md says why.
- The Steam, Apple and Google Play code for both was checked against the mock (Steam) and by reading (Apple, Google Play)
  only: no real Remote Play session or real store was tried.

Light2D on a light buffer: shadows from solid tiles and no 16-light cap

- Point lights are now added up in a light buffer (one draw call, RGBA16F, or RGBA8 at half range on a GPU that cannot
  blend half floats) that lit sprites, tiles and shapes read, instead of every pixel looping over 16 lights. A frame keeps
  up to 256 lights (it was 16): the same choice as before (directional first, then the lights that reach the view, more of
  their radius in view first, then the brighter), the same stats (`lights2d`, `lights2dDropped`) and the same
  `perf.measure` `lights`. The look of a scene with 16 lights or fewer is unchanged (the render goldens still match).
  A lit sprite or tile WITH a normal map is still shaded per pixel by the first 16 lights, because its shading depends on
  the direction of each light; flat surfaces get all of them. A scene without Light2D, or without lit visuals, draws no
  light pass; one with them adds one draw call (the perf baselines of Burrow Brigade went from 10 to 11 draw calls).
  The light pass needs an orthographic camera; a perspective camera shades per pixel with 16 lights as before.
- New field `SceneSettings.lightScale` (0.25 to 1, default 1): the size of the light buffer as a fraction of the
  picture. 0.5 quarters the fill cost of the lights, a good setting for phones and the web.
- New `Light2D.castShadows` and `Tilemap.occludesLight` (both default false). A Tilemap with `occludesLight` makes the
  tiles of its `solidTiles` block the light of every point Light2D with `castShadows`: the far side of a wall stays
  dark, the wall's own face stays lit, and a light inside a solid tile shines out of it. Editing a tile at run time
  (`tilemap.setTile`, the command `tilemap.set_tile`) moves the shadows on the next frame. The
  shadows are traced on the CPU per light (1024 rays) and looked up on the GPU; a light that does not move reuses its rays.
  At most 32 point lights per frame cast shadows (the ones ranked first); the others shine through walls, with one
  warning per scene. The new stat `lights2dShadowed` (`renderStats()`, `game.render_stats`) counts the ones with a shadow.
- docs/PERFORMANCE.md has the cost per light and per shadow-casting light measured on a Mac, and advice for mobile and
  the web; docs/AI_GUIDE.md a recipe for lights with tile shadows. The doc strings and docs no longer say "16 lights".
- `FA_LIGHT_FORMAT=rgba16f|rgba8|none` picks the light buffer format at start-up (testing the fallbacks; `none` uses the
  per-pixel loop over 16 lights, the same as a GPU that cannot render to either format).

Analytics with consent and remote config

- New `analytics` and `remoteConfig` in `factoria`, on top of `http.fetch` (docs/ANALYTICS.md). `analytics.event(name,
  props)` queues small events and sends them in batches to the `endpoint` of the new `"analytics"` section of
  `factoria.json`, but only after `analytics.setConsent(true)`: before that nothing is kept or sent, and a refusal forgets
  the queue. A batch goes out at `batch` events, after `flushSeconds`, on suspend and on quit (the quit waits up to 3
  seconds for the request). A failed send (no connection, 408, 429, 5xx) is retried with a doubling wait, at most 3
  attempts per event; another 4xx drops the batch. `consentFromAds: true` lets the ad consent answer the question until
  the player does. `remoteConfig.get(key, fallback)` reads the JSON of the new `"remoteConfig"` section, caches the last
  good answer in `storage` for offline runs and checks each value against the type of its fallback.
- `factoria validate` checks both sections (hosts declared in `"network"`, `https://`, ranges, misspelled keys) and warns
  about an `analytics.event(` call in a game without the section. The iOS export adds a Product Interaction (Analytics, not
  linked, no tracking) entry to the privacy manifest when the section exists.
- Menu kit: new part `analyticsConsent` (the question on the first run, from the main menu) and an Options switch,
  with `analyticsConsent.*` and `options.analytics` in the locale tables. The kit's own `recipe.test.js` answers the
  question before it opens the main menu.
- Tests: `game.analytics` (`sent`, `requests`, `queued`, `restart`) and `game.remoteConfig.restart`; the answers come from
  the fake `http.fetch`. `storage.keys()` hides the engine's `factoria.*` keys and `storage.clear()` removes them.
- No new command and no `api_since` row: both services are script modules, listed in `factoria api`.
- Burrow Brigade's statistics, balance and online news now use the engine API.

Local multiplayer: actions per player

- `input.player(i)` (0..3) gives each person sharing the machine their own view of the project's actions: `down`,
  `pressed`, `released`, `value`, `axis` and `vector`, driven only by the devices assigned with `player(i).use({ pad,
  padId, keys })`. `keys` names a key scheme (`"all"`, `"left"`, `"right"` or one from the new `factoria.json`
  `input.schemes`, which can `extend` another, add `keys` and give per-action `actions`); `padId` follows a physical
  gamepad across slot changes. A player with no device reads nothing; the global `input.*` still hears every device.
  Each player has bindings of their own: `bindings`, `rebind`, `reset`, `lastPressed`, and `export` / `import` to save
  them in `storage`. A bad slot, scheme, key or action throws with "did you mean" and changes nothing. Mouse and touch
  are not read by players. `input.keySchemes()`, `input.keySchemeKeys(name)` and `input.maxPlayers` list what exists.
  Tests start with no devices; a game assigns them when its scene starts. SCRIPTING.md and the AI guide (9.28) have the
  recipe.
- The menu kit's options script has a `players` property: with more than one, the Controls tab gets a Player button and
  rebinds, resets and saves the controls of the chosen player (`settings.playerBindings`); a single-player game is
  unchanged. MENUS.md and the `en`/`es`/`ar` texts have the two new keys (`options.player`, `options.playerBinding`).
- Burrow Brigade drives its four diggers with `input.player(i)` and four key schemes in `factoria.json`; its saved
  controls move to the engine's action names the first time they are read.

Recording input and starting a scene with props

- The input recorder moved from the editor into the engine and now hears the keys, mouse, touches, Back and gamepads
  (connections, buttons, axes) itself. The new command `input.record` (`{action: "start" | "stop", path?}`) records any
  running game; `stop` returns the replay that `factoria run --input` plays (optionally written to `path`). The editor
  records its Play sessions with the same recorder. Not recorded: mouse wheel, locked-mouse movement and typed text.
- Scenes can start with props: `scene.load(path, props)`, `game.load(path, props)`, `game.loadJson(scene, props)`, the
  `scene.load` command's `props`, and `factoria run --props JSON|FILE`. `game.sceneProps()` returns them from the scene's
  first `onStart`. A reload keeps them; a load without props gives `{}`.

Monitor choice and window modes

- `window.monitors()` lists the monitors (`index`, `name`, `size`, `primary`, `current`), `window.monitor` is the one the
  window is on and `window.setMonitor(i)` moves it there (Windows, macOS, Linux; XRandR on Linux is loaded when the game
  starts, so a machine without it lists one monitor). `window.setMode("windowed" | "borderless" | "fullscreen")` and
  `window.mode` choose how the window is shown; `setFullscreen(bool)` keeps working. On Windows and Linux full screen is
  a frameless window over the monitor, so `"fullscreen"` and `"borderless"` look the same; on macOS `"fullscreen"` is the
  native Space and `"borderless"` a frameless window that hides the menu bar and the Dock. SCRIPTING.md says what each
  OS does. `window.supports("borderless")` and `window.supports("monitors")` tell what the platform can do.
- Menu kit options screen: the Full screen toggle is now a Window mode button (windowed, borderless, full screen) and a
  Monitor button (only with more than one monitor). `settings.js` saves `windowMode` and `monitor` (`{ index, name }`)
  instead of `fullscreen` (a save from the older kit is still read) and restores the monitor, then the mode, at start.
  The locale tables have `options.windowMode`, `options.mode.*` and `options.monitor` instead of `options.fullscreen`.

`http.fetch` on every platform

- `import { http } from "factoria"`: `http.fetch(url, { method, headers, body, timeout })` returns a Promise of
  `{ status, ok, headers, text, json() }`. Windows uses WinHTTP, macOS and iOS `NSURLSession`, Linux libcurl (loaded
  when first used: the player does not link it, and without it `platform.has("http")` is false), Android
  `HttpURLConnection` and the web build the browser's `fetch` (CORS applies). An HTTP error status resolves with
  `ok: false`; a request that did not complete rejects with `code` and `hint`.
- A game declares the servers it calls in `factoria.json` `"network": { "hosts": [...], "purpose": "..." }`: `https://`
  only (plain `http://` to `localhost` for a test server), the host must be listed (`"*.example.com"` covers
  subdomains), no password in the URL, redirects only to https. `factoria validate` checks the section and warns about a
  script that calls `http.fetch` with no host declared. The Android export adds the `INTERNET` permission only when
  hosts are declared.
- Tests, `factoria call`, `session`, headless runs and MCP never touch the network: the fake answers what
  `game.platform.respond("http.fetch", { status, headers, text, json, error })` scripted. An input recording
  (`input.record`, editor play sessions) keeps the answers in the `"http"` field of the replay, and
  `factoria run --headless --input` plays them back.
- `platform.state` shows `httpBackend`, `httpWhy` and `networkHosts`. A plugin cannot offer the `"http"` service.
- New [NETWORKING.md](docs/NETWORKING.md); LEGAL.md and MOBILE.md no longer say that games have no network.

Audio buses: effects, ducking and snapshots

- Every bus (`sfx`, `music`, `ui`) is mixed into its own buffer before the master, so a bus can have effects:
  `audio.bus("music").lowpass(800)` (12 dB per octave, 0 or null = off), `.reverb(0.3)` (a small room), and
  `.duck("sfx", 0.5, 0.05, 0.5)` to push the music down while a sound effect plays (`.unduck()` or `duck(null)` ends it).
  `lowpass`, `reverb` and `volume` take `{ fade }` to slide; a bus with no effect does no effect work. The master takes
  a low-pass and a reverb too, but no ducking. Effects stay across scene loads, like volumes.
- Changing a bus volume (`audio.setVolume`, `audio.bus(name).volume(v)`) now ramps over about 10 ms instead of jumping, so
  it no longer clicks; `{ fade }` makes it a longer, straight-line fade.
- Snapshots: factoria.json `audio.snapshots` names sets of bus settings (volume scale, low-pass, reverb, ducking) and
  `audio.snapshot("underwater", { fade: 1 })` moves every bus to one, a bus it does not list going back to neutral.
  `factoria validate` reports a bad catalog with the JSON pointer, a fix and a "did you mean".
- Commands `audio.bus` (set or read a bus) and `audio.snapshot` (apply one, or list them) for MCP and the CLI.
  SCRIPTING.md ("Audio buses") has the cost of each effect and a recipe.

Test runner and `ui.check_layout`

- `game.click(widget)` (and `mouseMove`, `touch`, `touchStart`, `touchMove` with a widget) lays the UI out first, so a
  panel opened in the same frame can be clicked with no `step` or `ui.layout()`. It throws, naming the widget and why,
  for a widget that is inactive, has no area or is scrolled out of its `ScrollList`, instead of clicking nowhere.
- `game.tapKey(key)` presses and releases a key over one frame; SCRIPTING.md shows `game.tapKey("Enter")` submitting a
  `TextField`, and `fa.call("fs.write", ...)` saving a file from a test.
- `ui.check_layout` judges a widget in a `ScrollList` by the part the list shows (a row half inside is no longer
  reported for its clipped half) and takes `steps` per scene (click, key, action, frames) to open a panel before the checks.

Menu kit: optional shop and age gate, a Controls tab from the actions

- `project.add_menu_kit`: the `main-menu` part no longer brings `shop` and `ageGate`. `{"parts":["main-menu"]}` writes a
  main menu without the Shop button, the shop panel and the age gate line (and without their scripts); add `shop` and
  `ageGate` to `parts` to have them (no `parts` still adds everything).
- The options screen's Controls tab lists every input action of the game except the `ui_*` ones (it was a fixed list of
  `move_left`, `move_right`, `jump`, `pause`), labelled with `options.action.<action>` or the action's name when the game
  has no such string. The `actions` property of the prefab's Script (`"props": { "actions": [...] }`) picks and orders them.

Gamepads that come and go, and the Steam Deck

- `game.on("gamepadConnected" | "gamepadDisconnected", fn)` gives `{ slot, id, name, type }`. `input.gamepad(i).id` and
  `.name` read the same. The id is stable per physical pad on Windows (XInput slot), Linux, macOS, iOS, Android and the web,
  and a pad that returns gets its old slot when it is free. Tests: `game.gamepad(i).connect({ id, name, type })`.
- `game.device.steamDeck` and `game.device.handheld`. The Steam plugin says whether this is a Deck (plugin API version 4,
  `set_device_fact`); without it the `SteamDeck=1` environment variable decides. `game.setDevice` accepts both.

Tilemap: tileset margin and spacing, `setTile` without rewriting the array

- `Tilemap.margin` and `Tilemap.spacing` (pixels, default 0) describe a tileset image with a border and gutters between
  tiles. The 2D renderer (also the normal map), the tile count, `factoria validate` and the level commands read them.
  `assets.slice_sheet` is for animation grids and does not take them.
- `entity.tilemap.setTile(col, row, id)` and `getTile(col, row)` change one tile in place, and the new command
  `tilemap.set_tile` does the same from the CLI and MCP. The renderer reads the grid in place (no copy per frame), and 2D
  physics rebuilds only the colliders of the tiles you changed; a write of the whole `tiles` array still works and is
  caught by a hash.

The time of day and the day boundary

- `game.today()` also returns `hour`, `minute`, `second` (the local time of day) and `utc: { year, month, day, iso }` (the
  date in UTC). A built game reads the clock again about once a minute and on focus or resume, and `game.on("dayChanged",
  fn)` runs once when the local calendar day changes. `game.setDate`, `--date` and replay files (`time`) take a time,
  `game.setDate(iso, { utcOffsetMinutes })` the time zone; moving a test across midnight sends `dayChanged`.
- `platform.leaderboards.submit(id, score, { day })` and `entries(id, { day })` address the daily board of a given day (the
  fake and Steam keep every day). Without `day` a daily board is the local date's; pass `game.today().utc.iso` to both
  for one board worldwide. Game Center and Play Games reject a day other than the local or UTC today with `unsupported`.

Thai line breaks and the sara am check

- A wrapped line now also breaks after U+200B ZERO WIDTH SPACE (no width, never drawn), the UAX #14 spaces (U+1680,
  U+2000-U+2006, U+2008-U+200A, U+205F) and a hyphen (`-` unless a digit follows, U+2010), so Thai, Khmer, Lao and Burmese
  text whose translator marks word boundaries with U+200B wraps there. Unmarked text still needs a dictionary and is not broken.
- `FontCoverage::missing`, `localization validate` and the runtime missing-glyph warning check U+0E33 and U+0EB3 as the parts
  HarfBuzz always decomposes them into (U+0E4D U+0E32, U+0ECD U+0EB2), so a font lacking the nikhahit is reported.

Light2D in the stats and the perf budget

- `RenderStats` (`game.render_stats`, `game.renderStats()`) gets `lights2d` and `lights2dDropped`: the Light2D lights
  that shade a frame (at most 256 since the light buffer, see above) and the ones left out. `lights` and `lightsDropped` stay the 3D lights.
- `perf.measure`'s `lights`, and so the `maxLights` budget, is now the most 2D plus 3D lights of any frame: a budget
  written for a 2D game used to watch nothing.
- The Light2D lights of a frame are the ones that light the view: directional lights first, then the point lights whose
  radius reaches the camera's visible rectangle (more of their radius in view first, then the more intense ones). A light
  entirely off-view is never kept over one in view. More than the budget (256) in view logs one warning per scene naming the count.

Clipboard and window close

- `clipboard.read()` (a Promise) and `clipboard.write(text)` work on Windows, macOS, Linux and the web
  (`window.supports("clipboard")`); phones answer `unsupported`. Headless runs and tests use an in-memory clipboard, and a
  replay's `"clipboard"` entry sets it. A focused `TextField` pastes with Ctrl+V (Cmd+V) and copies with Ctrl/Cmd+C.
- `game.on("quit", fn)` runs when the player closes the window (close button, Cmd+Q, Alt+F4); `event.cancel()` keeps the
  game running. `game.quit()` closes without asking again. Desktop only. Test helper `game.closeWindow()`.

Music: scene loads, live volume, layers

- Fixed: a scene load stopped the sounds but kept the old scene's music in the mixer's memory, so a scene with the same
  `settings.music` started nothing (state said the track played, no voice did). A scene load now restarts the new scene's
  music, the same track included. `audio.music(path, { persist: true })` keeps a track playing through scene loads; a scene
  with the same `settings.music` does not restart it, another track replaces it.
- `audio.setVoiceVolume(id, volume, fade?)` changes the volume of a playing sound, with a straight-line fade.
- `audio.musicLayers({ name: path }, { volume, fade, persist, levels })` starts stems on the same audio sample (one lock,
  so no block of audio has only some of them) and `audio.setLayer(name, level, fade?)` fades them; the play log entries
  have a `layer` field. Layers loop, are never evicted by a full mixer, and `audio.stopMusic` stops all of them.
- `assets.synth_sound` levels every preset to about -18 LUFS (peak under -1 dBFS) instead of a -3 dBFS peak: squares, saws
  and noise were around -5 LUFS and tripped `factoria validate`'s loudness warning. The bytes of every seed change.

Steam from one Mac: optional plugin, exports, app 480, capsules

- The Steam plugin logs a warning, not an ERROR, when Valve's library is missing or Steam is not running. `project.new_plugin`
  (so `platform.add_backend`) now declares the plugin `"optional": true`; pass `optional: false` for a plugin the game needs.
- `project.export` takes `allowMissingPlugins` (`--allow-missing-plugins`): a plugin whose build for the target platform is
  missing is left out instead of stopping the export, a warning names it and the result lists it in `pluginsLeftOut`. It also
  works for a plugin that is not optional (the warning says scripts that call it fail). Plugins are still built only for the
  computer you build on: EXTENDING.md and EXPORTING.md say to take the other platforms' builds from CI.
- A desktop player with no build fingerprint (release 0.2.0 and older) now gets its own error: it predates fingerprints,
  `factoria setup players` installs the same one again, so use a newer player, `--player` or `--allow-player-mismatch`.
- `publish.steam` accepts app 480 (Spacewar) in a dry run with a warning; a real upload still refuses it.
- `assets.draw_capsules` takes `safeArea` (margins the logo stays inside, per store if needed; the Microsoft poster keeps its
  bottom third free by default) and `logoAnchor` (a name or a point of the safe area), and `focus` moves the logo when the key
  art already has the capsule's proportions. Misspelt keys get a "did you mean".

Video player

- A `Video` component draws an `.mpg` (MPEG-1 video with MP2 sound, decoded by pl_mpeg on the CPU, the same on every
  platform) in a UI rectangle: `fit` (`contain`, `cover`, `stretch`), `path`, `autoplay`, `loop`, `volume`, `bus`, `tint`.
  Time follows the game clock (it pauses with the game, headless runs and tests decode the same frames) and the sound plays
  through the mixer. Scripts use `entity.video`: `play`, `pause`, `stop`, `seek`, `time`, `duration`, `playing`, and
  `on("ended", fn)` (the game event `video.ended`).
- `assets.import` converts `.mp4`, `.m4v`, `.mov`, `.webm`, `.mkv` and `.avi` to an `.mpg` in `assets/video/` with ffmpeg
  (`factoria setup ffmpeg` installs one) and records where it came from; an `.mpg` is checked and copied. `factoria
  validate` reports a `Video` whose file is missing or that the engine cannot play, with the ffmpeg command that fixes it.
- `docs/MENUS.md` has a studio-intro recipe where any button skips the video. Clockwork Courier's intro is now a 4.8 second
  video of half a megabyte (FB-0051), recorded from an animated scene kept in `store/intro/`.
- Software renderers (llvmpipe, WARP) draw a full-screen video in about half the time: batches of plain textured quads
  (sprites, panels, a video) use a shader without the branches of glyphs, shapes and 2D lights, and a `Video` leaves out
  its background when the opaque picture covers it and draws an opaque picture without blending.

Steam Deck keyboard

- Plugin API 3: `add_text_input` registers a handler the engine calls when a `TextField` takes or loses the focus with a
  gamepad (the field's rectangle in window pixels, its text, `maxLength`), and `submit_text` hands text from the platform's
  keyboard back to that field on the next frame. Plugins built for version 1 or 2 are unaffected. `input.platformKeyboard`
  is true while a plugin's keyboard has the field, and the menu kit's on-screen keyboard stays closed then.
- The Steam plugin uses it: on a Steam Deck or in Big Picture it opens Steam's floating keyboard over the field, or the
  full-screen one where the floating one is not offered. Real-Deck check steps are in `docs/PLATFORM.md`.

Navigation: off-mesh links and walkable moving bodies

- `NavLink3D` (an entity's position to `end`, `bidirectional`, `cost`) is an off-mesh link: `nav.findPath` may take it to
  cross a gap, and the result's `links` lists `{point, entity}` where each link starts. A one-way link refuses the way
  back; a link whose end is off the mesh is ignored.
- `Collider3D.navWalkable` on a kinematic or jointed body (a rope bridge, a seesaw, a moving platform) leaves it out of
  the static bake and adds its top surface as walkable cells wherever it is now, joined to the ground within
  `stepHeight`; only the cells it left and entered are re-marked. `nav.info`, `nav.bake` and the editor's "Show navmesh"
  show links and these cells (`links`, `walkableBodies`). Clockwork Courier marks its bridges, seesaw and platforms, and
  `dog.js` needs one query instead of two (CC/FB-0056).

Physics across platforms

- The engine is built with no floating-point contraction (`-ffp-contract=off`, `/fp:precise`), and the simulation no longer
  calls the C library's `sin`/`cos`/`atan2`/`asin`/`acos` (each platform rounds their last bit differently): it uses
  deterministic versions built from `+ - * / sqrt` (`fa/core/det_math.h`), so physics is meant to give the same bits on
  Linux, Windows and macOS. CI prints a physics replay hash on those jobs and compares it with one committed value
  (`FA_PHYSICS_REPLAY_HASH`).
- `robust(check, { runs, nudge })` in `factoria:test` runs a check under small repeatable nudges of the bodies, so a level
  test asserts what is robust instead of an exact frame count. Clockwork Courier's "shortcut is not slower" test uses it
  (FB-0055).

Ads with consent on Android

- A plugin backend that offers only the `"ads"` service is an **ads backend**: it works next to the game's store backend, the
  engine sends `ads.*` to it and everything else to the store backend, `platform.ads.backend` picks one when a game has
  several, and `platform.state` shows `adsBackend` and `adsWhy`. Development runs and tests keep the fake.
- `platform.add_backend {"backend": "admob"}` writes and builds the `admob` plugin: Google's consent form (UMP) first, then
  the Mobile Ads SDK, one kept rewarded ad per placement, `{rewarded: true}` only from the SDK's reward callback. The
  app id is `platform.ads.appIds.android` in factoria.json, written into the manifest by the export; a development
  export always uses Google's test app id and test rewarded ad. `factoria validate` and a release export warn about the
  sample id, a missing app id or a placement without `ids.admob`. The command `admob.status` lists what is wrong.
- `platform.ads.audience` (`"general"`, `"children"`, `"mixed"`), `platform.ads.setUnderAge(bool)` and
  `platform.ads.privacyOptions()`; `platform.ads.consent()` gains `privacyOptions`. In a `"mixed"` game nothing is requested
  until the age is told. The menu kit has an `ageGate` part for it (`project.add_menu_kit {"parts": ["ageGate"]}`), and
  its options screen shows an "Ad privacy settings" button when Google requires one. The fake store answers all of it.

Ads with consent on iOS

- The `admob` plugin now has an iOS side, written in Swift: Google's consent form (UMP) first, then, only when
  `platform.ads.trackingPrompt` is true, Apple's "Allow tracking" sheet (never for a player under age), then the Mobile Ads
  SDK and the kept rewarded ad per placement. It behaves and answers like the Android one, including the audience,
  `setUnderAge`, `privacyOptions` and `admob.status`; `platform.ads.consent().tracking` is Apple's status when the game asks
  for the sheet. macOS has no AdMob SDK: the plugin offers no ads there and `platform.has("ads")` is false.
- Google's iOS SDK is a download, never in the repository: `platform.add_backend {"backend": "admob", "sdk": "<zip or folder>"}`
  copies its two XCFrameworks into the plugin (git ignores them) and builds the Swift side with Xcode.
- A plugin's `ios/plugin.json` can list vendored `xcframeworks` (the iOS export checks them, links the slice of the SDK and
  embeds a dynamic one) and `infoPlist` keys. The export writes `GADApplicationIdentifier` (`platform.ads.appIds.ios`; a
  development export always carries Google's iOS test app id), Google's `SKAdNetworkItems` and
  `NSUserTrackingUsageDescription` (`platform.ads.trackingDescription` or `trackingDescriptionKey`, translated per language of
  the game). A placement's iOS unit is `ids.admob_ios`. `factoria validate` and the export warn about the sample or missing
  iOS app id, a placement without `ids.admob_ios`, a tracking prompt with no ads plugin for iOS, and a tracking prompt with
  `export.ios.privacy.tracking` off.

Menu kit command

- `project.add_menu_kit {parts, overwrite}` (`factoria call project.add_menu_kit`) copies the menu kit of `docs/MENUS.md`
  into a game: main menu, options, credits, shop, pause, loading screen, on-screen keyboard and subtitles, each part with
  what it needs. It merges the kit's texts into the game's `locales/<language>.json` without replacing a key, leaves a
  file the game changed alone unless `overwrite` is true, and does nothing the second time. The kit lives in
  `templates/menus/`. The Controls tab of the options leaves out an action the game does not have.

Text entry on every device

- A focused `TextField` raises the phone's keyboard and hides it on blur (not for gamepad players). The menu kit in
  `docs/MENUS.md` has an on-screen keyboard for gamepad players (Latin, Cyrillic and Greek layouts; other scripts fall
  back to Latin). The web player takes typed text on mobile browsers through a hidden input, and the web smoke types
  into a field.

A 3D example game for phones

- Clockwork Courier (`examples/clockwork-courier`) is a complete 3D game made for phones first, the way your AI makes a
  game: a wind-up robot delivers parcels across six toy-town levels before its spring runs down, with touch controls
  (stick, buttons, drag to orbit, pinch to zoom), keyboard and gamepad, imported CC0 models and sounds, guard dogs,
  physics props, a studio intro and a loading screen, achievements, leaderboards, a paint shop, a "remove ads" purchase
  and a rewarded "more time" offer on the test store, comfort and accessibility options (left-handed layout, control size,
  reduced motion, assist mode, captions), English, Spanish and Japanese, and store texts, images and a trailer. Its
  `SHIPPING.md` says how each export was run (iOS Simulator, Android emulator, browser, macOS) and what is still done by
  hand.
- With this release's fixes, Clockwork Courier dropped the rest of its workarounds: the dog and tap-to-move walk on a
  `NavMesh3D`, the level panels are three shared prefabs, the name screen uses the menu kit's keyboard, the paints are
  per-material colours, the stars are ★ and ☆, and its tests reset their state with `game.resetState` and drive the
  mouse and the wheel. `ui.check_layout` finds no issue in it. Its studio intro is a video (FB-0051) and its dogs
  follow the courier across the rope bridges (FB-0056): no entry of its feedback is open.

A couch co-op example game for the desktop

- Burrow Brigade (`examples/burrow-brigade`) is a complete 2D game for one to four players on one screen, made for the
  desktop and Steam first, the way your AI makes a game: the miners dig down through mines generated from a seed (the
  same mine on every machine), in three strata with water, cave-ins and magma, gather ore, rescue moles and ride the lift
  up before their lamps burn out, while beetles, goblin thieves and the Mole King hunt them through the tunnels they dig.
  It has a join screen for four pads or a keyboard, per-player rebinding, a shared camera, revives, a pad unplugged
  mid-game, a camp with upgrades, three save slots whose format changed once (old saves are migrated), cloud copies, a
  daily dig and seed codes, achievements, stats and all-time and daily leaderboards on the test store, rich presence and
  Steam Deck checks, a news panel, remote balance values and opt-in analytics from its own server (a fake one in tests),
  music layers, ducking and captioned sound cues, display options, hold or toggle, a game speed for assist, English,
  Russian and Thai, and store texts, images and a trailer rebuilt by scripts. Its `SHIPPING.md` says how the Windows,
  Linux and macOS exports were made and what is still done by hand, and its `ENGINE_FEEDBACK.json` what it had to work
  around: those entries rank the next milestone.

Sliders and lists

- `Slider.format` shows the value as a pattern: `"{v:1}x"`, `"{percent}%"` (the value times 100); `Slider.formatKey` takes the
  pattern from a string table, so it can differ per language. `game.setSlider(id, value)` in a test drags a slider like a
  player: clamped, snapped to `step`, `ui.change` sent (the `ui.set_slider` command); writing `Slider.value` from a script
  still sends nothing. `ScrollList.shrink` makes a list as tall as its content up to the room the other children leave, so a
  short list in a `fit` panel makes a short panel.

Tests

- `factoria:test` can hold a mouse button and turn the wheel (`game.mouseDown`, `mouseUp`, `wheel`), so a drag orbit and a
  wheel zoom are tested through the input path. `game.resetState({ storage, platform })` clears the save data and the fake
  store between tests of one file, `game.setSystemLanguages([...])` sets what `i18n.systemLanguages` answers, and a quit
  request in a test (`game.quit()`, Back nobody consumes) sets `game.quitRequested` instead of stopping the run.
  SCRIPTING.md says `scene.load` from a test takes effect next frame while `game.load` is immediate. The hook warning
  skips a method that takes arguments, like `start(seconds)`.

Animation

- Models animated by node transforms play with no change to the file: a body part that is a child of an animated bone
  (RobotExpressive) and an animated mesh node with no skin at all (Kenney's cube pets) follow their node, through a
  rigid skin the importer makes. A file with clips that nothing can play logs one warning naming the clips.
- A glTF with several skins is drawn with each mesh's own skin (it used the first skin's palette for all, which bent the
  second skin's mesh out of shape). `Animator::skinPalettes` holds one palette per skin. Clockwork Courier imports the
  original robot and dog again and drops `tools/skinify.py` (FB-0001, FB-0002).

Graphics quality

- `window.renderScale` (0.5 to 1) draws the picture at a share of the window's size, in games and in tests;
  `window.supports("frameCap" | "renderScale" | "fullscreen" | "resize")` says what this run can do (the frame cap still
  throws on a phone: read it first); `game.device` gives `formFactor`, `gpuBackend`, `memoryGB` and a `tier` (`"low"`,
  `"medium"`, `"high"`) to pick a preset, with fixed values headless; tests pretend with `game.setDevice(...)`.
- `game.renderStats()` in tests (and the `game.render_stats` command) draws a frame when none was drawn yet and adds
  `shadowCasters` and `textureMB`. `perf.measure` records `triangles`, `lights` and `textureMB`; `perf.check` fails when
  they pass the baseline (only for baselines that have them) or the new `budgets` (`maxTriangles`, `maxLights`,
  `maxTextureMB`, `maxDrawCalls`, `maxEntities`).

Rendering

- `MeshRenderer.materialColors` colours one material of a glTF model: `{"Body": [0.2, 0.8, 0.7, 1]}` replaces the
  base colour factor of the material named "Body" on its sub-meshes (its texture still multiplies it), while
  `color` keeps tinting the whole model and the other materials keep their own colour. Entities that differ only in
  `materialColors` are drawn in separate batches. `factoria validate` checks the names against the model and suggests
  the right one for a typo (FB-0031).

Scripts

- `scene.preload(path)` and `assets.preload(paths)` read a scene's files (or a list of assets) ahead of time, a few per
  frame, and return a handle with `progress` (0..1), `done` and a `promise`: a loading screen keeps animating while the
  next level is read, and the `scene.load` that follows reads nothing from the disk. Tests do a fixed amount of work per
  frame, so they give the same result on every machine; `game.fileReads()` counts disk reads. Clockwork Courier's
  loading bar now shows real progress and its intro reads the title screen while it plays (FB-0012).
- A script stopped for running too long while inside `find`, `findIndex`, `findLast` or `findLastIndex` no longer
  crashes the game (a QuickJS bug freed one of the array's objects too early; the engine replaces those four). And a
  timer, tween or `world.on` listener stopped this way ends alone: before, every script after it was stopped too.

Platform services

- Ads: the new `platform.ads` service (`available(placement)`, `showRewarded(placement)` resolving `{rewarded, reason?}`
  and `consent()`) works with the placements of `factoria.json` `platform.ads.placements`, and `platform.release` is
  false in development runs, tests and the MCP server. The fake store answers with a scripted test ad (nothing is
  drawn): `game.platform.ad("watched" | "closedEarly" | "noFill" | "consentRefused")` chooses how it ends (command `platform.set_ad`). The real
  networks (Google UMP and AdMob, Apple ATT) are not in yet: the native backends answer `unavailable`.
- A leaderboard takes `period`: `"allTime"` (default), `"daily"` or `"weekly"`. The fake keeps one board per day or
  week of `game.today()`, so a daily board is empty again after `game.setDate` moves to the next day. The store backends
  map the period too (next bullet).
- Daily and weekly leaderboards on the stores. Steam keeps one board per period, named `<store name> <periodKey>`; Game
  Center uses a recurring leaderboard of App Store Connect as it is, at its current occurrence, or reads a classic board
  with the `.today` / `.week` time scope; Play Games reads the `TIME_SPAN_DAILY` / `TIME_SPAN_WEEKLY` table. These backends
  no longer reject periods with `unavailable`. Each store starts a period at its own time (table in docs/PLATFORM.md,
  "Leaderboard periods"); `submit` and `entries` carry `periodStart` and `periodEnd` when the store says them (Game Center's
  recurring boards), on `entries` as properties of the array (FB-0030).
- Clockwork Courier uses them instead of its ad stub and its single daily board (FB-0028, FB-0030).
- The fake store can take a purchase back, as a refund does: `game.platform.revoke(productId)` in tests (command
  `platform.revoke`) removes it from `restore()` and sends the `purchase` event with `status: "revoked"`.
- `platform.purchases.finish()` of a transaction the game was not told about now rejects its Promise with code
  `unknownId` (it used to throw at the call), so `.catch()` handles it like any store failure.
- Leaderboards in factoria.json take a `nameKey` (a locale key) instead of `name`, like achievements; the request
  the backend gets carries the name in the current language. PLATFORM.md documents `game.project.platform`, the
  catalog scripts can read.

Localization

- Numbers and times follow the language: `{v:number:1}` and `{t:duration}` in a string table and `i18n.number(v, {decimals})`
  and `i18n.duration(seconds)` in scripts write 1234.5 as "1,234.5", "1234,5" (Spanish; "12.345,5" from five digits),
  "1.234,5" (German), "1 234,5" (French, narrow no-break space) or "١٬٢٣٤٫٥" (Arabic digits), and 83.4 seconds as "1:23.4".
  A small table in the engine, no ICU; a language it does not know is written like English (docs/LOCALIZATION.md).
  Clockwork Courier uses it instead of its own helper (FB-0039).
- `keyArgs` on `Text`, `Button`, `Toggle`, `Slider`, `TextField` and `TouchButton`: the values of a key's `{placeholders}`
  (and the `count` of a plural entry), so a script sets them once instead of rewriting `text` every frame, and a language
  switch keeps them. `TouchButton` has a localization `key` like the other widgets. `factoria validate` checks a key's
  placeholders against the entity's `keyArgs`: it warns for a placeholder with no arg and for an arg no translation uses,
  not for every key with placeholders.
- `ui.check_layout {scenes, languages, textScales, pseudo}` loads each screen with UI in each language and text size
  (default: every language, scales 1 and 2) plus a pseudo-localized pass that lengthens every string by 40 %, and lists
  every text that overflows its box (the `ui.overflowed` test), overlaps another or leaves the screen, with the scene,
  the entity and its path, the key and the languages and scales where it happens. Clockwork Courier's profile keys and
  intro texts that broke at 200 % now shrink (FB-0043).

Tools

- `scene.format` with neither `paths`, `all` nor `check` writes nothing and fails with `paths_required`, saying how many
  scene and prefab files would change and the first ones; `paths` names the files or folders to format and
  `"all": true` takes the whole project. `factoria validate`'s hint names the files.
- `project.new_plugin` and `platform.add_backend` take `dryRun` (they list the `files` and the `keys` of
  `factoria.json` they would write, and write nothing) and refuse an argument they do not know, with a "did you mean".
- They patch `factoria.json` instead of rewriting it: only `plugins.<name>` is added, and the other keys, their order
  and the layout stay as they were. `export` and `icon` saves (the editor, `assets.draw_icon`) use the same patcher.
- The plugin templates come with a `.gitignore` for their build output.
- `factoria api --dts` lists a native plugin that is not built without its load error, so the typings no longer
  carry this machine's folders and come out the same on every machine.

Exports and store files

- `Products.storekit` is written by every iOS export whose catalog has products, with or without the Apple plugin, and
  holds one localization per language of the game (names and descriptions from the products' `titleKey` /
  `descriptionKey` in `locales/`).
- An Android source build reads the CMake version it will use instead of requiring `cmake;3.31.6`: the SDK's, else the
  newest 3.24+ in the SDK, else a 3.24+ of the computer (passed to Gradle as `cmake.dir`), so it works offline. The error
  hint says how to get one.
- `factoria` and `factoria_player` carry a build fingerprint (the commit, `-dirty` when it had uncommitted changes;
  `factoria version` prints it). A desktop export with a player from another build stops with an error that names both
  builds; `--allow-player-mismatch` (the `export` command's `allowPlayerMismatch`) bundles it anyway.
- `setup.install {"component": "ffmpeg"}` (`factoria setup ffmpeg`) downloads a pinned static ffmpeg, so
  `factoria run --record-video trailer.mp4` works without installing it by hand; `setup.status` lists the component.

Assets

- `assets.import` of a `.glb` or `.gltf` copies the textures and buffers its `uri`s point at next to the model (with
  provenance), shares an identical file already there, warns when the destination holds a different image of the same
  name (kits that ship different `colormap.png` files) and stops on a different buffer; `factoria validate` reports a
  model whose texture or buffer file is missing.
- `assets.set_provenance` (and every command that edits `assets.json`) keeps the order of a hand-ordered file instead of
  sorting all of it; a sorted file stays sorted.
- `factoria validate`'s loudness warnings use the sound as it plays: a project with `defaults.audio.normalize` has no
  peak or loudness warning left for it.
- New `assets.synth_sound {path, preset, seed}` makes barks, growls, meows and the usual effects (coin, jump, hit,
  explosion, laser...) offline as a deterministic WAV, with its provenance; no provider and no key.

Physics

- 3D physics no longer depends on what the World held before a scene loaded: `Joint3D` constraints are solved in the
  scene's entity order instead of the order of their entity ids, so a rope bridge or a seesaw behaves the same after
  other scenes, destroyed entities or reused entity slots (a level test could take 2000 or 2800 frames depending on
  which tests ran first).
- `CharacterController3D` on moving and dynamic bodies: a kinematic platform it stands on carries it (displacement, and the
  turn of a spinning platform; `carriedByPlatforms`, default true), it presses on the dynamic body below with
  `mass` x gravity (`applyWeight`, `mass`), so a seesaw tips and a bridge plank sags, and `pushStrength` scales the push on
  the free dynamic bodies it walks into (a body held by a `Joint3D` is never shoved). Clockwork Courier dropped its
  workarounds (FB-0010, FB-0011).
- A dynamic body that starts inside a static collider is reported once in the log (both entities, the depth and the fix),
  and `factoria validate` warns about it for scenes.
- Joints form islands: a chain of planks falls asleep when it is at rest, a collision in one island no longer stops the
  rest of the world, and two bridges side by side move exactly as each would alone. Chains of three or more jointed
  bodies get more solver iterations and settle by themselves, so a rope bridge no longer needs heavy damping
  (FB-0014, FB-0015, FB-0017, FB-0053, FB-0054).
- `Joint3D.damping` (friction on the relative turning) and `Joint3D.stalled` (read only: a motor pushes and the joint
  cannot turn, for example a gate against a wall). `docs/AI_GUIDE.md` has a rope bridge recipe.
- `connected: ""` means the world on `Joint3D` and `Joint2D` in scenes, `factoria validate` and scripts.

Navigation

- Path finding for 3D characters. A `NavMesh3D` component (`size`, `cellSize`, `agentRadius`, `agentHeight`,
  `stepHeight`, `maxSlope`) is baked by itself from the static colliders inside its box into a walkable grid;
  `nav.findPath(from, to, { radius })` in scripts and `nav.find_path` return the few corner points of a path around
  walls and up ramps, never up a step above `stepHeight`. A start or goal off the walkable ground, or in another
  area, comes back as a result that says how far the nearest walkable point is and how to fix it; a `radius` bigger
  than the mesh was baked for is an error that says to bake for the bigger agent. `nav.bake` and `nav.info` report the
  cells and areas (no timing: two bakes are identical). A collider with `navObstacle` is left out of the bake and blocks
  the cells it covers each time it moves (a gate, a crate). The editor draws the walkable cells (Window > Show navmesh).
  Guide: docs/NAVIGATION.md (FB-0009).

Native plugins

- `"optional": true` on a plugin in `factoria.json` says the game runs without it: when its build for your computer is
  missing (a store SDK only some developers build), `factoria validate` warns instead of failing. Exporting for a
  platform still needs that platform's build.

Mac App Store

- `sign.macos` takes `distribution: "appStore"`: it signs the macOS export with the App Sandbox, an Apple Distribution
  certificate and a provisioning profile, and builds the signed installer `<game-slug>-macos.pkg` with `productbuild`.
  `identity: "-"` signs ad hoc so you can run the sandboxed game on your own Mac.
- `publish.appstore` uploads that `.pkg` too (`platforms: ["macos"]`).
- New `export.macos` settings: `buildNumber`, `usesNonExemptEncryption` and `entitlements`.

Microsoft Store

- `factoria export --platform windows --format msix` (or `export.windows.format: "msix"`) writes
  `<slug>-windows.msix` next to the Windows folder, from any computer: the unsigned package the Microsoft Store takes, with
  the manifest, the logos cut from your icon and the block map. The identity comes from the new `export.windows.msix`
  settings (the editor's Windows tab and Export window have them).
- New `sign.windows` signs the package with your `.pfx` (`signtool`, or `osslsigncode` on macOS and Linux) to install it on
  a PC; on Windows `testCertificate` makes a self-signed one. The password is only read from the environment.
- New `publish.microsoft` uploads the package with the Microsoft Store Developer CLI.
- The web export and the AppImage use a shared zip writer; their bytes did not change in meaning.

Scripting

- New `game.today()` returns `{ year, month, day, weekday, utcOffsetMinutes, iso }`: the player's real local date in a
  built game, the fixed date `2026-01-01` in `factoria test` and headless runs, and the date a replay recorded when it
  plays (an old replay without one uses the fixed date). `game.setDate("YYYY-MM-DD")` in `factoria:test` changes it, and
  `--date` does the same for `run`, `screenshot`, `test`, `call`, `session` and `mcp`. An impossible date (`2026-02-29`)
  or another format is an error that says what is wrong. Read the date with `game.today()`, never `Date`.
- New `game.on("suspend" | "resume" | "focus" | "blur", fn)` and `game.focused` tell scripts when the app goes to the
  background and back, or the window loses the focus. The new `factoria.json` setting `pauseOnSuspend` (default `true`)
  pauses the game and the music while the app is in the background; `game.suspend()`, `game.resume()`, `game.focus()`
  and `game.blur()` in `factoria:test` test it. A pause menu opened by a `suspend` handler stays after resume.
- Clockwork Courier uses the date and the lifecycle API instead of its workarounds (FB-0019, FB-0035).
- `factoria test` no longer stops a test file after 600 s in all: only a single test over 60 s is stopped, so a long file
  of quick tests passes in a Debug build on a busy machine. The message says which limit it was.

UI

- A child can be put at a place among its siblings, which is the order a `column` or `row` layout follows:
  `scene.set_parent {id, parent, index}` (also `scene.spawn {index}`), `entity.setParent(parent, keepWorld, index)` and
  `world.spawn(json, { parent, index })` / `world.spawnPrefab(path, { parent, index })`. 0 is first; an index outside
  0..(number of the parent's other children) is an error that says the range. The order is saved with the scene.
- One panel can serve several scenes: a prefab reference takes `overrides`, a map from a child of the prefab (its id,
  name or a path like `"Panel/Title"`) to the `name`, `tags`, `active` and `components` to change, and
  `world.spawnPrefab(path, { childOverrides })` and `scene.spawn {prefab, overrides}` do the same. A child or field that
  does not exist is an error with a "did you mean". docs/MENUS.md shows it. Clockwork Courier's FB-0032 and FB-0023.
- Text that fits: `autoShrink` (with `minFontSize`, default 10) on `Text`, `Button`, `Toggle`, `Slider` and `TouchButton`
  shrinks the font until the text fits its box (`Text.maxWidth` x the new `Text.maxHeight`, or the room the widget leaves
  its label), never under `minFontSize` times `ui.textScale`. `maxTextScale` on `Text`, every widget and `TouchButton`
  stops `ui.textScale` from growing that text past a scale (a heading at 1.3). `Toggle.maxWidth` and `Slider.maxWidth`
  wrap long labels, `Slider.labelAbove` puts the label above the track. Layout, `autoSize`, `ui.measureText` (new
  options, returns `fontSize` too), `ui.rectOf` and the 2D and 3D renderers use the same size.
- New `ui.overflowed(idOrEntity)` and `"overflowed": true` in `ui.state` say a text still does not fit its box.
- Clockwork Courier dropped its text-fit workarounds in the level select, HUD, toasts and options (FB-0041, FB-0042).

## 0.2.0

FactorIA 0.2.0 is about finishing and shipping a game: edit scenes by hand next to your AI, translate the game, add
achievements and purchases on Steam, the App Store and Google Play, and export it for desktop stores, phones and the
browser.

Edit by hand in the editor

- The editor has a Hierarchy and an Inspector now. The Hierarchy lists every entity as a tree: click one to select it (a
  click in the game view selects it there too), drag it onto another to make it a child, drop it on the empty space to
  make it a top-level entity, and right-click for create child, duplicate, rename, active and delete. There is a search box.
- The Inspector shows the selected entity's components with a field for every value: tick boxes, number drags that
  respect each field's range, vectors, colour pickers, drop-downs for choices and for other entities, file pickers for
  pictures, sounds and materials, and a text box for free-form JSON. Hover a name to read what it does. Add Component and
  the x on a component's header add and remove components.
- Everything you change by hand goes through the same commands the AI uses, so Undo works (one drag is one step) and a
  value a field does not accept is refused with the reason. While the game plays you can edit the running game; Stop
  takes those edits back.
- A `MeshRenderer` shows its material's settings with the right widgets (sliders, vectors, colour pickers) and a Reset
  button for each, and a material that does not compile shows its error right under the material field.
- The new Project panel (a tab next to Console, also in the View menu) lists the project's files with thumbnails, a folder
  tree, a type filter and a search box. Drag a picture, sound, font, mesh, script or material onto an Inspector field of that
  type to set it, drag a prefab onto the game view to spawn it where you drop it, double-click a scene to open it, and
  right-click a file to show it in the file manager, copy its path or delete it. `assets.list` now also reports `material`
  for `.material.json` files.
- New command `scene.set_parent` moves an entity under another one (or to the top level), for the AI too.
- Move, rotate and scale in the game view: select something and drag the arrows (W), the rings (E) or the handles (R) that
  appear on it; Q goes back to just selecting. The four buttons next to Undo do the same. Hold Ctrl to snap, press Esc in
  the middle of a drag to cancel it. A whole drag is one Undo step, it works for 2D and 3D, for things on the screen (like
  a score) and for things inside another, and while the game is paused it edits the running game.

Revert an AI run

- Before each AI run the editor now saves a checkpoint of the project's files. When the run changed something, the chat
  shows "This run changed N files" with a Revert button: one click (after a confirmation) puts back every file, deletes the
  ones the run created and puts the scene back as one Undo step. Undo revert takes it back, and Edit > Revert Last AI Run
  does the same from the menu. The AI is told about the revert in your next message. Checkpoints are kept in
  `.factoria/checkpoints/` (newest 30) and are also available as the commands `checkpoint.create`, `checkpoint.list`,
  `checkpoint.diff` and `checkpoint.restore`.

Debug your scripts in VS Code

- Press F5 in VS Code on a FactorIA project: the game starts and stops on your breakpoints. Step through your code line
  by line, look at every variable and at `this`, watch expressions, and type JavaScript in the debug console to read or
  change the running game. `factoria setup vscode` (or Install in the editor's Setup window) adds the extension to VS
  Code, and to Insiders, VSCodium and Cursor when you have them; new projects come with a `.vscode/launch.json`.
- Breakpoints can have a condition, a hit count or a message to print instead of stopping (a logpoint, with
  `{expressions}` filled in). The debugger can stop on every error your scripts throw or only on the ones nothing
  catches, and Pause stops the game wherever it is, even in an endless loop.
- Three ways to start: play the game in its window, run it without a window for a number of frames (with an input
  replay), or run your tests and stop inside them.
- For the AI: `script.trace` puts the same breakpoints on a headless run and returns what it saw as JSON (the call stack,
  the local variables and your watch expressions at each hit, and the logpoint lines), so it can find out why a script
  misbehaves without guessing. See `factoria docs read debugging`.
- Exported games cannot be debugged: debug the project.

Find out what makes your game slow

- A profiler: it tells you where the time of a frame goes, per part of the engine (physics, scripts, sound, drawing...) and
  per script class, with the milliseconds each class takes per frame and how often it runs, plus the GPU time (on
  Windows and Linux; other systems say why not) and memory use. It only measures: your game plays exactly the same.
- In the editor, View > Profiler shows it live while you play. Every play session you record now also keeps this
  summary in `play.report`, so the AI can see which script is the slow one.
- `perf.profile` does the same on a headless run, with an optional input replay to reach the heavy part of the game. See
  `factoria docs read performance`.

Your game in every language

- Keep your texts in string tables (`locales/en.json`, `locales/es.json`...) and show them with a `key` on a `Text` or an
  interface widget, or with `i18n.t("score", { points: 3 })` in scripts: placeholders, plural forms for each language and
  a fallback language are built in. The game starts in the player's system language, and `i18n.setLanguage("es")`
  switches at any moment, every text at once.
- Text is laid out properly in every script: Arabic letters join and right-to-left lines start from the right, Chinese,
  Japanese and Korean lines break between characters, and fallback fonts (`fallbackFonts` for the whole game,
  `languageFonts` per language, in the `localization` part of `factoria.json`) fill in the characters your main font
  does not have.
- A text size option for players: `ui.textScale` makes every on-screen text and widget label bigger or smaller.
- `factoria validate` finds missing and leftover keys (with "did you mean"), wrong placeholders and plural forms, and
  any character none of your fonts can draw, naming the text and the file.
- Send your texts to translators as a spreadsheet (CSV) or an XLIFF file with the command `i18n.export`, and bring the
  translations back with `i18n.import`.
- `factoria docs read localization` is the guide, and the ready-made menus have a Language option.

Achievements, leaderboards, cloud saves and purchases

- One script API for what a store gives a game: `platform` has achievements, stats, leaderboards, cloud saves, in-game
  purchases (with restore), the store's overlay and rich presence. You write your game once, and the store it runs in
  answers. List your achievements, leaderboards and products in the `platform` part of `factoria.json`.
- Steam, Apple (App Store purchases, Game Center, iCloud) and Google Play (Play Billing, Play Games, Play Integrity):
  `factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`, `"googleplay"`) sets one up in one step and
  lists what is left for you to do in the store's dashboard.
- While you make the game, and in every test, a pretend store answers, so your AI can test a purchase, a cancelled one
  or an achievement without a store account. An exported game with no store set up never gives purchases away.
- `platform.integrity.token` gives your game's server a signed token that vouches for the app and the device (Google
  Play).
- So far these were tried against simulated stores only: make a test purchase with the store's sandbox or test account
  before you release. `factoria docs read platform` is the guide.

Ready for the desktop stores

- `factoria export --release` on Windows, macOS and Linux puts the whole game in one file, `game.pak`, with the scripts
  compiled to bytecode. Exports no longer copy the project's top-level `README.md`.
- When an exported game crashes it writes a report (what happened, where in the code, the last lines of the log) in a
  `crashes` folder next to `log.txt`, plus a minidump on Windows. Nothing is sent anywhere: a player can send it to you.
- Upload your game to Steam (`publish.steam`, with steamcmd), itch.io (`publish.itch`, with butler), the Epic Games
  Store (`publish.epic`, with BuildPatchTool) and GOG (`publish.gog`, with Galaxy Pipeline Builder) from your AI or the
  command line, each with a dry run to try first. Passwords and keys stay in environment variables or your user
  folder, never in the project.
- macOS: `factoria call sign.macos` signs your exported app with your Developer ID, has Apple notarize it and staples
  the ticket, so players can open it without a warning.
- Linux: `factoria export --platform linux --format appimage` makes the game one AppImage file with its icon and menu
  entry. Linux games exported from the FactorIA download now run on older systems and in the Steam Linux Runtime (glibc
  2.31 or newer).
- `factoria call project.new_ci_workflow` writes a GitHub Actions workflow that validates, tests and exports your game on
  every push.

Phones and tablets

- Change to know about: `factoria export --platform android --release` now stops when your game has no signing key,
  because Google Play rejects an app signed with the debug key. The message tells you how to make a key. To try a release
  build on your own phone anyway, add `--allow-debug-key` (the export command's `allowDebugKey` option).
- Menus and heads-up displays can keep clear of the notch, rounded corners and system bars: switch on `safeArea` next to
  `anchor` on a sprite, text, shape, particle emitter or interface widget, and it is placed against the free part of the
  screen. Scripts can read it as `screen.safeArea`. You can try a notched phone without one with
  `screen.set_safe_area {"profile":"phone-portrait"}`.
- The Android Back button and gesture now reach your game as `input.onBack`: close a menu or go up one screen and the game
  stays open. If nothing handles it the game closes, as before.
- `input.vibrate()` makes a phone vibrate (a light tap on iPhones). Exported Android games include the permission for it.
- Android games can raise the on-screen keyboard for text fields and receive what is typed. Keyboards that compose words
  (predictive text, swipe typing, emoji, Asian languages) still cannot type into an Android game; physical keyboards work.
- An on-screen gamepad for games made for a controller: add a `TouchStick` and a few `TouchButton`s to a scene and players
  move with the thumb and press A, B... on the screen. They press the same gamepad buttons and stick a real controller
  does, so your game needs no other change. Several fingers work at once, the controls stay clear of the notch, and they
  only show while the player is using touch (they hide when a real controller or keyboard is used).
- Tests can press Back, fake a notch, check vibrations and touch the on-screen gamepad without a device.
- iPhone and iPad exports include the privacy file the App Store asks for (`PrivacyInfo.xcprivacy`), listing the few
  system features FactorIA uses and saying that nothing is collected or tracked. If your game or a plugin collects data,
  tracks players or uses more system features, add them under `export.ios.privacy` in `factoria.json`; mistakes in it are
  reported with the fix. The app also says it uses no special encryption, so App Store Connect stops asking at every
  upload (`export.ios.usesNonExemptEncryption` changes it).
- `factoria setup players --platforms mobile` now also downloads the iPhone and iPad libraries on Windows and Linux, so
  you can prepare an iOS project there without pointing at a macOS download. Building it still needs a Mac.
- The mobile guide lists what to answer in Google Play's Data safety form and in App Store Connect's App Privacy section.

Upload your phone builds

- Upload your iOS build to TestFlight and App Store Connect from your AI or the command line (`publish.appstore`,
  on a Mac): you archive the game in Xcode as before, FactorIA sends the `.ipa` with an App Store Connect API key. Run it
  with `dryRun` first to see the exact command.
- Upload your Android release bundle to Google Play (`publish.googleplay`, needs fastlane): pick the track (internal
  testing by default), leave the release as a draft or roll it out, and send the "What's new" text per language from
  files of your project. A bundle signed with the debug key is refused before anything is sent. Google Play still wants the
  first bundle of a new app uploaded by hand.
- Your keys stay in files outside the project and are never shown or logged.

Games in the browser

- Export your game for the web: `factoria export --platform web` (or Web in the editor's Export window) makes a folder
  with an `index.html` that plays the game in any modern browser, and a `.zip` of it ready to upload to itch.io as an
  HTML5 game. The page shows a loading bar and explains in plain words when something is wrong (an old browser, a
  download that failed).
- In the browser, saves made with `storage` are kept between visits, sound starts with the player's first click or key,
  and gamepads work. Native plugins and store services (achievements, purchases) are not available on the web.
- The web player comes with every FactorIA download; `factoria setup players --platforms web` installs it if you need it.

Better looking 3D, and much bigger 3D scenes

- Materials look like real materials: `metallic` and `roughness` now use physically based shading, and shiny surfaces
  reflect the sky of your scene (`skyColor` and `horizonColor`), so a metal sphere looks like metal without any extra
  file. Scenes you already have look close to before, with a faint sheen on plastic and stone.
- Normal maps: give a `MeshRenderer` a `normalMap` picture to add bumps, scratches or bricks without extra triangles, and
  `normalScale` to make them stronger or softer.
- glTF models keep their materials: metallic and roughness (with their textures), normal maps, ambient occlusion and
  glowing parts are read from the file. Models without tangents get them generated.
- Big scenes are cheaper: anything outside the camera's view is skipped, and many copies of the same mesh with the same
  material are drawn together. Ten thousand identical cubes now cost one draw.
- Up to 32 lights at once instead of 8. With more, the engine keeps the sun and the brightest, nearest lights.
- The render statistics (`play.report`) now also count `meshesCulled`, `meshBatches` and `lightsDropped`.
- Your own shaders: a `MeshRenderer` can use a material file (`material`) with a few lines of GLSL that change how the
  surface looks (a pulsing glow, cut-out leaves, moving water) or move its vertices. Shadows follow the moved or cut-out
  shape, each entity can change the material's values (`materialParams`), and a change to the file shows up at once
  while the game runs. A material that does not compile draws magenta and says which line is wrong.
- A new guide for your own shaders (`factoria docs read shaders`): how to write a material, the rules for its few lines
  of GLSL, and five ready examples: a pulsing glow, dissolving, water, wind on grass and a rim light. The shader
  compiler comes with FactorIA, next to `factoria` in every download, so there is nothing to install. If Windows
  Defender removes `sokol-shdc.exe` by mistake, restore it from Windows Security > Protection history, or run
  `factoria setup shaders` to get it again.
- In the editor, saving a material, a shader or a texture updates the game view right away, while editing and while
  playing. A mistake in a shader keeps the last picture that worked and shows one error in the Console with the file
  and the line.
- The Gem Roller example has glowing, pulsing gems made with a custom material.
- Not yet: an environment picture for reflections.

Animation

- 3D models with skeletons: a glTF/GLB with named animation clips plays through the new `Animator` component, which goes on
  the entity with the model's `MeshRenderer`. Switch clips with a smooth cross-fade (`entity.animator.play("Run", 0.2)`),
  change the speed, and get an event when a clip reaches a moment you chose (a footstep at 0.3 s) with `world.on`.
- A small state machine is built in: list the parameters, the states (a clip each) and the transitions in the scene file
  (`"when": "speed > 0.1"`), then your script only sets values: `entity.animator.set("speed", 3)`. Animation runs in the
  fixed step, so tests and replays give the same result every time.
- New `tween` and `ease` in the scripting API: slide a menu in, fade a sprite, grow a pickup. Works on numbers, vectors
  and colors of anything, in 2D and 3D, with 30 easings (`"backOut"`, `"bounceOut"`...), delay, repeat, yoyo, chaining and
  `await tween(...).finished`.
- Animated models are drawn deformed by the animation, shadows included (up to 64 joints per model; a model with more
  is drawn in its bind pose and a warning says so). The new guide is `factoria docs read animation`.

3D physics: new shapes, joints and a character controller

- 3D colliders can now be capsules (`shape: "capsule"` with `radius` and `height`), convex shapes (`"convex"`, the
  smallest solid that wraps a model) and triangle meshes (`"mesh"`, the exact surface of a model, for terrain, ramps and
  level geometry). For the last two, set `Collider3D.mesh` to a primitive name or to your `.glb`/`.gltf` file, usually
  the same as the entity's `MeshRenderer.mesh`. All shapes collide with each other, and raycasts, shape casts, triggers,
  sleeping and the physics debug view work with all of them.
- A mesh collider is for things that never move. Put it on a body that moves and the engine tells you once, in plain
  words, to use a convex collider or several boxes and capsules instead.
- Joints: add a `Joint3D` to an entity that has a body to make a hinge (doors, pendulums, wheels, with optional angle
  limits and a motor), a ball joint (chains, shoulders) or a fixed joint, hanging from the world or from another body.
  A swinging pendulum keeps its real period.
- Character controller: add `CharacterController3D` to an entity and call `physics.moveCharacter(entity, delta)` each
  frame. It slides along walls, steps up stairs and kerbs (`stepOffset`), refuses slopes steeper than `slopeLimit`, stays
  on the ground going down a ramp, pushes crates, and tells you if it is on the ground (`isGrounded`, `groundNormal`).
  You add your own gravity and jump.
- Limits for now: a model with more than 256 vertices used as a convex collider is simplified to 256 points, jointed
  bodies never fall asleep, and the character is not carried by moving platforms.

More for 2D games

- Flipped and rotated tiles: a tile number can carry a flip or turn, so one picture serves four directions. In
  `scene.import_ascii` a legend entry accepts `flipX`, `flipY` and `rotate` (0, 90, 180, 270). Collision follows the
  plain tile number.
- 9-slice sprites: give a `Sprite` a `slice` (left, top, right, bottom in pixels of the picture) and it stretches like a
  button background, corners intact. It works with flips and with pictures packed in an atlas.
- 2D lights: a `Light2D` entity (point or directional) lights the sprites and tilemaps that set `lit`. Add a
  `normalMap` and the sprite shows bumps that react to the light. `SceneSettings.ambientLight` is the unlit brightness.
  Up to 16 lights at once; the nearest to the camera win.
- Parallax: a `Parallax` component makes a far background move slower than the camera (or faster, for foreground), and
  a sprite can repeat endlessly with `repeatX` / `repeatY`.
- Joints: a `Joint2D` on a body ties it to the world or another body as a hinge (revolute), rope (distance), slider
  (prismatic) or glue (weld), with limits, motors and springs. Scripts can read the reaction force and switch a motor.

Accessibility, speed checks and legal texts

- Colour filters for players: `colorFilter` on the `Camera` turns the whole picture greyscale, raises the contrast, or
  corrects the colours for players who cannot tell red from green (`protanopia`, `deuteranopia`) or blue from yellow
  (`tritanopia`). Your options screen sets it from the player's choice.
- See your game as a colour-blind player does: `factoria run --headless --screenshot-at 60 --screenshot-simulate
  deuteranopia` (or `simulate` in `game.screenshot`) saves the screenshot that way without changing the game, so you or
  your AI can check that hazards still stand out.
- Read menus aloud: `ui.speak(text)` says a line with the computer's or phone's own voice, in the game's language, and
  `ui.speechAvailable` tells whether the system can speak. Speak the button that has the focus and players who cannot
  read the screen can use your menus. Tests check what would be said with `game.spoken()`, without sound.
- Start from the player's own settings: `game.accessibility` tells you the text size the player set on their system,
  and whether they asked for less motion, high contrast or use a screen reader. Use it to set your options on the first
  run; what the player then chooses in your game wins.
- Subtitles: add a `Captions` entity to your scene, then `audio.play("voice.wav", { caption: "Watch out!" })` shows the
  line while the sound plays, and `ui.caption(text)` shows one with no sound. They follow the text size and the player's
  language, and an option can turn them off. Tests list them with `game.captions()`.
- `factoria docs read menus` shows each of these as an option of the ready-made menus, and the accessibility part of
  `factoria docs read finishing` lists them all.
- Speed and memory checks: `factoria call perf.baseline` measures how much CPU time and memory your game uses and how
  many things it draws, and saves it in `perf.json`. `factoria call perf.check` then fails when the game got much
  heavier, so you notice before your players do. `factoria docs read performance` explains how to use it in your own
  checks.
- Privacy policy and license: `factoria docs read legal` says what FactorIA sends from your game (nothing by itself),
  gives a privacy policy you can copy for a game that collects nothing, the paragraphs to add when you use analytics,
  ads, accounts or cloud saves, and when you need a license agreement of your own. It is not legal advice.

Guides for finishing and publishing

- `factoria docs read finishing` takes a game that plays to a game a store accepts, step by step with Lantern Keep's
  code: menus, options that stay set, saves that survive updates, languages, accessibility, credits and tests.
- `factoria docs read publishing` has one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App
  Store, itch.io, your own site): what FactorIA does for you and what you still do by hand, with fees and review times.
- Store images and trailers: `assets.draw_capsules` makes every picture a store page asks for (Steam capsules, Epic,
  GOG, Microsoft Store, Google Play, App Store screenshots, the itch.io cover) from one picture of your game and your
  logo or title. `factoria run --headless --input replay.json --record-video trailer.avi` records a trailer from an
  input replay, with sound; ask for `trailer.mp4` when ffmpeg is installed.

A complete example game

- Lantern Keep (`examples/lantern-keep`) is a small but complete 2D platformer, made the way your AI makes a game: six
  levels, menus, three save slots with a level select and cloud saves, achievements, leaderboards and a shop of cosmetics
  on the test store, accessibility options (text size, a slower game, invincibility, no screen shake), four languages
  including Arabic, an on-screen gamepad for phones and export settings ready for the stores. Read it, copy from it, or
  point your AI at it. Its `SHIPPING.md` lists what each store needs and what is still done by hand.

Learn FactorIA

- Two tutorials for people. `factoria docs read first-game-with-ai` makes your first game with the editor and an AI in
  six rounds, starting from the 2D platformer template: what to type, what to look for and how to undo.
  `factoria docs read make-by-hand` builds a small game by hand from the empty template (collect four gems, then a "You
  win!" screen), one whole file at a time, with a check after each step.
- What a game costs to make with AI: `factoria docs read ai-costs` shows what a complete game cost in a real run, what
  makes a run cheap or expensive, how to set a spending limit and where to see what you spent.
- A browsable API reference in the FactorIA repository: `docs/reference/` has an index of every component and command,
  one page per category, and the version that added each one.
- Searching the docs (`factoria docs search`, and your AI over MCP) shows the best section of each guide first, so a
  name like `onTriggerEnter` finds the scripting reference instead of many sections of one tutorial.

Fixed while making Lantern Keep

Lantern Keep showed what a complete game still had to work around. These are now in the engine, so your AI writes less
code of its own:

- Menus fit their texts: `autoSize` on `Button`, `Toggle` and `Slider` grows the widget to its label at a big text
  size or in a longer language. A button label with several lines is centred line by line, `maxWidth` wraps it, and a
  label that still does not fit is cut at the button's edge. `ScrollList.fill` lets a list take the height the rest of a
  column leaves, and a fitted panel bigger than the screen logs a warning naming it.
- Scripts can apply the layout right away: `ui.layout()` sizes and places the widgets at once, so a script that changes
  a text can read the real sizes (`Button.size`, `Panel.size`, `ui.rectOf`) straight after, without waiting for the next
  frame.
- Panels that do not fit: `fallbackLayout` (row, column or grid) is used instead of `layout` when the panel would leave
  the screen, for example a column that becomes a row at a big text size. `uniformSize` makes the `autoSize` buttons,
  toggles and sliders in a panel all as wide as the widest one and as tall as the tallest one.
- Right-to-left languages: a `Text` with `align: "start"` or `"end"` follows the language's direction, and a panel with
  `direction: "auto"` lays out its rows right to left in Arabic or Hebrew. Scripts read `i18n.direction`.
- Panels: a script hook `onEnable()` runs every time an entity is shown and `onDisable()` every time it is hidden, before
  the frame is drawn, so a panel never shows its placeholder texts for a frame. A hidden panel already has its
  `.behaviour`.
- Focus with a gamepad or the keyboard goes to the widget you expect in the direction you press, and a greyed-out
  `autoFocus` button no longer keeps the focus.
- 2D: a moving platform carries the bodies standing on it, also when the player's script sets its speed every frame
  (that speed is now relative to the platform; drop any carry code of your own). `Shape2D.lit` lets the placeholder
  shapes be lit by `Light2D`.
- ASCII levels: `scene.import_ascii` keeps prefabs as references, so editing a prefab changes every level without
  importing the maps again, and level files stay small. Several maps can share one legend file (`legendFrom`).
- Scripts: vectors and colours work like small arrays (`const [x, y] = position`, `position[0]`, `...color`), reading
  `game.screenSize` is about 60 times faster, and a promise rejection you handle a moment later is no longer reported.
  Unpausing the game keeps the speed you set in `time.scale`.
- Saves: a save file is written in one go, so a crash cannot leave half a file. A save file that does not load is kept
  as `storage.corrupt.json` instead of being overwritten, and `storage.corrupt` tells your game.
- Store texts can be translated: achievements and products in `factoria.json` can name a key of your `locales` files
  (`nameKey`, `descriptionKey`, `titleKey`), and the game lists them in the player's language.
- Tests: `factoria test tests/saves.test.js` runs one test file (or several, or a pattern). `game.click("playButton")`
  presses a widget by its id, `ui.rectOf` gives where a widget is on screen, `expect(x).toMatchObject({...})` checks
  some fields of an object, `game.platform.set({ backend: "none" })` tests the game as on a store-less build, and a
  "not a function" error shows the line with a mark under the call.
- Exports: `export.exclude` in `factoria.json` leaves folders out of every export (`"store/**"`). A publish dry run
  works before the store's upload tool is installed and lists what is missing. The exported game takes `--frames 120` to
  run a few frames and exit, as a quick check in CI. `factoria validate` warns about pictures phones cannot compress, and
  new projects keep `build/` out of git.
- The export guide (`factoria docs read exporting`) has one table of what each export needs (downloads, Android tools,
  Xcode) and whether your computer can make it at all, offline or after a download. A new Microsoft Store section says
  what FactorIA covers and what you still do by hand.
- A game icon without an image service: `assets.draw_icon` draws your icon and the Android icon from shapes, colours and
  text, so you need no paid picture provider and no Python.
- Store screenshots at full size: `game.screenshot` takes a `scale` (so does `factoria run --render-scale`), so a
  1280x720 game makes sharp 1920x1080 pictures instead of enlarged ones. The HUD and the visible area stay the same.
- `i18n.import` for a new language keeps the shape of your main language file, and `factoria docs read` prints clean
  text on Windows.
- The reference (`factoria api`, `docs/COMPONENTS.md`, the MCP tool list) now says which version added each component,
  field and command, and marks with "Not released yet" what is only on the main branch, so you can tell what your
  installed FactorIA has.
- Editing an ASCII level no longer means counting characters: `scene.ascii_edit` changes the map file of a level with
  operations (fill a rectangle, replace a glyph, insert or delete columns, put a coin "2 tiles above the ground" of
  column 40), rewrites only the rows and rebuilds the level, and tells you where every object ended up.
- On Windows, deleting a folder that holds files with very long paths (a macOS export nests four folders) now deletes
  all of it: exporting again into the same folder, `fs.delete` and deleting a project from the editor no longer leave
  old files behind.

Smaller improvements

- The editor's Screenshot toast has a "Show in Finder" / "Show in Explorer" button (it names your file manager) that reveals
  the new PNG, and File > Open Screenshots Folder opens the hidden `.factoria/screenshots/` folder (creating it if needed).
  A toast with a button stays longer and does not vanish while the mouse is over it.
- `factoria validate` no longer warns that a hand-written scene or prefab is "not in the canonical layout": such a file is
  valid. The report has a new informational `notes` list (`note:` lines in the text, `notes` in `--json`, the
  `project.validate` result and the editor's Validation report) with ONE entry naming those files and the optional
  `factoria call scene.format`. `scene.format {check, strict}` is still the CI gate.
- On Windows `factoria` now prints LF line endings like on macOS and Linux, so a doc or a JSON answer saved with `>`
  has no carriage returns.
- A Linux game named "game" now exports with the executable `game-bin`, so it no longer clashes with the `game` data
  folder next to it.

## 0.1.6

Menus and on-screen interface

- New interface pieces for your game: buttons, toggles, sliders, text fields, scrolling lists and panels with
  stretchable backgrounds, laid out in rows, columns or grids. Players use them with the mouse, the keyboard or a
  gamepad.
- Scripts can switch to full screen, change the window size, vsync and frame-rate cap, let players remap the controls,
  show the right button names for their gamepad, take typed text, and show or hide the cursor.
- A menus guide your AI follows to build a main menu, options, a pause menu, credits and a loading screen when your game
  needs them. New projects still start empty.
- Pausing really pauses now: physics, particles and animations stop too, while a pause menu keeps working.

Art, sound and music made by AI

- Your AI can generate images, sprite sheets, sound effects, music, voices and 3D models with the providers you set up
  (OpenAI, ElevenLabs, Meshy), keeping one style and colour palette across a game.
- Every generated or imported file remembers where it came from, and exports include `AI_CONTENT_DISCLOSURE.md` with
  the answers Steam asks about AI-generated content.
- Import Aseprite, Photoshop (PSD), OBJ and FBX files (FBX needs Blender or FBX2glTF installed), and cut sprite sheets
  into frames automatically.
- Lighter games: textures are compressed for each platform and packed into atlases, long music streams instead of
  loading whole into memory, and sounds can be evened out to the same loudness.
- `factoria validate` warns about images that are too big, sounds that clip or are too quiet, and games over a store's
  size limit.

Native plugins

- A game can bring its own native code as a plugin (C or C++ on desktop, Java or Kotlin on Android, libraries on iOS)
  without changing the engine. Plugins can live outside the game's folder, for SDKs you are not allowed to share.

## 0.1.5

- Exported Windows games open without a black console window, and the `.exe` carries your game's name and version
  (Properties in File Explorer shows them).
- Every run of a game writes a `log.txt` in the game's save folder, so a player can send it to you when something goes
  wrong.
- Exporting no longer fails on Windows when the output folder is deep enough to make paths longer than 260 characters.
- When a text uses characters its font does not have (Chinese, Japanese or Korean with the default font, for example),
  the log says which characters are missing and which font has them, instead of leaving the text blank without a word.
- When a command fails, your AI assistant always gets an error it can read and act on.

## 0.1.4

- Android: export your game as an APK to test or an AAB for Google Play, signed with your own key, with its icon.
- New Export window in the editor, with a button per platform and the settings each one needs (name, version, icons).
  What an export still lacks (Android SDK, players for another system) is installed in one click, or with
  `factoria setup` from a terminal.
- macOS: FactorIA is signed and notarized by Apple, so it opens without a security warning.
- iPhone, iPad and Apple Silicon Macs: touches and clicks land where they should, and games run on real devices.
- Android: a game you leave and open again starts correctly.
- The editor's title shows the FactorIA version and the open project.
- Exporting again only replaces a folder an earlier export made, never a folder of yours.
- Scripts: a warning when a method looks like a misspelled event name (for example `onUpdat`), which would otherwise
  never be called.
- License: FactorIA is MIT and the templates are MIT-0, so your game's code is yours to license as you like. Exported
  games include the license notices they need (`FACTORIA_NOTICES.txt`).

## 0.1.3

- Windows installer: installs for your user without an administrator prompt, adds FactorIA to the Start menu and
  makes `factoria` work in any terminal.
- Linux: a single-file AppImage, besides the `.tar.gz`. macOS: one download for Apple Silicon and Intel.
- Android and iOS export work straight from the download: you no longer need the engine's source code.
- Gamepads: hundreds more models are recognised on Linux, and on Android an unplugged pad frees its slot.
- 3D physics: balls roll and spin naturally when hit off-centre, resting bodies sleep and wake like in 2D, and fast
  objects no longer pass through walls.

## 0.1.2

- Editor: fixes in the AI chat, and projects can be deleted from the project list.
- Destroying an object also removes its physics body.
- Your AI assistant can export the game by itself.
- Screenshots taken by tests always show a complete, up-to-date frame.

## 0.1.1

- Editor: Ctrl+C and Ctrl+V work.

## 0.1.0

The first release of FactorIA, a 2D and 3D game engine made for an AI to build your game.

- Games are plain text (scenes in JSON, logic in JavaScript), so an AI can read and change every part of them, check
  its work and run tests.
- The editor is built around an AI chat: send pictures as references, keep several chats with their history, see how
  much of your plan you have used, and choose the model for each AI role.
- Templates to start from: a 2D platformer, an empty 2D game and an empty 3D game.
- 2D and 3D physics, gamepads, and play sessions that can be replayed exactly, with a report your AI can read.
- Downloads for Windows, macOS and Linux. The editor offers each new version and updates itself when you say so.
