// Tilemap data helpers shared by the scene loader (load-time checks), project validation and the
// scene.import_ascii command.
//
// Geometry (the renderer in fa_render and the collision in fa_physics use the same convention):
//   the Tilemap entity's position is the map's TOP-LEFT corner, +Y up, row 0 = top row;
//   tile (col, row) covers x in [col*tw, (col+1)*tw] and y in [-(row+1)*th, -row*th] in the entity's local space
//   (tw, th = tileSize); the world matrix of the entity (position, rotation, scale) maps that to the world.
// ISOMETRIC maps (Tilemap::projection) keep row 0 = the top row and col 0 = the left column of the data, but the cells are
//   diamonds: +col runs down-right and +row down-left on screen. The entity's position is the TOP corner of the map (the top
//   vertex of tile (0, 0)); with hw = tw / 2 and hh = groundHeight / 2 (tilemap_ground_height()) the centre of tile
//   (col, row) is ((col - row) * hw, -(col + row + 1) * hh) in local space. The tile image is tw wide and th high with the
//   diamond's top corner groundOffset below its top edge. tilemap_cell_center() and tilemap_cell_at_local() hold both
//   geometries; the renderer, 2D physics, light occluders, tile paths, bounds and scripts all go through them.
#pragma once

#include <cstdint>
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
    bool error = true;    // false = warning
    std::string pointer;  // JSON pointer relative to the component, e.g. "/tiles/12" ("" = the whole component)
    std::string message;
    std::string hint;
};

// The effective grid of a Tilemap: the ONE definition of the map size and tile list. The renderer, 2D physics, the editor
// and tooling all read a Tilemap through tilemap_size() / tilemap_tile_at() / tilemap_grid(), so what is drawn is exactly
// what collides.
// `Tilemap::tiles` is ONE flat array of integers (fa::ArrayI32), row-major, row 0 = TOP row; scene and prefab files may
// also write it as an array of rows, which the loader flattens (flatten_tilemap_rows(): the rows set width and height),
// and it is always saved flat.
//   * width/height come from the fields. A missing width (0) makes the whole list ONE row, or tiles / height columns when
//     only height is set; a missing height (0) is the number of rows needed for the list at that width. Extra entries
//     beyond width*height are ignored, missing ones are -1.
// Negative numbers are -1 (empty). Entries keep their flip/rotate flag bits (see kTileFlipX): tile_index() says which
// tile, tile_flags() how it is turned.
//
// CHANGES AND CACHES. `tiles` counts its writes (tiles.version(), tiles.dirty_begin()/dirty_end(): fa/core/typed_array.h),
// so a consumer that derives data from a map (physics bodies, render chunks, nav grids) compares a TilemapStamp with the
// one it built from instead of reading every tile. Every function here that only reads uses the const accessors; a
// consumer must too (`std::as_const(tm.tiles)`, a `const Tilemap&`), because a mutable `data()` / `operator[]` counts as a
// write and would make every cache rebuild every frame.
struct TilemapSize {
    int width = 0;   // tiles per row
    int height = 0;  // number of rows
    bool empty() const { return width <= 0 || height <= 0; }
};
// Just the size of the effective grid (cheap: no tile list is built). 0 x 0 when `tiles` is empty.
TilemapSize tilemap_size(const Tilemap& tm);

// The tile value at (col, row) read in place from `tiles` (no list is built, unlike tilemap_grid()); -1 when empty or
// outside `size` (from tilemap_size()). The renderer draws through this every frame; it never touches tiles.version().
int tilemap_tile_at(const Tilemap& tm, const TilemapSize& size, int col, int row);

// Writes one tile in place: only that element of `tiles` changes (a flat list shorter than the map grows to reach the
// cell). `value` is the tile index plus flag bits, or -1 to empty the cell. A write that changes the cell is counted ONCE
// by the array (tiles.version() goes up by one, the dirty range covers the cell) and recorded as a TileEdit for 2D physics;
// a cell that already holds `value` changes and records nothing, so version bumps and edits match one to one. Returns false
// (nothing written) when (col, row) is outside the map's size (tilemap_size) or `value` is below -1.
bool set_tilemap_tile(Tilemap& tm, int col, int row, int value);

// The change counter of the map: tiles.version() plus the number of times width / height changed between two calls of
// this function (the first call only takes the baseline). It only goes up for one map; compare it with an earlier result
// to learn that the map changed (nav.tileVersion in scripts). Cheap: no tile is read.
std::uint32_t tilemap_version(Tilemap& tm);

