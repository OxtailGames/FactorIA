# AI guide: tools, conventions, files and components

Part of [AI guide](../AI_GUIDE.md): the MCP tools and CLI, skills, coordinates and units, scene and prefab files, the component cheat-sheet (sections 4 to 7).

## 4. Using the MCP tools and the CLI

A tool name is the command name with `.` replaced by `_`. Arguments are one JSON object. Results are JSON, and a screenshot comes back as an image. A failure returns `code`, `message` and `hint`; the hint says how to fix it. An unknown name returns a "did you mean" suggestion. `docs_commands` lists every command with its `inputSchema`, so use it to get exact argument names.

<!-- generated: tools table, factoria call docs.write_reference '{"out":"docs"}' -->
| Category | Tools (the command name with `.` as `_`) | What they do |
|---|---|---|
| ai | `agent_cost`, `ai_extensions`, `ai_hooks`, `ai_hooks_test`, `ai_models`, `ai_plugin_install`, `ai_providers`, `ai_retrospective`, `ai_review`, `ai_review_feedback`, `ai_reviews`, `ai_run`, `ai_saver_fact`, `ai_saver_group`, `ai_savers`, `ai_session_timeline`, `ai_settings_get`, `ai_settings_set`, `ai_tool_plan`, `ai_tool_servers` | AI roles, hooks, extensions and the cost of the AI runs that made a game. |
| anim | `anim3d_add_event`, `anim3d_create`, `anim3d_generate`, `anim3d_generators`, `anim3d_info`, `anim3d_mirror_pose`, `anim3d_move_keys`, `anim3d_preview`, `anim3d_remove_event`, `anim3d_remove_keys`, `anim3d_remove_track`, `anim3d_restore`, `anim3d_retarget`, `anim3d_set_clip`, `anim3d_set_event`, `anim3d_set_interp`, `anim3d_set_keys`, `anim_add_event`, `anim_add_track`, `anim_check`, `anim_create_clip`, `anim_filmstrip`, `anim_list`, `anim_move_event`, `anim_move_keys`, `anim_pose`, `anim_remove_event`, `anim_remove_keys`, `anim_remove_track`, `anim_restore`, `anim_set_clip`, `anim_set_event`, `anim_set_interp`, `anim_set_keys`, `ik3d_check`, `ik3d_key`, `ik3d_solve` | 2D and 3D animation (clips, tracks, events, state machines, rigs) and 3D inverse kinematics, with their checks. |
| api | `api_commands`, `api_components`, `api_scripting` | Machine-readable lists of the components, commands and scripting API. |
| assets | `assets_analyze_audio`, `assets_animate_svg`, `assets_bake_sheet`, `assets_check_art`, `assets_check_mix`, `assets_contact_sheet`, `assets_convert_audio`, `assets_disclosure`, `assets_draw_capsules`, `assets_draw_icon`, `assets_generate_image`, `assets_generate_loop`, `assets_generate_model`, `assets_generate_music`, `assets_generate_sound`, `assets_generate_sprite_sheet`, `assets_generate_texture`, `assets_generate_voice`, `assets_import`, `assets_list`, `assets_pack_atlas`, `assets_pick`, `assets_preload`, `assets_preview_in_scene`, `assets_preview_sheet`, `assets_provenance`, `assets_rasterize_svg`, `assets_regenerate`, `assets_review`, `assets_set_provenance`, `assets_slice_sheet`, `assets_spectrogram`, `assets_subset_font`, `assets_synth_sound`, `audio_bake`, `audio_create`, `audio_edit`, `audio_info`, `audio_render`, `image_bake`, `image_create`, `image_draw`, `image_edit`, `image_export`, `image_frame_add`, `image_frame_cel`, `image_frame_move`, `image_frame_remove`, `image_frame_set`, `image_frame_sheet`, `image_generate_layer`, `image_info`, `image_inpaint`, `image_layer_add`, `image_layer_add_provider`, `image_layer_convert`, `image_layer_move`, `image_layer_remove`, `image_layer_set`, `image_paint`, `image_palette`, `image_palette_move`, `image_palette_remove`, `image_pixel`, `image_pixel_cleanup`, `image_pixel_dither`, `image_pixel_outline`, `image_pixel_rotate`, `image_pixel_scale`, `image_pixel_shade`, `image_resize`, `image_save`, `image_select`, `image_tag_remove`, `image_tag_set`, `image_tile_check`, `image_tile_set`, `image_tileset_build`, `image_tileset_check`, `image_tileset_info`, `image_tileset_rules`, `image_to_pixel_art`, `model_bake`, `model_bake_maps`, `model_check`, `model_create`, `model_decal`, `model_edit`, `model_game_ready`, `model_import_clean`, `model_info`, `model_palette`, `model_preview`, `model_select`, `model_texture`, `model_uv`, `music_arpeggio`, `music_bassline`, `music_check`, `music_chord`, `music_create`, `music_drums`, `music_edit`, `music_export_midi`, `music_import_midi`, `music_info`, `music_instrument`, `music_mix`, `music_notes`, `music_preview`, `music_render`, `music_scale`, `rig_bake`, `rig_create`, `rig_fit`, `rig_info`, `rig_templates`, `sfx_bake`, `sfx_edit`, `sfx_family`, `sfx_info`, `sfx_preset`, `sfx_render`, `sfx_tweak`, `skin3d_add`, `skin3d_auto`, `skin3d_clear`, `skin3d_info`, `skin3d_limit`, `skin3d_mirror`, `skin3d_normalize`, `skin3d_preview`, `skin3d_set`, `skin3d_smooth`, `style_ignore`, `style_set_role`, `vector_add`, `vector_align`, `vector_assign_ids`, `vector_blob`, `vector_boolean`, `vector_delete`, `vector_distribute`, `vector_duplicate`, `vector_group`, `vector_info`, `vector_mirror`, `vector_nodes`, `vector_offset`, `vector_reorder`, `vector_repeat`, `vector_set`, `vector_set_path`, `vector_shade`, `vector_shape`, `vector_simplify`, `vector_smooth`, `vector_stroke_to_path`, `vector_style`, `vector_text_to_path`, `vector_to_rig`, `vector_transform`, `vector_ungroup`, `vfx_create`, `vfx_edit` | Make, import, check and preview art, sounds, music, models, vectors and images (`image_*`, `model_*`, `sfx_*`, `music_*`...). |
| audio | `audio_bus`, `audio_log`, `audio_music`, `audio_music_state`, `audio_snapshot` | Drive and inspect buses, music players and the sounds played. |
| docs | `docs_commands`, `docs_components`, `docs_list`, `docs_read`, `docs_search`, `docs_write_reference` | Read the built-in docs, search them, and read the component and command reference. |
| engine | `engine_info`, `engine_update_status` | Engine version, platform, graphics backend, and whether FactorIA was updated while it runs. |
| feedback | `feedback_archive`, `feedback_check`, `feedback_check_fixed`, `feedback_delete`, `feedback_list`, `feedback_report`, `feedback_share`, `feedback_share_preview`, `feedback_share_status`, `feedback_update`, `feedback_verdicts` | File, list, check and close engine feedback (the feedback rule, section 3). |
| feel | `feel_cancel`, `feel_flash`, `feel_hitStop`, `feel_knockback`, `feel_settings`, `feel_shake`, `feel_sound`, `feel_spawn`, `feel_squash`, `feel_state` | Game feel effects: flash, hit-stop, knockback, shake, squash. |
| fs | `fs_delete`, `fs_edit`, `fs_list`, `fs_read`, `fs_search`, `fs_write` | Read, list, edit and delete the project's files (always inside the project). A write replaces the file atomically (a temporary file is renamed over it), so hot reload never sees a half-written scene. |
| game | `game_click`, `game_input`, `game_logs`, `game_pause`, `game_render_stats`, `game_resume`, `game_screenshot`, `game_state`, `game_state_hash`, `game_step`, `input_record`, `render_frame_graph`, `render_inspect`, `render_pick`, `vfx_budget`, `vfx_check`, `vfx_filmstrip`, `vfx_list`, `vfx_play`, `vfx_review`, `vfx_stop` | Run the headless game: step, pause, input, clicks, screenshots, state, logs; render and VFX probes. |
| i18n | `i18n_export`, `i18n_import`, `i18n_set_language`, `i18n_state` | Translations: export and import string tables, switch language, see missing strings. |
| jobs | `jobs_info` | The job system: worker threads and what ran. |
| material | `material_info` | Describe custom materials. |
| physics | `nav_bake`, `nav_find_path`, `nav_find_paths`, `nav_find_tile_path`, `nav_find_tile_paths`, `nav_flow_field`, `nav_info`, `physics_raycast`, `physics_raycast_all`, `physics_shape_cast` | Physics queries (raycasts, sweeps, overlaps) and navigation (NavMesh and tile paths). |
| platform | `platform_add_backend`, `platform_emit`, `platform_remote_play_connect`, `platform_remote_play_disconnect`, `platform_reset`, `platform_respond`, `platform_revoke`, `platform_set_ad`, `platform_set_fake`, `platform_state` | Fake store platform: set up a store backend, send store events, Remote Play. |
| play | `play_auto`, `play_report`, `play_sessions` | Let the game play itself (`play.auto`) and read the reports of play sessions. |
| project | `checkpoint_create`, `checkpoint_diff`, `checkpoint_list`, `checkpoint_read`, `checkpoint_restore`, `perf_baseline`, `perf_check`, `perf_measure`, `perf_profile`, `player_run_ios_sim`, `project_add_menu_kit`, `project_create`, `project_export`, `project_info`, `project_new_ci_workflow`, `project_new_plugin`, `project_serve_web`, `project_templates`, `project_test`, `project_validate` | Validate, test, export and measure the project; checkpoints and the CI workflow. |
| publish | `publish_appstore`, `publish_epic`, `publish_gog`, `publish_googleplay`, `publish_itch`, `publish_microsoft`, `publish_steam` | Upload exports to Steam, itch, Epic, GOG, the App Store and Google Play. |
| render | `mesh_create`, `mesh_destroy`, `mesh_info`, `mesh_list`, `mesh_save`, `mesh_update` | Procedural meshes: create, inspect and free them. |
| review | `review_cleanup`, `review_info`, `review_list`, `review_pick`, `review_sheet` | Review sheets: the choices a person makes by number, listed and recorded. |
| scene | `bones_create`, `load_cancel`, `load_status`, `prefab_save`, `scene_ascii_edit`, `scene_destroy`, `scene_format`, `scene_get_entity`, `scene_import_ascii`, `scene_list_entities`, `scene_load`, `scene_place_ascii`, `scene_preload`, `scene_reload`, `scene_remove_component`, `scene_save`, `scene_set_component`, `scene_set_parent`, `scene_spawn`, `skin_auto_weights`, `skin_bind`, `skin_set_weights`, `tilemap_cell_at`, `tilemap_cell_to_world`, `tilemap_generate`, `tilemap_generate_cancel`, `tilemap_generate_start`, `tilemap_generate_step`, `tilemap_paint_terrain`, `tilemap_retile`, `tilemap_set_terrains`, `tilemap_set_tile`, `tilemap_terrains` | Edit the running world: entities, components, parents, prefabs, tilemaps, skins, scene load and background loads. |
| screen | `screen_set_safe_area` | Pretend device screen features (safe area, notch). |
| script | `script_errors`, `script_eval`, `script_reload`, `script_trace`, `storage_clear`, `storage_list` | Scripts: evaluate JavaScript, reload modules, list errors, trace. |
| setup | `setup_install`, `setup_status` | Check what an export needs on this computer (`setup_install` is the user's call: an AI is refused, tell the user to press the editor's setup button or run `factoria setup`). |
| shader | `shader_compile` | Compile custom material shaders for several platforms. |
| sign | `sign_macos`, `sign_windows` | Sign the exported macOS app and Windows package. |
| skills | `skills_list`, `skills_new`, `skills_read` | List, read and create skills (topic guides). |
| ui | `ui_caption`, `ui_check_layout`, `ui_clear_captions`, `ui_force_touch`, `ui_set_mirror_rtl`, `ui_set_scale`, `ui_set_slider`, `ui_set_text_scale`, `ui_speak`, `ui_state`, `ui_stop_speaking` | UI checks and helpers: layout overflow, captions, touch interface, focus. |

