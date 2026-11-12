# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- `factoria mcp --tools core` (or a comma list such as `core,anim,physics`) lists only the core commands and the
  chosen groups, plus `tool_load`, `tool_describe` and `tool_call` to reach the rest, for MCP clients without tool
  search that would load ~400 definitions. The default `all` changes nothing. The core list and the group rules moved
  to `fa/tooling/tool_groups.h`, shared with the built-in agent's catalog.

## 0.23.0

FactorIA 0.23.0 (M101) closes what the example games reported since late October. Music streams each stem from its
ogg and its memory is counted in `perf` and the profiler; a scene load no longer carries over a pending crossfade or
section change. `audio.play` takes a world position with a rolloff, sound patch variants share one level, and
`check_mix` judges a baked loop across its loop points. `scene.save` keeps prefab instances and `validate` warns about
inline copies of a prefab. Image documents can be resized, style rules can be skipped per file, and `anim3d.generate` and
`anim3d.retarget` record their provenance. Meshes take an emissive strength above white, `model.game_ready` fits a
collider to one part, rigs merge their parts into one draw call, `IK2D` plants feet on uneven ground and
`SpriteAnimator.loopMode` loops a clip from the component. `factoria run --touch` previews touch controls on a desktop.

### Changes

- **Animation and WFC polish (M101.P8):** `tilemap.generate` stats gain `cutOff` (refusals for areas cut off by
  `reachability.allConnected`, flagged by the check itself, not by its wording); `SpriteAnimator.loopMode` has script accessors;
  IK2D ground snapping takes the nearest ancestor with a `RigidBody2D` as the character (a container that also holds the terrain
  no longer hides it), warns once when a ground ray never hits, and its field docs say the ground values are world units and the
  ray is vertical; docs/ANIMATION.md's Sky Hopper tutorial teaches the IK2D ground fields.
- **Polish of provenance and rigs (M101.P7):** every `anim3d.*` command that writes a clip (and `ik3d.key`) is no longer `readOnly`, and
  checks `assets.json` before it touches a file. `anim3d.restore` takes `provenance` (every `undo` now carries it): an undo puts the
  clip's record, recipe included, back, and `clip: null` deletes the record with the file. A capsule collider whose `height` is under
  twice its `radius` now warns instead of being raised silently. A model part name may not contain `+` (rig.bake `mergeParts` joins names
  with it). `rig.bake {mergeParts}` with no `path` skips the fresh documents already baked with that choice. docs/RIGGING.md and
  docs/IMAGES.md say what merging does to blended submeshes and that `image.create {output}` replaces an existing PNG.
- **Rolloff for spatial sounds (M101.3):** `AudioSource.rolloff` (`linear` default, `inverse`, `exponential`) with `refDistance` and
  `rolloffFactor`, and the same three options on `audio.play({position, range, ...})` (one formula, `audio_spatial_gain`;
  docs/SOUND.md "Rolloff"). `audio.play` with a `position` and `loop` now throws (use an `AudioSource`); a positioned play out of
  range no longer adds its caption, and `Audio::play_at` returns 0 only out of range (a silent in-range sound still gets an id).
- **Sound checks (M101.P5):** `sfx.bake` and `sfx.render {variants}` find the shared normalization gain (`normalize.shared`)
  once per patch instead of once per variant (a 64-variant patch rendered about 4000 times); a velocity no longer disappears into
  the shared gain; `assets.check_mix` judges loops by the `loopStart`/`loopEnd` of assets.json first (what the engine plays) and
  the WAV `smpl` chunk only as a fallback, says "skipped" (not "No sounds found") when every sound is a recipe input, and
  `assets.regenerate` lists at most 8 compared inputs (`comparedCount` has them all) and every missing input of a failure.
