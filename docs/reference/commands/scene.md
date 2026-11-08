[Back to the index](../README.md)

# Commands: scene

## `bones.create` (modifies state)

Since 0.7.0.

Create a chain of Bone2D entities along points, under a parent.

`points` are [x, y] positions in the PARENT's local space (at least 2); N points make N-1 bones. Bone 1 is a child of `parent`, placed at the first point and turned to face the second; every later bone is a child of the one before, placed at its tip, with the rotation that turns it toward the next point. Each Bone2D.length is the distance between its two points. `names` (N-1) names them, default prefix_1, prefix_2... (`prefix` default "bone"); two bones may not share a name under one parent, since clip paths and skins find them by name. Pose bones through Transform.rotation.z (clips, IK2D). Result: {parent, bones: [{id, name, length}]}. Example: bones.create {"parent":"hero","points":[[0,40],[0,20],[0,0]],"names":["thigh","shin"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `parent` | string | yes | Entity the first bone is a child of (id or name). |
| `points` | array | yes | Joint positions [x, y] in the parent's local space, from the root of the chain to its tip. |
| `names` | array | no | One name per bone (points - 1). |
| `prefix` | string | no | Name prefix when `names` is not given. Default "bone". |

## `load.cancel` (modifies state)

Not released yet (on main after 0.18.0).

Stop a background load, or drop the files a finished one read ahead.