`docs_commands {"name":"scene.spawn"}` gives one command in full (arguments, defaults, examples) and `docs_commands {"filter":"words"}` searches names, categories and summaries. Tools of plugins and of the project's `tools/*.js` are not in this table: `docs_commands` in the running project lists them.
<!-- end generated -->

Examples:

```
docs_read {"name":"scripting"}
docs_search {"query":"raycast"}
project_validate {}
scene_spawn {"prefab":"prefabs/enemy.prefab.json","position":[300,0]}
game_step {"frames":120}
game_step {"frames":60,"press":["move_right"]}
game_screenshot {}
game_state {"components":["Transform","RigidBody2D"],"maxEntities":50}
game_logs {"minLevel":"warn","max":50}
script_eval {"code":"world.findByTag(\"coin\").length"}
fs_read {"path":"scripts/player.js","startLine":1,"endLine":40}
fs_edit {"path":"scripts/player.js","find":"speed = 300","replace":"speed = 360"}
feedback_list {"status":"open"}
```

The argument names above are the ones the engine accepts. `fs_edit` requires the text in `find` to match exactly once, unless you pass `"replaceAll": true`.

Without MCP, the same commands run from a shell: `factoria commands` lists them, `factoria call <command> '<json>'` runs one on a fresh engine, and `factoria call --batch` or `factoria session` run several on one engine (section 11).

