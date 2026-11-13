// Autotile rules of a Tilemap: terrains. A terrain says which tile of the tileset to draw in a cell from the cells around
// it, so painting "grass" next to "water" draws the shore without the author choosing each edge tile. The rules are data
// (the `terrains` field of the Tilemap component), the same at edit time and at run time:
//   * tilemap.paint_terrain (command) and entity.tilemap.paintTerrain (script) set cells to a terrain and re-tile the
//     cells around them;
//   * tilemap.retile re-tiles the whole map; the image.tileset.* commands write the rules of a tileset they bake.
//
// A terrain has a MODE, which decides how many tiles it has and what they mean:
//   basic16  4 neighbours (N, E, S, W): 16 tiles, one per combination. The slot of a cell is
//            N*1 + E*2 + S*4 + W*8 (0 = alone, 15 = surrounded).
//   blob47   8 neighbours: a diagonal neighbour only counts when both orthogonal cells next to it are also in the terrain
//            (otherwise the picture would not change), which leaves 47 distinct looks. The raw mask is
//            N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128; the 47 reduced masks sorted ascending are the slots 0..46
//            (autotile_masks()).
// The tiles of a terrain are listed in slot order: either `first` (the tileset index of slot 0; the rest follow) or a
// `tiles` array with one entry per slot. An entry is a tile value, or an array of tile values that are VARIATIONS of that
// look: the one drawn in a cell is picked from the cell's column, row and the terrain's `seed`, so the same map always
// looks the same. A cell belongs to a terrain when its tile index is one of the terrain's tiles.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/scene/components.h"
#include "fa/scene/tilemap.h"

namespace fa {

// Neighbour bits of a raw mask (what autotile_slot() reads).
constexpr int kAutoN = 1, kAutoNE = 2, kAutoE = 4, kAutoSE = 8, kAutoS = 16, kAutoSW = 32, kAutoW = 64, kAutoNW = 128;

enum class AutotileMode { Basic16, Blob47 };

const char* autotile_mode_name(AutotileMode mode);  // "basic16" / "blob47"
bool autotile_mode_from_name(const std::string& name, AutotileMode& out);
int autotile_tile_count(AutotileMode mode);  // 16 / 47
// The raw masks (N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128) that stand for each slot, ascending: for blob47 the 47 masks
// that survive autotile_reduce(), for basic16 the 16 combinations of N, E, S and W.
const std::vector<int>& autotile_masks(AutotileMode mode);
// A raw 8-bit mask without the bits that do not change the look: blob47 clears a diagonal unless both orthogonals next to
// it are set; basic16 clears every diagonal.
int autotile_reduce(AutotileMode mode, int rawMask);
// The slot (0..count-1) of a raw mask: the index into the terrain's tile list.
int autotile_slot(AutotileMode mode, int rawMask);

// The variation of a cell: a number that depends only on the seed, the column and the row (no clock, no random state).
std::uint32_t autotile_hash(std::int64_t seed, int col, int row);

// One terrain, parsed from an entry of Tilemap.terrains.
struct Terrain {
    std::string name;
    AutotileMode mode = AutotileMode::Blob47;
    std::int64_t seed = 0;
    bool outsideIsTerrain = false;        // cells beyond the map edge count as this terrain
    std::vector<std::string> joins;       // other terrains this one connects to (their cells count as neighbours)
    std::vector<std::vector<int>> slots;  // per slot: the tile values to pick from (at least one), flags included
};

// Parses and checks Tilemap.terrains; every problem carries its JSON pointer (relative to the component, "/terrains/0/tiles")
// and teaches the fix. The Error message starts with that pointer.
Result<std::vector<Terrain>> parse_terrains(const Json& terrains);
// The problems parse_terrains() finds, as TilemapIssues (used by check_tilemap).
std::vector<TilemapIssue> check_terrains(const Json& terrains);

// The terrain-painting result.
struct TerrainChange {
    int col = 0;
    int row = 0;
    int from = -1;
    int to = -1;
};
struct TerrainPaintResult {
    std::vector<TerrainChange> changes;  // every cell whose tile changed (painted cells and re-tiled neighbours)
    int painted = 0;                     // cells inside the map that were set to the terrain (or erased)
    int outside = 0;                     // cells that were outside the map and skipped
};

// Sets the cells to `terrainName` (or empties them when `erase` is true) and re-tiles them and the 8 cells around each
// one that belong to a terrain. Writes through set_tilemap_tile(), so 2D physics, navigation and the renderer see it.
// Errors: unknown terrain (did-you-mean), invalid rules, no map.
Result<TerrainPaintResult> paint_terrain(Tilemap& tm, const std::string& terrainName,
                                         const std::vector<std::pair<int, int>>& cells, bool erase = false);
// Re-tiles every cell that belongs to a terrain from its neighbours (after rules or tiles were set by hand).
Result<TerrainPaintResult> retile_terrains(Tilemap& tm);

// retile_terrains() on a plain grid: `tiles` (width * height tile values, row-major, row 0 = TOP) is re-tiled in place with
// `terrains` (already parsed). Used after a generated level, whose slots only agree on the four sides.
void retile_terrain_grid(const std::vector<Terrain>& terrains, int width, int height, std::vector<int>& tiles);

// The terrain a tile value belongs to ("" when none), and its slot.
struct TerrainOfTile {
    std::string terrain;
    int slot = -1;
};
TerrainOfTile terrain_of_tile(const std::vector<Terrain>& terrains, int tileValue);

}  // namespace fa