// What a cache of data derived from a map keeps next to the data: the identity of the tiles array (a component removed
// and added again, or a world restored from a copy, is another array at version 0 again), its version, and the size the
// tiles were read with. The map is unchanged since the stamp was taken exactly when the two stamps are equal (the
// dirty range, tm.tiles.dirty_begin()/dirty_end(), says WHERE it changed when they are not).
struct TilemapStamp {
    std::uint64_t arrayId = 0;  // tm.tiles.id(); 0 = never taken
    std::uint64_t version = 0;  // tm.tiles.version()
    std::int32_t width = 0;
    std::int32_t height = 0;
    std::size_t count = 0;  // tm.tiles.size()
    bool operator==(const TilemapStamp&) const = default;
};
TilemapStamp tilemap_stamp(const Tilemap& tm);

// True when `fields` (the JSON of a Tilemap component as written in a file or a command) gives `tiles` as an array of
// rows. Such a value is flattened with flatten_tilemap_rows() before it reaches the component.
bool tilemap_rows_form(const Json& fields);
// What is wrong with a `tiles` that is NOT in the rows form, before it reaches the array (which would only say "expected an
// integer"): a value that is not an array, an element that is not a whole number (a string row from ASCII art points at
// scene.import_ascii). Pointers are relative to the component ("/tiles/3"); at most a handful per kind.
std::vector<TilemapIssue> check_tilemap_tiles_json(const Json& fields);
// Turns a rows-form `tiles` in `fields` into the flat list and sets `width` and `height` to the rows' size. Reports what
// is wrong (a row of another length than the first (or than `width`), a different `height`, a tile that is not an
// integer, a map over kMaxTypedArrayElements) as TilemapIssues whose pointers are relative to the component
// ("/tiles/3", "/tiles/3/7"); then `fields` is left as it was. Nothing happens for a flat or missing `tiles`.
std::vector<TilemapIssue> flatten_tilemap_rows(Json& fields);
// Replaces the tiles from JSON for code that builds maps by hand (tests, tools): a flat array keeps width and height as
// they are; an array of rows (shorter rows are padded with -1) sets them. Anything that is not a non-negative number is -1.
void set_tilemap_tiles(Tilemap& tm, const Json& tiles);

// The size plus the flat tile list.
struct TilemapGrid {
    int width = 0;           // tiles per row
    int height = 0;          // number of rows
    std::vector<int> tiles;  // width * height entries, row-major, row 0 = TOP row, -1 = empty

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

// Checks the DATA of a Tilemap as loaded from a scene or prefab: `tiles` holds integers (>= -1), its size matches
// width*height, solidTiles is a list of integers, tileSize is positive. Reports at most a handful of
// problems per kind so a broken 1000-tile map does not flood the output. Called by the scene loader (so scene.load,
// factoria validate and the engine report it with file + JSON pointer).
std::vector<TilemapIssue> check_tilemap(const Tilemap& tm);

// Replaces the grid: width, height and `tiles` as a flat row-major array (row 0 = TOP row, -1 = empty).
// tiles.size() must be width*height.
void set_tilemap_grid(Tilemap& tm, int width, int height, const std::vector<int>& tiles);

// True when the map is drawn and collides as diamonds (Tilemap::projection == Isometric).
inline bool tilemap_isometric(const Tilemap& tm) { return tm.projection == TilemapProjection::Isometric; }

// Height of one grid row's footprint: tileSize.y for an orthogonal map; for an isometric one groundHeight, or tileSize.y when
// groundHeight is 0. The rows of an isometric map are half of it apart.
float tilemap_ground_height(const Tilemap& tm);

// Centre of tile (col, row) in the tilemap entity's LOCAL space. Orthogonal: ((col + 0.5) * tw, -(row + 0.5) * th).
// Isometric: ((col - row) * tw / 2, -(col + row + 1) * groundHeight / 2), the middle of the diamond.
Vec2 tilemap_cell_center(const Tilemap& tm, int col, int row);

// The cell that contains a point of the tilemap's local space (y up), whether or not it lies inside the map: the caller
// compares it with tilemap_size(). Orthogonal: the square; isometric: the diamond (its edges belong to the cell on their
// right and below). False when the tile size is not positive.
bool tilemap_cell_at_local(const Tilemap& tm, Vec2 local, int& col, int& row);

// The linear map from the tilemap's local space to CELL space, where cell (col, row) is the unit square
// [col, col+1) x [row, row+1): cx = m[0] * x + m[1] * y, cy = m[2] * x + m[3] * y. Orthogonal: (x / tw, -y / th). Isometric:
// the same for a diamond grid, so a walk through cells works on both. All zero when the tile size is not positive.
void tilemap_local_to_cell(const Tilemap& tm, float m[4]);

// The box (min x, min y, max x, max y, local space, y up) the drawn tiles of an isometric or orthogonal map of `size` cover,
// tall tile images (groundOffset, a taller tileSize) included.
Rect tilemap_local_bounds(const Tilemap& tm, const TilemapSize& size);

// Number of tiles a tileset image of imageWidth x imageHeight pixels holds for this tilemap: tileset_columns() times the
// number of whole tile rows. 0 when it cannot be known.
int tileset_tile_count(const Tilemap& tm, int imageWidth, int imageHeight);

}  // namespace fa
