// Private declarations of the vector.* commands (docs/VECTOR.md). SVG stays the document: these sources read an SVG into a small
// element tree that writes back exactly what it read, turn shapes into paths, run the operations (path booleans, offset, stroke to
// path, simplify, smooth, align, distribute, repeat, style) and put the result back as an element. The public entry point for other
// tools (the editor's Vector panel, the shape builders of M54.2) is fa/tooling/vector.h.
//
//   vector_geom.cpp      points, matrices, the path model, path data (parse and write), shapes to paths, flattening, bounds
//   vector_fit.cpp       Bezier fitting (Schneider), simplify, smooth: polylines back to curves
//   vector_clip.cpp      Clipper2 (external/clipper2): booleans and offsets of polygons; the stroker (caps, joins, dashes)
//   vector_svg.cpp       the SVG element tree, ids and selectors, presentation attributes, element geometry
//   vector_ops.cpp       the operations on an SVG document
//   vector_style.cpp     vector.style
//   vector_commands.cpp  the commands: files, image documents, the preview
#pragma once

#include <cmath>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa::vec {

// ---- points and matrices ----------------------------------------------------------------------------------------

struct P {
    double x = 0, y = 0;
};
inline P operator+(P a, P b) { return {a.x + b.x, a.y + b.y}; }
inline P operator-(P a, P b) { return {a.x - b.x, a.y - b.y}; }
inline P operator*(P a, double k) { return {a.x * k, a.y * k}; }
inline double dot(P a, P b) { return a.x * b.x + a.y * b.y; }
inline double cross(P a, P b) { return a.x * b.y - a.y * b.x; }
inline double len(P a) { return std::sqrt(a.x * a.x + a.y * a.y); }
inline double dist(P a, P b) { return len(a - b); }
inline P unit(P a) {
    const double l = len(a);
    return l < 1e-12 ? P{0, 0} : P{a.x / l, a.y / l};
}

// x' = a x + c y + e, y' = b x + d y + f (the SVG matrix(a b c d e f)).
struct Mat {
    double a = 1, b = 0, c = 0, d = 1, e = 0, f = 0;
    P apply(P p) const { return {a * p.x + c * p.y + e, b * p.x + d * p.y + f}; }
    P apply_vector(P p) const { return {a * p.x + c * p.y, b * p.x + d * p.y}; }
    double det() const { return a * d - b * c; }
    // The factor lengths grow by on average (sqrt of |det|); exact for a rotation with a uniform scale.
    double scale() const { return std::sqrt(std::fabs(det())); }
    bool is_identity() const { return a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0; }
    bool invertible() const { return std::fabs(det()) > 1e-12; }
};
Mat operator*(const Mat& p, const Mat& q);  // apply q first, then p
Mat inverse(const Mat& m);                  // identity when not invertible
Mat translation(double dx, double dy);
Mat rotation(double degrees, double cx, double cy);
// A transform attribute ("translate(10 5) rotate(30)"). False and `err` set when it cannot be read.
bool parse_transform(const std::string& text, Mat& out, std::string& err);
// "matrix(...)" with the shortest exact form: translate(x y), scale, rotate or matrix.
std::string transform_to_string(const Mat& m, int decimals);

struct Rect {
    double x0 = 1e300, y0 = 1e300, x1 = -1e300, y1 = -1e300;
    bool empty() const { return x1 < x0 || y1 < y0; }
    void add(P p) {
        x0 = std::min(x0, p.x);
        y0 = std::min(y0, p.y);
        x1 = std::max(x1, p.x);
        y1 = std::max(y1, p.y);
    }
    void add(const Rect& r) {
        if (r.empty()) return;
        add(P{r.x0, r.y0});
        add(P{r.x1, r.y1});
    }
    double width() const { return empty() ? 0 : x1 - x0; }
    double height() const { return empty() ? 0 : y1 - y0; }
    P center() const { return {(x0 + x1) * 0.5, (y0 + y1) * 0.5}; }
};

// ---- the path model -----------------------------------------------------------------------------------------------

// One segment from the previous point to `p`: a line, or a cubic Bezier with control points c1 and c2.
struct Seg {
    bool cubic = false;
    P c1, c2, p;
};
struct SubPath {
    P start;
    std::vector<Seg> segs;
    bool closed = false;  // a closed subpath ends with an implicit line back to `start`
};
using Path = std::vector<SubPath>;

// A polygon or polyline: the points of a flattened subpath. A closed one does not repeat the first point.
using Poly = std::vector<P>;
struct Ring {
    Poly pts;
    bool closed = true;
};

