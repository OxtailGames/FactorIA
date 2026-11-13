// Tile mode for image documents and the seam check (docs/IMAGES.md, "Tiles").
//
// A picture that repeats (a ground texture, a wall, a sheet of tiles) must not show a line where one copy meets the next. Two things
// help: editing that WRAPS around the edges of a tile (a stroke that leaves the right edge comes back in on the left, so the edges keep
// matching while you draw), and a CHECK that compares the pixels that touch when the tile repeats.
//
//   * wrap math: tile_wrap(), used by the drawing commands in tile mode;
//   * the distance between two pixels (alpha counts), the same one the seam check and its tolerance use;
//   * check_tile_opposites(): the right column of every tile against its own left column, its bottom row against its top row;
//   * check_tile_set(): the sides that touch when the tiles of an autotile set are placed next to each other by their masks, and the joins
//     inside a generated tile where two quadrants cut from different parts meet.
//
// Pure functions of pixels: no files, no clock, no random numbers.
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// `v` moved into the tile [origin, origin + size) by whole tile steps: origin + ((v - origin) mod size).
inline int tile_wrap(int v, int origin, int size) {
    int m = (v - origin) % size;
    if (m < 0) m += size;
    return origin + m;
}

// How different two straight-alpha RGBA8 pixels look, 0 (the same) to 255: the larger of the alpha difference and the colour
// difference (largest channel) weighted by the smaller alpha, so the colour of a transparent pixel never counts.
int tile_pixel_distance(const std::uint8_t* a, const std::uint8_t* b);

// The tile grid of a document in tile mode: the canvas is cut into cells of tw x th pixels and a drawing wraps inside ONE cell (the one
// that holds its anchor: a pixel, the first point of a line, the corner of a rectangle). `on` is false for a document without `tile`.
struct TileGrid {
    bool on = false;
    int tw = 0, th = 0;
    int canvasW = 0, canvasH = 0;
    int cell_x(int x) const {
        return cell(x, tw, canvasW);
    }  // left edge of the cell holding column x (clamped to the canvas)
    int cell_y(int y) const { return cell(y, th, canvasH); }
    int wrap_x(int x, int cellX) const { return tile_wrap(x, cellX, tw); }
    int wrap_y(int y, int cellY) const { return tile_wrap(y, cellY, th); }

private:
    static int cell(int v, int size, int canvas) {
        int c = v >= 0 ? v / size : -((-v + size - 1) / size);
        c = c < 0 ? 0 : (c > canvas / size - 1 ? canvas / size - 1 : c);
        return c * size;
    }
};
// The tile grid a document JSON asks for (`tile`: true or {width, height}); off when it has none or it does not fit the canvas.
TileGrid tile_grid_of(const Json& documentJson);

struct TileRect {
    int x = 0, y = 0, width = 0, height = 0;
};

// One seam: the sides of two tiles that touch. `axis` "horizontal": the right column of tile A touches the left column of tile B;
// "vertical": the bottom row of A touches the top row of B. For the opposite sides of one tile A and B are the same tile.
struct TileSeam {
    std::string axis;  // "horizontal" or "vertical"
    int a = 0, b = 0;  // tile numbers (row-major in the picture, 0-based)
    // Interior joins of a generated tile (check_tile_set with `joins`): axis "centreColumn" (the line down the middle, between a left and a
    // right quadrant) or "centreRow" (the line across the middle); `a` == `b` is the tile, runs are positions along the line, `half` says
    // which half of the line ("top" / "bottom" of a centreColumn, "left" / "right" of a centreRow) and `parts` names the two parts the
    // quadrants are cut from ("corner | edge").
    std::string half, parts;
    int length = 0;                         // pixel pairs compared
    int mismatched = 0;                     // pairs further apart than the tolerance
    int worst = 0;                          // the largest distance
    double mean = 0;                        // the mean distance
    std::vector<std::pair<int, int>> runs;  // positions along the seam (inclusive) of the mismatching pairs, in runs
};

