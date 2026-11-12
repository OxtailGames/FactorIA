// Measuring pictures against the house style (assets.json "style", fa/tooling/style_guide.h): the numbers a check needs from
// an image (colours, outline, brightness, light), where the scenes draw each texture and how big, and the verdict of every
// style rule that is set. Shared by `assets.check_art` (the full report) and `project.validate` (a warning for each rule
// that is clearly broken). docs/ASSETS.md, "Checking art: assets.check_art".
//
// The measurement of a file does not depend on the style, so it is cached under .factoria/art-cache/<sha256 of the file>
// and reused until the file changes: validate measures a project once and reads the cache afterwards.
#pragma once

#include <algorithm>
#include <cstdint>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/style_guide.h"
#include "fa/tooling/validate.h"

namespace fa {

class World;

struct ArtColour {
    std::uint8_t r = 0, g = 0, b = 0;
    std::uint32_t count = 0;  // pixels
};

// What the tools need to know about one picture, independent of the style. Pixels with alpha >= 128 are "visible".
struct ArtMeasure {
    int width = 0, height = 0;
    std::uint64_t visible = 0;     // pixels with alpha >= 128
    double partialShare = 0;       // pixels with 0 < alpha < 255, as a share of the pixels with alpha > 0
    int distinct = 0;              // distinct colours among the visible pixels
    bool exact = true;             // `colours` lists every distinct colour (else: 5-bit bins, the mean colour of each)
    std::vector<ArtColour> colours;  // most used first, at most 512
    double valueLow = 0, valueHigh = 0;  // HSV value of the 1st and 99th percentile of the visible pixels, 0..1
    double saturationMean = 0;     // mean HSV saturation of the visible pixels, 0..1
    // The silhouette ring: visible pixels next to a pixel with alpha < 128 (the picture's own edge does not count).
    std::uint64_t ringPixels = 0;
    std::vector<ArtColour> ringColours;  // the commonest colours of the ring (5-bit bins), at most 8
    double ringWidth = 0;          // median thickness, in pixels, of the line of the commonest ring colour
    // Which way the shading leans: the direction in which pixels get brighter, as degrees towards the light (counter-clockwise
    // from the right) and how strong the lean is (0 = none, 1 = a perfect gradient). Cells of a sheet are measured one by one.
    double lightDegrees = 0;
    double lightStrength = 0;
    int blockSize = 0;             // pixel art drawn k x k blocks: the largest k in 2..8 (1 = plain pixels, 0 = not pixel art)
    int cellWidth = 0, cellHeight = 0;  // the cells the light was measured in (0 = the whole picture)

    Json to_json() const;
    static std::optional<ArtMeasure> from_json(const Json& j);
};

// The thickness of the outline line of a picture, or 0 when the commonest colour of its edge is a fill rather than a line
// (its runs are longer than a quarter of the picture's short side, at least 4 px).
inline double outline_line_width(const ArtMeasure& m) {
    const double shortSide = double(std::min(m.cellWidth > 0 ? m.cellWidth : m.width, m.cellHeight > 0 ? m.cellHeight : m.height));
    return m.ringWidth > 0 && m.ringWidth <= std::max(4.0, shortSide / 4.0) ? m.ringWidth : 0.0;
}

// Measures `img`. A cell size above 0 makes the light measurement per cell (a sprite sheet).
ArtMeasure measure_art(const Image& img, int cellWidth = 0, int cellHeight = 0);

// The measurement of the project file `rel`, from the cache when the file has not changed. `fromCache` tells which.
// Writing the cache is best effort. Error: the file is missing or not a picture.
Result<ArtMeasure> measure_art_file(const std::string& projectDir, const std::string& rel, bool* fromCache = nullptr);

// ---- where the scenes draw a texture ---------------------------------------------------------------------------

// One Sprite that draws a texture, as the scenes place it.
struct TextureUse {
    std::string scene;         // the scene or prefab file
    std::string texture;       // project-relative
    double framePx[2] = {0, 0};  // texture pixels drawn: the region, the sheet frame or the whole texture
    double world[2] = {0, 0};    // size in world units after the Sprite size and the scale of the entity and its parents
    int layer = 0;
    bool screenSpace = false;  // a UI sprite: its size is in design pixels
    bool nearest = true;       // Sprite.pixelArt: nearest-neighbour filtering
    bool stretched = false;    // 9-slice: not drawn at one scale
};

// What a scene's camera shows.
struct SceneView {
    std::string scene;
    bool hasCamera = false;
    double halfHeight = 0;     // world units from the middle to the top edge (orthographic); 0 = the design height / 2
    Color clear{0.08f, 0.08f, 0.12f, 1};
    bool clears = true;
    // Sprites that cover half of the view or more, below the layer of others: what is drawn behind the sprites of the scene.
    struct Backdrop {
        std::string texture;
        int layer = 0;
    };
    std::vector<Backdrop> backdrops;
};

struct ProjectArtUse {
    int designWidth = 1280, designHeight = 720;
    std::string orientation = "landscape";
    std::vector<TextureUse> uses;
    std::vector<SceneView> views;
    // Uses of `texture`, most of the project's scenes first.
    std::vector<const TextureUse*> of(const std::string& texture) const;
    const SceneView* view_of(const std::string& scene) const;
};

// Adds the Sprites and the camera of a loaded scene (or an instantiated prefab) to `use`. The VFS root must be the project
// (texture and sheet sizes are read through it).
void collect_art_use(World& world, const std::string& sceneFile, ProjectArtUse& use);
// Reads the design resolution and orientation of factoria.json "display" into `use` (defaults when absent).
void read_art_display(const std::string& projectDir, ProjectArtUse& use);
// Reads factoria.json for the design resolution and loads every scene and prefab to collect their Sprites.
ProjectArtUse scan_art_use(const std::string& projectDir);

// Texture pixels per world unit of a use (0 when the use has no fixed scale: screen space or 9-slice).
double texels_per_unit(const TextureUse& u);
// The median of the distinct values of `uses` (0 when none has one).
double median_texels_per_unit(const std::vector<const TextureUse*>& uses);

// The size, in screen pixels, of the longer side of `u` as the camera of `view` shows it on a screen of the given size.
// The design resolution maps to the screen by "fit" (the whole design area inside the screen).
double on_screen_px(const TextureUse& u, const SceneView* view, const ProjectArtUse& project, double screenWidth, double screenHeight);

// The screens readability is judged on: a phone (logical points, so a 1280x720 game shown "fit" is scaled by 0.54) and a
// desktop monitor. Portrait projects get the same sizes turned.
struct ReferenceScreens {
    double phoneWidth = 844, phoneHeight = 390;
    double desktopWidth = 1920, desktopHeight = 1080;
};
ReferenceScreens reference_screens(const ProjectArtUse& project);

// ---- the verdict of each rule ----------------------------------------------------------------------------------

enum class Verdict { Ok, Warn, Fail };
const char* verdict_name(Verdict v);
inline Verdict worse(Verdict a, Verdict b) { return int(a) >= int(b) ? a : b; }

struct ArtRule {
    std::string rule;      // "outline.color", "palette.offShare"...
    double value = 0;      // what was measured
    double threshold = 0;  // the limit of "ok"
    std::optional<double> failThreshold;  // the limit of "warn", when there is one
    Verdict verdict = Verdict::Ok;
    std::string message;   // what the number means, for this asset
    std::string hint;      // the fix: a real command or setting
    Json detail;           // more numbers (object), or null

