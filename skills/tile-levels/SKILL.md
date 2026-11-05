---
name: tile-levels
description: ASCII tile maps with scene.import_ascii, autotile terrains, camera bounds. Read before making a level.
---

# Tile levels

## ASCII maps

`scene.import_ascii` (MCP `scene_import_ascii`, CLI `factoria call scene.import_ascii @levels/level1.json`) turns
ASCII `rows` plus a `legend` into a Tilemap and its coins, enemies and spawn points (prefabs placed at the cell centres). Keep
the map in `levels/` and re-run it after every edit. Put `"path": "scenes/x.scene.json"` in the map file: it edits that scene
FILE (optionally starting `from` a base scene) and never touches the running game; no `--scene`, no `scene.save`. The file
keeps prefab references (`{"id", "prefab", "components": {overrides, position}}`) instead of expanded copies, and so does
the base scene's prefab entities, so editing a prefab changes every level without importing again. Maps can share a
legend: `"legendFrom": "levels/legend.json"` (merged under the map's own `legend`).
`Tilemap.columns` is optional (0 = derived from the tileset image width): leave it out. Guide section 9.8. Do not place
tile objects by hand or write a level generator.

## Autotile terrains

A ground, wall or water that must join its neighbours (edges, corners) is a TERRAIN: `Tilemap.terrains` holds the rules (which
tile for each combination of neighbours) and you paint the terrain, not tile numbers. Make the tileset and its rules with
`image.tileset.build` (a sheet of 16 or 47 tiles from four parts, with `variations` and a `seed`; docs_read {"name":"images"},
"Tiles"), check it with `image.tileset.check`, then on the map: `tilemap.set_terrains {"id":"map","path":"assets/art/ground.terrains.json"}`,
`tilemap.paint_terrain {"id":"map","terrain":"ground","rect":{"col":2,"row":1,"width":7,"height":5}}` (`"erase": true` to remove;
it re-tiles the cells around it) and `tilemap.retile` after you write `tiles` by hand. A game script paints
with `entity.tilemap.paintTerrain("ground", [[col, row]])` and `eraseTerrain`, `retile`, `terrainAt` (SCRIPTING.md, "Autotile"). Guide section 9.8.

## More levels like one you drew

`tilemap.generate` makes a new, bigger level from a small example you drew (Wave Function Collapse; same arguments, same
level). `constraints` (fixed cells, `border`, `forbidden`, `required`, `counts`) and `reachability` (`from`, `to`,
`toTiles`, `allConnected`, `solidTiles`) make it a playable one: an entrance that reaches the exit and the treasure.
Guide section 9.8.

A game that wants a new level on every run calls the script API `tilemap.generate({sample, size, seed: rng.create(runSeed).int(0, 2147483647), place: {...}})`.
It returns a handle (`progress`, `done`, `error`, `result`, `promise`, `cancel()`), works a little every frame (about 4 ms
with a window per running generation, so a phone does not stall; run one at a time, up to 8 at once can use about 32 ms of a frame) and gives the same level as the command for the same arguments. With `place`
it builds the Tilemap and turns the sample's markers (glyphs whose legend entry has a `prefab`: spawn points, coins,
enemies) into entities, as `scene.import_ascii` does. It belongs to the scene that started it: a scene load rejects it,
so check `scene.generation` before using the answer. `stats.ms` and `memoryBytes` of the result are informative, not deterministic: never compare them. Guide section 9.8, "A new level on every run".

## Camera and area limits

`entity.bounds()` is the world rectangle `{x, y, w, h}` (bottom-left corner and size) of a
Tilemap, Sprite or Shape2D. Clamp a follow camera with `world.find("map").bounds()`, not with map sizes copied into props.
Guide section 9.6.

## One-way platforms

`Collider2D.oneWay: true` (not Tilemap solid tiles).
