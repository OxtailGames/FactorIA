// The pixel operations behind image.paint and image.edit, as functions the editor's Image panel calls too (docs/IMAGES.md, "The Image
// panel"). The commands and the panel run THE SAME code: a stroke the panel shows while the mouse moves is the stroke image.paint
// writes when the mouse is released, pixel for pixel.
//
// Everything here works on a straight-alpha RGBA8 `Image` that sits at the canvas position (originX, originY): coordinates are
// CANVAS pixels. Nothing here reads or writes a file except read_image_selection and open_image_edit_buffer (which only read).
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/image_doc.h"

namespace fa {

struct TileGrid;   // fa/tooling/image_tile.h

// A selection: coverage 0..255 for each pixel of the canvas (255 = fully selected). Outside the canvas nothing is selected.
struct ImageSelection {
    int w = 0, h = 0;
    std::vector<std::uint8_t> v;
    ImageSelection() = default;
    ImageSelection(int width, int height, std::uint8_t fill = 0) : w(width), h(height), v(std::size_t(width) * height, fill) {}
    std::uint8_t at(int x, int y) const { return x < 0 || y < 0 || x >= w || y >= h ? 0 : v[std::size_t(y) * w + x]; }
    std::uint8_t& ref(int x, int y) { return v[std::size_t(y) * w + x]; }
    bool empty() const { return v.empty(); }
};

// The stored selection `name` of the document `rel` (image.select keeps it in .factoria/selections/), or None when there is none by
// that name or it was made for another canvas size. "all" is the whole canvas.
std::optional<ImageSelection> read_image_selection(const std::string& projectDir, const std::string& rel, const std::string& name, int canvasW,
                                                   int canvasH);

// The straight-alpha colour (r, g, b in 0..255, alpha a in 0..1) over one RGBA8 pixel `p`, by the W3C formula.
void image_over_pixel(std::uint8_t* p, double r, double g, double b, double a);

// Stores `selection` as the selection `name` of the document `rel`, as image.select does (a grey PNG under .factoria/selections/). Fails
// with the reason when the name is not valid or the file cannot be written.
Result<void> write_image_selection(const std::string& projectDir, const std::string& rel, const std::string& name,
                                   const ImageSelection& selection);

// ---- strokes --------------------------------------------------------------------------------------------------------

struct ImageBrush {
    double size = 4;                // diameter in pixels (0.5 to 512)
    double hardness = 1;            // 1 = hard edge (half a pixel anti-aliased); lower fades from hardness * radius to the edge
    double opacity = 1;             // strength of the whole stroke
    Color color{0, 0, 0, 1};
    bool erase = false;             // lower the alpha instead of painting
    double spacing = 0;             // arc length between stamps; 0 = a fifth of the size, at least 1
};
// Paints one stroke along the polyline `points` (canvas pixels; one point is a dab): a stamp at the first point, one every `spacing`
// of arc length, one at the last point. A pixel keeps the largest coverage any stamp gave it. `selection` (when given) limits where it
// paints. Returns how many stamps were made. This is image.paint's algorithm. With `tiles` (a tile grid that is on) the stroke wraps
// around the edges of the tile that holds its first point.
std::size_t paint_image_stroke(Image& img, int originX, int originY, const std::vector<std::pair<double, double>>& points,
                               const ImageBrush& brush, const ImageSelection* selection, const TileGrid* tiles = nullptr);

// ---- patches: the selected pixels of a layer, to move, transform or copy ------------------------------------------------

struct ImagePatch {
    Image img;                      // straight alpha; the alpha already includes the selection's coverage
    int x = 0, y = 0;               // canvas position of its top-left pixel
};
ImagePatch image_patch_extract(const Image& img, int originX, int originY, const ImageSelection& selection);
// Lowers the alpha of the selected pixels by the selection's coverage.
void image_patch_erase(Image& img, int originX, int originY, const ImageSelection& selection);
// Draws the patch over the buffer; returns how many visible pixels fell outside it.
std::size_t image_patch_draw(Image& img, int originX, int originY, const ImagePatch& patch);
// Tile mode: the patch that was cut at (fromX, fromY) and now sits at patch.x / patch.y, each pixel wrapping around the edges of the
// tile it came from; returns how many visible pixels fell outside the buffer.
std::size_t image_patch_draw_wrapped(Image& img, int originX, int originY, const ImagePatch& patch, int fromX, int fromY, const TileGrid& tiles);

struct ImageTransform {
    double scaleX = 1, scaleY = 1;
    double rotate = 0;              // degrees, clockwise
    bool flipH = false, flipV = false;
    double pivotX = 0, pivotY = 0;  // canvas pixels
    bool nearest = false;           // hard pixels (pixel art) instead of bilinear
};
// The patch scaled, rotated and flipped around the pivot. Fails when the result would be larger than 64 million pixels.
Result<ImagePatch> image_patch_transform(const ImagePatch& patch, const ImageTransform& transform);

// ---- the pixels of one layer, as the commands edit them ----------------------------------------------------------------

struct ImageEditBuffer {
    Image img;                      // the layer's own pixels (a layer smaller than the canvas is grown to cover it)
    int ox = 0, oy = 0;             // canvas position of img's top-left pixel
    bool fixedRect = false;         // a layer with masks keeps its box: edits outside it are dropped
    std::string kind;               // "pixels"
};
// The pixels image.paint and image.edit would edit in the layer `layerPath` (a name or an index path like "1/0") of `document` (the
// JSON of the document `rel`), in `frame` of an animated document. Only a pixels layer has them: another kind is an error that says
// what to do.
Result<ImageEditBuffer> open_image_edit_buffer(const std::string& projectDir, const std::string& rel, const Json& document,
                                               const std::string& layerPath, int frame);

}  // namespace fa
