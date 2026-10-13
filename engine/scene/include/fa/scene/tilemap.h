// Tilemap data helpers shared by the scene loader (load-time checks), project validation and the
// scene.import_ascii command.
//
// Geometry (the renderer in fa_render and the collision in fa_physics use the same convention):
//   the Tilemap entity's position is the map's TOP-LEFT corner, +Y up, row 0 = top row;
//   tile (col, row) covers x in [col*tw, (col+1)*tw] and y in [-(row+1)*th, -row*th] in the entity's local space
//   (tw, th = tileSize); the world matrix of the entity (position, rotation, scale) maps that to the world.
#pragma once

#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/components.h"

namespace fa {

// One problem found in the data of a Tilemap component.
struct TilemapIssue {
    bool error = true;        // false = warning
    std::string pointer;      // JSON pointer relative to the component, e.g. "/tiles/12" ("" = the whole component)
    std::string message;
    std::string hint;
};

// Checks the DATA of a Tilemap as written in a scene or prefab: `tiles` is an array of integers (>= -1) or of equal rows,
// its size matches width*height, solidTiles is a list of integers, tileSize is positive. Reports at most a handful of
// problems per kind so a broken 1000-tile map does not flood the output. Called by the scene loader (so scene.load,
// factoria validate and the engine report it with file + JSON pointer).
std::vector<TilemapIssue> check_tilemap(const Tilemap& tm);

// Replaces the grid: width, height and `tiles` as a flat row-major array (row 0 = TOP row, -1 = empty).
// tiles.size() must be width*height.
void set_tilemap_grid(Tilemap& tm, int width, int height, const std::vector<int>& tiles);

// Centre of tile (col, row) in the tilemap entity's LOCAL space: ((col + 0.5) * tw, -(row + 0.5) * th).
Vec2 tilemap_cell_center(const Tilemap& tm, int col, int row);

// Number of tiles a tileset image of imageWidth x imageHeight pixels holds for this tilemap: `columns` (or the number of
// whole tiles per image row when columns is not set) times the number of whole tile rows. 0 when it cannot be known.
int tileset_tile_count(const Tilemap& tm, int imageWidth, int imageHeight);

}  // namespace fa