A running load stops: what it decoded is thrown away, an async scene.load does not switch, and a script's handle rejects with "cancelled" in the next frame. A finished load's files read ahead are dropped now, and an async scene.load whose files were ready this frame does not switch at its end. Answers {id, cancelled}. Example: load.cancel {"id":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | The loadId to stop. |

## `load.status`

Not released yet (on main after 0.18.0).

Show the background loads: progress, items, bytes, errors.

With `id`: that load (from scene.preload, assets.preload, scene.load {async:true}, or a script's handle). Without: {jobs, threaded, warmBytes}, the loads that run and the last 16 that ended. A load is {id, kind, paths, origin (script|tool), state (scanning|loading|done|failed|cancelled), progress (0..1, never goes down), items {done, total} (the scan counts as one), bytes, uploadedBytes, error?, hint?}. `threaded` is false when the job pool has no worker thread: the files are then read on the main thread, a share per frame. Example: load.status {"id":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | integer | no | A loadId. Default: every running and recent load. |

## `prefab.save` (modifies state)

Save an entity of the running world, with its children, as a prefab file.

Writes {"format":"factoria.prefab/1","entity":{...}} in the canonical compact layout (the one scene.save and scene.format write), ready to commit and to instantiate with scene.spawn {"prefab":path}, a scene entity {"prefab":path} or a scene.import_ascii legend. `id` is the id (or name) of an entity of the running world; the whole tree below it is saved with every component's non-default serialized fields (runtime state such as velocities and animation time is not). A prefab describes the reusable thing, not this instance, so the file does NOT carry: the ids (every instantiation gets fresh ones; an id stays only where another entity of the saved tree points at it through an Entity field, so those references survive); the root's Transform.position (where the instance happens to stand: the spawn call, the scene entity or the legend places each new instance; children keep their positions relative to the root; rotation and scale are kept); tags starting with 'tilemap:' (scene.import_ascii adds them to the objects it places, and a prefab carrying one would be destroyed when that map is re-imported); Entity fields pointing at an entity outside the saved tree (they would dangle). An entity created from a prefab saves fully expanded (no `prefab` key). To keep the exact position, save the whole world with scene.save instead. `path` is project-relative (or absolute inside the project), must end in .prefab.json and normally lives in prefabs/. An existing file is NOT replaced unless `overwrite` is true. Returns {path, entity (id of the saved entity in the running world), children (number of saved descendants), overwritten, notes?}; `notes` lists what was left out of the file when something noteworthy was. Errors name the id with did-you-mean suggestions or the path rule with a corrected name. Example: prefab.save {"id":"enemy_3","path":"prefabs/enemy.prefab.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity to save; its children are saved with it. |
| `path` | string | yes | Project-relative output path ending in .prefab.json, e.g. prefabs/enemy.prefab.json. |
| `overwrite` | boolean | no | Replace the file when it already exists. Without it an existing file is an error. Default false. |

## `scene.ascii_edit` (modifies state)

Since 0.2.0.

Edit the ASCII map of a level file (a scene.import_ascii args file) with operations instead of rewriting rows, then rebuild the level.

`file` is a project-relative JSON file holding scene.import_ascii arguments (at least `rows`; its legend is `legend` merged over `legendFrom`). `ops` run in order, all-or-nothing (an error names the op, e.g. ops[2], and nothing is written). Columns and rows are 0-based, row 0 = TOP, like import_ascii. Ops: {op:'fill', rect:[col,row,w,h], glyph}; {op:'replace', from, to, rect?} (whole map without rect); {op:'insertColumns', at, count, glyph?} (without glyph the new columns repeat the column left of `at` (column 0 when at = 0) with every glyph that spawns an object turned into '.', so the ground continues and nothing is duplicated); {op:'deleteColumns', at, count}; {op:'put', col, glyph, row} or {op:'put', col, glyph, above:h} = h rows above the ground of that column (1 = standing on it; ground = the topmost cell whose glyph is a tile in the file's tilemap.solidTiles, else the Tilemap of the scene the file builds). A glyph that is not '.', ' ' or in the legend is refused with suggestions. The edited `rows` are written back to `file` (one row per line, every other key and the key order kept). With `rebuild` (default true) and a `path` in the file, the level is then rebuilt exactly like `factoria call scene.import_ascii @file` and its result is merged into this one (`spawned` lists id, glyph and cell [col,row] of every object). `dryRun` writes nothing and returns the edited `rows` (and the import's dry run). Returns {file (written unless dryRun), width, height, ops (applied), changedCells (cells whose glyph changed; inserted/deleted columns count all their cells), dryRun, rows? (dryRun)} plus the import result when it ran (its `path` and `saved` name the scene file). Example: scene.ascii_edit {"file":"levels/1-1.json","ops":[{"op":"put","col":40,"glyph":"o","above":1},{"op":"insertColumns","at":60,"count":5}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | yes | Project-relative JSON file with scene.import_ascii arguments (rows, legend/legendFrom, tilemap, path...). |
| `ops` | array | yes | Operations applied in order, all-or-nothing. fill {rect:[col,row,w,h], glyph}; replace {from, to, rect?}; insertColumns {at, count, glyph?}; deleteColumns {at, count}; put {col, glyph, row \| above}. 0-based, row 0 = top. |
| `rebuild` | boolean | no | Rebuild the level with scene.import_ascii on the edited file when it has a `path`. Default true. |
| `dryRun` | boolean | no | Write nothing; return the edited rows (and the import's dry run). Default false. |

## `scene.destroy` (modifies state)

Destroy an entity and its children.

Destruction is applied immediately when called outside a frame. Example: scene.destroy {"id":"coin_3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

## `scene.format` (modifies state)

Rewrite scene and prefab files in the canonical compact layout, without loading them.

Parses every *.scene.json and *.prefab.json file and writes it back exactly as the engine writes scenes (2-space indent, short arrays of numbers and strings on one line, long ones wrapped at about 100 columns, a Tilemap's `tiles` one map row per line). Run it after editing scenes or prefabs by hand so diffs stay small and the maps stay readable. Only whitespace changes: values and key order are kept, and every file is read back and compared with the original data before it is written. Nothing is loaded into the running world, so nothing else changes (files that already have the canonical layout are not touched). `paths` lists files (names ending in .scene.json or .prefab.json) or folders (searched recursively), project-relative; without `paths` the command writes NOTHING and fails (code paths_required) saying how many files would change and the first ones; `all` true formats the whole project (skipping folders that start with '.', node_modules and a top-level build/). With `check` true nothing is written: the files that are not canonical are listed (the whole project when `paths` is absent; use it in CI or to review). A file that is not valid JSON is reported in `errors` with its file, line and column and skipped; the other files are still processed. Returns {formatted: [paths], unchanged: n, errors: [{file, line?, column?, message, hint?}], notes?}, or with `check`: {notCanonical: [paths], unchanged: n, errors, notes?}. With `check` and `strict` the command FAILS (error code not_canonical, the message lists the files, the hint says to run scene.format without `check`) when any file is not canonical: `factoria call` exits non-zero, so a CI step can gate on it. project.validate lists the non-canonical ones in one informational note (not a warning). Example: scene.format {"paths":["prefabs"],"check":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | no | Scene/prefab files or folders (recursive), project-relative. Needed to write: without it (and without all or check) the command fails and writes nothing. |
| `all` | boolean | no | true = format every *.scene.json and *.prefab.json of the project (instead of paths). Writing the whole project always takes this or paths. Default false. |
| `check` | boolean | no | true = write nothing, only list (notCanonical) the files whose layout differs from the canonical one (the whole project when paths is absent). Default false. |
| `strict` | boolean | no | With check: fail with error code not_canonical when any file is not canonical, instead of only listing it. Ignored without check. Default false. |

## `scene.get_entity`

Get one entity with every component field (including defaults and runtime values).

Accepts the entity id or its name. Example: scene.get_entity {"id":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

## `scene.import_ascii` (modifies state)

Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a legend.

Author a tile level as text. `rows` is the map, one string per row, ONE CHARACTER PER TILE, row 0 = the TOP row (all rows the same length). `legend` maps each character to a tile index (integer) or to an object: {"tile"?: int, "prefab"?: "prefabs/x.prefab.json", "id"?: "player", "overrides"?: {component patches}, "offset"?: [dx, dy]}. '.' and ' ' are empty tiles unless the legend defines them. A glyph with a `tile` draws that tile; with a `prefab` it also spawns the prefab at the CENTRE of its cell (a glyph may have both; a prefab-only glyph leaves the tile empty). `overrides` patch the prefab's components per glyph; `offset` shifts the object (world units) from the cell centre. The tilemap is the entity `entity` (default "tilemap"): created when missing, updated when it exists; `tilemap` sets its Tilemap fields (tileset, tileSize, projection, groundHeight, groundOffset, margin, spacing, columns, solidTiles, color, layer; columns is optional: left at 0 it is derived from the tileset width, tileSize.x, margin and spacing). Its position is the map's TOP-LEFT corner (+Y up, like Tilemap everywhere; an isometric map's position is its TOP corner, and objects stand at the centres of its diamonds); pass `position` (+ `anchor`: top-left, bottom-left or center) to place it, e.g. anchor bottom-left at [0,0] puts the level's floor at y=0. Objects are ordinary top-level entities that save with the scene; ids are `id` from the legend (unique objects such as "player") or generated in row-major order as <prefab name>_<n> (coin_1, coin_2...); every object is tagged "tilemap:<entity>". With `replace` (default true) the objects of earlier imports into the same tilemap are destroyed first, so re-importing an edited map does not duplicate them. `legendFrom` names a JSON file with a legend shared by several maps (e.g. "levels/legend.json"); it is merged under `legend` (the map's own entry wins for a glyph) and its unused entries are not warned about. TWO WAYS TO USE IT. (1) With `path` it edits that scene FILE and nothing else: the file (or `from`, a base scene to start from; a missing `path` without `from` starts as an empty scene) is loaded into a scratch world, the map is imported into it and the result is written to `path` in the canonical layout of scene.save. The running world, audio, physics and scripts are not touched, so it is safe to call from a tool or a one-shot `factoria call` and the file can be rebuilt as often as needed. The file keeps PREFAB REFERENCES instead of expanding prefabs: each legend object is written as {"id", "prefab", "tags", "components": {the legend overrides + Transform.position}} and the prefab entries of the base scene stay as they are, so editing a prefab file changes every level without importing again and level files stay small (a scene loaded into the world still expands them). An entity that `edits` touches, or a base prefab entry without an `id`, is written expanded. `dryRun` writes nothing and returns the scene JSON in `scene`. `edits` (file mode only) patches components of that scene's entities right after the map is imported and before the write, e.g. the camera and sky colour of a base scene: {"<entity id>": {"<Component>": {field: value}}}, each entry exactly scene.set_component (a missing component is added, only the given fields change, and a value outside a field's range is refused; Script.props is replaced as a whole unless the edit has "$merge": true next to its fields, e.g. {"level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}, which merges the given props into the current ones as an RFC 7386 JSON merge-patch: other props stay, null deletes one); a wrong entity, component or field fails the call naming it, with suggestions, and writes nothing. If the file has load errors the call fails instead of dropping them. (2) Without `path` it changes the RUNNING world (like scene.spawn); `save` then also writes the current scene file like scene.save, so it needs a scene you chose (--scene or scene.load): when the running scene is only the project's mainScene loaded by default, `save` is refused (error unsafe_save) instead of overwriting it. With `path`, `save` is ignored: the file is always written. Nothing is changed when an argument is wrong: errors name the row/column, the glyph, the legend and suggestions. Returns {tilemap, created, width, height, tileCount, spawned:[{id, prefab, glyph, cell:[col,row], position:[x,y]}], removed, tag, warnings, notes?, saved?} plus, with `path`, {path, from (the file it started from, null = empty scene), entityCount, dryRun, scene? (dryRun)}. Example: scene.import_ascii {"rows":["..........","...o..o...",".P......o.","##########"],"legend":{"#":0,"o":{"prefab":"prefabs/coin.prefab.json"},"P":{"prefab":"prefabs/player.prefab.json","id":"player"}},"tilemap":{"tileset":"assets/tiles.png","tileSize":[32,32],"solidTiles":[0]},"anchor":"bottom-left","position":[0,0],"path":"scenes/level1.scene.json","from":"levels/base.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `rows` | array | yes | The map: one string per row, one character per tile, row 0 = TOP row, all rows the same length. |
| `legend` | object | no | Glyph -> tile index (integer, -1 = empty) or {tile?: int, rotate?: 0\|90\|180\|270 (clockwise), flipX?: bool, flipY?: bool, prefab?: 'prefabs/x.prefab.json', id?: 'player', overrides?: {Component: {fields}}, offset?: [dx, dy]}. '.' and ' ' mean empty unless defined here. |
| `legendFrom` | string | no | Project-relative JSON file with a SHARED legend (e.g. levels/legend.json: {"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}}), merged UNDER `legend`: the map's own entries win for the same glyph. Entries only the shared file defines are not warned about when unused. `legend` may then be omitted. |
| `tilemap` | object | no | Tilemap field values (tileset, tileSize, projection, groundHeight, groundOffset, margin, spacing, columns, solidTiles, color, layer) applied to the new or existing tilemap. The grid itself comes from rows/legend. |
| `entity` | string | no | Id of the tilemap entity: created if missing, updated if it exists. Default "tilemap". |
| `replace` | boolean | no | Destroy the objects spawned by earlier imports into this tilemap (tag tilemap:<entity>) first, so re-importing does not duplicate them. false keeps them. Default true. |
| `path` | string | no | File mode: project-relative scene file (e.g. scenes/level1.scene.json) to edit. It is loaded into a scratch world, the map is imported into it and it is written back; the running world is not touched. Does not exist yet (and no `from`): starts as an empty scene. Writable places only (not .factoria/ except .factoria/tmp/). |
| `from` | string | no | File mode (needs `path`): scene file to start from instead of `path`, e.g. a base scene with settings, camera and HUD but no map. `path` is then replaced by the result. Must exist. |
| `dryRun` | boolean | no | File mode (needs `path`): write nothing and return the resulting scene JSON in `scene`. Default false. |
| `edits` | object | no | File mode (needs `path`): {entity id: {Component: {field: value}}} applied to the scene after the map is imported and before it is written, each entry like scene.set_component (e.g. {"camera": {"Camera": {"clearColor": [0.5, 0.7, 0.9, 1]}}}). Add "$merge": true inside a component's entry to MERGE Script.props (RFC 7386: other props stay, null deletes a key) instead of replacing it: {"level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}. A wrong entity/component/field fails and nothing is written. |
| `save` | boolean | no | Running-world mode: also write the current scene file (like scene.save). Refused when the running scene is only the default mainScene (no --scene, no scene.load): pass `path` instead. Ignored when `path` is given. Default false. |
| `position` | array | no | [x, y] (or [x, y, z]) world position of the map's anchor point. Default: a new tilemap sits at [0,0] (its top-left corner); an existing one stays where it is. |
| `anchor` | string ["top-left","bottom-left","center"] | no | Which point of the map is placed at `position` (assumes an unrotated map). Default top-left, the Tilemap entity's own origin. |

## `scene.list_entities`

List entities (id, name, tags, components) with optional filters.

Filters: name (substring, case-insensitive), tag (exact), component (name). limit defaults to 100. Use scene.get_entity for full data. Example: scene.list_entities {"tag":"enemy","limit":20}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Substring of the entity name or id. |
| `tag` | string | no | Only entities having this tag. |
| `component` | string | no | Only entities having this component, e.g. RigidBody2D. |
| `limit` | integer | no | Maximum entities returned. Default 100. |

## `scene.load` (modifies state)

Replace the running scene with a scene file.

Loads immediately (outside a frame) or at the end of the current frame. Like scene.reload it first re-reads script modules and factoria.json input actions that changed on disk and clears script errors. Load problems are returned in `messages`. `props` (a JSON object) is handed to the new scene's scripts: game.sceneProps() returns it from their first start(). A reload (scene.reload, hot reload) keeps the props; a scene.load without props gives the scene none. `async`: true reads the scene's files in the background first (docs/PERFORMANCE.md, "Background loading") and answers at once with `loadId`; the switch happens at the end of the frame the files are ready, in the frames the game runs (load.status shows the progress, load.cancel stops it). A later scene.load replaces it. Example: scene.load {"path":"scenes/level2.scene.json","props":{"difficulty":"hard"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative scene path. |
| `props` | object | no | Plain JSON the new scene's scripts read with game.sceneProps() (default: none, {}). |
| `async` | boolean | no | Read the scene's files in the background and switch once they are ready (answers {async, loadId} at once). Default false: load now (or at the end of the frame). Default false. |

## `scene.preload` (modifies state)

Not released yet (on main after 0.18.0).

Read a scene's files in the background, so a later scene.load waits for nothing.

Starts a background load of the scene file and everything it uses (prefabs, materials, scripts, models, textures, fonts, sounds): the IO thread reads them and jobs decode them while frames run; each frame the main thread uploads a share to the GPU (docs/PERFORMANCE.md, "Background loading"). Answers at once with `loadId` and the load's status; it advances in the frames the game runs (game.step, play.auto, a running window). The files stay ready until the second scene load after the preload finished (load.cancel drops them earlier). A missing scene is an error with "did you mean". Example: scene.preload {"path":"scenes/level2.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative scene path, e.g. scenes/level2.scene.json. |

## `scene.reload` (modifies state)

Reload the current scene from disk (discards runtime changes).

Resets the world to the saved scene file. Also re-reads what changed on disk: script modules (and the modules importing them), factoria.json input actions, fixedHz, deadzone and ui.scale; script errors are cleared. Example: scene.reload {}

## `scene.remove_component` (modifies state)

Remove a component from an entity.

Transform and EntityInfo cannot be removed. Example: scene.remove_component {"id":"player","component":"Script"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes |  |
| `component` | string | yes |  |

## `scene.save` (modifies state)

Save the running world to a scene file (current scene path by default).

Writes canonical scene JSON (only non-default fields, except settings.gravity2D and settings.gravity3D, which are always written so the file shows the gravity the level uses). Files inside .factoria/ belong to the engine and its tools: only the scratch folder .factoria/tmp/ may be written there (the same rule as fs.write and fs.delete). To change a scene FILE without touching the running world use scene.import_ascii with `path`. Example: scene.save {"path":"scenes/snapshot.scene.json"}. Entities a script created at runtime (world.spawn, world.spawnPrefab) and their children are NOT written: the script builds them again when the scene loads, so saving them would duplicate them. The result lists them under `skippedSpawned` (count, first ids) with a hint; pass includeSpawned:true only to bake them into the file on purpose (then the script must not spawn them again). Entities made with scene.spawn, the editor or other authoring commands are always saved.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative output path. Default: the current scene. |
| `includeSpawned` | boolean | no | Also write the entities scripts spawned at runtime (world.spawn / world.spawnPrefab) and their children. Default false: they are left out, because the script spawns them again on load. Default false. |

## `scene.set_component` (modifies state)

Add a component to an entity (if missing) and set the given fields.

`fields` is a partial object; unspecified fields keep their value. A value outside a field's range (see api.components) is refused, and a bad field changes nothing: errors name the field, the allowed values and the range. A field with free-form JSON content (Script.props) is REPLACED as a whole by default; with `merge` true `fields` is an RFC 7386 JSON merge-patch instead: an object for such a field is merged into the current one recursively (keys you do not mention stay, a null value deletes the key), and a null for any other field resets it to its default. Example: scene.set_component {"id":"player","component":"Sprite","fields":{"color":"red"}}; change one prop and keep the rest: scene.set_component {"id":"level","component":"Script","fields":{"props":{"levelIndex":3,"oldProp":null}},"merge":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |
| `component` | string | yes | Component name, e.g. Transform, Sprite, RigidBody2D. |
| `fields` | object | no | Field name -> value. |
| `merge` | boolean | no | true = read `fields` as an RFC 7386 JSON merge-patch: objects (Script.props) merge into the current value recursively, null deletes a key (or resets a plain field to its default). false = every given field is replaced as a whole. Default false. |

## `scene.set_parent` (modifies state)

Since 0.2.0.

Move an entity under another entity, or to the top level of the scene.

`parent` null or "" makes it a root. By default (`keepWorldTransform` true) the entity stays where it is on screen: its local Transform is recomputed for the new parent; with false the local Transform is kept, so the entity moves with the new parent. The entity becomes the LAST child of its new parent unless `index` says where: 0 = first; it counts the new parent's other children, so moving within the same parent works (index 0 on the last child makes it first); an index below 0 or above the number of other children is refused, and `index` needs a parent (top-level order is creation order). Scene files keep the order. A parent that is the entity itself or one of its children is refused (a cycle). Example: scene.set_parent {"id":"coin_3","parent":"chest"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name) to move. |
| `parent` | any | no | New parent's id (or name); null or empty = top level. |
| `keepWorldTransform` | boolean | no | true = keep the world position, rotation and scale (the local Transform changes); false = keep the local Transform. Default true. |
| `index` | integer | no | Place among the new parent's other children (0 = first). Omitted = last. Needs a parent. |

## `scene.spawn` (modifies state)

Create an entity from entity JSON, or instantiate a prefab at a position.

Either pass entity JSON ({name, id?, tags?, components:{...}}) or {prefab, position?}. Optional parent id. Returns the created entity (with defaults) plus load messages. Example: scene.spawn {"name":"Coin","components":{"Transform":{"position":[100,50,0]},"Shape2D":{"shape":"circle","size":[20,20],"color":"gold"}}}  or  scene.spawn {"prefab":"prefabs/enemy.prefab.json","position":[300,0]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `prefab` | string | no | Project-relative prefab path to instantiate. |
| `position` | array | no | [x, y] or [x, y, z] world position (Transform.position). |
| `entity` | object | no | Entity JSON; alternatively put its fields (name, components...) at top level. |
| `parent` | string | no | Parent entity id. |
| `index` | integer | no | Place among the parent's children (0 = first, up to their count). Omitted = last. Needs parent. |
| `overrides` | object | no | With prefab: patches for the prefab's children, keyed by child id, name or path (see docs/MENUS.md). |
| `name` | string | no |  |
| `id` | string | no |  |
| `tags` | array | no |  |
| `components` | object | no | Component name -> field object. |

## `skin.auto_weights` (modifies state)

Since 0.7.0.

Write the skin's automatic weights out as explicit ones, to paint over with skin.set_weights.

Computes what SpriteSkin.weights "auto" would give every vertex of the full mesh grid (each vertex follows its nearest bones, up to 4) and stores it in SpriteSkin.weights as [boneIndex, weight, ...] per vertex, row-major from the top row (vertex = row * (columns + 1) + column). The picture does not change. The skin must be bound (skin.bind). Result: {entity, vertices, columns, rows, bones}. Example: skin.auto_weights {"entity":"leg"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The skinned Sprite entity (id or name). |

## `skin.bind` (modifies state)

Since 0.7.0.

Skin a Sprite to bones: add the SpriteSkin, name its bones and bind it at the pose they have now.

Adds a SpriteSkin to the Sprite entity `entity` if it has none, sets its bones and records the bind pose (skin_bind): the sprite looks the same until a bone moves from where it is now. Name the bones with `bones` (ids or names, the order is the weight order) or give `root`, a bone: it and every Bone2D below it, depth first. `mesh` [columns, rows] sets Sprite.meshColumns / meshRows (a skin needs a mesh grid, or SpriteSkin.outline). The weights stay as they are ("auto" by default; skin.auto_weights writes them out to paint). Result: {entity, bones: [ids], mesh: [columns, rows] | null, note?}. Example: skin.bind {"entity":"leg","root":"thigh","mesh":[4,8]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The Sprite entity to skin (id or name). |
| `bones` | array | no | Bone ids or names, in weight order. |
| `root` | string | no | A bone: use it and all the Bone2D entities below it. |
| `mesh` | array | no | [columns, rows] of the Sprite's mesh grid. |

## `skin.set_weights` (modifies state)

Since 0.7.0.

Paint the bone weights of chosen vertices: set, add or smooth.

`vertices` are grid vertex numbers (row * (columns + 1) + column, row 0 on top), "all", or {"rect": [x0, y0, x1, y1]} (every vertex inside that rectangle of the sprite's local space, +Y up). `bone` is a bone index in SpriteSkin.bones or its name. Modes: `set` gives the bone `weight` (0..1) and scales the vertex's other bones to fill the rest; `add` adds `weight` (negative removes) to the bone's weight; `smooth` moves every weight `weight` (default 0.5, 0..1) of the way toward the average of the vertex's grid neighbours (`bone` is not needed). Afterwards each vertex keeps its 4 heaviest bones, weights under 0.001 dropped, summing to 1. Automatic weights are written out first when the skin still says "auto". Result: {entity, changed, mode}. Example: skin.set_weights {"entity":"leg","vertices":{"rect":[-8,0,8,12]},"bone":"thigh","weight":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The skinned Sprite entity (id or name). |
| `vertices` | any | yes | Array of vertex numbers, "all", or {"rect": [x0, y0, x1, y1]} in the sprite's local space. |
| `bone` | any | no | Bone index in SpriteSkin.bones, or the bone's name or id. Not needed for smooth. |
| `weight` | number | no | set: the new weight 0..1. add: the amount to add (may be negative). smooth: how far toward the neighbours' average, 0..1 (default 0.5). |
| `mode` | string ["set","add","smooth"] | no | How the weight is applied. Default "set". |

## `tilemap.cell_at`

Since 0.3.0.

The cell of a Tilemap under a world point (orthogonal squares or isometric diamonds).

Returns {id, col, row, inside, tile} for the Tilemap on entity `id`: the cell that contains the world point (`x`, `y`), by the entity's world transform (position, rotation, scale) and the map's `projection`. `inside` is false when the cell lies outside the map (col and row are then still the cell numbers the point falls in, so negative or past the edge) and `tile` is -1. Pair it with `camera.screenToWorld` to pick the cell under the mouse; the script form is `entity.tilemap.cellAt(point)`. Example: tilemap.cell_at {"id":"ground","x":120,"y":-80}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |
| `x` | number | yes | World x. |
| `y` | number | yes | World y (+Y up). |

## `tilemap.cell_to_world`

Since 0.3.0.

The world position of the centre of a Tilemap cell (orthogonal squares or isometric diamonds).

Returns {id, col, row, x, y} for the Tilemap on entity `id`: the world position of the centre of cell (`col`, `row`) (0-based, row 0 = TOP row), by the entity's world transform and the map's `projection`. The cell may lie outside the map. It is the inverse of tilemap.cell_at for the cell's centre; the script form is `entity.tilemap.cellToWorld(col, row)`. Example: tilemap.cell_to_world {"id":"ground","col":3,"row":4}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |
| `col` | integer | yes | Tile column, 0 = leftmost. |
| `row` | integer | yes | Tile row, 0 = TOP row. |

## `tilemap.generate` (modifies state)

Since 0.17.0.

Generate a level from an example with Wave Function Collapse: a grid that only contains the patterns of the sample.

Learns from a small example level and makes a new, bigger one that looks like it, the same on every machine for the same arguments. `sample` is the example: the id of an entity with a Tilemap, ASCII rows (an array of strings, or a string with line breaks) with a `legend` in the format of scene.import_ascii (glyph -> tile index or {tile?, prefab?...}; '.' and ' ' are empty), an object {rows, legend?, legendFrom?}, or the path of a JSON file holding one. `size` is the output in cells ([width, height], {width, height} or one number). MODELS: `overlapping` (default) learns every n x n window of the sample (n 2..5, default 3) and fills the output cell by cell, always the one with the fewest options left, so every n x n window of the result also exists in the sample (with `symmetry` also in its rotations and mirrors); a bigger n copies larger pieces, a smaller n mixes more freely. `tiled` ignores n and symmetry (they are not even checked) and reads which tiles may touch from the autotile rules (Tilemap.terrains, tilemap.set_terrains, image.tileset.build) of the sample's Tilemap, of `into`, or from `terrains`; the sample only sets how often each tile is picked, and blob47 corners are fixed afterwards like tilemap.retile. Without rules it fails and says how to add them. `symmetry` 1 (default) uses the sample as drawn, 2 adds its mirror image, 4 its three turns, 8 turns and mirrors (use it for floors and walls, not for tiles that point somewhere). `periodic` true makes the output wrap around its edges (a tileable level) and, unless `periodicInput` says otherwise, also lets the sample wrap. `seed` (default 0) picks the level: same sample, seed and arguments, same level, on every platform. A dead end (a cell with no pattern left) restarts with the next derived seed, up to `maxAttempts` (default 10, 50 with `constraints` or `reachability`); when all fail the error says where, and what to try (a bigger or more varied sample, a smaller n, symmetry, periodic). Output: with `into` (the id of an entity with a Tilemap) the grid is written there (tileset, tileSize and solidTiles stay) in the RUNNING world; without it the grid comes back as `rows` + `legend`, ready for scene.import_ascii, and with `rows` true it comes back as well when `into` is given. Glyphs of an ASCII sample that spawn prefabs come back as the same glyph in `rows`; `into` writes only their tiles, so build objects with scene.import_ascii. A Tilemap sample is printed with generated glyphs ('.' = empty). CONSTRAINTS (`constraints`, checked before generating; each problem names its JSON pointer): `fixed` [{at:[x,y] | rect:[x,y,w,h], tile}] pins cells (an entrance, an exit), `border` {tile, thickness?} walls in the edge, `forbidden` [tile] never appear, `required` [tile] appear at least once, `counts` [{tile, min?, max?}], `place` [{tile, count?, where?, from?, on?}]. A `tile` is a glyph of an ASCII sample, a tile number (-1 = empty) or, for the tiled model, a terrain name; a list of them means any of them. A tile the sample never shows cannot be fixed, counted or forbidden. A missing minimum is repaired on the next attempt by pinning cells (positions drawn from the seed; `constraints.repair` false turns that off). A MAXIMUM STEERS THE SOLVER: once that many cells are decided to hold the tile, it is taken out of every cell still open, so a tile the sample draws once (an entrance '@', an exit '>') does not turn up two to four times and refuse attempt after attempt; a grid that is over a maximum anyway is refused and restarted, and so is any other miss. PLACE puts markers in the FINISHED level: {tile:'>', where:'farthest', from:'@', on:['.']} writes the exit on the floor cell with the longest WALKING distance from the entrance (`where`: farthest, nearest or random; `count` cells; the walk is the one `reachability` describes, so farthest / nearest need it). Entries run in order, so "entrance anywhere, exit farthest from it" is two entries (the second names the first's tile in `from`). The tile may be a legend glyph the sample rows never draw (then the solver never produces it and only `place` can: the usual way to get exactly one entrance and one exit); `on` says which tiles a marker may replace (left out: any walkable cell, never a fixed cell or an earlier marker). Every choice (random cells, ties) comes from the level's seed. An entry that finds too few cells refuses the attempt and the next seed is tried; the result's constraints.placed lists the cells (and distances). The counts and the reachability check judge the grid AFTER it is placed, so a marker that blocks the way is caught. (Not the script API's top-level `place`, which places the objects of the sample.) REACHABILITY (`reachability`): {from:[x,y], to:[x,y] | [[x,y]...], toTiles:[tile] (every cell holding one is a goal), allConnected:true (all walkable cells form one area), solidTiles:[tile numbers that block] (default: those of `into` or of the sample), costs:{tile: cost|null}, diagonals}. It uses the rules of nav.find_tile_path, on the finished level (`solidTiles` and `costs` are the final tile numbers, after the tiled model's blob47 corners are fixed; `counts` and `toTiles` look at the cells as the generator decided them, before that re-tiling); a grid that fails restarts with the next derived seed, so the level you get is playable. The report lists walkable cells, the cells and areas that were cut off (a few rects) and the path length to each goal. Everything derives from `seed`, never the clock. LIMITS: `maxWork` (default 600000000 units of work over all attempts, counted the same on every machine: it is what decides whether a level is too big) and `maxSeconds` (default 1800, a pure safety net far above the work cap: CPU seconds of the whole process counting every thread; on the web build wall-clock seconds) stop a level that cannot be solved with a teaching error. Returns {model, width, height, seed, rows?, legend, counts: {glyph: cells}, into?, warnings?, sample: {source, width, height}, constraints?: {fixedCells, forbiddenTiles, counts: [{tile, found, min?, max?}], pinnedCells, placed?: [{tile, where, count, at:[[x,y]...], distances?, from?}]}, reachability?, stats: {attempts, contradictions, rejected, patterns, cells, observations, propagations, work, pinned, ms, memoryBytes, peakBytes}}. The level and the counters (attempts, work...) are the same on every machine; stats.ms (the time it took), memoryBytes and peakBytes (bytes: they depend on the compiler and standard library) are not part of the determinism promise. Limits: output sides up to 2048, sample up to 262144 cells, 20000 patterns, about 256 MB of solver memory (checked first, before anything is built for the constraints; the error says what to shrink), 65536 fixed cells. An argument name that is not listed is refused with the valid ones (`place` belongs to the script API's tilemap.generate, which places the objects of the sample; with this command call scene.import_ascii on the returned rows and legend). Example: tilemap.generate {"sample":["........","..##....","..##..#.","......#.","..#.....","........"],"legend":{"#":0},"size":[32,20],"seed":7,"n":3,"symmetry":8,"constraints":{"border":{"tile":"#"},"fixed":[{"at":[1,1],"tile":"."}]},"reachability":{"from":[1,1],"allConnected":true,"solidTiles":[0]}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `sample` | any | no | The example to learn from: the id of an entity with a Tilemap; ASCII rows (array of strings, or one string with line breaks) with `legend`; an object {rows, legend?, legendFrom?} (scene.import_ascii arguments); or a project-relative .json file with such an object. Required for model overlapping; for tiled it only sets the tile frequencies. |
| `legend` | object | no | Glyph -> tile index or {tile?, rotate?, flipX?, flipY?, prefab?...}, as in scene.import_ascii; for ASCII rows given as an array or text. '.' and ' ' are empty unless defined here. |
| `legendFrom` | string | no | Project-relative JSON file with a shared legend (see scene.import_ascii), merged under `legend`. |
| `size` | any | yes | Output size in cells: [width, height], {width, height} or one number for a square. Each side 1..2048 (and at least n for overlapping). |
| `seed` | integer | no | Picks the level. The same sample, seed and arguments always give the same level. Each restart after a dead end uses the next derived seed. Default 0. |
| `model` | string ["overlapping","tiled"] | no | overlapping: learn the n x n patterns of the sample. tiled: tile adjacency from the autotile rules (Tilemap.terrains). Default "overlapping". |
| `n` | integer | no | Overlapping model: side of the learned windows, 2..5 (checked only for the overlapping model). Bigger copies larger pieces of the sample; smaller mixes more. Ignored by tiled (not even checked). Default 3. |
| `symmetry` | integer | no | One of 1, 2, 4, 8 (checked only for the overlapping model). 1 = the sample as drawn, 2 = also mirrored left-right, 4 = also turned 90/180/270 degrees, 8 = turned and mirrored. Only for tiles that look the same turned (floor, wall); overlapping model; ignored by tiled. Default 1. |
| `periodic` | boolean | no | The output wraps around its edges (a tileable level). Also lets the sample wrap unless periodicInput is given. Default false. |
| `periodicInput` | boolean | no | The sample wraps around its edges (patterns cross them). Default: the value of `periodic`. |
| `maxAttempts` | integer | no | Attempts before giving up: a dead end (or a grid that breaks a constraint or is not reachable) restarts with the next derived seed. When `constraints` or `reachability` is given and this is left out, 50 attempts are made instead of the default, because those refuse many grids. Default 10. |
| `maxWork` | integer | no | Cap on the work (stats.work of an earlier run shows what a level needs: pattern removals and the adjacency they touch, cells observed, the fixed cells and the reachability check) over all attempts. It counts the same on every machine, so a level either always fits or never does. Hit it and the call fails with how to shrink the level or raise the cap. Default 600000000. |
| `maxSeconds` | number | no | Pure safety net on the CPU seconds the process may spend on this call (all threads count; the web build counts wall-clock seconds), about a hundred times what the default maxWork takes. The cap a result depends on is maxWork: this one only stops a machine that is stuck or far slower than any expected. Default 1800. |
| `constraints` | object | no | Rules the level must follow. A tile is a glyph of an ASCII sample, a tile number (-1 = empty) or a terrain name (tiled); a list = any of them. Contradictions are reported before generating, with the JSON pointer. |
| `reachability` | object | no | The level must be playable. Same walking rules as nav.find_tile_path (the rules are the same code): 4-way, or 8-way without cutting corners, entering a tile costs its cost. A grid that fails restarts with the next derived seed. The result's `reachability` reports unreachable cells and areas and the path lengths. |
| `into` | string | no | Id of an entity with a Tilemap to write the result into (its tiles, width and height are replaced; tileset, tileSize and solidTiles stay). RUNNING world only. |
| `rows` | boolean | no | Return the level as ASCII `rows`. Default: true without `into`, false with it. |
| `terrains` | array | no | Tiled model: autotile rules to use instead of the Tilemap's own (same objects as Tilemap.terrains). |

## `tilemap.generate_cancel` (modifies state)

Since 0.17.0.

Drop a generation started with tilemap.generate_start and free its memory.

Idempotent: an unknown job (finished, failed, already cancelled, or dropped by a scene load) answers {cancelled:false}. Example: tilemap.generate_cancel {"job":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `job` | integer | yes | The job tilemap.generate_start returned. |

## `tilemap.generate_start` (modifies state)

Since 0.17.0.

Check the arguments of tilemap.generate and start a generation that you advance yourself with tilemap.generate_step.

Takes exactly the arguments of tilemap.generate, checks them at once (the same errors, before anything is generated) and returns {job, width, height, seed, cells, patterns, memoryBytes} without generating. The sample is read and its pattern model is BUILT in this call (the cost of the sample, not of the level: milliseconds for a small one, longer for a 512 x 512 sample with n 5 and symmetry 8), so call it at a loading point or from a tool, not in the middle of a busy frame; everything after it, the solve included, is paced by tilemap.generate_step. Then call tilemap.generate_step {job} until it answers done: its `result` is what tilemap.generate returns, and `into` is written at that moment, not before. The level does not depend on how the steps are cut: any `work` or `budgetMs` gives the same level and the same stats.work for the same arguments. A job belongs to the scene that started it (a scene load drops it) and holds its solver memory until it finishes, fails or is cancelled; at most 8 run at once and their memory adds up under the same 256 MB limit. Scripts do not need this: `tilemap.generate(...)` in a Behaviour starts the job, advances it every frame within a budget and places the objects of the sample. Example: tilemap.generate_start {"sample":["#####","#...#","#####"],"legend":{"#":0},"size":[16,12],"seed":3}

| Argument | Type | Required | Description |
|---|---|---|---|
| `sample` | any | no | The example to learn from: the id of an entity with a Tilemap; ASCII rows (array of strings, or one string with line breaks) with `legend`; an object {rows, legend?, legendFrom?} (scene.import_ascii arguments); or a project-relative .json file with such an object. Required for model overlapping; for tiled it only sets the tile frequencies. |
| `legend` | object | no | Glyph -> tile index or {tile?, rotate?, flipX?, flipY?, prefab?...}, as in scene.import_ascii; for ASCII rows given as an array or text. '.' and ' ' are empty unless defined here. |
| `legendFrom` | string | no | Project-relative JSON file with a shared legend (see scene.import_ascii), merged under `legend`. |
| `size` | any | yes | Output size in cells: [width, height], {width, height} or one number for a square. Each side 1..2048 (and at least n for overlapping). |
| `seed` | integer | no | Picks the level. The same sample, seed and arguments always give the same level. Each restart after a dead end uses the next derived seed. Default 0. |
| `model` | string ["overlapping","tiled"] | no | overlapping: learn the n x n patterns of the sample. tiled: tile adjacency from the autotile rules (Tilemap.terrains). Default "overlapping". |
| `n` | integer | no | Overlapping model: side of the learned windows, 2..5 (checked only for the overlapping model). Bigger copies larger pieces of the sample; smaller mixes more. Ignored by tiled (not even checked). Default 3. |
| `symmetry` | integer | no | One of 1, 2, 4, 8 (checked only for the overlapping model). 1 = the sample as drawn, 2 = also mirrored left-right, 4 = also turned 90/180/270 degrees, 8 = turned and mirrored. Only for tiles that look the same turned (floor, wall); overlapping model; ignored by tiled. Default 1. |
| `periodic` | boolean | no | The output wraps around its edges (a tileable level). Also lets the sample wrap unless periodicInput is given. Default false. |
| `periodicInput` | boolean | no | The sample wraps around its edges (patterns cross them). Default: the value of `periodic`. |
| `maxAttempts` | integer | no | Attempts before giving up: a dead end (or a grid that breaks a constraint or is not reachable) restarts with the next derived seed. When `constraints` or `reachability` is given and this is left out, 50 attempts are made instead of the default, because those refuse many grids. Default 10. |
| `maxWork` | integer | no | Cap on the work (stats.work of an earlier run shows what a level needs: pattern removals and the adjacency they touch, cells observed, the fixed cells and the reachability check) over all attempts. It counts the same on every machine, so a level either always fits or never does. Hit it and the call fails with how to shrink the level or raise the cap. Default 600000000. |
| `maxSeconds` | number | no | Pure safety net on the CPU seconds the process may spend on this call (all threads count; the web build counts wall-clock seconds), about a hundred times what the default maxWork takes. The cap a result depends on is maxWork: this one only stops a machine that is stuck or far slower than any expected. Default 1800. |
| `constraints` | object | no | Rules the level must follow. A tile is a glyph of an ASCII sample, a tile number (-1 = empty) or a terrain name (tiled); a list = any of them. Contradictions are reported before generating, with the JSON pointer. |
| `reachability` | object | no | The level must be playable. Same walking rules as nav.find_tile_path (the rules are the same code): 4-way, or 8-way without cutting corners, entering a tile costs its cost. A grid that fails restarts with the next derived seed. The result's `reachability` reports unreachable cells and areas and the path lengths. |
| `into` | string | no | Id of an entity with a Tilemap to write the result into (its tiles, width and height are replaced; tileset, tileSize and solidTiles stay). RUNNING world only. |
| `rows` | boolean | no | Return the level as ASCII `rows`. Default: true without `into`, false with it. |
| `terrains` | array | no | Tiled model: autotile rules to use instead of the Tilemap's own (same objects as Tilemap.terrains). |

## `tilemap.generate_step` (modifies state)

Since 0.17.0.

Advance a generation started with tilemap.generate_start by a bounded amount of work.

Does at most `work` units of work (default 500000, about 10 ms of a Debug build; the same unit as stats.work) or, with `budgetMs`, steps until that many milliseconds have passed (at least one step). Returns {done:false, progress, attempts, work, contradictions, rejected} while it runs (progress 0..1 follows the solver: inside an attempt it is the share of cells decided, scaled into that attempt's part of the bar (the first attempt covers 0 to 0.8, each retry a quarter of what is left), so it moves while the solver works and never goes down when an attempt restarts; it is 1 only when done) and {done:true, progress:1, result} when the level is finished, `result` being what tilemap.generate returns. A step can overshoot its budget by one unit of the algorithm: an attempt (its reset, the solve, the output, the counts and the reachability check) advances in chunks of about 16384 units, so a step stays near its budget. Three pieces are not cut and run to their end inside one step: the rebuild of the entropy heap when it is at its allowance (a pass over at most 4 entries per cell), the re-tiling of a terrain (Tiled) level by the reachability check (one pass over the grid) and each path search of the reachability check (one A* bounded by the grid, at most 16 per attempt). Errors (the generation failed, hit `maxWork`, the entity of `into` is gone) end the job. A job whose scene was unloaded no longer exists. Example: tilemap.generate_step {"job":1,"work":200000}

| Argument | Type | Required | Description |
|---|---|---|---|
| `job` | integer | yes | The job tilemap.generate_start returned. |
| `work` | integer | no | Units of work to do in this call (stats.work counts the same units). Default 500000. |
| `budgetMs` | number | no | Instead of `work`: step until this many milliseconds have passed (at least one step). How far a job gets in a call then depends on the machine, never the level. |

## `tilemap.paint_terrain` (modifies state)

Since 0.16.0.

Paint (or erase) a terrain on a Tilemap's cells and re-tile the cells around them with its autotile rules.

Sets the cells to the terrain `terrain` of the Tilemap on entity `id` (rules in Tilemap.terrains) and re-tiles them and the 8 cells around each one, so the edge, corner and inside tiles line up: paint a lake and the shore appears. Name the cells with `cells` ([[col, row], ...], row 0 = TOP row) and/or `rect` ({col, row, width, height}). `erase` true empties the cells instead (-1) and re-tiles what was next to them. Cells outside the map are skipped and counted in `outside`. Only cells that already belong to a terrain are re-tiled: tiles you placed by hand stay. A terrain cell's tile is picked from the terrain's variations by column, row and seed, so the same painting always looks the same. Changes the RUNNING world only (scene.save keeps it); the script form is `entity.tilemap.paintTerrain(terrain, cells)`. Returns {id, painted, outside, changed, changes: [{col, row, from, to}] (the first 200), changesTruncated}. Example: tilemap.paint_terrain {"id":"map","terrain":"grass","rect":{"col":2,"row":2,"width":5,"height":3}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |
| `terrain` | string | yes | Name of a terrain in Tilemap.terrains. |
| `cells` | array | no | Cells to paint: [col, row] pairs (or {col, row} objects), row 0 = TOP row. |
| `rect` | object | no | A block of cells to paint: {col, row, width, height}. |
| `erase` | boolean | no | Empty the cells (-1) instead of painting the terrain, and re-tile their neighbours. Default false. |

## `tilemap.retile` (modifies state)

Since 0.16.0.

Re-tile every terrain cell of a Tilemap from its neighbours.

Recomputes the tile of every cell that belongs to a terrain of the Tilemap on entity `id` from the cells around it, with the terrain's rules (Tilemap.terrains). Use it after writing `tiles` by hand, after tilemap.set_terrains with new rules, or after resizing the map. Cells that belong to no terrain are not touched. Changes the RUNNING world only. Returns {id, changed, changes (the first 200), changesTruncated}. Example: tilemap.retile {"id":"map"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |

## `tilemap.set_terrains` (modifies state)

Since 0.16.0.

Set a Tilemap's autotile rules from a list or a rules file (as image.tileset.build writes them).

Replaces Tilemap.terrains of the entity `id` with `terrains` (an array of terrain objects) or with the `terrains` of the rules file `path` (a JSON file {"format": "factoria.terrains/1", "terrains": [...]}, such as the .terrains.json that image.tileset.build writes next to the tileset). The rules are checked first: a bad rule changes nothing and the error names its JSON pointer and the fix. `retile` true also re-tiles the map with the new rules. Changes the RUNNING world only (scene.save keeps it). Returns {id, terrains: [names], retiled}. Example: tilemap.set_terrains {"id":"map","path":"assets/art/ground.terrains.json","retile":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |
| `terrains` | array | no | Terrain objects: {name, mode: basic16\|blob47, first \| tiles, seed?, joins?, outside?}. See the Tilemap component's `terrains` field. |
| `path` | string | no | Project-relative path of a rules file ({format, terrains}). Instead of `terrains`. |
| `retile` | boolean | no | Re-tile every terrain cell with the new rules. Default false. |

## `tilemap.set_tile` (modifies state)

Since 0.3.0.

Change one tile of a Tilemap in the running scene, in place.

Writes tile `tile` (a tileset index plus optional flip flags, or -1 for empty) at column `col`, row `row` of the Tilemap on entity `id` (0-based, row 0 = TOP row). Only that element of `tiles` changes: the array is not rewritten, the renderer reads it directly and 2D physics rebuilds only the colliders of the changed tiles on the next step. This is the command form of `entity.tilemap.setTile(col, row, tile)` in scripts. It changes the RUNNING world only (not the scene file; use scene.save to keep it, scene.import_ascii to rebuild a level file). A cell outside the map or a value that is not a tile is refused and nothing changes. Returns {id, col, row, tile, previous}. Example: tilemap.set_tile {"id":"map","col":12,"row":7,"tile":-1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |
| `col` | integer | yes | Tile column, 0 = leftmost. |
| `row` | integer | yes | Tile row, 0 = TOP row. |
| `tile` | integer | yes | Tileset index (plus optional flip flags, see Tilemap.tiles), or -1 to empty the cell. |

## `tilemap.terrains`

Since 0.16.0.

The autotile rules of a Tilemap: its terrains, their slots and how many cells belong to each.

Reads Tilemap.terrains of the entity `id` and returns {id, valid, issues, terrains: [{name, mode, seed, tiles (the count), slots: [{slot, mask, tiles}], cells (how many map cells belong to it)}]}. `mask` is the neighbour mask the slot draws (N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128). `issues` lists every problem of the rules with its JSON pointer and the fix. Example: tilemap.terrains {"id":"map"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity that has the Tilemap. |