A tool result can end with a block that starts with `[FactorIA notice]`: the server restarted itself after a FactorIA update (the headless game restarts from the start scene), or it runs the old code and the user must reconnect (`/mcp`), or the project's `.mcp.json` changed after your client started. Read it, tell the user what it asks of them, and redo whatever it says was lost; `engine_update_status` repeats it ("MCP", docs `mcp`, "After an update").

The MCP server also offers prompts: `make-game` (argument `idea`), `add-feature` (`feature`), `fix-bug` (`description`) and `report-engine-gap`.

### 4.1 Skills: topic guides you read when the task needs one

The long guides are **skills** (the Agent Skills format: a folder with a `SKILL.md`, see `factoria docs read skills`), not part of your prompt or of this file. Your system prompt lists the ones your role is offered, one line each (Claude Code lists them itself). Before that kind of work, read the skill: `skills_read {"name":"tile-levels"}` (CLI: `factoria call skills.read '{"name":"tile-levels"}'`); the answer lists the skill's other files, read one with `"file":"reference.md"`. `skills_list` shows all of them and where each lives. The engine's own cover tile levels, 3D physics, custom shaders, glow and effects, web requests, menus and finishing, publishing and exporting, looking at the picture, the art and audio craft and `review-ready` (keep `REVIEW.md` current). This game can have its own in `skills/<name>/SKILL.md`: when you learn something about THIS game that a later AI needs (how enemies are built, the balance table), write it with `skills_new {"name","description"}` and fill in the file; the description says when to read it. `factoria validate` checks them. A game's skill with the name of an engine skill replaces it.

## 5. Coordinates, units and conventions

