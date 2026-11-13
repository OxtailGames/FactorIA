// The shape builders of vector.shape and vector.blob: smooth blobs through or around points, stars, gears, rounded polygons, arrows,
// speech bubbles and ribbons, as paths (y down, angles in degrees clockwise on screen). See fa/tooling/vector.h.
#include "vector_shapes.h"

#include <algorithm>
#include <cmath>

namespace fa::vec {

namespace {
constexpr double kPi = 3.14159265358979323846;
double rad(double deg) { return deg * kPi / 180.0; }
double clampd(double v, double lo, double hi) { return std::min(std::max(v, lo), hi); }
int clampi(int v, int lo, int hi) { return std::min(std::max(v, lo), hi); }

void line_to(SubPath& sp, P p) {
    Seg s;
    s.p = p;
    sp.segs.push_back(s);
}
void cubic_to(SubPath& sp, P c1, P c2, P p) {
    Seg s;
    s.cubic = true;
    s.c1 = c1;
    s.c2 = c2;
    s.p = p;
    sp.segs.push_back(s);
}
P lerp(P a, P b, double t) { return a + (b - a) * t; }

SubPath polygon_subpath(const Poly& v) {
    SubPath sp;
    sp.start = v[0];
    for (std::size_t i = 1; i < v.size(); ++i) line_to(sp, v[i]);
    sp.closed = true;
    return sp;
}
}  // namespace

P polar(P c, double r, double degrees) { return {c.x + r * std::cos(rad(degrees)), c.y + r * std::sin(rad(degrees))}; }

void arc_segments(SubPath& sp, P c, double r, double a0, double a1) {
    const double total = a1 - a0;
    if (std::fabs(total) < 1e-9 || r <= 0) return;
    const int n = std::max(1, int(std::ceil(std::fabs(total) / 90.0 - 1e-9)));
    const double step = total / n;
    for (int i = 0; i < n; ++i) {
        const double s = rad(a0 + step * i), e = rad(a0 + step * (i + 1));
        const double k = 4.0 / 3.0 * std::tan((e - s) / 4.0) * r;
        const P p0{c.x + r * std::cos(s), c.y + r * std::sin(s)}, p3{c.x + r * std::cos(e), c.y + r * std::sin(e)};
        cubic_to(sp, {p0.x - k * std::sin(s) * 1.0, p0.y + k * std::cos(s)},
                 {p3.x + k * std::sin(e), p3.y - k * std::cos(e)}, p3);
    }
}

Path round_corners(const Poly& v, const std::function<double(int, double, double)>& fillet) {
    const int n = int(v.size());
    struct Corner {
        P a, c1, c2, b;
        bool sharp = true;
    };
    std::vector<Corner> cs(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) {
        const P prev = v[std::size_t((i + n - 1) % n)], cur = v[std::size_t(i)], next = v[std::size_t((i + 1) % n)];
        const double lin = dist(prev, cur), lout = dist(cur, next);
        Corner& c = cs[std::size_t(i)];
        c.a = c.b = cur;
        if (lin < 1e-9 || lout < 1e-9) continue;
        const P uin = (cur - prev) * (1.0 / lin), uout = (next - cur) * (1.0 / lout);
        const double turn = std::acos(clampd(dot(uin, uout), -1.0, 1.0));
        if (turn < 1e-3 || turn > kPi - 1e-3) continue;
        const double shortest = std::min(lin, lout);
        double d = fillet(i, turn, shortest);
        d = std::min(d, 0.5 * shortest);
        if (d <= 1e-9) continue;
        const double r = d / std::tan(turn / 2);
        const double k = 4.0 / 3.0 * std::tan(turn / 4) * r;
        c.a = cur - uin * d;
        c.b = cur + uout * d;
        c.c1 = c.a + uin * k;
        c.c2 = c.b - uout * k;
        c.sharp = false;
    }
    SubPath sp;
    sp.start = cs[0].b;
    for (int j = 1; j <= n; ++j) {
        const Corner& c = cs[std::size_t(j % n)];
        line_to(sp, c.a);
        if (!c.sharp) cubic_to(sp, c.c1, c.c2, c.b);
    }
    // the last line ends where the path started when vertex 0 is sharp: drop the zero-length closing piece
    if (!sp.segs.empty() && dist(sp.segs.back().p, sp.start) < 1e-9 && !sp.segs.back().cubic) sp.segs.pop_back();
    sp.closed = true;
    return {sp};
}

// ---- blob ---------------------------------------------------------------------------------------------------------

Path build_blob(const VecBlobSpec& s) {
    const int n = int(s.points.size());
    std::vector<P> p;
    for (const VecPoint& q : s.points) p.push_back({q.x, q.y});
    SubPath sp;
    if (n == 0) return {};
    sp.start = p[0];
    const bool closed = s.closed && n >= 3;
    if (!s.around) {
        const double t = clampd(s.tension, 0.0, 1.5) / 3.0;
        auto at = [&](int i) -> P {
            if (closed) return p[std::size_t(((i % n) + n) % n)];
            return p[std::size_t(clampi(i, 0, n - 1))];
        };
        const int segs = closed ? n : n - 1;
        for (int i = 0; i < segs; ++i) {
            const P p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
            cubic_to(sp, p1 + (p2 - p0) * t, p2 - (p3 - p1) * t, p2);
        }
    } else if (closed) {
        // a uniform cubic B-spline over the closed control polygon: segment i is controlled by p[i-1], p[i], p[i+1], p[i+2]
        auto at = [&](int i) { return p[std::size_t(((i % n) + n) % n)]; };
        sp.start = (at(-1) + at(0) * 4.0 + at(1)) * (1.0 / 6.0);
        for (int i = 0; i < n; ++i) {
            const P b = at(i), c = at(i + 1), d = at(i + 2);
            cubic_to(sp, (b * 2.0 + c) * (1.0 / 3.0), (b + c * 2.0) * (1.0 / 3.0), (b + c * 4.0 + d) * (1.0 / 6.0));
        }
    } else {
        // clamped: the control polygon has its end points tripled, so the curve starts and ends on them
        std::vector<P> c = {p[0], p[0]};
        for (const P& q : p) c.push_back(q);
        c.push_back(p[std::size_t(n - 1)]);
        c.push_back(p[std::size_t(n - 1)]);
        for (std::size_t i = 0; i + 3 < c.size(); ++i) {
            const P b = c[i + 1], cc = c[i + 2], d = c[i + 3];
            cubic_to(sp, (b * 2.0 + cc) * (1.0 / 3.0), (b + cc * 2.0) * (1.0 / 3.0), (b + cc * 4.0 + d) * (1.0 / 6.0));
        }
    }
    sp.closed = closed;
    return {sp};
}

// ---- star, polygon -----------------------------------------------------------------------------------------------------

Path build_star(const VecStarSpec& s) {
    const int n = clampi(s.points, 3, 128);
    const double ratio = clampd(s.innerRatio, 0.02, 0.98);
    Poly v;
    for (int i = 0; i < 2 * n; ++i)
        v.push_back(polar({s.center.x, s.center.y}, i % 2 ? s.radius * ratio : s.radius, s.rotation + 180.0 * i / n));
    const double round = clampd(s.roundness, 0.0, 1.0);
    if (round <= 0) return {polygon_subpath(v)};
    return round_corners(v, [&](int, double, double shortest) { return round * 0.5 * shortest; });
}

Path build_polygon(const VecPolygonSpec& s) {
    const int n = clampi(s.sides, 3, 128);
    Poly v;
    for (int i = 0; i < n; ++i) v.push_back(polar({s.center.x, s.center.y}, s.radius, s.rotation + 360.0 * i / n));
    if (s.cornerRadius <= 0) return {polygon_subpath(v)};
    const double r = s.cornerRadius;
    return round_corners(v, [&](int, double turn, double) { return r * std::tan(turn / 2); });
}

// ---- gear ----------------------------------------------------------------------------------------------------------------

Path build_gear(const VecGearSpec& s) {
    const int n = clampi(s.teeth, 3, 128);
    const P c{s.center.x, s.center.y};
    const double R = s.radius, Rr = R * (1.0 - clampd(s.depth, 0.02, 0.6));
    const double pitch = 360.0 / n;
    const double ht = pitch * clampd(s.toothWidth, 0.1, 0.9) / 2.0;
    const double hb = ht + (pitch / 2.0 - ht) * 0.45;  // the flanks lean outwards a little
    SubPath sp;
    sp.start = polar(c, Rr, s.rotation - hb);
    for (int i = 0; i < n; ++i) {
        const double a = s.rotation + pitch * i;
        line_to(sp, polar(c, R, a - ht));
        arc_segments(sp, c, R, a - ht, a + ht);
        line_to(sp, polar(c, Rr, a + hb));
        arc_segments(sp, c, Rr, a + hb, a + pitch - hb);
    }
    sp.closed = true;
    Path out{sp};
    const double hole = clampd(s.hole, 0.0, 0.9);
    if (hole > 0) {
        // wound the other way, so it is a hole under both fill rules
        SubPath h;
        h.start = polar(c, R * hole, 0);
        arc_segments(h, c, R * hole, 0, -360);
        h.closed = true;
        out.push_back(h);
    }
    return out;
}

// ---- arrow ---------------------------------------------------------------------------------------------------------------

Path build_arrow(const VecArrowSpec& s) {
    const P from{s.from.x, s.from.y}, to{s.to.x, s.to.y};
    const double c = dist(from, to);
    if (c < 1e-9) return {};
    const P u = unit(to - from);
    const P right{-u.y, u.x};  // to the right of the travel on screen (y down)
    const double hl = clampd(s.headLength, 0.0, c);
    const double sw = s.shaftWidth / 2, hw = s.headWidth / 2;
    if (std::fabs(s.curve) < 1e-4) {
        const P b = to - u * hl;
        Poly v = {from - right * sw, b - right * sw, b - right * hw,   to,
                  b + right * hw,    b + right * sw, from + right * sw};
        return {polygon_subpath(v)};
    }
    const double sag = clampd(s.curve, -0.5, 0.5) * c;  // positive: bulges to the right
    const double R = (c * c / 4 + sag * sag) / (2 * std::fabs(sag));
    const P mid = lerp(from, to, 0.5);
    const P bulge = right * (sag > 0 ? 1.0 : -1.0);
    const P O = mid + bulge * (std::fabs(sag) - R);
    const double a0 = std::atan2(from.y - O.y, from.x - O.x), a1 = std::atan2(to.y - O.y, to.x - O.x);
    double delta = a1 - a0;
    while (delta > kPi) delta -= 2 * kPi;
    while (delta < -kPi) delta += 2 * kPi;
    const double sign = delta >= 0 ? 1.0 : -1.0;
    const double a0d = a0 * 180 / kPi, a1d = a0d + delta * 180 / kPi;
    const double headAngle = std::min(hl / R, 0.9 * std::fabs(delta));
    const double ahd = a1d - sign * headAngle * 180 / kPi;
    // which of the two concentric circles is on the right of the travel: moving with increasing angle (clockwise on screen) the
    // centre is on the right
    const double rr = std::max(R - hw, R * 0.05);
    const double rOuter = R + sw, rInner = std::max(R - sw, R * 0.02);
    SubPath sp;
    sp.start = polar(O, rOuter, a0d);
    arc_segments(sp, O, rOuter, a0d, ahd);
    line_to(sp, polar(O, R + hw, ahd));
    line_to(sp, to);
    line_to(sp, polar(O, rr, ahd));
    line_to(sp, polar(O, rInner, ahd));
    arc_segments(sp, O, rInner, ahd, a0d);
    sp.closed = true;
    return {sp};
}

// ---- speech bubble ---------------------------------------------------------------------------------------------------------

Path build_bubble(const VecBubbleSpec& s) {
    const double w = std::max(s.width, 1.0), h = std::max(s.height, 1.0);
    const double x0 = s.center.x - w / 2, x1 = s.center.x + w / 2, y0 = s.center.y - h / 2, y1 = s.center.y + h / 2;
    const double r = clampd(s.cornerRadius, 0.0, std::min(w, h) / 2);
    const P T{s.tailTo.x, s.tailTo.y};
    const bool inside = T.x > x0 && T.x < x1 && T.y > y0 && T.y < y1;
    struct V {
        P p;
        double radius;
    };
    std::vector<V> vs;
    const double tw = clampd(s.tailWidth, 1.0, std::min(w, h));
    int side = -1;  // 0 top, 1 right, 2 bottom, 3 left
    if (s.hasTail && !inside) {
        const double dx = (T.x - s.center.x) / (w / 2), dy = (T.y - s.center.y) / (h / 2);
        side = std::fabs(dx) > std::fabs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0);
    }
    const double rBase = std::min(r, tw * 0.35), rTip = clampd(s.tailRoundness, 0, 1) * tw * 0.5;
    auto along = [&](double lo, double hi, double want) {
        const double a = lo + r + tw / 2, b = hi - r - tw / 2;
        return a > b ? (lo + hi) / 2 : clampd(want, a, b);
    };
    // clockwise on screen from the top-left corner
    vs.push_back({{x0, y0}, r});
    if (side == 0) {
        const double c = along(x0, x1, T.x);
        vs.push_back({{c - tw / 2, y0}, rBase});
        vs.push_back({T, rTip});
        vs.push_back({{c + tw / 2, y0}, rBase});
    }
    vs.push_back({{x1, y0}, r});
    if (side == 1) {
        const double c = along(y0, y1, T.y);
        vs.push_back({{x1, c - tw / 2}, rBase});
        vs.push_back({T, rTip});
        vs.push_back({{x1, c + tw / 2}, rBase});
    }
    vs.push_back({{x1, y1}, r});
    if (side == 2) {
        const double c = along(x0, x1, T.x);
        vs.push_back({{c + tw / 2, y1}, rBase});
        vs.push_back({T, rTip});
        vs.push_back({{c - tw / 2, y1}, rBase});
    }
    vs.push_back({{x0, y1}, r});
    if (side == 3) {
        const double c = along(y0, y1, T.y);
        vs.push_back({{x0, c + tw / 2}, rBase});
        vs.push_back({T, rTip});
        vs.push_back({{x0, c - tw / 2}, rBase});
    }
    Poly poly;
    for (const V& v : vs) poly.push_back(v.p);
    return round_corners(poly, [&](int i, double turn, double) {
        const double rad_ = vs[std::size_t(i)].radius;
        return rad_ <= 0 ? 0.0 : rad_ * std::tan(turn / 2);
    });
}

}  // namespace fa::vec

