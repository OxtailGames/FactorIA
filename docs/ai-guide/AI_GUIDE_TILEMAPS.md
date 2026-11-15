# AI guide: tilemap levels

Part of [AI guide](../AI_GUIDE.md): recipe 9.8, tilemap levels, objects and tile collision.

### 9.8 Tilemap levels, objects and tile collision

Author a tile level as ASCII art with the command `scene.import_ascii` (MCP `scene_import_ascii`; an authoring command of the editor, `factoria call` and MCP: an exported game does not have it, a game builds levels at play time with `tilemap.generate` and `place`, which uses `scene.place_ascii`). It writes the `Tilemap` and spawns the coins, enemies and spawn points that stand on it, at the right place. Do not compute tile positions by hand and do not write a level generator script: to make MORE levels that look like one you drew, use `tilemap.generate` (below).

```
factoria call scene.import_ascii @level1.json          # args in a file; or MCP scene_import_ascii {...}
```

```json
{
  "rows": [
    "..........",
    "...o..o...",
    "..........",
    ".P......o.",
    "##########",
    "%%%%%%%%%%"
  ],
  "legend": {
    "#": 0,
    "%": 1,
    "o": { "prefab": "prefabs/coin.prefab.json" },
    "P": { "prefab": "prefabs/player.prefab.json", "id": "player" }
  },
  "tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32], "solidTiles": [0, 1] },
  "anchor": "bottom-left",
  "position": [0, 0],
  "path": "scenes/level1.scene.json"
}
```

- `rows` is the map: one string per row, ONE CHARACTER PER TILE, all rows the same length, row 0 is the TOP row. `.` and a space are empty tiles unless the legend defines them.
- `legend` maps each character to a tile index (an integer, `-1` = empty) or to an object `{"tile"?, "flipX"?, "flipY"?, "rotate"?, "prefab"?, "id"?, "overrides"?, "offset"?}`. A glyph with a `tile` draws that tile (`flipX`, `flipY` and `rotate` 0/90/180/270 clockwise turn it, section 9.26). A glyph with a `prefab` spawns that prefab at the CENTRE of its cell (a glyph may have both). `overrides` patches the prefab's components for that glyph (`{"Script": {"props": {"speed": 60}}}`), and `offset` `[dx, dy]` shifts the object from the cell centre in world units (a 96 px flag that must stand on the ground, for instance).
- `legendFrom` (optional) is a project-relative JSON file with a legend shared by several maps, e.g. `"legendFrom": "levels/legend.json"` holding `{"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}}` (or `{"legend": {...}}`). It is merged UNDER the map's own `legend`: the map wins for a glyph both define, and `legend` may be left out. Entries that only the shared file defines are never reported as unused; the map's own unused entries still are.
- `tilemap` holds the Tilemap fields for a new tilemap (`tileset`, `tileSize`, `projection`, `groundHeight`, `groundOffset`, `margin`, `spacing`, `columns`, `solidTiles`, `color`, `layer`). You do not need `columns`: left at 0 (the default) it is derived from the tileset image, as many whole tiles of `tileSize[0]` as fit across it. Pass it only for an image with another layout. If an earlier import set `columns` explicitly and you now change `tileset` or `tileSize` without `columns`, it goes back to 0 (the result says so in `notes`). The grid (`tiles`, `width`, `height`) always comes from `rows`.
- `entity` (default `"tilemap"`) is the id of the Tilemap entity: created when missing, updated when it exists. Use another id for a second layer, such as a background.
- `position` and `anchor` (`top-left`, `bottom-left` or `center`) place the map: `anchor` says which point of the map sits at `position`. With `bottom-left` at `[0, 0]` the level's floor starts at y = 0. Without them a new tilemap has its top-left corner at the origin, and an existing one stays where it is.
- Objects are ordinary top-level entities, saved with the scene. Give unique objects an `id` in the legend (`"id": "player"`). Other objects get ids from the prefab file name in row-major order: `coin_1`, `coin_2`, `crawler_1`. Every object carries the tag `tilemap:<entity>` (for example `tilemap:tilemap`).
- Re-import after editing the map: with `replace` (default `true`) the objects of earlier imports into the same tilemap are destroyed first, so nothing is duplicated and the ids stay stable. `replace: false` keeps them.
- `path` is the scene FILE to build (see "Edit a scene file, not the running game" below). It is the normal way to use the command.
- `save: true` (only without `path`) also writes the current scene file, so one call is enough. It is refused when the running scene is just the project's `mainScene` that was loaded because nobody chose a scene (see below).
- The result lists the `spawned` objects (`id`, `prefab`, `cell: [col, row]`, `position`), the `removed` ids, the number of non-empty tiles (`tileCount`) and `warnings` (a legend glyph that is never used, no tileset, no `solidTiles`).
- Errors name the row and column, the glyph and the legend, with a "did you mean": ragged rows, an unknown glyph, a legend value that is not an integer or an object, a missing prefab, a duplicate fixed `id`, a tile index outside the tileset. A failed import changes nothing.