// What one quadrant of a generated tile (fa/tooling/image_tileset.h) is cut from: the picture of a part in an orientation. Only the pixels next
// to the middle lines are kept, since an interior join compares what two quadrants' pictures say about the pixels next to the line.
struct TileJoinSource {
    std::string part;  // "corner", "edge", "inside", "innerCorner"
    std::string key;   // identifies the picture (part, orientation, variant): quadrants with the same key always agree
    std::vector<std::uint8_t>
        columns;  // RGBA of the picture's columns qw-1 and qw (qw = tileWidth / 2) over the quadrant's rows: 2 * qh pixels, row by row
    std::vector<std::uint8_t>
        rows;  // RGBA of its rows qh-1 and qh over the quadrant's columns: 2 * qw pixels, column by column
};
// The four quadrants of one tile: top-left, top-right, bottom-left, bottom-right.
using TileJoinSources = std::array<TileJoinSource, 4>;

struct TileSeamReport {
    int tolerance = 0;                // the tolerance used (0 = pixels must be equal)
    bool toleranceAutomatic = false;  // it was worked out from the picture
    double interior = 0;  // the mean distance between neighbouring pixels inside the tiles: what "smooth" means here
    int seamsChecked = 0;
    int pixelPairs = 0;
    std::vector<TileSeam> bad;  // the seams with a mismatch
    int tilesChecked = 0;       // tiles that were not empty
    int tileWidth = 0, tileHeight = 0, columns = 0, rows = 0;
    bool seamless() const { return bad.empty(); }
};

// The mean distance between neighbouring pixels inside the tiles of the picture (rows and columns, never across a tile edge).
double tile_interior_difference(const Image& image, int tileWidth, int tileHeight);
// The tolerance used when none is given: 0 when `exact` (pixel art keeps hard colours), else 1.5 x the interior difference, rounded up.
int tile_automatic_tolerance(double interior, bool exact);

// Opposite sides of every tile of the picture (tileWidth x tileHeight cells from the top-left; both must divide the picture). A tile
// that is fully transparent is skipped. `tolerance` < 0 = automatic (`exact`: pixel art, so 0).
TileSeamReport check_tile_opposites(const Image& image, int tileWidth, int tileHeight, int tolerance, bool exact);

// The seams between neighbouring tiles of an autotile set drawn as a sheet: tile i sits at column i % columns, row i / columns; masks[i]
// is its reduced neighbour mask (fa/scene/autotile.h: N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128), -1 for a tile to leave out. Every
// pair of tiles that can stand side by side in a map is compared: A east of B needs A to have an east neighbour and B a west one.
// `diagonals` (blob47): the cells around the pair must give both tiles the diagonal bits they have, and the whole seam is compared.
// Without diagonals (16 tiles) only the half of the seam where A and B have, or both lack, the neighbour on that side is compared: the
// set holds no tile for the corner cell between them. `tolerance` < 0 = automatic.
// `joins` (one entry per tile, in tile order; optional): the interior joins of every tile, where two quadrants cut from different pictures
// meet (corner next to edge, edge next to inside, inner corner next to edge...). The two quadrants must agree on the pixels either side of
// the line: where the picture of one quadrant shows another pixel than the picture of the other at the same place, the join is a seam
// with the same tolerance. Bad joins join `bad` (axis "centreColumn" / "centreRow") and count in seamsChecked and pixelPairs.
TileSeamReport check_tile_set(const Image& image, int tileWidth, int tileHeight, int columns,
                              const std::vector<int>& masks, bool diagonals, int tolerance, bool exact,
                              const std::vector<TileJoinSources>* joins = nullptr);

// The picture of a check for people: the tile (cell `tile` of the picture, or the whole picture when the tiles are the picture) repeated
// 3 x 3 with a red line over every mismatching seam pair of the central copy, magnified by `scale`. `report` comes from check_tile_opposites.
Image tile_check_preview(const Image& image, int tileWidth, int tileHeight, int tile, const TileSeamReport& report,
                         int scale);
// The sheet of an autotile set magnified by `scale`, with a red mark on every side of a tile that has a mismatching seam, and on the middle
// line of a tile where two quadrants do not join.
Image tile_set_preview(const Image& image, int tileWidth, int tileHeight, const TileSeamReport& report, int scale);

}  // namespace fa
