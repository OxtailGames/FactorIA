// Pixel-exact drawing and palette-indexed pictures (docs/IMAGES.md, "Pixel art").
//
// An INDEXED layer of an image document stores palette indices, not colours: the canvas is locked to the document's palette, so a
// pixel can only be one of its colours (or transparent). This header has what the tools that draw pixel art build on:
//   - PixelPalette: the colours (with optional names), the colour ramps (shade and light steps) and the nearest-colour search;
//   - IndexGrid: a picture of palette indices (-1 = transparent), and its text form (one string per row);
//   - the drawing algorithms (Bresenham lines with the pixel-perfect option, rectangles, midpoint ellipses, polygons, flood fill).
//     They return the pixels a shape covers and know nothing of colours, layers or documents; no anti-aliasing anywhere.
// Everything is integer arithmetic or deterministic float, with no random numbers and no clock.
#pragma once

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct PixelPoint {
    int x = 0, y = 0;
    bool operator==(const PixelPoint& o) const { return x == o.x && y == o.y; }
    bool operator<(const PixelPoint& o) const { return y != o.y ? y < o.y : x < o.x; }  // row by row, top to bottom
};

// ---- the text form of indices -----------------------------------------------------------------------------------------------

// The character that stands for palette index i in the rows of an indexed layer: 0-9, a-z, A-Z, then !#$%&*+-/:;<=>?@^_~ (81).
inline constexpr std::string_view kPixelIndexChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&*+-/:;<=>?@^_~";
inline constexpr int kMaxIndexedColours = 81;
inline constexpr char kPixelTransparentChar = '.';
// The character of an index (-1 = transparent = '.'), or '?' when the index has none.
char pixel_index_char(int index);
// The index a character stands for: -1 for '.', -2 when it is no index character.
int pixel_char_index(char c);

// ---- palette and ramps ------------------------------------------------------------------------------------------------------

struct PixelPalette {
    struct Entry {
        std::string name;                 // "" = unnamed
        std::array<std::uint8_t, 3> rgb{};
    };
    std::vector<Entry> entries;
    // Declared colour ramps: palette indices from the darkest to the lightest, at least two each, a colour in at most one ramp.
    std::vector<std::vector<int>> ramps;

    int size() const { return int(entries.size()); }
    bool empty() const { return entries.empty(); }
    // "name" when it has one, else "#rrggbb".
    std::string label(int index) const;
    std::string hex(int index) const;
    std::optional<int> find_name(std::string_view name) const;     // exact, then ignoring case
    std::optional<int> find_rgb(std::uint8_t r, std::uint8_t g, std::uint8_t b) const;
    // The palette colour nearest to (r, g, b) by Euclidean distance in OKLab; a tie takes the earlier entry. Needs a non-empty palette.
    int nearest(std::uint8_t r, std::uint8_t g, std::uint8_t b) const;
    // The ramp that holds `index` (position in PixelPalette::ramps) and the place in it, or nullopt when no declared ramp has it.
    std::optional<std::pair<int, int>> ramp_of(int index) const;
    // `steps` steps along the ramp of `index`: negative = darker (shade), positive = lighter. The step stops at the end of the ramp.
    // A colour in a declared ramp follows it. Otherwise the neighbour is DERIVED from the palette: one step darker is the colour
    // with a lower OKLab lightness that is nearest to this one (so the hue stays), one step lighter the nearest with a higher
    // lightness; no such colour = the colour itself.
    int step(int index, int steps) const;
};

// Finds the palette colour a reference names: an index (integer), a name, a single index character ("a"), "#rrggbb" / a CSS name that
// IS a palette colour, or (allowTransparent) null / "." / "transparent" / "none" = -1. A colour that is not in the palette is an error
// with the nearest palette colour; an unknown name is an error with "did you mean".
Result<int> pixel_palette_find(const PixelPalette& palette, const Json& ref, bool allowTransparent);

// ---- pictures of indices ---------------------------------------------------------------------------------------------------

struct IndexGrid {
    int w = 0, h = 0;
    std::vector<int> v;   // row by row; -1 = transparent, 0.. = palette index
    IndexGrid() = default;
    IndexGrid(int width, int height) : w(width), h(height), v(std::size_t(width) * height, -1) {}
    bool inside(int x, int y) const { return x >= 0 && y >= 0 && x < w && y < h; }
    int at(int x, int y) const { return inside(x, y) ? v[std::size_t(y) * w + x] : -2; }   // -2 = outside
    void set(int x, int y, int index) { if (inside(x, y)) v[std::size_t(y) * w + x] = index; }
};
// The text rows of a grid ('.' = transparent). Every index must be below kMaxIndexedColours.
std::vector<std::string> index_grid_rows(const IndexGrid& grid);
// The grid of text rows; an error names the first bad row and column. `paletteSize` < 0 skips the range check.
Result<IndexGrid> index_grid_from_rows(const std::vector<std::string>& rows, int paletteSize);
// The picture: each index becomes its palette colour, alpha 255; transparent is (0, 0, 0, 0). An index outside the palette is transparent.
Image index_grid_image(const IndexGrid& grid, const PixelPalette& palette);

// ---- drawing: the pixels a shape covers ----------------------------------------------------------------------------------------

// Bresenham's line from a to b, both ends included, in order from a to b.
std::vector<PixelPoint> pixel_line(PixelPoint a, PixelPoint b);
// A connected chain of pixels (each next to the one before, diagonals included) without its L-corners: a pixel whose two
// neighbours in the chain are themselves diagonal neighbours is dropped, so a line is never two pixels thick at a bend.
std::vector<PixelPoint> pixel_perfect(const std::vector<PixelPoint>& chain);
// The polyline through `points` (consecutive duplicates collapse); `perfect` removes the L-corners of the whole chain; `closed`
// joins the last point to the first.
std::vector<PixelPoint> pixel_polyline(const std::vector<PixelPoint>& points, bool perfect, bool closed = false);
// The rectangle x, y, width, height (width and height >= 1): its outline, or all its pixels. Sorted row by row, no duplicates.
std::vector<PixelPoint> pixel_rect(int x, int y, int width, int height, bool filled);
// The ellipse inscribed in the box x, y, width, height (midpoint algorithm; odd and even sizes both work; a 1-pixel side is a line).
// Outline or filled, sorted row by row, no duplicates.
std::vector<PixelPoint> pixel_ellipse(int x, int y, int width, int height, bool filled);
// A polygon through `points` (at least 3): its outline, or the pixels whose centre lies inside (even-odd) plus the outline.
std::vector<PixelPoint> pixel_polygon(const std::vector<PixelPoint>& points, bool filled);
// The pixels connected to (x, y) that hold the same index as it (4 or 8 neighbours), sorted row by row. Empty when (x, y) is outside.
std::vector<PixelPoint> pixel_flood(const IndexGrid& grid, int x, int y, bool eightConnected);

}  // namespace fa
