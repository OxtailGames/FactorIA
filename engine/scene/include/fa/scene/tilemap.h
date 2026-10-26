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

// FLIPPED AND ROTATED TILES. A tile value is the tileset index in its low 28 bits plus three flag bits above them, so one
// integer in `Tilemap.tiles` says which image and how it is turned (the same three operations as Tiled's flip flags):
//   kTileFlipX       268435456 (1 << 28)  mirror left-right
//   kTileFlipY       536870912 (1 << 29)  mirror top-bottom
//   kTileTranspose  1073741824 (1 << 30)  mirror across the top-left to bottom-right diagonal
// The image is transposed FIRST, then mirrored in x, then in y. A 90 degree clockwise turn is transpose + flipX, 180 is
// flipX + flipY, 270 (90 counter-clockwise) is transpose + flipY. Flags never change which tile it is: -1 stays empty,
// `solidTiles` and the tileset range check look at the index only, so a flipped solid tile is still solid. Build values
// with make_tile() (or in scene.import_ascii legends: {"tile": 3, "flipX": true, "rotate": 90}).
constexpr int kTileFlipX = 1 << 28;
constexpr int kTileFlipY = 1 << 29;
constexpr int kTileTranspose = 1 << 30;
constexpr int kTileIndexMask = kTileFlipX - 1;
constexpr int kTileFlagMask = kTileFlipX | kTileFlipY | kTileTranspose;

// The tileset index of a tile value (flags removed); -1 stays -1.
inline int tile_index(int value) { return value < 0 ? -1 : (value & kTileIndexMask); }
// The flag bits of a tile value (0 for -1).
inline int tile_flags(int value) { return value < 0 ? 0 : (value & kTileFlagMask); }
// `index` turned `turns` quarter turns clockwise (any integer, wrapped to 0..3), then mirrored in x and/or y.
int make_tile(int index, int turns = 0, bool flipX = false, bool flipY = false);

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
// Entries that are not numbers, and negative numbers, are -1 (empty). Entries keep their flip/rotate flag bits (see
// kTileFlipX): tile_index() says which tile, tile_flags() how it is turned.
struct TilemapSize {
    int width = 0;               // tiles per row
    int height = 0;              // number of rows
    bool empty() const { return width <= 0 || height <= 0; }
};
// Just the size of the effective grid (cheap: no tile list is built). 0 x 0 when `tiles` is empty or not an array.
TilemapSize tilemap_size(const Tilemap& tm);

// The tile value at (col, row) read in place from `tiles` (no list is built, unlike tilemap_grid()); -1 when empty or
// outside `size` (from tilemap_size()). The renderer draws through this every frame.
int tilemap_tile_at(const Tilemap& tm, const TilemapSize& size, int col, int row);

// Writes one tile in place: `tiles` keeps its array, only that element changes (a flat map grows to reach the cell when
// the array is shorter than width*height; a row is padded with -1). `value` is the tile index plus flag bits, or -1 to
// empty the cell. Records a TileEdit for 2D physics. Returns false (nothing written) when (col, row) is outside the
// map's size (tilemap_size) or `value` is not -1 or in 0..kTileFlagMask|kTileIndexMask.
bool set_tilemap_tile(Tilemap& tm, int col, int row, int value);

// The change counter of the map (Tilemap::version) brought up to date: it also counts writes that replaced `tiles`,
// `width` or `height` as a whole, which it finds by hashing them (O(tiles)). The number only goes up; compare it with an
// earlier result to learn that the map changed. The first call only takes the baseline.
std::uint32_t tilemap_version(Tilemap& tm);

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
// the image: whole tiles that fit in imageWidth after `margin` and `spacing` (at least 1). 0 when it cannot be known
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
