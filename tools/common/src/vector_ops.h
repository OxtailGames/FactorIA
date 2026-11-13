// The operations of the vector.* commands on an SvgDoc (vector_svg.h). Each takes the elements the command picked, computes every
// change first and only then writes, so an operation that fails leaves the document as it was. Each returns the JSON summary the
// command merges into its result. The tolerance and every distance are in the drawing space (viewBox units).
#pragma once

#include <array>
#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "vector.h"
#include "vector_svg.h"

namespace fa::vec {

struct Settings {
    double tol = 0.05;        // the largest distance between a result and the exact outline, in drawing units
    int gridDecimals = 3;     // the integer grid the clipping runs on
    int outDecimals = 3;      // digits after the point in written path data
    bool curves = true;       // fit Beziers to the result; false keeps the polygon
    double cornerAngle = 28;  // direction change (degrees) above which a vertex stays a sharp corner
};
// The default tolerance for a drawing: 1/4000 of its longer side.
Settings default_settings(const Rect& canvas);
// The same settings with another tolerance (grid and digits follow).
Settings with_tolerance(Settings s, double tol);
// The settings for an element's own space, which `scale` times the drawing space (tolerance and digits follow).
Settings local_settings(const Settings& s, double scale);

// Picked elements to the shapes they stand for (groups expand to their shapes, in document order, each once). A pick with no shape
// adds a warning; throws when there is none at all.
std::vector<XNode*> expand_shapes(const std::vector<XNode*>& picked, const char* command,
                                  std::vector<std::string>& warnings);

// vector.boolean: the first shape's outline becomes the result; the other shapes go (unless `keepInputs`).
Json op_boolean(SvgDoc& doc, BoolOp op, const std::vector<XNode*>& picked, const Settings& s, bool keepInputs,
                std::vector<std::string>& warnings);
// vector.offset
Json op_offset(SvgDoc& doc, const std::vector<XNode*>& picked, double distance, Join join, double miterLimit, bool copy,
               const Settings& s, std::vector<std::string>& warnings);

struct StrokeOverrides {
    std::optional<double> width;
    std::optional<Cap> cap;
    std::optional<Join> join;
    std::optional<double> miterLimit;
    std::optional<std::vector<double>> dashes;  // empty = solid
    std::optional<double> dashOffset;
    std::optional<std::string> paint;  // the colour of a shape that has no stroke of its own
};
// vector.stroke_to_path
Json op_stroke_to_path(SvgDoc& doc, const std::vector<XNode*>& picked, const StrokeOverrides& ov, const Settings& s,
                       std::vector<std::string>& warnings);
// vector.simplify / vector.smooth
Json op_simplify(SvgDoc& doc, const std::vector<XNode*>& picked, const Settings& s, std::vector<std::string>& warnings);
Json op_smooth(SvgDoc& doc, const std::vector<XNode*>& picked, double smoothness, const Settings& s,
               std::vector<std::string>& warnings);

enum class Axis { Horizontal, Vertical };
struct AlignArgs {
    std::string horizontal;  // "", left, center, right
    std::string vertical;    // "", top, middle, bottom
    std::string to;          // selection, canvas, key
    XNode* key = nullptr;
    bool visual = true;  // measure with the stroke
};
// vector.align / vector.distribute
Json op_align(SvgDoc& doc, const std::vector<XNode*>& units, const AlignArgs& a, std::vector<std::string>& warnings);
struct DistributeArgs {
    Axis axis = Axis::Horizontal;
    std::string by = "gaps";  // gaps, centers
    std::optional<double> spacing;
    bool visual = true;
};
Json op_distribute(SvgDoc& doc, const std::vector<XNode*>& units, const DistributeArgs& a,
                   std::vector<std::string>& warnings);

struct RepeatArgs {
    std::string mode;  // grid, radial
    int columns = 1, rows = 1;
    double gapX = 0, gapY = 0;
    int count = 0;
    std::optional<P> center;
    std::optional<double> radius;
    double sweep = 360;
    bool orient = true;
    double rotation = 0;
    bool visual = true;
};
// vector.repeat
Json op_repeat(SvgDoc& doc, XNode& unit, const RepeatArgs& a, std::vector<std::string>& warnings);

// Things in the document the operations do not read or cannot move (CSS rules in <style>, <use>), for the command's warnings.
std::vector<std::string> document_warnings(const SvgDoc& doc);

// vector.info
Json op_info(const SvgDoc& doc, const std::vector<XNode*>& only, std::vector<std::string>& warnings);

// Applies `m` (a transform of the drawing space, written `mText`, e.g. "rotate(30 50 50)") to the element: its own transform becomes the
// one that, inside its parents, moves it by `m`. The attribute keeps the readable form where the parents do not transform. Ids, groups and
// everything else stay.
void apply_canvas_transform(XNode& n, const Mat& m, const std::string& mText, const char* cmd);

// The bounds of an element (a shape, or the shapes under a group) in the drawing space; `visual` adds half the stroke width.
// False with `why` when it has nothing to measure.
bool unit_bounds(XNode& unit, bool visual, Rect& out, std::string& why);

// ---- vector.style --------------------------------------------------------------------------------------------------

struct StyleArgs {
    std::optional<double> outlineWidth;  // pixels of the SVG's declared size; set = apply an outline
    std::string outlineColour;           // a CSS colour
    std::optional<std::vector<std::array<std::uint8_t, 3>>> palette;  // set = snap colours to it
};
Json op_style(SvgDoc& doc, const std::vector<XNode*>& picked, bool wholeDocument, const StyleArgs& a,
              std::vector<std::string>& warnings);

// Colour of a CSS colour value as 0..255 RGB and alpha 0..1; false for none, url(), currentColor, inherit, unknown names.
bool parse_css_colour(const std::string& text, std::array<std::uint8_t, 3>& rgb, double& alpha);

// ---- shape builders (vector_build.cpp): new elements, mirror, shade ------------------------------------------------------

// Where a new element goes and how it looks. Its coordinates are the parent's own (the same numbers you would type into the SVG).
struct Placement {
    XNode* parent = nullptr;            // null = the root <svg>
    XNode* before = nullptr;            // insert in front of this element (its parent is the parent)
    std::string id;                     // the wanted id; empty = a name from the kind
    std::string transform;              // the transform attribute of the new element
    std::string fill, stroke, opacity;  // CSS colours; empty = the default for the kind
    std::optional<double> strokeWidth;
    std::map<std::string, std::string> attrs;  // any other attribute (class, stroke-linecap...)
    bool lineArt = false;  // the default look is a stroke without fill (an open curve), else a fill without stroke
    double defaultStrokeWidth = 2;
};
// A <path> with `path` as its data (parent coordinates) at the placement. Returns {element, nodes, bounds (drawing space)}.
Json op_add_path(SvgDoc& doc, const Placement& at, const std::string& baseId, const Path& path, const Settings& s,
                 std::vector<std::string>& warnings);
struct RibbonPiece {
    std::string suffix, d, fill;  // the id suffix, the path data, the fill (empty = the placement's fill)
};
// A new element <tag> with the given attributes (written in this order after the id) at the placement, styled like the other builders do.
// Returns {element, bounds (drawing space), parent}.
Json op_add_node(SvgDoc& doc, const Placement& at, const std::string& baseId, const std::string& tag,
                 const std::vector<std::pair<std::string, std::string>>& attrs, const char* command);
// A <g> holding several paths, back to front.
Json op_add_group(SvgDoc& doc, const Placement& at, const std::string& baseId, const std::vector<RibbonPiece>& pieces,
                  const Settings& s, std::vector<std::string>& warnings);

struct MirrorArgs {
    Axis axis = Axis::Vertical;     // Vertical: the mirror line is vertical (x = at), left and right swap
    std::string atMode = "canvas";  // canvas, start, end, or "value" with `at`
    double at = 0;
    bool weld = true;
    std::optional<double>
        snap;  // points this close to the axis are put on it before welding (default: twice the tolerance)
};
// vector.mirror
Json op_mirror(SvgDoc& doc, const std::vector<XNode*>& picked, const MirrorArgs& a, const Settings& s,
               std::vector<std::string>& warnings);

struct ShadeArgs {
    double lightDegrees = 135;  // the direction TOWARDS the light, counter-clockwise from +x, as in the style guide
    std::string lightSource = "default";
    std::optional<double> depth, highlightDepth;
    bool shadow = true, highlight = true;
    std::string shadowColour, highlightColour;  // CSS colours; empty = derived from the fill
    double strength = 0.12;                     // OKLab lightness the derived colours differ by
    double shadowOpacity = 1, highlightOpacity = 1;
    std::optional<std::vector<std::array<std::uint8_t, 3>>>
        palette;  // the style palette: colours come from it when the fill is in it
};
// vector.shade
Json op_shade(SvgDoc& doc, const std::vector<XNode*>& picked, const ShadeArgs& a, const Settings& s,
              std::vector<std::string>& warnings);

struct TextArgs {
    std::string text, font, anchor = "start";
    double size = 24, letterSpacing = 0, lineSpacing = 1;
    P at{};
};
// vector.text_to_path for new text (the placement's parent coordinates)
Json op_add_text(SvgDoc& doc, const Placement& at, const TextArgs& a, const Settings& s,
                 std::vector<std::string>& warnings);
// ... and for <text> elements of the drawing: each becomes a <path> with its id, fill, class and transform.
Json op_text_to_path(SvgDoc& doc, const std::vector<XNode*>& picked, const std::string& font, const Settings& s,
                     std::vector<std::string>& warnings);

// Colours: a shade of an RGB colour in OKLab (direction -1 darker, +1 lighter, `amount` lightness units), as "#rrggbb".
std::string oklab_shift(const std::array<std::uint8_t, 3>& rgb, int direction, double amount);

}  // namespace fa::vec