Change one tile of a running level with `entity.tilemap.setTile(col, row, id)` / `getTile(col, row)` in a script, or the command `tilemap.set_tile` (`{"id":"map","col":3,"row":5,"tile":-1}`); do not rewrite the whole `tiles` array for one tile. 2D physics rebuilds only the colliders that changed. A tileset image with a border or gutters needs `margin` and `spacing` on the `Tilemap`; `assets.slice_sheet` does not take them.

**Autotile terrains.** Do not choose the edge tiles of a coast or a wall by hand. Make the tileset from a few parts with `image.tileset.build` (the 16 or 47 tiles of the set, a baked PNG and a rules file, `docs.read IMAGES`, section "Tiles"), set `Tilemap.tileset` to that PNG, `tileSize` to the tile size and load the rules with `tilemap.set_terrains {"id":"map","path":"assets/art/ground.terrains.json"}` (they are saved in the scene as `Tilemap.terrains`). Then `tilemap.paint_terrain {"id":"map","terrain":"ground","cells":[[3,4],[4,4]]}` (script: `entity.tilemap.paintTerrain("ground", [[3, 4], [4, 4]])`) sets cells to the terrain and re-tiles them and the 8 cells around them; `erase: true` empties cells and re-tiles what was next to them. Only cells that already belong to a terrain are re-tiled, so hand-placed tiles stay. `tilemap.terrains {"id":"map"}` shows the terrains with their slots and how many cells belong to each, and reports a wrong rule with its JSON pointer.

Run `project_validate`, then take a screenshot to check the picture: the tiles, the coins and the player must line up.

**Edit a scene file, not the running game (`path`, `from`, `dryRun`).** Without `path` the command changes the RUNNING world, like `scene.spawn`. That is the right tool in the editor or in a play-test, but a poor one for building level files: `scene.load` and `scene.save` act on the running world too, and loading a scene stops the audio and resets the physics. Give the command a `path` and it works on the file instead:

```
factoria call scene.import_ascii @levels/level1.json       # level1.json carries "path": "scenes/level1.scene.json"
```