| Topic | Rule |
|---|---|
| 2D world | Units are design pixels. +X is right and +Y is up. The origin is the centre of the screen. With the 1280x720 design size of the templates, a default camera shows x from -640 to 640 and y from -360 to 360. |
| Screen space | `"space": "screen"` on Sprite, Shape2D, Text or ParticleEmitter. Units are design pixels, the origin is the top-left corner and +Y points down. Cameras do not affect it, and with several cameras (split screen) it is drawn once over the whole screen, not once per camera. Use it for HUD and menus. Section 9.4 shows how to pin items to the corners. |
| `anchor` and `pivot` | Screen space only: `anchor` (0..1 in each axis) is the screen point the position is relative to: [0,0] top-left, [1,0] top-right, [0,1] bottom-left, [1,1] bottom-right. `pivot` is the point of the item that sits at that point: [0,0] bottom-left, [0,1] top-left, [1,1] top-right, [0.5,0.5] centre. Sprite and Shape2D default to [0.5,0.5]; Text defaults to [0,1]. |
| 3D | Units are meters. Right-handed, +Y up. A perspective camera looks down its local -Z axis. |
| Angles | Degrees. In 2D only `rotation[2]` is used, counter-clockwise. In 3D, `rotation` is `[pitch X, yaw Y, roll Z]` and the matrix is `Ry(yaw) · Rx(pitch) · Rz(roll)`. |
| Colors | `[r, g, b, a]` with values 0..1, `"#rgb"`, `"#rrggbb"` or `"#rrggbbaa"`, or a name: white, black, red, green, blue, yellow, cyan, magenta, gray, grey, orange, purple, pink, brown, transparent. If any value in an array is above 1, the engine reads the array as 0..255 bytes, so keep to 0..1. |
| Rects | `{x, y, w, h}` or `[x, y, w, h]` (`physics.overlapBox`, `debug.rect`, `entity.bounds()`): `(x, y)` is the minimum corner, the BOTTOM-LEFT in the +Y-up world, and `w`, `h` the size. |
| Vectors | In scripts, a vector argument accepts `Vec2`/`Vec3` values, `{x, y}` or `[x, y]`. In JSON, use arrays (`[x, y]` or `[x, y, z]`); `{x, y}` objects also work in component fields. |
| Input | Gameplay reads actions (`input.pressed("jump")`) declared in `factoria.json` under `input.actions`. Bindings are key names (`"A"`, `"Space"`, `"Left"`, `"LeftShift"`, `"0"` to `"9"`, `"F1"`), `"MouseLeft"`, `"MouseRight"`, `"MouseMiddle"`, `"Touch"` (any finger down), a chord with modifiers (`"Ctrl+Z"`, `"Shift+MouseLeft"`; `Ctrl`, `Shift`, `Alt`, `Super` name either side; a plain `Z` bound by another action does not fire while Ctrl+Z is held) or gamepad names, which match ANY connected pad: buttons `"GamepadA"`, `"GamepadB"`, `"GamepadX"`, `"GamepadY"`, `"GamepadStart"`, `"GamepadBack"`, `"GamepadGuide"`, `"GamepadDpadLeft"`/`Right`/`Up`/`Down`, `"GamepadLeftShoulder"`, `"GamepadRightShoulder"`, `"GamepadLeftThumb"`, `"GamepadRightThumb"` and the analog half axes `"GamepadLeftStickLeft"`/`Right`/`Up`/`Down`, `"GamepadRightStickLeft"`/`Right`/`Up`/`Down`, `"GamepadLeftTrigger"`, `"GamepadRightTrigger"`. Sticks and triggers are analog: `input.axis("move_left", "move_right")` gives -1..1 and `input.vector(...)` a short vector for a half-tilted stick, `input.value(action)` gives 0..1, and an action counts as down from 0.5. A radial deadzone (default 0.2, `"input": {"deadzone": 0.2}` in `factoria.json`) hides stick drift. For local multiplayer give each person `input.player(i)`: the same actions read from that person's own pad or key block, with bindings of their own (section 9.28); `input.gamepad(1).down("A")` reads the raw buttons of one pad. Tests drive pads with `game.gamepad(0).press("A")` and `.axis("LeftX", -1)`. On phones, the `TouchStick` and `TouchButton` widgets (UI table below) press these same gamepad bindings, so a pad game plays by touch unchanged. Unknown binding names are errors with a "did you mean". Real pads are read in windowed runs: Windows (XInput), Linux (joystick API), macOS/iOS (GameController) and Android and the web (the browser's Gamepad API). Face buttons are positional (`GamepadA` is the bottom button whatever the pad prints on it). On Linux a pad is translated through a mapping line found by its USB/Bluetooth ids: the engine embeds the Linux lines of the community SDL GameControllerDB (about 740 entries, including generic "USB Gamepad" devices, DualShock 4, DualSense, Switch Pro), and a pad listed nowhere gets the Xbox (xpad) layout. For a pad whose buttons come out wrong, add its line (copy it from SDL's GameControllerDB or SDL tools; the engine logs the pad's GUID) to a `gamecontrollerdb.txt` next to `factoria.json` (one line per pad, `#` comments), or have the player set the standard `SDL_GAMECONTROLLERCONFIG` environment variable; priority is that variable, then the file, then the built-in lines. Android drops a pad's slot when the pad is unplugged and tells Z/RZ sticks from Z/RZ triggers by the axes the device reports. No real pad has been tried on Linux or Android yet. `game.on("gamepadConnected" | "gamepadDisconnected", (pad) => ...)` gives `{ slot, id, name, type }`; `id` is the same for the same physical pad every time, and a pad that returns gets its old slot when that is free (`input.gamepad(i).id` and `.name` read them; pads plugged in before the first scene are not announced). Tests: `game.gamepad(1).connect({ id, name, type })`. |
| Ids | Give every gameplay entity a stable `id` (`"player"`, `"coin_3"`). Entity references use ids. |
| Paths | Project-relative with forward slashes (`assets/hero.png`). The file tools (`fs_*`) reject absolute paths and any `..` segment. To create a sprite or other binary file from text tools, call `fs_write` with `"encoding": "base64"` and the base64 of the PNG bytes as `content` (generate the PNG in a JS tool or script, or encode it yourself); the default `"utf8"` is text only. |
| Determinism | Random numbers come from `rng` (imported from "factoria"); a generator that must repeat from a seed uses its own `rng.create(seed)` (section 9.16). Time comes from the `dt` argument or `time.dt`. `Math.random` is routed to the same world stream as `rng.float()` (so a run still repeats), but write `rng`: it is the documented API. `Math.sin`, `cos`, `atan2`, `exp`, `pow`, `log` and the other transcendental functions give the same bits on every platform (SCRIPTING.md, "Runtime notes"). `Date` is the real wall clock in a game script: never use `Date.now()` or `new Date()`, read the calendar with `game.today()`. |
| Names | JSON keys are camelCase. Components are PascalCase (`RigidBody2D`). Enum values are lowercase (`"orthographic"`, `"additive"`). Commands are `area.verb_object`. |
| Secrets | Never put API keys in a project. They belong in `~/.factoria/ai.json` or in environment variables. |

## 6. Scene and prefab files

A scene is `factoria.scene/1`. Each entity has `id`, `name`, `tags`, `active`, `prefab`, `components` and `children`. Entity references use the string `id`.

