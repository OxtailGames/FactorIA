// Private declarations of the image.* editing commands (docs/IMAGES.md, "Commands"). The public API is fa/tooling/image_doc.h:
// these commands edit the JSON of a document and hand it to save_image_document.
//
//   image_edit_common.cpp    open a document, address layers (name or index path), selections on disk, working layers, results
//   image_edit_commands.cpp  image.create, image.info, image.export, image.layer.add/set/remove/move
//   image_select.cpp         image.select and the mask operations (grow, shrink, feather, invert, combine)
//   image_edit_pixels.cpp    image.edit and image.paint
//   image_indexed.cpp        image.pixel, image.draw, image.palette, image.layer.convert (indexed pixel-art layers)
//   image_psd.cpp            the layers of a Photoshop file, for assets.import
//   image_frames.cpp         the timeline of an animated document and FrameScope (a command working on one frame)
//   image_frame_commands.cpp image.frame.* and image.tag.*
//   image_tile_commands.cpp  image.tile.* and image.tileset.* (tile mode, the seam check, autotile sets)
#pragma once

#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>

#include "assets_internal.h"
#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/tooling/image_doc.h"

namespace fa::imgedit {

namespace stdfs = std::filesystem;
using assets_detail::fail;

// ---- documents and layers -----------------------------------------------------------------------------------------

// The JSON of a document on disk. Throws CommandError (code invalid_argument / not_found) with a fix.
struct DocFile {
    std::string rel;  // project-relative, normalized
    Json json;
};
DocFile open_doc(const std::string& projectDir, const std::string& relArg, const char* command);
// A normalized project-relative document path that ends in .image.json (does not need to exist).
std::string doc_path_arg(const std::string& relArg, const char* command, const char* key = "path");

// A layer found in a document's JSON.
struct LayerRef {
    Json* layer = nullptr;
    Json* list = nullptr;             // the array it sits in (the document's `layers`, or a group's)
    int index = 0;                    // its position in `list`
    std::vector<int> path;            // index path from the root: {1, 0} is "1/0"
    std::string indexPath;            // "1/0"
    std::string pointer;              // "/layers/1/layers/0"
    int parentX = 0, parentY = 0;     // the summed offsets of the groups it sits in
    Json* parent = nullptr;           // the group that holds it, nullptr at the root
};
// `ref` is a layer name, an index path ("1/0": layer 1 of the document, then its child 0) or an integer. Throws a CommandError
// that lists the layers (and suggests the nearest name) when it matches none, or several.
LayerRef find_layer(Json& doc, const Json& ref, const char* command, const std::string& argName = "layer");
// The same, but returns false (and leaves `out` alone) when nothing matches; ambiguity still throws.
bool try_find_layer(Json& doc, const Json& ref, const char* command, const std::string& argName, LayerRef& out);
// "0 sky (gradient), 1 hero (pixels), 1/0 ..." for messages.
std::string describe_layers(const Json& doc, std::size_t max = 24);
std::vector<std::string> layer_names(const Json& doc);
// The layer as `index path`.
std::string index_path_string(const std::vector<int>& path);
// A name for a new layer that no layer of the document uses: "pixels", then "pixels 2", ...
std::string unique_layer_name(const Json& doc, const std::string& base);

// ---- results ------------------------------------------------------------------------------------------------------

struct Region {
    int x = 0, y = 0, width = 0, height = 0;
    bool empty() const { return width <= 0 || height <= 0; }
    Json to_json() const { return Json::object({{"x", x}, {"y", y}, {"width", width}, {"height", height}}); }
};
// The box of the pixels that differ between two pictures (empty when equal; the whole `after` when the sizes differ).
Region changed_region(const Image& before, const Image& after);

// The result of a command that baked: {document, path, width, height, written, ai, sha256, inputs, provenance, warnings,
// $image, nextSteps} (what image.bake returns).
Json bake_result_json(const std::string& projectDir, const ImageBakeResult& r);

// The picture of the document as it is now (None when it does not load: the region then covers the canvas).
// In an animated document the frame the running command works on (FrameScope in image_frames.h): frame 0 outside one.
std::optional<Image> render_document_json(const std::string& projectDir, const Json& doc);
// The same, with the onion skin the command asked for: what the preview shows. Never used to compare pictures.
std::optional<Image> render_preview_json(const std::string& projectDir, const Json& doc);

// Saves `doc` as `rel` (validates, writes, bakes) after a command changed it, and builds the result: the bake result plus
// `region` (the box that changed in the picture, compared with `before`), `changed`, and the picture as `$image`.
// `extra` members are merged into the result; `warnings` are appended to the result's.
Json commit_document(const std::string& projectDir, const std::string& rel, const Json& doc, const std::optional<Image>& before, bool bake,
                     Json extra, const std::vector<std::string>& warnings, const char* command);

// Renders layer `layerJson` alone (opacity 1, normal blend, not clipped, visible), at the canvas offset (offX, offY) added to its
// own x and y, onto a transparent canvas of width x height. Its masks, adjustments and effects are applied.
// `docJson` (the document the layer belongs to) supplies the `palette` and `ramps` an indexed layer needs.
Image render_layer_alone(const std::string& projectDir, const Json& layerJson, int width, int height, int offX, int offY,
                         std::vector<std::string>* warnings = nullptr, const Json* docJson = nullptr);

// ---- masks and selections -----------------------------------------------------------------------------------------

// A selection: coverage 0..255 per pixel of the canvas (255 = fully selected).
struct Mask {
    int w = 0, h = 0;
    std::vector<std::uint8_t> v;
    Mask() = default;
    Mask(int width, int height, std::uint8_t fill = 0) : w(width), h(height), v(std::size_t(width) * height, fill) {}
    std::uint8_t at(int x, int y) const { return x < 0 || y < 0 || x >= w || y >= h ? 0 : v[std::size_t(y) * w + x]; }
    std::uint8_t& ref(int x, int y) { return v[std::size_t(y) * w + x]; }
    std::size_t count(int threshold = 128) const;      // pixels with coverage >= threshold
    Region bounds() const;                              // the box of the pixels with coverage > 0
};
enum class CombineMode { Replace, Add, Subtract, Intersect };
void mask_combine(Mask& base, const Mask& other, CombineMode mode);
void mask_invert(Mask& m);
void mask_grow(Mask& m, float pixels);      // pixels with coverage >= 128 spread by a disc of this radius; the result is hard-edged
void mask_shrink(Mask& m, float pixels);
void mask_feather(Mask& m, float pixels);   // a Gaussian blur of the edge, sigma = pixels / 2

// Selections live in the project, next to the editor's other private files: .factoria/selections/<document path>/<name>.png, a
// grey PNG of the canvas's size (white = selected). A name is 1 to 40 letters, digits, '-' and '_'.
bool valid_selection_name(const std::string& name);
std::string selection_file(const std::string& rel, const std::string& name);   // project-relative
void save_selection(const std::string& projectDir, const std::string& rel, const std::string& name, const Mask& m);
// Throws a CommandError that lists the stored selections (and suggests the nearest) when there is none by that name, or when it
// was made for another canvas size. The name "all" is the whole canvas and needs no file.
Mask load_selection(const std::string& projectDir, const std::string& rel, const std::string& name, int canvasW, int canvasH, const char* command);
bool selection_exists(const std::string& projectDir, const std::string& rel, const std::string& name);
std::vector<std::string> list_selections(const std::string& projectDir, const std::string& rel);
// The picture with the unselected part dimmed and the edge of the selection marked; written to <name>.preview.png next to the
// selection, returns that path (project-relative).
std::string write_selection_preview(const std::string& projectDir, const std::string& rel, const std::string& name, const Image& picture, const Mask& m);

// ---- the pixels of one layer, to edit ----------------------------------------------------------------------------

// The layer's own pixels placed in CANVAS coordinates ((ox, oy) is the canvas position of img's top-left pixel).
struct Work {
    Image img;                 // straight-alpha RGBA8
    int ox = 0, oy = 0;
    bool fixedRect = false;    // a layer with masks keeps its box: edits outside it are dropped (its masks are in its own pixels)
    bool rasterized = false;   // the layer was not a pixels layer: it is turned into one when committed
    int originX = 0, originY = 0;   // the box the buffer started with, canvas coordinates
    std::string kind;          // the layer's kind before
    std::vector<std::string> warnings;
};
// Loads or renders the pixels of `ref` for editing. `expand` grows the buffer to the canvas when the layer is smaller (so
// pixels can be painted anywhere on it). A group and an adjustment layer cannot be edited: a teaching CommandError.
Work open_work(const std::string& projectDir, Json& doc, const LayerRef& ref, const char* command, bool expand, bool allowRasterize);
// Writes the buffer back: the layer's PNG (a pixels layer: its own file; another kind: a new file in <document>.layers/, and the
// layer becomes a pixels layer, its masks, adjustments and effects now part of the pixels). Updates `ref.layer`'s JSON.
void commit_work(const std::string& projectDir, const std::string& rel, Json& doc, const LayerRef& ref, Work& work, const char* command);
// A new pixels layer from `img` at canvas position (x, y): inserted above `above` in its parent (or at the top when `above` is
// null). Returns the new layer's index path.
std::string add_pixels_layer(const std::string& projectDir, const std::string& rel, Json& doc, const LayerRef* above, const std::string& name,
                             const Image& img, int canvasX, int canvasY, const char* command, bool ai = false);
// Writes a PNG of the project (record: provenance in assets.json as made by `command`). Returns false and sets `err` on failure.
void write_layer_png(const std::string& projectDir, const std::string& pngRel, const std::string& docRel, const Image& img, const char* command, bool ai);
std::string layer_png_path(const std::string& projectDir, const std::string& docRel, const std::string& layerName, const Json& doc);

// ---- commands -----------------------------------------------------------------------------------------------------

void register_edit_commands(CommandRegistry& registry, const std::string& projectDir);    // image_edit_commands.cpp
void register_select_commands(CommandRegistry& registry, const std::string& projectDir);  // image_select.cpp
void register_pixel_commands(CommandRegistry& registry, const std::string& projectDir);   // image_edit_pixels.cpp
void register_indexed_commands(CommandRegistry& registry, const std::string& projectDir);  // image_indexed.cpp
void register_pixel_helper_commands(CommandRegistry& registry, const std::string& projectDir);  // image_pixel_helpers.cpp
void register_tile_commands(CommandRegistry& registry, const std::string& projectDir);          // image_tile_commands.cpp

// ---- PSD (image_psd.cpp) ------------------------------------------------------------------------------------------

struct PsdLayer {
    std::string name;
    int x = 0, y = 0;                // top-left on the canvas
    Image pixels;                    // straight-alpha RGBA8 (empty for a group)
    float opacity = 1;
    bool visible = true;
    std::string blend = "normal";    // an ImageBlend name
    bool clip = false;
    bool isGroup = false;
    std::vector<PsdLayer> children;  // bottom first
};
struct PsdDocument {
    int width = 0, height = 0;
    std::vector<PsdLayer> layers;    // bottom first
    std::vector<std::string> warnings;
    int layerCount = 0;              // layer records in the file (groups included)
};
// Reads the layer tree of a Photoshop file (8 or 16 bit, RGB or grayscale; raw, RLE and zip channel data). An error says why
// the layers cannot be read (the importer then falls back to the merged image); a file with no layers gives layerCount 0.
Result<PsdDocument> read_psd_layers(const std::vector<std::uint8_t>& bytes, const std::string& file);

}  // namespace fa::imgedit
