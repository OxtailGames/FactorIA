// What an image provider needs from an image document, and how its answer becomes a layer (docs/IMAGES.md, "Pictures from a
// provider"). The provider itself is in fa_ai (image.inpaint and image.generate_layer, tools/ai/src/image_provider_commands.cpp);
// this side knows the document: it renders the picture the provider paints over, reads the selection, and adds the `provider` layer
// with its mask. Nothing here calls a provider or the network.
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"

namespace fa {

// The document, picture and selection a provider call starts from.
struct ImageEditInput {
    std::string doc;            // project-relative path of the document, normalized
    int width = 0, height = 0;  // the canvas
    int frame = 0;              // the frame the picture is of (0 in a document with one frame)
    bool animated = false;      // the document has more than one frame
    std::string layer;          // the layer the picture is of ("" = the whole composite)
    Image picture;          // canvas-sized RGBA: the composite of `frame`, or `layer` alone; empty when not asked for
    std::string selection;  // the stored selection that was used ("" = none given)
    std::vector<std::uint8_t>
        mask;  // canvas-sized coverage 0..255 of the selection (255 = repaint); empty = no selection
    std::size_t selectedPixels = 0;  // pixels with coverage >= 128
    bool palette = false;            // the document has a palette (an indexed document): the result is quantized to it
    std::vector<std::array<std::uint8_t, 3>> colours;  // that palette
    std::vector<std::string> warnings;
};

// Reads {path, selection?, layer?, frame?, selectionName?} of a document. `selection` is the name of a stored selection ("all" is the
// whole canvas), or an object with the arguments of image.select (`by`, `x`, `y`, `width`, `height`, `color`, ...), stored under
// `selectionName` (default "inpaint") so the layer's mask and the history can point at it. `needSelection` makes the selection
// required; `needPicture` renders the picture. Throws CommandError with a fix (a wrong name lists the stored selections).
ImageEditInput image_edit_input(const std::string& projectDir, const Json& args, bool needSelection, bool needPicture,
                                const char* command);

// The project-relative path for a picture of `layerName` in `<document>.layers/` that no layer uses yet ("hero.layers/sky.png").
// The PNG is not written.
std::string image_provider_source_path(const std::string& projectDir, const std::string& doc,
                                       const std::string& layerName);

// A layer name no layer of the document has: `base`, then "base 2", ...
std::string image_unique_layer_name(const std::string& projectDir, const std::string& doc, const std::string& base);

// The layer `image.layer.add_provider` adds: arguments {path, source, name?, provenance, selection?, x?, y?, parent?, index?, bake?}.
// `source` is a PNG of the project (already written); `selection` is a stored selection (or "all") whose coverage becomes a `pixels`
// mask of the layer, copied next to the PNG so the layer does not change when the selection does.
Json image_layer_add_provider(const std::string& projectDir, const Json& args);

}  // namespace fa
