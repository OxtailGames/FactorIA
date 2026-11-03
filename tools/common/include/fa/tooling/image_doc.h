// Layered image documents (*.image.json) and the one CPU compositor that draws them (docs/IMAGES.md).
//
// A document is the SOURCE of a picture: a canvas, and a list of layers (a PNG, a fill, a gradient, a procedural texture, an SVG,
// text, a provider-made picture, a group, an adjustment, an indexed pixel-art picture) with opacity, a blend mode, masks, clipping and an offset. The PNG a
// Sprite draws is BAKED from it next to the document ("hero.image.json" -> "hero.png") with the recipe in its provenance
// (assets.json), so `assets.regenerate` remakes it and a changed source warns as stale, like every offline maker.
//
// The commands (image.*) and the editor panel share this library: they edit the document's JSON, then call
// save_image_document, which validates, writes and bakes. Nothing here needs a GPU, a window or another program.
//
// Colour and alpha, decided once:
//   - Pixels are blended in the stored (sRGB-encoded) values, like Photoshop, GIMP and Aseprite do, so a multiply layer looks
//     as it does there. No linear-light conversion happens anywhere; gradients interpolate the encoded values too.
//   - PNGs and every raster layer are STRAIGHT alpha (colour not multiplied by alpha). The compositor works in float,
//     straight alpha, with the W3C compositing formula (alpha first, then the blend function of the two straight colours, so
//     a half-transparent layer never darkens or tints its edge). Gradients, masks and blurs interpolate premultiplied values.
//   - The result is quantized to 8 bits once, at the end. A fully transparent pixel is written as (0, 0, 0, 0).
//   - The same document and the same files give the same bytes (no clock, no random numbers, no threads) with the same build.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/tooling/pixel_art.h"

namespace fa {

inline constexpr const char* kImageDocFormat = "factoria.image/1";
inline constexpr const char* kImageDocSuffix = ".image.json";
inline constexpr int kImageDocMaxSide = 4096;

enum class ImageLayerKind { Pixels, Fill, Gradient, Procedural, Svg, Text, Provider, Group, Adjustment, Indexed };

enum class ImageBlend {
    Normal, Multiply, Screen, Overlay, Darken, Lighten, ColorDodge, ColorBurn, HardLight, SoftLight,
    Difference, Exclusion, Add, Subtract, Hue, Saturation, Color, Luminosity
};

// The JSON spelling ("colorDodge") of each, in the order above; null/empty for a name that is not one.
const char* image_blend_name(ImageBlend mode);
std::optional<ImageBlend> parse_image_blend(std::string_view name);
std::vector<std::string> image_blend_names();
// One pixel of the compositor: the straight-alpha colour `source` (its alpha already includes layer opacity, masks and clipping)
// drawn over the straight-alpha `backdrop` with `mode`, by the W3C compositing formula. The reference for the tests of every
// mode, and what the editor uses to show a colour under a blend mode.
Color blend_pixel(ImageBlend mode, Color backdrop, Color source);
const char* image_layer_kind_name(ImageLayerKind kind);
std::vector<std::string> image_layer_kind_names();

// The colour operations a layer's `adjustments` list may hold (and an adjustment layer applies to everything below it), and
// the `effects` that may change a layer's footprint (shadows, glows, outlines). Each entry is {"type": name, ...}.
struct ImageOpInfo {
    std::string name;
    std::string description;  // what it does and its fields, one paragraph
};
std::vector<ImageOpInfo> image_adjustment_types();
std::vector<ImageOpInfo> image_effect_types();

struct ImageGradientStop {
    float at = 0;  // 0..1 along the gradient
    Color color;
};
struct ImageGradient {
    bool radial = false;
    float angle = 0;                // linear: degrees, 0 runs from the top to the bottom, 90 from the left to the right
    Vec2 center{0.5f, 0.5f};        // radial: fractions of the layer's box
    float radius = 1;               // radial: 1 reaches the corners of the box (half its diagonal from the centre)
    std::vector<ImageGradientStop> stops;
};

struct ImageMask {
    enum class Type { Pixels, Rect, Ellipse, Polygon, Path };
    Type type = Type::Pixels;
    std::string pointer;            // "/layers/2/masks/0"
    bool invert = false;
    float feather = 0;              // pixels of soft edge (a blur of the mask), 0 = hard
    std::string source;             // pixels: a PNG of the project (white shows, black hides; its alpha counts too)
    int x = 0, y = 0;               // pixels: where the PNG sits; rect and ellipse: the box (with width and height)
    int width = 0, height = 0;
    std::vector<Vec2> points;       // polygon
    std::string path;               // SVG path data ("M10 10 L90 10 L50 80 Z"), coordinates in the layer's own pixels
};

struct ImageLayer {
    ImageLayerKind kind = ImageLayerKind::Fill;
    std::string pointer;            // "/layers/2" or "/layers/1/layers/0"
    std::string name;
    bool visible = true;
    float opacity = 1;
    ImageBlend blend = ImageBlend::Normal;
    int x = 0, y = 0;               // where the layer's own top-left corner lands on its parent (whole pixels, may be negative)
    bool clip = false;              // clipped to the opaque part of the layer below
    std::vector<ImageMask> masks;   // multiplied together; coordinates are the layer's own
    std::vector<Json> adjustments;  // colour operations on the layer's pixels, in order
    std::vector<Json> effects;      // footprint-changing operations, after the masks, in order