// SVG path data (every command, relative or absolute; arcs and quadratics become cubics). False with `err` set.
bool parse_path_data(const std::string& d, Path& out, std::string& err);
// Absolute path data with `decimals` digits after the point (trailing zeros dropped).
std::string path_to_data(const Path& p, int decimals);
std::string format_number(double v, int decimals);

Path transform_path(const Path& p, const Mat& m);
Rect path_bounds(const Path& p);  // exact for the curves
int node_count(const Path& p);
bool has_curves(const Path& p);
bool has_closed(const Path& p);

// The path as polylines: curves cut into straight pieces no further than `tol` from the curve, and never turning more than about
// 6 degrees at a vertex (so a curve is recognisable as one afterwards). Zero-length pieces are dropped.
std::vector<Ring> flatten_path(const Path& p, double tol);
// Only the closed subpaths, as rings (what a fill covers).
std::vector<Poly> fill_rings(const Path& p, double tol);

// A path from rings (lines only).
Path path_from_rings(const std::vector<Ring>& rings);
// Circle/ellipse/rounded rectangle as paths, for the shape builders and tests.
Path ellipse_path(double cx, double cy, double rx, double ry);
Path rect_path(double x, double y, double w, double h, double rx, double ry);

// ---- fitting ------------------------------------------------------------------------------------------------------

struct FitOptions {
    double tolerance = 0.1;      // the largest distance between the fitted curve and the points
    double cornerAngle = 28;     // degrees of direction change at a vertex above which it stays a sharp corner
};
// Lines and cubic Beziers through the polylines: corners stay corners, straight stretches become single lines, curved stretches
// become as few cubics as the tolerance allows. Closed rings stay closed.
Path fit_rings(const std::vector<Ring>& rings, const FitOptions& opt);
// Fewer nodes: a path with curves is refitted from its flattened outline (the tolerance holds); a path of straight lines only
// loses the vertices within the tolerance of the line between their neighbours (Douglas-Peucker).
Path simplify_path(const Path& p, double tolerance, double cornerAngle);
// Every node that is not a corner (turning less than `cornerAngle` degrees at it) gets smooth handles: `smoothness` 0 leaves the
// segments straight, 1 is the usual round curve through the nodes. Straight pieces and curves alike are rebuilt from the nodes.
Path smooth_path(const Path& p, double smoothness, double cornerAngle);

// ---- polygon operations (Clipper2) ------------------------------------------------------------------------------

enum class BoolOp { Union, Subtract, Intersect, Xor };
enum class Join { Round, Miter, Bevel, Square };
enum class Cap { Butt, Round, Square };

// `decimals`: the grid the integer clipping runs on (10^-decimals of a unit); pick it well below the fit tolerance.
struct ClipGrid {
    int decimals = 3;
};
// Overlapping rings made into the clean non-overlapping outlines of what they cover (holes included), `evenOdd` or non-zero.
std::vector<Poly> normalize(const std::vector<Poly>& rings, bool evenOdd, const ClipGrid& g);
// The union of pieces that each cover an area, whatever their orientation (the pieces are turned to one orientation first; a thin
// piece the grid flips would otherwise cancel the piece it overlaps). No holes except the ones the pieces leave. Used by the stroker.
std::vector<Poly> union_pieces(const std::vector<Poly>& pieces, const ClipGrid& g);
// `subject` op `clip`, both already clean. Subtract is subject minus clip. Throws CommandError for coordinates too large for the grid.
std::vector<Poly> boolean_op(BoolOp op, const std::vector<Poly>& subject, const std::vector<Poly>& clip, const ClipGrid& g);
// The outline of the area grown by `delta` (negative shrinks).
std::vector<Poly> offset_rings(const std::vector<Poly>& rings, double delta, Join join, double miterLimit, double arcTol, const ClipGrid& g);

struct StrokeStyle {
    double width = 1;
    Cap cap = Cap::Butt;
    Join join = Join::Miter;
    double miterLimit = 4;
    std::vector<double> dashes;  // on, off, on, off ... (an odd list repeats); empty = solid
    double dashOffset = 0;
};
// The area the stroke of the subpaths covers, as clean rings (nonzero), in the same space as the path. Curves are flattened to
// `flatTol`. Follows SVG: miter joins past the limit become bevels, dashes restart on every subpath, a zero-length subpath draws a
// dot with round or square caps.
std::vector<Poly> stroke_outline(const Path& p, const StrokeStyle& s, double flatTol, const ClipGrid& g);

}  // namespace fa::vec
