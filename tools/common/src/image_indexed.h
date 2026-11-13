// Private declarations shared by the commands that work on indexed pixel-art layers: image.pixel / image.draw / image.palette /
// image.layer.convert (image_indexed.cpp) and the pixel helpers image.pixel.* / image.to_pixel_art (image_pixel_helpers.cpp).
#pragma once

#include <string>
#include <vector>

#include "fa/tooling/image_tile.h"
#include "fa/tooling/pixel_art.h"
#include "image_edit.h"

namespace fa::imgedit::indexed {

// The indexed layer a command edits, as a grid.
struct Target {
    LayerRef ref;
    PixelPalette pal;
    IndexGrid grid;
    int ox = 0, oy = 0;  // canvas position of the grid's top-left pixel
    Json extra = Json::object();
    std::vector<std::string> warnings;
    TileGrid tile;  // the document's tile mode (tile.on); the grid then covers every tile cell it touches
};

Json layer_summary(const LayerRef& r);
std::string layer_label(const LayerRef& r);
// The palette of the document (its own, else the style's); `force` resolves it even when no layer is indexed yet.
PixelPalette load_doc_palette(const std::string& projectDir, const std::string& rel, const Json& docJson, bool force,
                              const char* cmd);
// Writes the palette into the document when it has none; true when it did.
bool pin_palette(Json& docJson, const PixelPalette& pal);
// Replaces the result's `$image` with the picture magnified by whole pixels (see image.pixel).
void attach_preview(const std::string& projectDir, const std::string& rel, const Json& docJson, Json& out, int scale);
int scale_arg(const Json& a, const char* cmd);
// Finds the indexed layer `a.layer` (creating it with `create`), loads the palette (pinning it) and the layer's rows.
Target open_target(const std::string& projectDir, DocFile& d, const Json& a, const char* cmd);
// Writes the grid back into the layer's rows.
void store_grid(Target& t);

}  // namespace fa::imgedit::indexed