// ---- the public functions ---------------------------------------------------------------------------------------------------

namespace fa {

std::string vector_blob_path(const VecBlobSpec& s, int d) { return vec::path_to_data(vec::build_blob(s), d); }
std::string vector_star_path(const VecStarSpec& s, int d) { return vec::path_to_data(vec::build_star(s), d); }
std::string vector_gear_path(const VecGearSpec& s, int d) { return vec::path_to_data(vec::build_gear(s), d); }
std::string vector_polygon_path(const VecPolygonSpec& s, int d) { return vec::path_to_data(vec::build_polygon(s), d); }
std::string vector_arrow_path(const VecArrowSpec& s, int d) { return vec::path_to_data(vec::build_arrow(s), d); }
std::string vector_bubble_path(const VecBubbleSpec& s, int d) { return vec::path_to_data(vec::build_bubble(s), d); }

VecRibbonPieces vector_ribbon_paths(const VecRibbonSpec& s, int dec) {
    using namespace vec;
    const double cx = s.center.x, cy = s.center.y, W = std::max(s.width, 1.0), H = std::max(s.height, 1.0);
    const double bx0 = cx - W / 2, bx1 = cx + W / 2, top = cy - H / 2, bot = cy + H / 2;
    const double drop = s.drop, ext = std::max(s.extent, 0.0), notch = std::clamp(s.notch, 0.0, ext);
    auto poly = [&](Poly v) { return path_to_data({polygon_subpath(v)}, dec); };
    VecRibbonPieces out;
    Poly lt = {{bx0 - ext, top + drop}, {bx0, top + drop}, {bx0, bot + drop}, {bx0 - ext, bot + drop}};
    if (notch > 0) lt.push_back({bx0 - ext + notch, cy + drop});
    out.leftTail = poly(lt);
    out.rightTail = poly(Poly{{bx1, top + drop},
                              {bx1 + ext, top + drop},
                              notch > 0 ? P{bx1 + ext - notch, cy + drop} : P{bx1 + ext, cy + drop},
                              {bx1 + ext, bot + drop},
                              {bx1, bot + drop}});
    out.leftFold = poly(Poly{{bx0, bot}, {bx0 + std::max(drop, 1.0), bot}, {bx0, bot + drop}});
    out.rightFold = poly(Poly{{bx1, bot}, {bx1, bot + drop}, {bx1 - std::max(drop, 1.0), bot}});
    out.band = path_to_data(rect_path(bx0, top, W, H, 0, 0), dec);
    return out;
}

}  // namespace fa