```json
{
  "format": "factoria.scene/1",
  "settings": { "gravity2D": [0, -980] },
  "entities": [
    {
      "id": "camera",
      "name": "Main Camera",
      "components": {
        "Camera": { "projection": "orthographic", "clearColor": [0.35, 0.55, 0.85, 1], "primary": true }
      }
    },
    {
      "id": "player",
      "name": "Player",
      "tags": ["player"],
      "components": {
        "Transform": { "position": [-300, -250, 0] },
        "Shape2D": { "shape": "rectangle", "size": [32, 48], "color": [0.95, 0.35, 0.3, 1], "layer": 2 },
        "RigidBody2D": { "type": "dynamic", "fixedRotation": true },
        "Collider2D": { "shape": "box", "size": [32, 48], "friction": 0.2 },
        "Script": { "path": "scripts/player.js", "props": { "speed": 300, "jumpSpeed": 620 } }
      }
    }
  ]
}
```

`settings` holds the scene-wide values: `gravity2D`, `gravity3D`, `ambientLight`, `skyColor`, `horizonColor`, `fogColor`, `fogDensity`, `music`, `musicVolume`. A hand-written scene may leave out any of them (or all of `settings`) and gets the defaults. When the engine writes a scene (`scene_save`, `scene_import_ascii` with `path`, the editor) it saves only the settings that differ from their defaults, EXCEPT the gravity: `gravity2D` (default `[0, -980]`, pixels/s² in 2D) and `gravity3D` (default `[0, -9.81, 0]`, m/s² in 3D) are always written, so the file itself shows what pulls the bodies down, even at the default. A saved 2D level therefore starts like this, and a 2D game reads only `gravity2D`:

```json
{
  "format": "factoria.scene/1",
  "settings": {
    "gravity2D": [0.0, -980.0],
    "gravity3D": [0.0, -9.81, 0.0]
  },
  "entities": [
```

A prefab is `factoria.prefab/1` with one `entity`:

```json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Enemy",
    "tags": ["enemy"],
    "components": {
      "Shape2D": { "shape": "rectangle", "size": [40, 40], "color": [0.8, 0.2, 0.2, 1] },
      "RigidBody2D": { "type": "dynamic", "fixedRotation": true },
      "Collider2D": { "shape": "box", "size": [40, 40] },
      "Script": { "path": "scripts/enemy.js", "props": { "speed": 120 } }
    }
  }
}
```

A scene entity can start from a prefab and override it: `{"id": "enemy_1", "prefab": "prefabs/enemy.prefab.json", "components": {"Transform": {"position": [200, -100, 0]}}}`.