    // pixels and provider: a PNG. svg: a file, or the SVG text in `svg`.
    std::string source;
    std::string svg;
    Json provenance;                // provider: the record as assets.json keeps it (provider, model, prompt, ai, ...)
    // fill and gradient (and svg): the size of the layer's box; 0 = the canvas size (svg: fitted inside the canvas)
    int width = 0, height = 0;
    Color color{0, 0, 0, 1};        // fill and text
    ImageGradient gradient;
    Json texture;                   // procedural: the picture arguments of assets.generate_texture
    // text
    std::string text;
    std::string font;               // "" (DejaVu Sans), "builtin:pixel", ... or a project .ttf/.otf
    float size = 16;                // em height in pixels
    std::string align = "left";     // left, center or right of x
    float lineHeight = 1.2f;        // line spacing, in ems
    std::vector<ImageLayer> children;  // group: bottom first, like the document
    // indexed: the pixels as text rows, one character per pixel ('.' transparent, else a palette index: fa/tooling/pixel_art.h). Empty =
    // a blank layer of `width` x `height` (0 = the canvas size). The colours are the document's `palette`.
    std::vector<std::string> rows;
    bool ai = false;                // indexed: the pixels were made from an AI-made picture (image.layer.convert records it), so the bake is AI-made
};

struct ImageDocument {
    std::string file;               // the project-relative path it was read from ("" when parsed from memory)
    int width = 0, height = 0;
    std::optional<Color> background;
    std::string output;             // the PNG it bakes to (project-relative); "" = next to the document
    std::string description;
    // The palette indexed layers are locked to (the document's `palette`, or the style palette of assets.json) and its colour ramps.
    // Empty when the document has no indexed layer and declares no palette.
    PixelPalette palette;
    std::vector<ImageLayer> layers; // bottom first: later layers are drawn over earlier ones
    Json json;                      // the document as written
};

// One problem of a document, with the JSON pointer inside it.
struct ImageIssue {
    std::string pointer;
    std::string message;
    std::string hint;
};

// Reads and checks a document. EVERY problem found goes to `issues` (when given); on any problem the result is an error that
// carries the first one, with the file and pointer in its message. `projectDir` is where the files the layers name are looked
// for ("" = do not check that they exist). `file` only labels messages.
Result<ImageDocument> parse_image_document(const Json& json, const std::string& file, const std::string& projectDir,
                                           std::vector<ImageIssue>* issues = nullptr);
// The same for a project-relative file. A JSON syntax error is reported with its line and column.
Result<ImageDocument> load_image_document(const std::string& projectDir, const std::string& rel, std::vector<ImageIssue>* issues = nullptr);

struct ImageRenderOptions {
    std::string projectDir;         // where project-relative files (PNGs, SVGs, fonts) are read
};
struct ImageRender {
    Image image;                    // width x height, straight-alpha RGBA8
    std::vector<std::string> inputs;    // every project file read (sorted, no duplicates): what the recipe hashes
    std::vector<std::string> warnings;  // things that were ignored or clamped
};
// Draws the document. Fails (with the layer's pointer and a fix) when a file cannot be read or an SVG cannot be drawn.
Result<ImageRender> composite_image_document(const ImageDocument& doc, const ImageRenderOptions& options);

// ---- baking: the PNG next to the document -----------------------------------------------------------------------------

// The project-relative PNG a document at `rel` bakes to: its `output`, else `rel` with ".image.json" replaced by ".png".
std::string image_document_output(const ImageDocument& doc, const std::string& rel);

enum class ImageBakeState {
    Fresh,       // the PNG exists and the recipe in assets.json matches the document and every file it read
    Missing,     // no PNG yet
    Stale,       // the document or a file it reads changed since the PNG was baked
    Unrecorded,  // the PNG exists but assets.json does not say it was baked from this document
    Broken       // the document does not load
};
struct ImageBakeStatus {
    ImageBakeState state = ImageBakeState::Missing;
    std::string output;             // the PNG (project-relative); "" when Broken
    std::string reason;             // one sentence for a person
};
ImageBakeStatus image_bake_status(const std::string& projectDir, const std::string& rel);
const char* image_bake_state_name(ImageBakeState state);

struct ImageBakeOptions {
    bool onlyIfNeeded = false;      // do nothing when the status is Fresh
};
struct ImageBakeResult {
    std::string document;           // project-relative
    std::string output;             // the PNG, project-relative
    int width = 0, height = 0;
    bool written = false;           // false: it was Fresh and onlyIfNeeded was set
    bool ai = false;                // recorded as AI-made (a provider layer, or a file whose provenance says so)
    std::string sha256;             // of the PNG's bytes
    std::vector<std::string> inputs;
    std::vector<std::string> warnings;
    Json provenance;                // the record written to assets.json
};
// Composites the document and writes the PNG (deterministic bytes), then records provenance + recipe {command "image.bake",
// args {path}, inputs: the document and every file it read} in assets.json. Keeps the license and author a person recorded.
Result<ImageBakeResult> bake_image_document(const std::string& projectDir, const std::string& rel, const ImageBakeOptions& options = {});

// What an editor or command does on save: checks `document` (nothing is written when it has a problem), writes it to `rel`
// as canonical JSON (2-space indent, trailing newline) and bakes it. `bake: false` only writes.
Result<ImageBakeResult> save_image_document(const std::string& projectDir, const std::string& rel, const Json& document, bool bake = true);

// Every *.image.json of the project (project-relative, sorted; hidden folders, node_modules and a top-level build/ skipped).
std::vector<std::string> list_image_documents(const std::string& projectDir);
// Bakes the documents whose PNG is missing or stale (what `factoria export` does first). A document that does not load is an
// error naming it. Returns the baked documents.
Result<std::vector<ImageBakeResult>> bake_image_documents_if_needed(const std::string& projectDir);

}  // namespace fa
