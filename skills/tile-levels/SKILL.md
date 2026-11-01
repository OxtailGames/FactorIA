---
name: tile-levels
description: ASCII tile maps with scene.import_ascii, camera bounds. Read before making a level.
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

## Camera and area limits

`entity.bounds()` is the world rectangle `{x, y, w, h}` (bottom-left corner and size) of a
Tilemap, Sprite or Shape2D. Clamp a follow camera with `world.find("map").bounds()`, not with map sizes copied into props.
Guide section 9.6.

## One-way platforms

`Collider2D.oneWay: true` (not Tilemap solid tiles).