**Saving a scene keeps the instances.** The world remembers which entities a prefab made, so `scene_save` (and the editor's Save) writes each one back as `{"id", "prefab", ...}` plus only what differs from the prefab: `name`, `tags`, `active`, the component fields that are not the prefab's (`components`, merged into the prefab's), the changes to the prefab's children and their components (`overrides`, keyed by the child's id, or its name or path when it has no id) and the children you added (`children`). Edit a field and exactly that field appears in the file; set it back and it disappears; an unedited scene saves to the same text it was loaded from (when it is in the canonical layout `scene_save` writes; a hand-formatted file is normalized on its first save). When the prefab file changes, the instances follow it. What an instance cannot say (a child or component of the prefab removed, a child added under a part of the prefab) is written as ordinary inline entities, and the `scene_save` result lists them under `expandedPrefabs` with the reason, so a scene never loses data silently. Entities you copy (editor Duplicate) or build inline have no prefab and stay inline.

### Saving a prefab from the running game, and keeping files tidy

Do not format prefab JSON by hand. Build the thing in the running game (`scene_spawn`, `scene_set_component`, children with `parent`), look at it, then save it:

```
prefab_save {"id": "enemy_3", "path": "prefabs/enemy.prefab.json"}
```

Over the CLI, a plain `factoria call` starts a new game each time, so the entity must exist in the start scene; to save something you spawned first, use `factoria call --batch` or `factoria session` (section 11).

The file is a `factoria.prefab/1` document in the canonical layout (the one `scene_save` writes), with the entity's whole tree: its children and each component's non-default fields. A prefab describes the reusable thing, not the instance you built it from, so the file does NOT carry:

- **Ids.** Every instantiation gets fresh ones. An `id` stays only where another entity of the saved tree points at it through an entity-typed field, so that reference still resolves.
- **The root's `Transform.position`.** It is where this instance stands. The spawn call (`scene_spawn {"prefab":..., "position":[x,y]}`), the scene entity or the `scene.import_ascii` legend places each new instance. Children keep their positions relative to the root, and the root's rotation and scale are kept.
- **Tags that start with `tilemap:`.** `scene.import_ascii` adds them to the objects it places, and a prefab that carried one would be destroyed when that map is re-imported.
- **Entity references that leave the saved tree.** They would point at nothing in every instance.

The result is `{path, entity, children, overwritten, notes}`; `notes` lists what was left out when it matters (for example the root position that was dropped). `path` must end in `.prefab.json` and normally lives in `prefabs/`, where `project_info` and `project_validate` look. An existing file is an error until you pass `"overwrite": true`. To keep one entity exactly where it stands, save the whole scene with `scene_save`.

After you edit scene or prefab files by hand, run `scene_format` (CLI: `factoria call scene.format '{"paths":["scenes"]}'`). It rewrites the `*.scene.json` and `*.prefab.json` files you name in the canonical layout: 2-space indent, short arrays of numbers on one line (`"position": [0, 12.5, 0]`), long ones wrapped at about 100 columns, a Tilemap's `tiles` one map row per line. It does not load anything into the game and it only changes whitespace: values and key order stay as they are, and each file is read back and compared with the original data before it is written. `paths` (files or folders) says which; `"all": true` takes the whole project; with neither (and no `check`) the command writes nothing and fails, saying how many files it would change and the first ones, so a call never rewrites files you did not mean to touch. With `"check": true` nothing is written and the result lists the files that are not canonical in `notCanonical`, which is what a CI step or a review wants; add `"strict": true` and the command fails (error code `not_canonical`, the message lists the files) when any file is not canonical, so `factoria call scene.format '{"check":true,"strict":true}'` exits non-zero. `project_validate` also warns once per scene or prefab that is not canonical, with the command to run. A file with a JSON syntax error is reported in `errors` with its file, line and column and skipped; fix it and run the command again.

## 7. Component cheat-sheet

This is a summary. `factoria api --md` (and the `docs_components` tool, which pages: `{"name":"Sprite"}` gives one component) has every field, its default and its range, generated from the engine, so it is always current.

**Core (every entity has these)**

| Component | Key fields | Typical use |
|---|---|---|
| `Transform` | `position` [x,y,z] (local to the parent), `rotation` [x,y,z] in degrees, `scale` | Where things are. |
| `EntityInfo` (not a component) | top-level `id`, `name`, `tags`, `active` | Identity. `active: false` disables an entity and its children. |

**2D**

| Component | Key fields | Typical use |
|---|---|---|
| `Camera` | `projection` (orthographic, perspective), `primary`, `clearColor`, `depth`, `clear`, `orthoSize` (0 = design height / 2), `viewport` ([x, y, w, h] of the game target, 0..1, top-left origin, default [0, 0, 1, 1]), `viewportSpace` (`screen` or `design`), `lighting` (`scene` or `studio`), `studioIntensity`, `fov`, `bloom` (bool, default off), `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` (default true), `colorFilter` (`none`, `greyscale`, `highContrast`, `protanopia`, `deuteranopia`, `tritanopia`), `renderTarget` (a name: the camera draws into the texture `"target:<name>"` instead of the screen), `renderTargetSize` ([w, h], 1..4096) | The view. Without a primary camera the screenshot is black. Every active camera with `primary: true` draws into its `viewport` in ascending `depth`: two or more make a split screen or an inset (section 9.29), and the lowest `depth` is the camera of the post effects, `camera.main` and the default of the screen conversions. `bloom: true` adds a glow around bright pixels; `bloomScreenSpace: false` keeps the screen-space HUD crisp (section 9.20). `colorFilter` is the players' accessibility filter (section 9.20.1). `lighting: "studio"` ignores the scene's lights and ambient and lights with a key, fill and rim of its own; with `primary: false` and a `CameraView` widget it is the 3D picture of an item inside a menu ([MENUS.md](../MENUS.md) "A camera inside the UI"). With `renderTarget: "book"` it draws live into a texture that `MeshRenderer.texture`, `Sprite.texture`, `Panel.texture` or `Button.icon` show as `"target:book"` (a screen on a model, a mirror, a page whose buttons work through the model; section 9.30). |
| `Sprite` | `texture` (asset path; empty = solid `color`), `size` (0 = image size), `pivot` (default [0.5, 0.5]), `color`, `flipX`, `flipY`, `layer`, `space`, `anchor`, `blend`, `region`, `pixelArt`, `skew`, `meshColumns` / `meshRows` / `vertexOffsets` / `vertexColors` | An image or a coloured quad. `skew` slants it, `meshColumns` x `meshRows` + `vertexOffsets` bend it (see "Tint, gradient stops, skew and bent sprites"). |
| `SpriteAnimator` | `clip` (a clip name of the sheet), `mode` (forward, reverse, pingpong), `columns`, `rows`, `firstFrame`, `lastFrame`, `fps`, `loop`, `loopMode` (inherit = the clip's own loop flag, loop, once), `playing` (needs a Sprite) | Frame-by-frame animation from a sprite sheet; play a clip by name (`entity.spriteAnimator.play("run")`, event `clipEnded`). |
| `Tint` | `color` (RGBA, multiplied into the entity and all its descendants) | Fade or colour a group at once: a day/night wash, a hit flash, a menu fading in. |
| `Video` | `path`, `autoplay`, `loop`, `volume`, `bus`, `fit`, `tint` + the UiBox fields; runtime `playing`, `time`, `duration`, `ended` | An `.mpg` (MPEG-1 + MP2) drawn in a UI rectangle with its sound; time follows the game clock. Script: `entity.video.play()`, `.seek(s)`, `.on("ended", fn)`. Bring any video with `assets.import` (needs ffmpeg). [ASSETS.md](../ASSETS.md) "Video", [MENUS.md](../MENUS.md) studio intro. |
| `Shape2D` | `shape` (rectangle, circle, line, triangle, diamond, polygon, star), `size`, `color`, `filled`, `thickness`, `layer`, `space`, `anchor`, `pivot` (default [0.5, 0.5]), `blend`, `sides`, `points`, `innerRadius`, `lit`, `cornerRadius`, `softness`, `gradient` (none, linear, radial), `color2`, `gradientAngle`, `gradientStops`, `gradientEase` | Placeholder art and UI panels. No assets needed. For a circle, `size[0]` is the diameter. A `triangle` points up (apex at the top-middle of its `size` box); a `diamond` is a rhombus whose 4 points touch the middles of the box edges (gems, enemies, markers); a `polygon` is a regular polygon with `sides` sides (default 6) and a `star` has `points` tips (default 5) with notches at `innerRadius` (0..1, default 0.5) of the outer radius, both inscribed in the `size` box with the first vertex up. Outlines (`filled: false`) of triangle, diamond, polygon and star grow inward, like the rectangle's. `pivot` is the point of the `size` box that sits on the position and that the entity rotates around: to spin a triangle without it wobbling use `pivot: [0.5, 0.3333]` (its centroid). Circles and diamonds already spin in place at the default pivot. |
| `Text` | `text` (`\n` breaks lines), `fontSize` (default 24), `color`, `align`, `pivot` (default [0, 1]), `maxWidth`, `layer` (default 100), `space`, `anchor`, `font` | Labels, scores and the HUD (`space: "screen"`). Shaped text: Arabic and Hebrew read right to left, `maxWidth` also wraps Chinese, Japanese and Korean without spaces. DejaVu Sans is the default font and has no CJK: ship a Noto font (`docs_read {"name":"text"}`). |
| `Tilemap` | `tileset`, `tileSize`, `width`, `height`, `tiles` (row 0 is the top row, -1 = empty; flat list with `width`/`height`, or an array of rows that the loader flattens; it is saved flat), `solidTiles`, optional `columns` (0 = derived from the tileset image), optional `margin` and `spacing` (pixels around and between the tiles of the tileset image, default 0), optional `projection` (`orthogonal`, or `isometric` for diamond tiles, section 9.8), `groundHeight` and `groundOffset` (isometric only) | A level from a grid, written together with its coins and enemies by `scene.import_ascii` (section 9.8). Solid tiles get collision. |
| `ParticleEmitter` | `emitting`, `rate`, `burst`, `autoDestroy`, `maxParticles`, `lifetime`, `speed`, `direction` (0 = right, 90 = up), `spread`, `gravity`, `startSize`, `endSize`, `startColor`, `endColor`, `blend`, `texture`, `layer`, `space`, `anchor`; richer effects: `colorGradient`, `sizeCurve`, `speedCurve`, `alphaCurve`, `flipbookColumns`/`flipbookRows`, `startRotation`, `spin`, `drag`, `noiseStrength`, `shape` (point, circle, box, cone, edge, mesh), `inheritVelocity`, `trail`, `subEmitters`, `collision` (plane, tilemap), `pixelMode` | Sparks, dust, smoke, fire and explosions (section 9.12; every new field is off by default, so a plain emitter is unchanged; `docs_read {"name":"particles"}`). `"space": "screen"` (plus `anchor`) draws them in the HUD pass in design pixels (origin top-left); `direction` and `gravity` keep their meaning (90 = up, negative `gravity` y falls down the screen). Ignored for `is3D`. |
| `Vfx` | `effect` (a `*.vfx.json`), `autoplay`, `playing`, `loop`, `autoDestroy`, `speed` | An effect document placed in a scene like a prefab: sparks, a flash, a sound and a shake on one timeline (section 9.12). Its emitters and lights become children; `vfx.play` makes one at a position with one call. |

`layer` is the draw order: higher layers draw on top. Inside one layer, items sort by the entity's `position.y` (the LOWER y is drawn on top, which is what a top-down or isometric scene wants: what stands nearer the viewer is lower on the screen), and items with the same y by creation order (later on top). A `Tilemap` is one item of that order: all its tiles are drawn together, row by row (see section 9.8, isometric maps), so put it on a lower `layer` than the sprites that stand on it. `space: "screen"` items ignore the camera (all of them: they are drawn once over the whole screen, after every camera).

**3D**

| Component | Key fields | Typical use |
|---|---|---|
| `MeshRenderer` | `mesh` (cube, sphere, plane, cylinder, capsule, cone, quad, a .glb/.gltf path, or the id `mesh:N` of a procedural mesh from `mesh.create`), `color`, `texture`, `normalMap`, `normalScale`, `metallic`, `roughness`, `emissive`, `emissiveStrength`, `unlit`, `castShadows`, `receiveShadows`, `uvScale`, `materialColors` | Visible 3D objects with a PBR material. Primitives need no assets. Unless `unlit`, it needs a light to look right. glTF models bring their own material (section 9.9). |
| `Animator` | `clip`, `speed`, `loop`, `playing`, `fade`, `events`, and a state machine: `params`, `states`, `transitions` | Plays the clips of a skinned glTF on the entity with the MeshRenderer, or (with `clips` and no `model`) the keyframed 2D clips `*.anim.json` that move the entity's child parts (`layers` with masks play more clips at once); blends between them, sends clip events, switches state from parameters. Script: `entity.animator.play("Run", 0.2)`, `.set("speed", 3)`. Section 9.25, [ANIMATION.md](../ANIMATION.md). |
| `Light` | `type` (directional, point, spot), `color`, `intensity`, `range`, `spotAngle`, `castShadows` (directional only) | Lighting and shadows. A directional light points along the entity's -Z axis after its rotation. Up to 32 lights are used per frame (section 9.9). |

**Physics**

| Component | Key fields | Typical use |
|---|---|---|
| `RigidBody2D` | `type` (static, dynamic, kinematic), `velocity` [x,y], `angularVelocity` (degrees/s), `gravityScale`, `fixedRotation`, `bullet`, `linearDamping`, `angularDamping` | Moves an entity under 2D physics. A static body never moves. |
| `Collider2D` | `shape` (box, circle, capsule), `size`, `radius`, `offset`, `isTrigger`, `enabled`, `oneWay`, `friction`, `restitution`, `density`, `layer` (0..31), `mask` (-1 = all layers) | Collision shape. With `isTrigger: true` it reports overlaps and does not block. With `enabled: false` it is switched off (queries pass through, no contacts), writable at run time. With `oneWay: true` it is a one-way platform (section 9.5). |
| `RigidBody3D` | `type`, `mass`, `velocity` [x,y,z], `angularVelocity` (degrees/s about x, y, z), `lockRotation`, `angularDamping`, `rollWithMotion`, `rollingFriction`, `gravityScale`, `linearDamping` | A simple 3D body. A dynamic **box** is a rigid body: collisions and friction turn it (it tips over a ledge, tumbles, settles on a face), so put `"lockRotation": true` on a character or a crate that must stay upright. A sphere is an arcade rolling ball by default (`rollWithMotion`, contacts never turn it); with `"rollWithMotion": false` it is a rigid body too and real friction rolls and spins it. Box colliders follow `Transform.rotation`. Fast bodies are swept against every solid collider, so they do not tunnel. |
| `Collider3D` | `shape` (box, sphere, capsule, convex, mesh, heightfield), `size`, `radius`, `height`, `mesh` (a model path or a procedural `mesh:N` id), `offset`, `isTrigger`, `enabled`, `friction`, `restitution`, `layer`, `mask` | 3D collision. Boxes are oriented: they follow the entity's world rotation (parents included). `size` and `offset` are scaled by `Transform.scale`, and `offset` is rotated with the entity. `capsule` is `radius` + `height` (tip to tip) along the entity's local Y. `convex` is the hull of `mesh`'s vertices; `mesh` uses its triangles and is for STATIC level geometry only (section 9.18). `heightfield` is the grid of the `Heightfield3D` on the same entity (static terrain only). `enabled: false` switches the collider off at run time (queries, contacts and the NavMesh bake ignore it; the component stays). `mesh` is a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or a .gltf/.glb path, usually the same as `MeshRenderer.mesh`. |
| `Heightfield3D` | `rows`, `columns` (samples, 2 to 4096), `cellSize` (meters between samples in x and z), `heightScale`, `heightOffset` (y = height * scale + offset), `heights` (rows * columns numbers, row by row from the lowest z, then x), `holes` (one 0 or 1 per cell, (rows - 1) * (columns - 1); 1 = no collision; empty = none) | The grid of heights of a 3D terrain collider: add it with a `Collider3D` of shape `heightfield` and no or a static `RigidBody3D` (a moving body cannot be terrain). The grid is centred on the entity and turns and scales with it; every cell is two triangles. Spheres, capsules, boxes and hulls rest, roll and sleep on it, raycasts, shape casts, overlaps and characters see it, a body falls through a hole cell, and the ground is solid 8 m deep: a body that ends up under the surface of a solid cell (the terrain was raised under it) is pushed back up if its lowest point is at most 8 m below it and the cell under its centre is not a hole. The arrays are plain JSON arrays on disk; a script edits it by assigning the array again (`terrain.heights = values`, a plain array or a `Float32Array`): the engine compares the new values with the old ones, so only the samples that differ count as changed, the physics updates only those cells and wakes only the sleeping bodies near them. Errors (wrong array length, a sample that is not a number) are reported once with the fix and the field has no collider until fixed. |
| `Joint3D` | `type` (hinge, ball, fixed), `connected` (entity id, empty = the world), `anchor`, `connectedAnchor`, `autoAnchor`, `axis`, `useLimits`, `lowerLimit`, `upperLimit` (degrees), `useMotor`, `motorSpeed` (degrees/s), `maxMotorTorque`, `collideConnected`, `damping`, `angle` and `stalled` (read-only) | Joins this entity's `RigidBody3D` to another body: doors, pendulums, wheels, ragdoll limbs, chains (section 9.18). Needs a `Collider3D` on the same entity. |
| `CharacterController3D` | `radius`, `height`, `center`, `stepOffset`, `slopeLimit` (degrees), `skin`, `layer`, `mask`, `velocity`, `carriedByPlatforms`, `applyWeight`, `mass`, `pushStrength`, `isGrounded` and `groundNormal` (read-only) | A walking capsule moved by `physics.moveCharacter` (section 9.18): slides along walls, climbs steps, refuses steep slopes, sticks to the ground going down, pushes crates. No `RigidBody3D` or `Collider3D` on the same entity. |

**UI (menus and settings screens; screen space only, section 9.22)**

| Component | Key fields | Typical use |
|---|---|---|
| `Panel` | `size`, `pivot`, `anchor`, `layer` (default 200), `color`, `texture` + `slice` (9-slice), `layout` (none, row, column, grid), `spacing`, `padding` [l,t,r,b], `columns`, `align`, `justify`, `fit` | A background that places its children in a column, row or grid. |
| `Button` | `text`, `size`, `autoFocus`, `interactable`, `font`, `fontSize`, `textColor`, `accentColor` + the style fields of Panel | Sends `ui.click`. |
| `Toggle` | `label`, `value` | Sends `ui.change` `{value: bool}`. |
| `Slider` | `label`, `value`, `min`, `max`, `step`, `showValue`, `format` (`"{percent}%"`) | Sends `ui.change` `{value: number}`; left / right change it by `step`. |
| `TextField` | `text`, `placeholder`, `maxLength` | Sends `ui.change` while typing and `ui.submit` on Enter. |
| `ScrollList` | `spacing`, `padding`, `scrollSpeed`, `scroll` | A column that scrolls with the wheel and clips its children. |
| `TouchStick` | `stick` (left, right), `knobColor`, `touchOnly` + the style fields of Panel (`safeArea` on by default); runtime `value`, `pressed`, `shown` | On-screen stick for phones: a finger moves that stick of a virtual pad, so actions bound to `GamepadLeftStick*` work by touch. Shown only while the player uses touch (`docs_read {"name":"mobile"}`). |
| `TouchButton` | `button` (`A`, `B`, `X`, `Y`, `Start`, `DpadUp`...), `text`, `font`, `fontSize`, `textColor`, `touchOnly` + the style fields of Panel; runtime `pressed`, `shown` | On-screen button for phones: holds that pad button, so actions bound to `GamepadA`... fire by touch. Test with `game.touchStart([x, y])` on it. |

**Audio and scripts**

| Component | Key fields | Typical use |
|---|---|---|
| `AudioSource` | `clip`, `volume` (0..1), `pitch`, `loop`, `playOnStart`, `spatial`, `range`, `playing` (runtime: set true to play) | A sound on an entity. Formats: .wav, .ogg, .mp3. |
| `AudioListener` | `volume`, `zoom` (scales how far spatial sounds are heard: 2 doubles the reach) | The "ears" for spatial sound. Without one, the first camera drawn listens (the primary camera with the lowest `depth`: player one's in a split screen). |
| `Script` | `path` (module), `props` (values that override the class fields), `enabled` | Attaches a Behaviour to the entity. |