- `path` (project-relative, e.g. `scenes/level1.scene.json`) is the scene file to edit. The file is loaded into a scratch world that the engine throws away, the map is imported into it, and the result is written back to `path` in the same layout as `scene_save` (compact `tiles` rows, the gravity always in `settings`, stable key order, so a diff shows what changed). The running world, its scene, the audio, the physics and the scripts are not touched, and nothing is reloaded, so it is safe to call from a project tool, from a script or while a game is running. If the running scene is that file and hot reload is on (windowed play), the game reloads it from disk like after any other edit of the file.
- `from` (needs `path`) is a scene file to START from instead of `path`. A generator uses it to build `path` from a base scene that has the settings, camera, HUD and level script but no map (`"from": "levels/base.scene.json"`); `path` is then replaced. `from` must exist (the error suggests close scene names).
- A `path` that does not exist yet and no `from`: the scene starts empty (default settings, no camera) and is created. That makes a new level one call; the result says so in `notes`. If `path` looks like a typo of an existing scene (`scenes/mian.scene.json`), `warnings` says "Did you mean 'scenes/main.scene.json'?" after creating it. Pass `from` to build on an existing scene.
- `dryRun: true` (needs `path`) writes nothing and returns the resulting scene in `scene`, for a preview or a test. The same call without `dryRun` writes exactly that scene.
- `edits` (needs `path`) patches components of the scene's entities after the map is imported and before the file is written: `{"<entity id>": {"<Component>": {field: value}}}`. Each entry is exactly `scene_set_component` (a component the entity lacks is added, only the given fields change, a value outside a field's range is refused, `Script.props` is replaced as a whole, so pass all the props, unless the entry has `"$merge": true`: then `props` is merged into the current props as an RFC 7386 JSON merge-patch, keys you do not mention stay and `null` deletes one). It is how a generator tunes the base scene it starts from (`"edits": {"camera": {"Camera": {"clearColor": [0.5, 0.7, 0.95, 1]}}, "level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}`: the level number changes, the base scene's other props such as `killY` stay, and the generator never reads the base scene) without writing a patched copy of the base scene first. It also reaches the entities the import placed. A wrong entity, component or field fails the call, names `edits["<id>"]["<Component>"]` with suggestions, and nothing is written. Without `path` use `scene_set_component` on the running world; `edits` is refused there.
- **What the file contains.** The written scene keeps PREFAB REFERENCES instead of expanding prefabs: each legend object is `{"id": "coin_1", "prefab": "prefabs/coin.prefab.json", "tags": ["coin", "tilemap:tilemap"], "components": {"Transform": {"position": [...]}, ...the glyph's overrides}}`, and the prefab entities of the `from` scene stay exactly as written there. Editing a prefab file then changes every level the next time it loads, with no import in between, and level files stay small. A scene loaded into the world still expands them (only the file is shorter). An entity that `edits` touches is written as its prefab plus the differences (the edit). `scene_format` and `project_validate` treat the new files like any other scene.
- The result has the usual keys plus `path`, `from` (the file it started from, `null` for an empty scene), `entityCount`, `dryRun` and `saved` (the file written, absent in a dry run).
- Everything else behaves as in the running world: `replace` removes the objects of the earlier import from the scene, ids are checked against every entity of the file (a fixed `id` that the file already uses is an error), the tileset is read for the range check. A failed import writes nothing, and a start file that has load errors (an unknown component, a bad value) is refused instead of being rewritten with those entries silently dropped. `save` is ignored when `path` is given.
- `path` is written like any file written by a command: not into `.factoria/` except `.factoria/tmp/` (see "Scratch files" below), and not outside the project.

**The safe workflow for a level.** Keep the map in a JSON file (`levels/level1.json`) with `"path": "scenes/level1.scene.json"` and rebuild it with `factoria call scene.import_ascii @levels/level1.json` from the project folder. No `--scene`, no `scene_load`, no `scene_save`. Without `path` the same file with `"save": true` would, on a `factoria call` without `--scene`, rewrite the project's main scene with the wrong map. The engine therefore refuses `save` without `path` while the running scene is only the default `mainScene` (nobody passed `--scene` or called `scene.load`, and it is not the editor): the error `unsafe_save` names the file it would have overwritten and says to add `path`, or to choose the scene first on purpose (`--scene scenes/main.scene.json`). When `save` is allowed, the result's `notes` say `SAVED '<file>'` and that it is the running scene.

**Scratch files (`.factoria/tmp/`).** `.factoria/` holds what the engine and its tools produce (screenshots, save games, AI transcripts, editor state); `scene_save`, `scene_import_ascii` with `path`, `fs_write`, `fs_edit` and `fs_delete` refuse to write or delete there, with one exception that all of them share: `.factoria/tmp/` is a scratch folder where files can be created, overwritten and deleted (for example a test's output). `fs_list` and `fs_search` hide `.factoria/` but show a `path` inside `.factoria/tmp`. It is not committed.

The map's world rectangle is `world.find("map").bounds()` (`{ x, y, w, h }`, bottom-left corner and size): use it for camera limits, kill planes and spawn areas instead of repeating `columns * tileSize` in props (section 9.6).

What the command writes is a plain `Tilemap` component. A `Tilemap` draws a grid from a tileset image. Row 0 is the TOP row, and `-1` is an empty tile. The entity's position is the top-left corner of the map, with +Y up. Tile (col, row) covers x from `px + col*tw` to `px + (col+1)*tw` and y from `py - (row+1)*th` to `py - row*th`, so its centre is `(px + (col+0.5)*tw, py - (row+0.5)*th)`.

`entity.tilemap.cellAt([x, y])` gives the cell under a world point (`{col, row}`, or `null` outside the map) and `entity.tilemap.cellToWorld(col, row)` the world position of a cell's centre; the commands `tilemap.cell_at` and `tilemap.cell_to_world` do the same from outside a script. They follow the entity's position, rotation and scale and the projection, so picking a cell under the mouse is `map.tilemap.cellAt(input.mouse.world)`.

**Isometric maps.** `"projection": "isometric"` draws diamond tiles for a 2:1 city, farm or strategy map, still as one batched mesh. `tileSize` is the size of one tile IMAGE (it may be taller than the diamond: a block, a tree, a house). The diamond itself is `tileSize.x` wide and `groundHeight` tall (0 = `tileSize.y`), and its top corner is `groundOffset` pixels below the top edge of the image. The entity's position is the TOP corner of cell (0, 0); `+col` runs down and to the right and `+row` down and to the left, so cell (c, r) has its centre at `(px + (c - r) * tileSize.x / 2, py - (c + r + 1) * groundHeight / 2)`. Cells are drawn row by row from row 0, left to right, so a tile taller than its diamond overlaps the cells behind it, never the ones in front. Colliders (`solidTiles`), `occludesLight` shadows and `nav.findTilePath` follow the diamonds: a solid cell is a diamond, and a tile path moves between the cell centres. The editor outlines and picks the map by the diamond that holds all its cells. Sprites cannot sit between the rows of a Tilemap: draw the ground as a Tilemap on a low `layer` and the buildings or characters as sprites on a higher one.

```json
{
  "id": "level",
  "name": "Level",
  "components": {
    "Transform": { "position": [-640, 360, 0] },
    "Tilemap": {
      "tileset": "assets/tiles.png",
      "tileSize": [32, 32],
      "width": 6,
      "height": 3,
      "tiles": [
        -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1,
         0,  1,  1,  1,  0,  2
      ],
      "solidTiles": [0, 1, 2]
    }
  }
}
```

The flat `tiles` array has `width * height` entries. `tiles` may also be written as an array of rows (`[[-1, 0, 1], [2, 2, 2]]`); then the rows define the size and `width`/`height` are not needed: the loader turns the rows into the flat list and sets `width`/`height` from them, and the engine always saves the flat form. In a script `tilemapComponent.tiles` is a flat `Int32Array` COPY (`comp.tiles[i] = x` changes nothing; write `const t = comp.tiles; ...; comp.tiles = t`). The renderer and the 2D collision read the same grid, so what is drawn is exactly what collides. A flat list without `width` is read as ONE row (validation warns). When the engine saves a scene or prefab (`scene_save`, `save: true`, the editor), it writes a flat `tiles` one map row per line with aligned columns, as in the example above, so the file shows the map and a diff shows which row changed. The same writer puts short arrays (`position`, `color`, `tags`, `solidTiles`) on one line and wraps long number lists at about 100 columns. This is plain JSON, so you can keep that layout when you edit a scene by hand, but nothing depends on it; run `scene_format` (section 6) after a hand edit and it puts the map rows and the arrays back in that layout. The tileset image holds tiles of `tileSize`, laid out left to right and top to bottom. `columns` (tiles per image row) is optional: leave it out and it is derived from the image width divided by `tileSize[0]`, so tile 3 of a 4-tile-wide image is the 4th tile of the first row. Set it only for a layout that does not follow the image width. Validation reports a missing tileset, a `tiles` list that does not match `width * height` (or rows of different lengths, or strings instead of integers), and tile indices outside the tileset image.

How tiles collide (verified against the physics rules):

- Every tile index in `solidTiles` becomes part of one static body per Tilemap. Horizontal runs in a row are merged, and identical runs in consecutive rows are merged too.
- Tile shapes are on layer 0, with friction 0.5 and no bounce. They are not triggers, so tiles raise no trigger events, and they are not one-way.
- Tile indices that are not in `solidTiles` are drawn but never block.
- Merging can leave seams between boxes of different heights. A character with friction can catch on a seam when it slides along a wall. Give characters `friction: 0` against walls, or use a circle or capsule foot.
- Tiles cannot carry behaviour. Coins, enemies and spawn points are entities spawned by `scene.import_ascii` from the legend (above).

**Editing a map without rewriting rows.** When the level lives in an args file (`levels/1-1.json`), change it with `scene.ascii_edit` (MCP `scene_ascii_edit`) instead of counting characters in a 300-column row. `ops` run in order, all-or-nothing (an error names the op, `ops[2]`, and writes nothing); columns and rows count from 0, row 0 = top:

```
factoria call scene.ascii_edit '{"file":"levels/1-1.json","ops":[
  {"op":"put","col":40,"glyph":"o","above":1},
  {"op":"fill","rect":[10,20,4,1],"glyph":"#"},
  {"op":"replace","from":"o","to":".","rect":[100,0,30,23]},
  {"op":"insertColumns","at":60,"count":5},
  {"op":"deleteColumns","at":200,"count":3}]}'
```

`put` takes `row` (absolute) or `above` (cells above the ground of that column, 1 = standing on it; ground = the topmost tile listed in the file's `tilemap.solidTiles`, else the Tilemap of the scene the file builds). `insertColumns` without `glyph` repeats the column left of `at` with every object glyph turned into `.`. The file keeps its other keys and order, with one row per line. When the file has a `path` the level is rebuilt like `scene.import_ascii @file` (`rebuild: false` skips it) and the result lists every object with its glyph and `cell`; `dryRun` writes nothing and returns the edited `rows`.

**A level from an example (`tilemap.generate`).** Draw one small level you like and let the engine make a new, bigger one that is made only of its patterns (Wave Function Collapse, the same result on every machine for the same arguments). `sample` is the example: the id of an entity with a Tilemap, or ASCII `rows` with a `legend` in the format of `scene.import_ascii`; `size` is the output in cells:

```
factoria call tilemap.generate '{"sample":["........","..##....","..##..#.","......#.","..#.....","........"],
  "legend":{"#":0},"size":[32,20],"seed":7,"n":3,"symmetry":8}'
```

It answers with `rows` and `legend` (hand them to `scene.import_ascii`, with the objects of your legend if you want them placed) and `stats` (`attempts`, `contradictions`, `rejected`, `patterns`, `work`, `ms`...). Everything in `stats` except `ms`, `memoryBytes` and `peakBytes` is the same on every machine; `ms` is the time it took on this one and the two byte counts are of this build's containers, so they can differ. With `"into":"map"` the grid is written into the Tilemap of that entity in the RUNNING world instead (add `"rows":true` to get the rows too). Rules of thumb:

- `n` (2..5, default 3) is the size of the pieces copied from the sample: a bigger `n` repeats larger shapes of the example, a smaller `n` mixes them more freely and may produce layouts the sample never showed. The output contains no window of `n` x `n` cells that is not in the sample (or in its rotations and mirrors with `symmetry`). Only the overlapping model reads `n` and `symmetry`; the tiled model ignores both, so they are not even checked there.
- `symmetry` 1 uses the sample as drawn; 2 adds its mirror image; 4 its turns; 8 turns and mirrors. Use 8 for floors and walls that look the same from any side, and 1 for anything that points somewhere (stairs, lamps, a "ground is down" platformer).
- `periodic: true` makes the output wrap around its edges (a tileable level) and lets the sample wrap too (`periodicInput`).
- `model: "tiled"` does not learn from a picture: it reads which tiles may touch from the autotile rules (`Tilemap.terrains`, `tilemap.set_terrains`, `image.tileset.build`) of the sample's Tilemap, of `into`, or from `terrains` in the call, and the sample only weighs how often each tile is picked. Without rules it fails and says how to add them.
- `seed` picks the level (same arguments, same level). A dead end (a cell with no pattern left) restarts with the next derived seed up to `maxAttempts` (default 10, 50 with `constraints` or `reachability`); if all attempts fail, the error says at which cell, after how many attempts, and what to try: a bigger or more varied sample, a smaller `n`, `symmetry` 2, 4 or 8, `periodic`. Very small, very regular samples (a room with one pillar) cannot grow into a big level: draw a sample with some variety.
- Limits: output sides up to 2048, samples up to 262144 cells and 20000 distinct patterns, about 256 MB of solver memory (an upper bound of what the solver holds, checked before anything else is built, so a huge size fails at once; the error says what size fits) and 65536 fixed cells (`fixed` rects and `border` count cell by cell). `maxWork` (default 600000000 units of work over all attempts; `stats.work` of an earlier run shows what a level needs) is the cap a result depends on: it counts the same on every machine, so a level either always fits or never does, and it includes the cost of the fixed cells and of the reachability check. `maxSeconds` (default 1800, at most 86400) is only a safety net on the CPU seconds of the process (every thread counts; the web build counts wall-clock seconds). Both stop a level that cannot be solved with an error (`budget_exceeded`) that gives the sizes and says how to shrink it or how to raise the cap.
- Glyphs of the legend that spawn prefabs come back as the same glyph in `rows`; `into` writes only the tiles (a warning says so), so build the objects with `scene.import_ascii`.

**A playable generated level (`constraints`, `reachability`).** WFC copies local patterns; it does not know a level needs an entrance, an exit and a treasure you can walk to. Say it in the call. `constraints` pins and counts tiles, `reachability` checks the walk. A tile is a glyph of the sample (`"#"`), a tile number (`3`, `-1` = empty) or, for the tiled model, a terrain name; a list means any of them. The generator only places what the sample shows: draw the treasure and the enemy in the sample once, in the middle of it (a tile drawn only on the sample's right or bottom edge cannot be placed inside a bigger level).

```
factoria call tilemap.generate '{"sample":["################","#..............#","#..##......#...#","#..##...##.#...#",
    "#......####....#","#..#...........#","#..#....$..##..#","#.......#..##..#","#...##..#......#","#...##....E....#",
    "#..............#","################"],
  "legend":{"#":0,".":1,"$":2,"E":3},"size":[24,16],"seed":2,
  "constraints":{"border":{"tile":"#"},
                 "fixed":[{"at":[1,1],"tile":"."},{"at":[22,14],"tile":"."}],
                 "required":["$"], "counts":[{"tile":"E","max":2}]},
  "reachability":{"from":[1,1],"to":[[22,14]],"toTiles":["$"],"solidTiles":[0]}}'
```

The entrance (1,1) and the exit (22,14) are floor, the level is walled in, a treasure exists, there are at most 2 enemies, and the exit and every treasure can be walked to from the entrance. The answer adds `constraints` (`fixedCells`, and per count the `found` number) and `reachability`: `{from, walkableCells, reachableCells, unreachable: {cells, areas, largest: [{cells, rect:[x,y,w,h], at}]}, goals, paths: [{to, steps, cost}]}` (`unreachableGoals` lists the goals that could not be reached, but a level that is returned has none). Rules:

- `constraints.fixed` is `{"at":[x,y],"tile":T}` or `{"rect":[x,y,w,h],"tile":T}` (x is the column, y the row, 0 = top-left); `border` is `{"tile":T,"thickness":1}` and an explicit `fixed` cell wins over it; `forbidden` is a list of tiles that never appear; `required` is a list of tiles that appear at least once; `counts` is `[{"tile":T,"min":a,"max":b}]`: a `max` steers the solver (once a tile has `max` cells, it is taken out of what the other cells may become, and that is propagated, so the generator stops before the cap instead of refusing the finished grid; `max: 1` on a tile the sample draws many times just works); `place` is `[{"tile":T,"count":1,"where":"farthest"|"nearest"|"random","from":T2,"on":[tiles]}]`, markers put on the finished grid (see below). A rect or border longer than the sample's own straight pieces may be impossible: when every attempt dead-ends, the error says where.
- Contradictions are found before anything is generated and name the entry: `/constraints/fixed/1: the cell (3, 3) is fixed to ... and to ...`, `/constraints/required/0: ... is also forbidden at /constraints/forbidden/0`, a tile that is not in the sample, a cell outside the level, `min` above `max`, minimums that do not fit in the level, a `reachability` start on a cell fixed to a wall (unless `costs` makes that tile walkable, as `nav.find_tile_path` reads it), `required` against a `max: 0` of the same tile, minimums and maximums of tiles that share symbols (also against the fixed cells), and a fixed cell or border tile that the sample can only show in other places or only next to a tile you forbade. When something only shows up while generating, the error names the fixed cell or border entry near it, and the hint says what to loosen (forbidden tiles, pins, fixed cells). Path `cost`s in the `reachability` report are rounded to 3 decimals.
- `reachability.from` + `to` (one cell or a list) + `toTiles` (every cell holding one of those tiles must be reachable) or `allConnected: true` (all walkable cells form one area; with no `from` the biggest area is the reference). `solidTiles` are the tile numbers that block; by default those of the `into` Tilemap, then of the sample (`tilemap.solidTiles` of ASCII rows), and with none it fails and says to add them. `costs` and `diagonals` are the same as in `nav.find_tile_path`, and the walk is the same one (a diagonal never cuts a corner), so `nav.find_tile_path` on the Tilemap you wrote with `into` finds the path the report lists. The tiled model is checked after its blob47 corners are fixed, so `solidTiles` and `costs` are the final tile numbers; `counts` and `toTiles` look at the cells as the generator decided them, before that re-tiling (for the tiled model, name the terrain or the tile of the rules, not a corner variant).
- **`constraints.place`: the entrance, the exit, the boss.** Each entry puts `count` (default 1) cells of `tile` (one glyph or tile number) on the finished level, in the order of the list. It replaces only cells whose tile is in `on`; without `on` any walkable cell of `reachability` qualifies (so one of the two is needed). Cells fixed by `constraints.fixed` or `border`, and cells an earlier entry placed, are never replaced. `where` picks the cells: `"farthest"` / `"nearest"` by the walking distance `reachability` measures (its `solidTiles`, `costs` and `diagonals`), from `from` (a tile: the distance is to the nearest cell holding it, e.g. the entrance an earlier entry placed; without it, `reachability.from`), or `"random"` (the default: drawn from the seed; when the level has a walk start, only cells that can be walked to from it qualify, and without `reachability` any cell of `on`). A tie is broken by the seed too, so the same call gives the same level. The tile does not have to be drawn in the sample: a glyph that is only in `legend` (a marker such as `@` or `>` with a `prefab`) is accepted in `place` (as `tile`, and as `from` / `on` once an earlier entry has placed it) and nowhere else, and the generator never copies it. The markers go on before the counts and the reachability check, so those judge the finished level: an exit on a cell the entrance cannot walk to is refused and the next seed is tried. The answer lists what was put in `constraints.placed` (per entry: `tile`, `where`, `count`, `at` the cells as `[x, y]`, `distances` and `from` when a walk was measured). A mistake that can be seen before generating (a tile that is not in the sample or legend, `from` or `farthest` without `reachability`, `count` above the cells of the level, an unknown key, `from` naming the tile being placed) is an error that names `/constraints/place/N` with a did-you-mean; a level with no room left for the entry fails that attempt and the next seed is tried. (The script API's `tilemap.generate` has its own `place` option that builds entities: it is one level up from `constraints`.)
- A grid that breaks a rule is refused and the next derived seed is tried, so the level you get is playable; a missing minimum is also repaired by pinning cells at positions drawn from the seed (`constraints.repair: false` turns that off and leaves a missed minimum to the retries; a `max` is never repaired: the solver stops the tile at its cap while it works and the finished grid is checked again, and refused when a max is still over, for example when fixed cells and forced neighbours already hold more cells than the cap). The `stats` show the effort (`attempts`, `rejected`, `pinned`). If every attempt fails the error says why (for example "no route from the start (1, 1) to 1 of 2 goal cell(s)") and what to try: fewer constraints, a bigger sample, more `maxAttempts`.
- Everything is deterministic: the retries derive from `seed`, never from the clock.

**A new level on every run (script `tilemap.generate`).** A game that wants a different level each time it starts calls `tilemap.generate(options)` from a script. The options are those of the command plus `place`; the seed comes from `rng.create`, so a stored `runSeed` rebuilds the same level and the clock is never used. The call checks the arguments at once (a mistake throws with its JSON pointer and a hint) and returns a handle; the generator then works a little every frame, so the game keeps running and a phone does not stall:

```js
export default class LevelLoader extends Behaviour {
    runSeed = 1;                                        // set it from Script.props or a stored run
    onStart() {
        const rand = rng.create(this.runSeed);
        const gen = scene.generation;                   // see "Scene lifetime" below
        this.job = tilemap.generate({
            sample: "levels/sample.json",               // rows + legend with the spawn point, coins and enemies drawn once
            size: [60, 24], seed: rand.int(0, 2147483647), n: 3,
            constraints: { border: { tile: "#" } },
            reachability: { from: [1, 1], toTiles: ["$"], solidTiles: [0] },
            place: { entity: "level", tilemap: { tileset: "assets/art/tiles.png", tileSize: [16, 16] } },
        });
        this.job.promise.then((r) => {
            if (scene.generation !== gen) return;       // another scene was loaded meanwhile
            console.log("level ready", r.stats.attempts, "attempt(s)");
        }, (e) => console.error(e.message, e.hint));
    }
    onUpdate() { console.log(this.job.progress); }      // 0..1, never goes down; drive a loading bar with it
}
```

- `place` builds the level when it is ready the way `scene.import_ascii` does (the same report, in `result.placed`): the Tilemap entity (`place.entity`, default `tilemap`; fields from `place.tilemap`; `position` / `anchor`) and one entity per glyph of the sample whose legend entry has a `prefab` (spawn points, coins, enemies), with the ids and tags `scene.import_ascii` gives them. Draw the markers in the sample once, where you want them to repeat (a tile that only appears on the sample's right or bottom edge cannot be placed inside a bigger level). `place` is exclusive with `into` (tiles only, into an existing Tilemap) and does not take the arguments that write files (`path`, `from`, `save`, `dryRun`) or `rows` / `legend` in the call: the sample and legend define it.
- The handle has `progress` (0..1, never goes down: it follows the solver, so it moves through the cells of an attempt and a restart does not take it back; it reads 1 only when `done`), `done`, `error` and `hint` (`""` while it works), `result` (what the command answers; `null` until ready), `attempts`, `work` (the unit of `maxWork`), `promise` (resolves with `result`; rejects with an Error that has `.hint`) and `cancel()`. Values change between frames, never in the middle of your code. A script that only polls `done` is not reported for an unhandled rejection.
- Budget: each frame does up to 500000 units of generator work in tests and headless runs, so the frames it takes are the same on every machine; with a window the running generations work until about 4 ms of the frame are used, shared equally between them (the number of frames then depends on the machine, and the game must not depend on it). The 4 ms (and the 500000 units) are for all running generations together, not for each: up to 8 can run at once and each then advances at an eighth of the speed, so starting several slows them all down; run one at a time (start the next when `done`) to get each level sooner. `stats.ms` and `memoryBytes` in the result are informative: they depend on the machine, not on the seed, so a game must not compare them or branch on them (`rows`, `stats.work`, `stats.attempts` are the deterministic ones). The level itself, `rows` and `stats.work` are the same as the command's for the same arguments, however the work is cut. The model is built by the `tilemap.generate` call itself (one frame), and after that an attempt advances in pieces, so a step stays near its budget (about 16384 work units of overshoot at most); the pieces that are not cut are the rebuild of the solver's entropy heap, the re-tiling of a Tiled level by `reachability` and each path search of `reachability` (one per step). Keep run-time levels modest anyway, and pre-generate the big ones with the command.
- Scene lifetime: a generation belongs to the scene that started it. When another scene is loaded the generation ends with an error, nothing is placed and its memory is freed; the promise rejects. If your code waits for `promise`, keep `const gen = scene.generation` and drop the answer when `scene.generation !== gen` before it uses the result (a rejected promise needs no such check). At most 8 generations run at once and their solver memory adds up under the same 256 MB limit; `maxWork` and `maxSeconds` (CPU seconds spent generating, not frames spent on other things) end a level that cannot be solved with `budget_exceeded`.
- The command also has a stepped form for tests and tools: `tilemap.generate_start` (same arguments, returns a `job`), `tilemap.generate_step {job, work?, budgetMs?}` (returns `done`, `progress`, and the `result` when done) and `tilemap.generate_cancel {job}`. A scene load drops these jobs too.

**Generate the level, or write its ASCII by hand?** Decide before you spend a turn on either:

- **Write the ASCII by hand** (`scene.import_ascii`, `scene.ascii_edit`) when the level is a *designed* thing: a tutorial, a puzzle with one solution, a boss arena, a level whose shape teaches or tells a story, anything you will tune cell by cell, or a game with a handful of levels. A generator cannot know the point of the level; you can, and an AI can check a hand-written level against the rules in two lines (`nav.find_tile_path` from the start to the exit).
- **Generate** when the game wants *many* levels or a *new one each run* (a roguelike floor, a replayable puzzle board, an endless runner section) and any playable level of the right *style* will do. The sample is where you put the style: draw one small level (16 x 16 is plenty) with the walls, platforms, enemies and coins as they should look, and the generator repeats its local shapes at any size.
- **Both:** draw the sample by hand (that is design), then generate the rest. Keep the border and fixed cells in `constraints`, say what must be reachable in `reachability`, and write down in the game's tests that every seed you ship passes (a test that generates the first 20 seeds and checks `stats` and the path is cheap and catches a sample edit that breaks the levels).
- **Shape the sample for the rules you ask.** The generator copies the local shapes of the sample, so a glyph that is unique in the sample (the player, the exit) shows up several times in the result unless a `max` caps it. Leave one-of-a-kind markers out of the sample and put them with `constraints.place` (entrance on any floor cell, exit `farthest` from it; examples/ember-descent does it), or cap a common one with `counts max`. `reachability.allConnected` refuses a sample of rooms joined by one-cell corridors almost every time (a corridor that ends nowhere cuts a room off): draw open areas with pillars and wide passages, then check 20 seeds.
- **Do not generate** a level you could not describe a failure of: if "any output is fine" is not true, add a `constraint` or `reachability` rule for what makes one bad; if you cannot, write it by hand. A generated level you have not looked at is not finished: preview a few seeds, then fix the sample (a bigger or more varied one, `symmetry`, a smaller `n`) rather than the output.
- **Pre-generate or generate at run time?** For a fixed set of levels run the command once, look at the `rows` it answers, write them with the `legend` into a level file (the editor window below does it with Save level file) and ship the file: the player gets what you saw. Use the script API only when the level really differs per run, and keep the seed in the save so the run can continue (`rng.create(seed)`).
- **In the editor**, View > Level generator (docs/EDITOR.md, "Level generator") is the loop a person uses: select the sample, press Next seed until a level looks right, Keep in the scene (one undo step, objects included) or Save level file. Tell the user to use it when they want to *choose* among levels; use the command yourself when you do not need to look.
