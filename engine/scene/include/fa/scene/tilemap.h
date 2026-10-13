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

// The effective grid of a Tilemap: the ONE definition of the map size and tile list. The renderer, 2D physics, the editor
// and tooling all read a Tilemap through tilemap_grid(), so what is drawn is exactly what collides.
//   * Rows form (`tiles` is an array of rows): the rows define the map. height = number of rows, width = length of the
//     longest row (shorter rows are padded with -1). The `width`/`height` fields are not needed and are ignored here;
//     check_tilemap() reports them when they disagree with the rows.
//   * Flat form (`tiles` is an array of integers, row-major): width/height come from the fields. A missing width (0)
//     makes the whole list ONE row, or tiles / height columns when only height is set; a missing height (0) is the
//     number of rows needed for the list at that width. Extra entries beyond width*height are ignored, missing ones
//     are -1.
// Entries that are not numbers, and negative numbers, are -1 (empty).
struct TilemapSize {
    int width = 0;               // tiles per row
    int height = 0;              // number of rows
    bool empty() const { return width <= 0 || height <= 0; }
};
// Just the size of the effective grid (cheap: no tile list is built). 0 x 0 when `tiles` is empty or not an array.
TilemapSize tilemap_size(const Tilemap& tm);

// The size plus the flat tile list.
struct TilemapGrid {
    int width = 0;               // tiles per row
    int height = 0;              // number of rows
    std::vector<int> tiles;      // width * height entries, row-major, row 0 = TOP row, -1 = empty

    bool empty() const { return width <= 0 || height <= 0; }
    // Tile at (col, row); -1 when outside the map.
    int at(int col, int row) const {
        if (col < 0 || row < 0 || col >= width || row >= height) return -1;
        return tiles[std::size_t(row) * std::size_t(width) + std::size_t(col)];
    }
};
TilemapGrid tilemap_grid(const Tilemap& tm);

// Number of tile columns of the tileset image for this tilemap: `columns` when it is set (> 0), otherwise derived from
// the image: whole tiles that fit in imageWidth (imageWidth / tileSize.x, at least 1). 0 when it cannot be known
// (columns not set and no usable image width or tileSize).
int tileset_columns(const Tilemap& tm, int imageWidth);

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

// Number of tiles a tileset image of imageWidth x imageHeight pixels holds for this tilemap: tileset_columns() times the
// number of whole tile rows. 0 when it cannot be known.
int tileset_tile_count(const Tilemap& tm, int imageWidth, int imageHeight);

}  // namespace fa
