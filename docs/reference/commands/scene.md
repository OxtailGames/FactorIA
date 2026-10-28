[Back to the index](../README.md)

# Commands: scene

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

Loads immediately (outside a frame) or at the end of the current frame. Like scene.reload it first re-reads script modules and factoria.json input actions that changed on disk and clears script errors. Load problems are returned in `messages`. `props` (a JSON object) is handed to the new scene's scripts: game.sceneProps() returns it from their first start(). A reload (scene.reload, hot reload) keeps the props; a scene.load without props gives the scene none. Example: scene.load {"path":"scenes/level2.scene.json","props":{"difficulty":"hard"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative scene path. |
| `props` | object | no | Plain JSON the new scene's scripts read with game.sceneProps() (default: none, {}). |

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

Writes canonical scene JSON (only non-default fields, except settings.gravity2D and settings.gravity3D, which are always written so the file shows the gravity the level uses). Files inside .factoria/ belong to the engine and its tools: only the scratch folder .factoria/tmp/ may be written there (the same rule as fs.write and fs.delete). To change a scene FILE without touching the running world use scene.import_ascii with `path`. Example: scene.save {"path":"scenes/snapshot.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative output path. Default: the current scene. |

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

