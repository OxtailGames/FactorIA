// The tileset generator: a few parts (inside, edge, corner, ...) become the 16 or 47 tiles of an autotile set (docs/IMAGES.md, "Tiles").
//
// A tile is made of four QUADRANTS (a quarter of the tile each). What a quadrant shows depends on the two neighbours next to it and the
// diagonal one between them:
//
//        neighbours next to the quadrant   diagonal   quadrant
//        none                                          the outer CORNER
//        only the one across the tile's top/bottom     the horizontal EDGE (top or bottom)
//        only the one across the tile's left/right     the vertical EDGE (left or right)
//        both                              missing     the INNER CORNER   (blob47 only; basic16 has no diagonals)
//        both                              present     the INSIDE
//
// The parts are whole tile pictures drawn for ONE orientation, and the other orientations come from them by flipping (any tile size) or
// transposing (square tiles): `inside` is a flat tile of the terrain, `edge` has the terrain's top edge (terrain below, nothing above), `corner`
// has the terrain's top-left outer corner, `innerCorner` is an inside tile with the top-left corner cut out. The minimal set is
// inside + edge + corner (+ innerCorner for blob47); optional parts (edgeBottom, edgeLeft, edgeRight, cornerNE, ...) replace a derived
// orientation when a flip would put the light on the wrong side. A part may be a LIST of variants; variation v >= 1 of a tile picks the
// variants by the seed, variation 0 always uses the first one.
//
// The sheet holds the tiles in slot order (fa/scene/autotile.h: slot s of variation v is tile s * variations + v), row by row.
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/image_tile.h"
#include "fa/tooling/pixel_art.h"

namespace fa {

// Every part name, base parts first: inside, edge, corner, innerCorner, then the optional orientations.
const std::vector<std::string>& tileset_part_names();
// The parts a set of this mode cannot be built without ("basic16" / "blob47"). `squareTile`: width == height; a tile that is not square
// cannot be transposed, so it also needs `edgeLeft` (and `innerCorner` stays blob47-only).
std::vector<std::string> tileset_required_parts(const std::string& mode, bool squareTile);

struct TilesetLayout {
    int tileWidth = 0, tileHeight = 0;
    int columns = 0, rows = 0;  // tiles per row, rows of the sheet
    int slots = 0;              // 16 or 47
    int variations = 1;
    int tiles = 0;  // slots * variations
    int width() const { return columns * tileWidth; }
    int height() const { return rows * tileHeight; }
    int tile_index(int slot, int variation) const { return slot * variations + variation; }
};
TilesetLayout tileset_layout(const TilesetSpec& spec);
// The reduced neighbour mask of each tile of the sheet (fa/scene/autotile.h bits), in tile order: the mask of its slot, repeated for each variation.
std::vector<int> tileset_tile_masks(const TilesetSpec& spec);

// Reads a project picture for a part. It reports a file it cannot read by throwing (the compositor's failure carries the layer's pointer);
// build_tileset lets it through.
using TilesetLoader = std::function<const Image&(const std::string& pointer, const std::string& rel)>;

struct TilesetBuild {
    Image sheet;  // layout.width() x layout.height(), straight-alpha RGBA8
    TilesetLayout layout;
    std::vector<std::string> warnings;  // variations that came out identical, ...
    std::vector<TileJoinSources>
        joins;  // per tile (sheet order): what each quadrant is cut from, for the interior joins check_tile_set compares
};
// Draws the sheet. Fails (message starts with the JSON pointer of the part) when a part is missing or is not tileWidth x tileHeight.
Result<TilesetBuild> build_tileset(const TilesetSpec& spec, const PixelPalette& palette, const TilesetLoader& load);

// The terrain rule of the set for Tilemap.terrains (fa/scene/autotile.h): {name, mode, seed, tiles: [...]}. Tile index = position in the
// sheet, row by row, so it is right when the sheet is the Tilemap's tileset and `columns` is the layout's.
Json tileset_terrain_json(const TilesetSpec& spec, const std::string& fallbackName);

inline constexpr const char* kTerrainsFormat = "factoria.terrains/1";
// {"format": "factoria.terrains/1", "terrains": [terrain]}: the rules file image.tileset.rules writes and tilemap.set_terrains reads.
Json tileset_rules_file_json(const TilesetSpec& spec, const std::string& fallbackName);

}  // namespace fa
