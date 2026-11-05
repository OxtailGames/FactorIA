// The shape builders of vector.shape and vector.blob as paths (vector_shapes.cpp), the same geometry as the public functions of
// fa/tooling/vector.h, before it is written as path data.
#pragma once

#include "fa/tooling/vector.h"
#include "vector.h"

namespace fa::vec {

Path build_blob(const VecBlobSpec& s);
Path build_star(const VecStarSpec& s);
Path build_gear(const VecGearSpec& s);
Path build_polygon(const VecPolygonSpec& s);
Path build_arrow(const VecArrowSpec& s);
Path build_bubble(const VecBubbleSpec& s);

struct TextMetrics {
    double advance = 0;    // the widest line
    double lineHeight = 0;
    int lines = 1, glyphs = 0;
    std::vector<char32_t> missing;
};
// The outline of `text` in the engine's fonts as one path, in the em units of `size`, baseline origin at `at`. `anchor`: start, middle, end.
Result<Path> build_text(const std::string& text, const std::string& font, double size, P at, const std::string& anchor, double letterSpacing,
                        double lineSpacing, TextMetrics* metrics);

// A closed polygon with its corners rounded. `fillet(i, turn, shortest)` is the distance from vertex i, along both of its sides,
// where the curve leaves them; `turn` is the direction change at the vertex (radians), `shortest` its shorter side. The distance is
// cut to half of the shorter side so neighbours never overlap. 0 keeps the corner sharp.
Path round_corners(const Poly& v, const std::function<double(int i, double turn, double shortest)>& fillet);
// Cubic Beziers along the circle from angle a0 to a1 (degrees clockwise on screen; a1 < a0 goes the other way), added to `sp`, whose
// current end must already be the point at a0.
void arc_segments(SubPath& sp, P center, double r, double a0, double a1);
P polar(P center, double r, double degrees);

}  // namespace fa::vec
