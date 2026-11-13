// Private declarations shared by the sources of the image document (image_doc_*.cpp). The public API is
// fa/tooling/image_doc.h.
//
//   image_doc_blend.cpp    the 18 blend modes and the alpha compositing formula
//   image_doc_ops.cpp      adjustments and effects: the tables the layers' lists are checked against and walked with
//   image_doc_vector.cpp   SVG path data, polygons and ellipses to coverage planes (vector masks), the Gaussian blur of a feather
//   image_doc_parse.cpp    JSON -> ImageDocument, with the teaching errors
//   image_doc_render.cpp   the compositor
//   image_doc_bake.cpp     baking the PNG, provenance and recipe, the status of a baked document, save
//   image_doc_commands.cpp the image.* commands
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/style_guide.h"

namespace fa::imgdoc {

// A float raster, straight alpha (r, g, b, a in 0..1, four floats per pixel, row 0 = top). (ox, oy) is where its top-left pixel
// lies in the coordinates of whatever owns it (a layer's own pixels, or the canvas).
struct Raster {
    int w = 0, h = 0;
    int ox = 0, oy = 0;
    std::vector<float> px;

    Raster() = default;
    Raster(int width, int height, int originX = 0, int originY = 0)
        : w(width), h(height), ox(originX), oy(originY), px(std::size_t(width) * height * 4, 0.0f) {}
    bool empty() const { return w <= 0 || h <= 0; }
    float* at(int x, int y) { return &px[(std::size_t(y) * w + x) * 4]; }
    const float* at(int x, int y) const { return &px[(std::size_t(y) * w + x) * 4]; }
};

// A coverage plane (0..1) over a rectangle: the footprint of a mask.
struct Plane {
    int w = 0, h = 0;
    int ox = 0, oy = 0;
    std::vector<float> v;
    Plane() = default;
    Plane(int width, int height, int originX, int originY, float fill = 0.0f)
        : w(width), h(height), ox(originX), oy(originY), v(std::size_t(width) * height, fill) {}
    float& at(int x, int y) { return v[std::size_t(y) * w + x]; }
    float at(int x, int y) const { return v[std::size_t(y) * w + x]; }
};

Raster from_image(const Image& image);
Image to_image(const Raster& raster);  // quantizes once: lround(255 * v); a pixel of alpha 0 is written (0, 0, 0, 0)

// ---- blend (image_doc_blend.cpp) -------------------------------------------------------------------------------------

// Composites the straight-alpha source pixel `s` (alpha already multiplied by opacity, mask and clip) over the backdrop pixel
// `b` (four floats each) and writes the straight-alpha result to `out` (may alias `b`).
void composite_pixel(ImageBlend mode, const float* b, const float* s, float* out);

// ---- ops (image_doc_ops.cpp) -----------------------------------------------------------------------------------------

// Checks one entry of an `adjustments` or `effects` list; every problem goes to `issues` (pointer = the entry's).
// `projectDir` ("" = do not check files) is where a normal map named by an operation must exist.
void check_op(bool effect, const Json& op, const std::string& pointer, std::vector<ImageIssue>& issues,
              const std::string& projectDir = "");

// What an operation may need from the renderer: a project picture (a normal map), the project's style, and a way to fail with
// the pointer of the layer being drawn. `fail` must throw.
struct OpEnv {
    std::function<const Image&(const std::string& rel)> image;
    std::function<const StyleGuide&()> style;
    std::function<void(const std::string& message, const std::string& hint)> fail;
};
// Colour operations on a raster, in place (alpha is kept). Entries were checked by check_op.
void apply_adjustments(const std::vector<Json>& list, Raster& raster, const OpEnv& env);
// Footprint operations on a raster (may grow it; the origin ox, oy moves so the pixels stay where they were).
void apply_effects(const std::vector<Json>& list, Raster& raster, const OpEnv& env);

// ---- vector (image_doc_vector.cpp) -----------------------------------------------------------------------------------

struct Polyline {
    std::vector<Vec2> pts;
};
// SVG path data to polylines (curves and arcs flattened; every subpath is closed, as a fill closes it). False with `err` set
// when the data is not a path.
bool parse_svg_path(const std::string& d, std::vector<Polyline>& out, std::string& err);
// The coverage of the shapes (nonzero fill) over the rectangle [ox, ox+w) x [oy, oy+h), anti-aliased (4 sub-scanlines, exact
// horizontal coverage). Coordinates are those of the plane.
Plane fill_shapes(const std::vector<Polyline>& shapes, int w, int h, int ox, int oy);
Polyline ellipse_polyline(float x, float y, float width, float height);
// Gaussian blur (sigma in pixels) of a plane, in place; outside the plane counts as 0.
void blur_plane(Plane& plane, float sigma);

}  // namespace fa::imgdoc