    Json to_json() const;
};

// The thresholds the verdicts use, so docs and tests quote the same numbers.
struct ArtThresholds {
    static constexpr double outlineColourDistance = 48;  // a pixel this close (RGB, 0..441) to the outline colour is on it
    static constexpr double outlineShareOk = 0.8, outlineShareWarn = 0.5;
    static constexpr double outlineWidthWarn = 1.0, outlineWidthFail = 2.0;  // pixels away from the style's width
    static constexpr double rangeWarn = 0.05, rangeFail = 0.15;               // beyond value / saturation limits
    static constexpr double texelsWarn = 0.15, texelsFail = 0.35;             // relative difference to texelsPerUnit
    static constexpr double lightWarnDegrees = 45, lightFailDegrees = 90;
    static constexpr double lightMinStrength = 0.1, lightFullStrength = 0.2;
    static constexpr double pixelEdgeWarn = 0.01, pixelEdgeFail = 0.05;       // partial-alpha share of a pixel-art edge
    static constexpr int pixelColoursWarn = 64, pixelColoursFail = 256;
    static constexpr double paletteDistancePixelArt = 2;   // RGB distance a pixel may be from the palette in pixel art
    static constexpr double paletteDistance = 40;          // ... in other art
    static constexpr double offShareWarnPixelArt = 0.001, offShareFailPixelArt = 0.02;
    static constexpr double offShareWarn = 0.2, offShareFail = 0.5;
};

// Evaluates the style rules that are SET in `style` against one measurement: outline.color, outline.width, value.min/max,
// saturation.min/max, lightDirection, pixelArt.edges, pixelArt.colours, palette.offShare, and texelsPerUnit when the
// scenes use the texture (`uses`). Rules that are not set produce nothing. A rule that cannot be judged for this picture
// (an opaque tile has no silhouette, a flat picture has no light) is left out.
std::vector<ArtRule> evaluate_style_rules(const ArtMeasure& m, const StyleGuide& style, const std::vector<const TextureUse*>& uses);

// A rule the style scope left out of a check, and why (docs/ASSETS.md, "Scoping the style rules").
struct StyleSkip {
    std::string rule;    // the rule that was produced, e.g. "texelsPerUnit"
    std::string reason;  // "role ui (assets.json provenance.role)", "style.ignore entry assets/fx/ (rules: outline)"
};

// The role of `path`: provenance.role of its entry in `manifest` (the parsed assets.json), else the first style.roles glob that names it,
// else "". `source` tells which one ("provenance.role" or "style.roles <glob>").
std::string style_role_of(const Json& manifest, const StyleGuide& style, const std::string& path, std::string* source = nullptr);

// Removes from `rules` the ones the style does not ask of this asset: those named by a style.ignore entry that lists rules for `path`, and
// those its `role` turns off (style_role_skips). Every removed rule goes to `skipped` with the reason, so a check can say what it left out.
void apply_style_scope(const StyleGuide& style, const std::string& path, const std::string& role, const std::string& roleSource, std::vector<ArtRule>& rules,
                       std::vector<StyleSkip>& skipped);

// The warnings of `project.validate` for the textures in `textures` (project-relative, those a Sprite draws): one for each
// style rule that is clearly broken (verdict fail), naming the rule, the numbers and the fix. Nothing when the project's
// style sets no art rule. `uses` comes from the scenes validate has loaded.
void check_art_style(const std::string& projectDir, const std::set<std::string>& textures, const ProjectArtUse& use,
                     std::vector<ValidationIssue>& warnings);

}  // namespace fa
