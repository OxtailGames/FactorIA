// Vector shape builders as SVG path data (docs/VECTOR.md): the geometry behind vector.shape, vector.blob and vector.text_to_path,
// for code that wants a shape without going through a command (the editor's Vector panel, vector.to_rig). Each function returns the
// `d` of a <path>: absolute commands, lines and cubic Beziers, y DOWN like SVG, angles in degrees clockwise on screen with 0 pointing
// right (so -90 points up). The specs are only clamped to what the geometry can draw; the commands check the arguments and teach.
#pragma once

#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

struct VecPoint {
    double x = 0, y = 0;
};

// A smooth closed blob or open curve from a few points. `around` = false: the curve passes THROUGH the points (a cardinal spline,
// `tension` 0 = straight lines between them, 0.5 = Catmull-Rom, up to 1 = loose and overshooting). `around` = true: the points are a
// control polygon the curve stays inside of and never touches (a uniform cubic B-spline; `tension` is not used).
struct VecBlobSpec {
    std::vector<VecPoint> points;  // at least 3 when closed, 2 when open
    bool closed = true;
    bool around = false;
    double tension = 0.5;
};
struct VecStarSpec {
    VecPoint center;
    double radius = 40;       // to the tips
    int points = 5;           // 3 to 128
    double innerRatio = 0.5;  // the radius of the valleys as a fraction of `radius`
    double roundness = 0;     // 0 sharp, 1 as round as the edges allow
    double rotation = -90;    // where the first tip points
};
struct VecGearSpec {
    VecPoint center;
    double radius = 40;  // to the tips of the teeth
    int teeth = 8;       // 3 to 128
    double depth = 0.2;  // the height of a tooth as a fraction of `radius`
    double toothWidth =
        0.5;            // the width of a tooth at its tip as a fraction of the pitch (the distance between two teeth)
    double hole = 0.3;  // the radius of the centre hole as a fraction of `radius`, 0 for none
    double rotation = -90;  // where the first tooth points
};
struct VecPolygonSpec {
    VecPoint center;
    double radius = 40;  // of the circle through the corners
    int sides = 6;       // 3 to 128
    double cornerRadius =
        0;  // the radius of the rounded corners, in drawing units (cut down where the sides are too short)
    double rotation = -90;  // where the first corner points
};
struct VecArrowSpec {
    VecPoint from, to;  // the tail end of the shaft and the tip of the head
    double shaftWidth = 8;
    double headLength = 20;  // from the tip back along the arrow
    double headWidth = 24;
    double curve =
        0;  // bend: 0 straight; the sagitta as a fraction of the length, positive bends to the right of from -> to
};
struct VecBubbleSpec {
    VecPoint center;
    double width = 80, height = 50;
    double cornerRadius = 10;
    bool hasTail = true;
    VecPoint tailTo;             // the tip of the tail, outside the box
    double tailWidth = 14;       // where it leaves the box
    double tailRoundness = 0.5;  // 0 sharp tip, 1 as round as the tail allows
};
// A banner: a front band with a folded tail behind each end. Pieces back to front.
struct VecRibbonSpec {
    VecPoint center;
    double width = 90, height = 24;  // of the front band
    double extent = 18;              // how far each tail sticks out past the band
    double drop = 8;                 // how far the tails sit lower than the band
    double notch = 7;                // the depth of the V cut in the end of a tail, 0 for a straight end
};
struct VecRibbonPieces {
    std::string leftTail, rightTail, leftFold, rightFold, band;  // path data
};

std::string vector_blob_path(const VecBlobSpec& s, int decimals = 3);
std::string vector_star_path(const VecStarSpec& s, int decimals = 3);
std::string vector_gear_path(const VecGearSpec& s, int decimals = 3);
std::string vector_polygon_path(const VecPolygonSpec& s, int decimals = 3);
std::string vector_arrow_path(const VecArrowSpec& s, int decimals = 3);
std::string vector_bubble_path(const VecBubbleSpec& s, int decimals = 3);
VecRibbonPieces vector_ribbon_paths(const VecRibbonSpec& s, int decimals = 3);

// Text as path data (engine fonts, HarfBuzz shaping, see outline_text in fa/render/fonts.h): `size` is the em in drawing units,
// (x, y) the baseline origin, `anchor` "start", "middle" or "end". Returns the `d` of one path (nonzero fill) and, if given, the advance
// of the widest line and the number of glyphs drawn. An unreadable font is an error.
Result<std::string> vector_text_path(const std::string& text, const std::string& font, double size, VecPoint at,
                                     const std::string& anchor, double letterSpacing, int decimals,
                                     double* advance = nullptr, int* glyphs = nullptr);

}  // namespace fa