- **Polish of `image.resize` and the style roles (M101.P6):** `image.resize` keeps the masks of a fill, gradient or procedural layer
  on the same pixels (such a layer becomes a box of the old canvas and moves with the anchor, like an adjustment layer with masks),
  (the result's `warnings` name it),
  cuts the text rows of indexed layers and cels to the new canvas instead of padding them (a 4x4 image resized to 4096x4096 stays a few
  KB; more than 64 MB of rows fails with a hint) and clamps positions instead of overflowing. The Image panel's Resize button is now
  the canvas size in the toolbar (it fit badly at 1024 px) and the popup's Resize is disabled while the size is the current one.
  `style.ignore` with `rules` on an entry that skips every rule no longer narrows it (the result's `notes` say so);
  `assets.set_provenance` takes `role: ""` (or null) to remove a role; `assets.regenerate`, importing a file again and
  `assets.generate_image` with `overwrite`, `assets.generate_texture` and `assets.draw_icon` keep the role; `style.ignore` and `style.set_role` refuse only `..` path segments.
- **Music streams from its ogg (M101.1b, closes KW/FB-0001):** a stem of a song that plays from stem files stays encoded and
  keeps a window of 6 s of decoded audio (about 2.5 to 3.5 MiB per stem with its decoder and ogg) instead of the whole song decoded (10.1 MB per minute per stem),
  filled ahead by an audio service thread that reads where the mixer publishes each stem will read, so a game thread that stalls
  does not dry the music (a jump to a section decodes its first chunks before it plays, waiting for the service for one chunk at
  most); section jumps, loops, crossfades and layer fades land on the same frames as before and the audio callback still takes
  no lock and allocates nothing. The stems play from their encoded ogg in memory, not from disk. Stems of 20 s or more that are `.ogg` at 44.1 kHz stream;
  `import.music.stream` (`"auto"`, `"always"`, `"never"`, in the `import.music` block of the mix entry; `music.render` keeps
  it) decides by hand. **Behaviour change:** `mode: "auto"` now picks the stems whenever the song has stem files, on every device
  (a desktop used to render live); `mode: "live"` keeps the old behaviour. `auto` compares the song with the sha256 that
  `music.render` recorded (`provenance.recipe.inputs`) and plays a song edited since live, with one warning, so a running game hears the edit. A window that is dry when the device needs it plays
  silence for that stem and is counted: `stats()` and `game.state`'s `audio` have `musicUnderruns`, `musicUnderrunFrames`
  (also inside `underruns`) and `streamedSongs`, and `audio.music_state`'s `cache` says which stems are `streamed` and their
  `underruns`. `musicBytes` / `musicMB` count a streamed stem's window and encoded bytes. docs/MUSIC.md has the MB per minute
  per mode.
- **IK2D plants feet on the ground (M101.10b, FB-0025):** `IK2D.groundMask` / `groundReach` / `groundOffset` / `groundRest` make
  the engine aim the chain at the floor under the target (a ray into the 2D physics world, the character's own colliders
  ignored), keeping the swing lift of a walk clip above the rest height, so a foot marker animated by a clip can be the target
  and the game needs no ray script. `groundMask` 0 (the default) changes nothing. `update_ik2d` / `solve_ik2d` take an optional
  `GroundRaycast2D` like `update_ik3d`; one-off solves pass none. Sky Hopper's `feet()` shrinks to switching the mask in the air.
- **audio.play at a place (M101.3, KW/FB-0006):** `audio.play(path, { position: [x, y, z], range })` plays a one-shot from a
  point with no entity, attenuated and panned by the `AudioListener` as an `AudioSource` with `spatial: true` is (linear
  fall-off to 0 at `range`, default 800; `[x, y]` in 2D). Out of range it plays nothing and returns 0. It does not follow
  anything after it starts. Kindlewatch drops its hand-made `playAt`.
- **Emissive above white for meshes (M101.11, CC/FB-0057):** `MeshRenderer.emissiveStrength` (0..100, default 1) multiplies
  `emissive`, so a lamp can be brighter than white and `Camera.bloom` glows more for it. The game target is now RGBA16F
  (HDR) wherever the GPU renders to it with blending, filtering and the requested MSAA, else RGBA8 as before
  (`FA_SCENE_FORMAT=rgba8` forces it, `Renderer::hdr_scene()` says which); the screen, screenshots and video stay 8-bit,
  and a float target costs more memory bandwidth than an 8-bit one. If the GPU lists RGBA16F but cannot make the target in
  it (GLES3/WebGL2 with MSAA and no `EXT_color_buffer_float`), the game target is made in RGBA8 instead when the renderer starts
  and `hdr_scene()` says false (only the game target falls back; a later resize that fails keeps the format).
  Look change for games that already use `Camera.bloom`: a specular above 1 and additive sums now reach the bloom unclamped,
  so the glow can be bigger than before, and it differs between GPUs with and without RGBA16F (the latter keep the old look);
  bloom ignores NaN and infinite pixels (with MSAA an Inf is only dropped inside a lamp: the resolve averages it into a large number at the edge). The colour filter clamps its input, so its output is
  unchanged. Meshes that differ only in `emissiveStrength` are not batched together, like a different `emissive`.
  `validate` warns about a colour such as `[3, 2, 1]` that reads as 0..255 and is almost black, and for `emissive` it points
  to `emissiveStrength`. Clockwork Courier's market lamps glow again with it.
- **Music memory is counted (M101.1a):** `Audio::stats()` (and `game.state`'s `audio`) reports `musicBytes`, the decoded
  stems the music cache holds, and `decodedBytes` now includes them, so `audioDecodedMB` explains the process size.
  `audio.music_state` lists the cached songs with their bytes per stem (`cache`, `cacheBytes`); `perf.profile` memory has
  `musicMB`; the `perf.measure` sample reports `audioDecodedMB` and `musicMB` (never gated, not in baselines).
  docs/MUSIC.md has the MB per minute per layer.
- **Validate (M101.9b, SH/FB-0024):** `validate` warns about a scene entity that repeats the components of a prefab inline
  (same name or component set, at most two differences) instead of being an instance, and about an instance that also saves
  two or more components with the prefab's own values. The warning names the file and JSON pointer, the prefab, and the
  `{id, prefab, differences}` entry that replaces the copy (what `scene.save` writes since M101.9a). Entries are matched
  with the loaded world by position (an entity without `id` or with a duplicate one is checked too), prefabs with the
  same name are compared first, the parts of `.prefab.json` files are checked, and a file with many copies lists the
  first 5 and counts the rest.
- **Small fixes from the examples (M101.10a):** `SpriteAnimator.loopMode` (`inherit`, `loop`, `once`) decides whether a
  clip restarts after its last frame whatever the sheet's own loop flag says, so one baked clip can loop on one entity and
  play once on another; `inherit` is the default and the old `loop` bool stays (false = once). A level that
  `tilemap.generate` refuses because cut-off areas refused more than half of the attempts now says that the sample's shape
  is the cause (rooms joined by one-cell passages, closed pockets) and how to fix the sample. Gem Roller no longer calls
  its project tool at runtime (the scatter code moved to `scripts/scatter_gems.js`, which the game and the tool both
  import), so its gems appear in an exported build; `factoria validate` and the export already warn about such a call.

- **Music (M101.2, pending state):** the music of a scene that reloads no longer fires what the scene before had queued:
  the new `MusicPlayer` adopts the music that is playing and drops a crossfade or section change that waited for a bar line
  (or takes the target song when the crossfade had started). `entity.music.status` and `audio.music_state` show the queue
  with `pendingSong`, `pendingSection` and `pendingAt` (an audio frame); `setIntensity`, `goToSection` and `crossfadeTo`
  return `{frame, time, quantize}`, where the change lands. `crossfadeTo` without `section` starts the other song at its
  beginning, never at the component's `startSection`. `appliedIntensity` (what the layers follow) and `requestedIntensity`
  (the last value set) sit beside `intensity`.
- **Music polish (M101.P1):** `pendingSong` is only set while a crossfade's song loads or is on its way to the mixer (not for
  a song that failed to load, which shows in `error`); `crossfadeTo` answers with an error and a hint when the transport
  refuses the song. A streamed song's window is 32 chunks (6 s, 2 MiB per stem) so a crossfade inside one song keeps its
  look-ahead; the music service decodes the first chunks of every stem before filling any window and no longer wakes every
  2 ms when nothing can change. The underruns and the bytes of a song the cache let go of while it still plays stay in
  `stats()`, `audio.music_state` and `musicMB`, `audioDecodedMB` is the run's maximum, and the editor's profiler shows the
  music memory.
- `input.record` records an action pressed with `game.input` by name (`"actions"` in the replay frame) and the headless replay
  plays it back, so a recording made by action name replays to the same state.
- `fa.call` in a test has the read-only `assets.provenance` and `assets.disclosure`; docs/SCRIPTING.md lists the commands a
  test has and a test keeps the list true.
- `game.findByTag` and `game.findAll` in `factoria:test`, like `world`'s.
- Touch interface on a desktop: `factoria run --touch`, `ui.force_touch` and `game.screenshot {forceTouch}` show the
  touch-only controls (`TouchStick`, `TouchButton`) without editing the scene. `game.screenshot {forceTouch}` changes it only
  for that picture; button prompts (`Input::button_name`) follow the forced touch too.
- **For game authors and AIs (M101.9a):** `scene.save` and the editor's Save keep prefab instances. An entity made
  from a prefab is written as `{"id", "prefab", only the differences}` (`name`, `tags`, `active`, changed component
  fields, `overrides` for the prefab's children, added `children`) instead of being expanded into inline entities, so
  later changes of the prefab file still reach the scene; editing a field saves only that override and editing it back
  drops it, and loading and saving a scene in the saver's layout gives the same text. An instance the form cannot
  express (a part of the prefab removed) is written inline and listed under `expandedPrefabs` in the `scene.save`
  result (and in an editor notification) with the reason. A part of the prefab whose id differs from the prefab's (the
  suffix of a second instance) is written inline when a string elsewhere in the scene names that id. An instance added
  as a child of an instance stays an instance. Undo, redo, Play/Stop and the AI revert keep the origin of the entities
  too, and `scene.import_ascii` / `edits` with `path` writes an entity that `edits` touches as its prefab plus the
  edit, no longer expanded. Closes KW/FB-0008.
- **For engine developers (M101.9a):** `EntityInfo::prefab` and `EntityInfo::fromPrefab` (not reflected) remember the
  instance root and the entities its prefab made; `save_scene(world, SaveSceneOptions)`, `snapshot_scene(world)` and
  `PrefabSave` (`fa/scene/serialize.h`); `diff_entity_with_prefab(world, entity, prefabPath)` returns the `{prefab,
  differences}` entry of an entity against a prefab, or why it is not expressible, for the `validate` warning on
  inline copies (M101.9b).
- **Models and rigs for mobile (M101.8):** `model.game_ready`'s collider takes `part` (fit it to one named part, e.g. a pine's
  trunk instead of its canopy, also with `merge`), `radius` and `height` (override the fitted values). `rig.bake` takes
  `mergeParts`: the skinned parts that share a material become one submesh (same vertices, weights and bind pose, so the
  same pose), kept in the recipe; Kindlewatch's characters go from 75 to 38 draw calls and Gem Roller's scout from 30 to 18.
- `anim3d.generate` and `anim3d.retarget` record a provenance recipe (inputs: the rig, and for a retarget the source clip),
  so `assets.regenerate {"stale": true}` makes a clip again after its rig is fitted again; editing a clip by hand removes the
  recipe. `assets.set_provenance` and `schemas/assets.schema.json` take the kind `anim3d`, also for clips outside `assets/`.
- `image.create` takes `output`, the PNG the document bakes to.
- A test runs every recipe command in a scratch project and validates the `assets.json` it writes against the schema.
- `image.resize {path, width, height, anchor, fill}` changes the canvas of an image document: every layer, frame and cel moves
  or is cropped by one of nine anchors, indexed rows are cut or padded, palette, ramps, tags and sheet stay; the Image panel has
  a Resize... button (one undo step).
- `style.ignore {path, rules}` skips only the named style rules for a file, folder or glob; `style.set_role` and a `role`
  (`ui`, `icon`, `effect`) in an asset's provenance turn off the rules that do not apply to that kind of picture.
  `assets.check_art` reports what it skipped and why (`styleSkipped`). Kindlewatch drops its ignore list for roles.
- Sound patch variants can share one level: `master.normalize.shared: true` finds one gain on the loudest variant and applies it to all of them, so they keep their relative loudness (per-variant stays the default).
- `sfx.bake` takes `path` (one patch or a list) to bake only those patches.
- `assets.regenerate {stale}` lists the inputs it compared (`compared`: path and hash, and the style-guide values) when it answers "up to date".
- `assets.check_mix` skips a recording that is only an input of an audio document's recipe (listed in `skipped` with the reason, unless `paths` names it) and judges `loop_seam_jump` and `loop_seam_slope` of a baked loop across its loop points (the crossfade a `loop` step made), not across the file's ends.

