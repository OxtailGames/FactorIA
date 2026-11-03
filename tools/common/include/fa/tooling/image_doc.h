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
//   - An animated document (`frames`, `tags`, `cels`) bakes a SPRITE SHEET; a document without them bakes the same PNG as ever.
//   - The same document and the same files give the same bytes (no clock, no random numbers, no threads) with the same build.
#pragma once

#include <map>
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

// A cel is what a pixels or indexed layer shows in one frame after the first. The layer's own `source` / `rows` / x / y is the cel of
// frame 0; a frame with no cel of its own keeps showing the cel before it (it is HELD), so a layer that never changes needs none.
struct ImageCel {
    std::string pointer;            // "/layers/1/cels/0"
    int frame = 1;                  // the frame it starts at (>= 1); cels are listed in increasing frame order
    bool empty = false;             // the layer shows nothing from this frame
    int link = -1;                  // >= 0: shows the same picture as the cel that is current at that earlier frame (a linked cel)
    std::string source;             // pixels: a PNG of the project
    std::vector<std::string> rows;  // indexed: the picture as text rows (fa/tooling/pixel_art.h)
    std::optional<int> x, y;        // where the cel's top-left corner lands; default: the layer's x and y
    float opacity = 1;              // multiplies the layer's opacity
};

// What a layer shows in one frame, resolved: held cels and links followed.
struct ImageCelView {
    bool empty = true;              // nothing is drawn (pixels: no source)
    const std::string* source = nullptr;                // pixels
    const std::vector<std::string>* rows = nullptr;     // indexed (null or empty: a blank layer)
    int x = 0, y = 0;
    float opacity = 1;
    int origin = 0;                 // the frame whose cel supplies it (frames with the same origin share one picture)
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
    // pixels and indexed: the cels of the frames after the first (see ImageCel). A pixels layer with `cels` may have no `source`: it is
    // empty in frame 0.
    std::vector<ImageCel> cels;
    bool hasCels = false;           // the JSON has a `cels` key (even an empty list)
};

// The cel `layer` shows in `frame` (0 = the layer's own content). Layers of other kinds show the same in every frame.
ImageCelView image_layer_cel(const ImageLayer& layer, int frame);

enum class ImageTagDirection { Forward, Reverse, PingPong };
const char* image_tag_direction_name(ImageTagDirection direction);
std::vector<std::string> image_tag_direction_names();

// One frame of an animated document.
struct ImageFrame {
    int duration = 100;             // milliseconds
};
// A named run of frames; the bake makes a SpriteAnimator clip of it.
struct ImageTag {
    std::string pointer;            // "/tags/0"
    std::string name;
    int from = 0, to = 0;           // first and last frame, inclusive
    ImageTagDirection direction = ImageTagDirection::Forward;
    int repeat = 0;                 // how many times it plays; 0 = it loops for ever
};
inline constexpr int kImageMaxFrames = 1024;

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
    // Animation. A document is animated when its JSON has `frames` or `tags`: the bake is then a sprite sheet (image_sheet below).
    bool animated = false;
    std::vector<ImageFrame> frames; // empty = one frame (a document that is not animated)
    std::vector<ImageTag> tags;
    int sheetColumns = 0;           // `sheet.columns`: frames per row of the baked sheet; 0 = ceil(sqrt(cells))
    Json json;                      // the document as written
};
// The number of frames (1 for a document with no `frames`).
int image_frame_count(const ImageDocument& doc);

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

// Onion skin: the frames around the one drawn, ghosted under it. A ghost is the frame with its colours pulled towards `beforeColor` /
// `afterColor` (60%) and its alpha multiplied by `opacity`, by 1/2 for the second frame away, 1/3 for the third, and so on.
struct ImageOnionSkin {
    int before = 1, after = 1;      // how many frames before and after (0 to 8)
    float opacity = 0.4f;           // of the nearest ghost
    Color beforeColor{1.0f, 0.25f, 0.25f, 1.0f};
    Color afterColor{0.25f, 0.5f, 1.0f, 1.0f};
    bool loop = false;              // frames wrap around: the frame before 0 is the last one
};

struct ImageRenderOptions {
    std::string projectDir;         // where project-relative files (PNGs, SVGs, fonts) are read
    int frame = 0;                  // which frame to draw (0 to image_frame_count - 1)
    std::optional<ImageOnionSkin> onion;  // ghost the neighbouring frames under it (a preview; never used by the bake)
    // Pictures that stand in for project files: a layer (or mask, or operation) that names a file found here as a key reads this picture
    // instead of the PNG on disk, and the file need not exist. The editor's Image panel shows a stroke being painted this way (the pixels
    // are not on disk yet). The bake never sets it. Pictures read this way are not listed in `inputs`.
    const std::map<std::string, Image>* pictures = nullptr;
};
struct ImageRender {
    Image image;                    // width x height, straight-alpha RGBA8
    std::vector<std::string> inputs;    // every project file read (sorted, no duplicates): what the recipe hashes
    std::vector<std::string> warnings;  // things that were ignored or clamped
};
// Draws the document (one frame: `options.frame`). Fails (with the layer's pointer and a fix) when a file cannot be read or an SVG
// cannot be drawn, or when the frame does not exist.
Result<ImageRender> composite_image_document(const ImageDocument& doc, const ImageRenderOptions& options);

// ---- the sprite sheet of an animated document -------------------------------------------------------------------------

// The clip of a tag as the sheet stores it. SpriteAnimator plays a contiguous run of cells at one speed, so a tag that is not a plain
// forward run of equal frames (reverse, ping-pong, repeated, frames of different durations) gets extra cells after the frames
// that spell out its play order.
struct ImageSheetClip {
    std::string name;
    int firstFrame = 0, lastFrame = 0;  // cells of the sheet, inclusive
    double fps = 10;
    bool loop = true;
};
struct ImageSheetPlan {
    int columns = 1, rows = 1;
    int cells = 0;                      // frames + the extra cells of the clips that need them
    std::vector<int> cellFrame;         // the document frame drawn in each cell (cells 0 .. frames-1 are the frames in order)
    std::vector<ImageSheetClip> clips;
    std::vector<std::string> warnings;  // a duration that could not be kept exactly
    Json sheet;                         // the `sheet` entry of assets.json
};
// How the document's frames and tags lay out in the sheet. Needs only the document (no files). Fails when the sheet would be larger
// than a texture (16384 px on a side).
Result<ImageSheetPlan> plan_image_sheet(const ImageDocument& doc);
// The sheet picture: every cell drawn (`plan.cellFrame`), left to right, top to bottom.
Result<ImageRender> composite_image_sheet(const ImageDocument& doc, const ImageSheetPlan& plan, const ImageRenderOptions& options);

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
    Json sheet;                     // animated document: the `sheet` entry written to assets.json (null otherwise)
    std::string sha256;             // of the PNG's bytes
    std::vector<std::string> inputs;
    std::vector<std::string> warnings;
    Json provenance;                // the record written to assets.json
};
// Composites the document and writes the PNG (deterministic bytes; for an animated document, the sprite sheet of its frames plus the
// SpriteAnimator clips of its tags in the `sheet` entry), then records provenance + recipe {command "image.bake",
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
