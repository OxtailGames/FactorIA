// Points, matrices and the path model of the vector.* commands: SVG path data in and out, flattening, bounds. See vector.h.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <format>

#include "vector.h"

namespace fa::vec {

namespace {
constexpr double kPi = 3.14159265358979323846;
constexpr double kKappa = 0.5522847498307936;  // the handle of a quarter circle as a cubic
}  // namespace

// ---- matrices -----------------------------------------------------------------------------------------------------

Mat operator*(const Mat& p, const Mat& q) {
    return {p.a * q.a + p.c * q.b,       p.b * q.a + p.d * q.b,       p.a * q.c + p.c * q.d,
            p.b * q.c + p.d * q.d,       p.a * q.e + p.c * q.f + p.e, p.b * q.e + p.d * q.f + p.f};
}

Mat inverse(const Mat& m) {
    const double det = m.det();
    if (std::fabs(det) < 1e-12) return {};
    Mat o;
    o.a = m.d / det;
    o.b = -m.b / det;
    o.c = -m.c / det;
    o.d = m.a / det;
    o.e = (m.c * m.f - m.d * m.e) / det;
    o.f = (m.b * m.e - m.a * m.f) / det;
    return o;
}

Mat translation(double dx, double dy) { return {1, 0, 0, 1, dx, dy}; }

Mat rotation(double degrees, double cx, double cy) {
    const double r = degrees * kPi / 180.0, cs = std::cos(r), sn = std::sin(r);
    return translation(cx, cy) * Mat{cs, sn, -sn, cs, 0, 0} * translation(-cx, -cy);
}

namespace {

std::string trim_copy(const std::string& s) {
    std::size_t a = 0, b = s.size();
    while (a < b && std::isspace(static_cast<unsigned char>(s[a]))) ++a;
    while (b > a && std::isspace(static_cast<unsigned char>(s[b - 1]))) --b;
    return s.substr(a, b - a);
}

std::vector<double> numbers_in(const std::string& s) {
    std::vector<double> v;
    const char* p = s.c_str();
    while (*p) {
        char* end = nullptr;
        const double d = std::strtod(p, &end);
        if (end == p) {
            ++p;
            continue;
        }
        v.push_back(d);
        p = end;
    }
    return v;
}

}  // namespace

bool parse_transform(const std::string& text, Mat& out, std::string& err) {
    Mat m;
    std::size_t i = 0;
    while (i < text.size()) {
        while (i < text.size() && (std::isspace(static_cast<unsigned char>(text[i])) || text[i] == ',')) ++i;
        if (i >= text.size()) break;
        const std::size_t open = text.find('(', i);
        const std::size_t close = open == std::string::npos ? open : text.find(')', open);
        if (open == std::string::npos || close == std::string::npos) {
            err = "'" + text.substr(i) + "' is not a transform function";
            return false;
        }
        const std::string name = trim_copy(text.substr(i, open - i));
        const std::vector<double> v = numbers_in(text.substr(open + 1, close - open - 1));
        Mat t;
        if (name == "matrix" && v.size() == 6) t = {v[0], v[1], v[2], v[3], v[4], v[5]};
        else if (name == "translate" && (v.size() == 1 || v.size() == 2)) t = translation(v[0], v.size() > 1 ? v[1] : 0);
        else if (name == "scale" && (v.size() == 1 || v.size() == 2)) t = {v[0], 0, 0, v.size() > 1 ? v[1] : v[0], 0, 0};
        else if (name == "rotate" && (v.size() == 1 || v.size() == 3)) t = rotation(v[0], v.size() == 3 ? v[1] : 0, v.size() == 3 ? v[2] : 0);
        else if (name == "skewX" && v.size() == 1) t.c = std::tan(v[0] * kPi / 180.0);
        else if (name == "skewY" && v.size() == 1) t.b = std::tan(v[0] * kPi / 180.0);
        else {
            err = "'" + name + "(" + text.substr(open + 1, close - open - 1) + ")' is not a valid transform function (matrix(6 numbers), translate(x y), scale(x y), rotate(a x y), skewX(a), skewY(a))";
            return false;
        }
        m = m * t;
        i = close + 1;
    }
    out = m;
    return true;
}

std::string format_number(double v, int decimals) {
    if (!std::isfinite(v)) return "0";
    char buf[64];
    std::snprintf(buf, sizeof buf, "%.*f", std::clamp(decimals, 0, 9), v);
    std::string s = buf;
    if (s.find('.') != std::string::npos) {
        while (s.back() == '0') s.pop_back();
        if (s.back() == '.') s.pop_back();
    }
    if (s == "-0") s = "0";
    return s;
}

std::string transform_to_string(const Mat& m, int decimals) {
    auto n = [&](double v) { return format_number(v, decimals); };
    auto near = [](double a, double b) { return std::fabs(a - b) < 1e-9; };
    if (m.is_identity()) return {};
    if (near(m.a, 1) && near(m.b, 0) && near(m.c, 0) && near(m.d, 1)) return "translate(" + n(m.e) + " " + n(m.f) + ")";
    if (near(m.b, 0) && near(m.c, 0) && near(m.e, 0) && near(m.f, 0)) return "scale(" + n(m.a) + (near(m.a, m.d) ? "" : " " + n(m.d)) + ")";
    return "matrix(" + n(m.a) + " " + n(m.b) + " " + n(m.c) + " " + n(m.d) + " " + n(m.e) + " " + n(m.f) + ")";
}

// ---- path data ----------------------------------------------------------------------------------------------------

namespace {

struct Scanner {
    const std::string& s;
    std::size_t i = 0;
    explicit Scanner(const std::string& text) : s(text) {}
    void skip() {
        while (i < s.size() && (s[i] == ' ' || s[i] == ',' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) ++i;
    }
    bool at_end() {
        skip();
        return i >= s.size();
    }
    bool number(double& out) {
        skip();
        const char* begin = s.c_str() + i;
        // a path number: sign, digits, point, digits, exponent (no hex, inf or nan)
        const char* p = begin;
        if (*p == '+' || *p == '-') ++p;
        const char* digits = p;
        while (*p >= '0' && *p <= '9') ++p;
        if (*p == '.') {
            ++p;
            while (*p >= '0' && *p <= '9') ++p;
        }
        if (p == digits || (p == digits + 1 && *digits == '.')) return false;
        if (*p == 'e' || *p == 'E') {
            const char* q = p + 1;
            if (*q == '+' || *q == '-') ++q;
            if (*q >= '0' && *q <= '9') {
                while (*q >= '0' && *q <= '9') ++q;
                p = q;
            }
        }
        out = std::strtod(std::string(begin, p).c_str(), nullptr);
        i += std::size_t(p - begin);
        return true;
    }
    bool flag(double& out) {
        skip();
        if (i < s.size() && (s[i] == '0' || s[i] == '1')) {
            out = s[i] == '1' ? 1.0 : 0.0;
            ++i;
            return true;
        }
        return false;
    }
};

void arc_to_cubics(P from, double rx, double ry, double rotation_deg, bool large, bool sweep, P to, std::vector<Seg>& out) {
    if (from.x == to.x && from.y == to.y) return;
    rx = std::fabs(rx);
    ry = std::fabs(ry);
    if (rx < 1e-12 || ry < 1e-12) {
        out.push_back({false, {}, {}, to});
        return;
    }
    const double phi = rotation_deg * kPi / 180.0, cp = std::cos(phi), sp = std::sin(phi);
    const double dx = (from.x - to.x) * 0.5, dy = (from.y - to.y) * 0.5;
    const double x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy;
    const double lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry);
    if (lambda > 1) {
        const double k = std::sqrt(lambda);
        rx *= k;
        ry *= k;
    }
    const double num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1;
    const double den = rx * rx * y1 * y1 + ry * ry * x1 * x1;
    double coef = den == 0 ? 0 : std::sqrt(std::max(0.0, num / den));
    if (large == sweep) coef = -coef;
    const double cxp = coef * (rx * y1 / ry), cyp = coef * -(ry * x1 / rx);
    const double cx = cp * cxp - sp * cyp + (from.x + to.x) * 0.5, cy = sp * cxp + cp * cyp + (from.y + to.y) * 0.5;
    auto angle = [](double ux, double uy, double vx, double vy) { return std::atan2(ux * vy - uy * vx, ux * vx + uy * vy); };
    const double theta1 = angle(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry);
    double delta = angle((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry);
    if (!sweep && delta > 0) delta -= 2 * kPi;
    if (sweep && delta < 0) delta += 2 * kPi;
    const int n = std::max(1, int(std::ceil(std::fabs(delta) / (kPi / 2) - 1e-9)));
    const double step = delta / n, alpha = 4.0 / 3.0 * std::tan(step / 4.0);
    auto point = [&](double t) { return P{cp * rx * std::cos(t) - sp * ry * std::sin(t) + cx, sp * rx * std::cos(t) + cp * ry * std::sin(t) + cy}; };
    auto deriv = [&](double t) { return P{-cp * rx * std::sin(t) - sp * ry * std::cos(t), -sp * rx * std::sin(t) + cp * ry * std::cos(t)}; };
    for (int k = 0; k < n; ++k) {
        const double t0 = theta1 + step * k, t1 = t0 + step;
        const P p0 = point(t0), p1 = k == n - 1 ? to : point(t1);
        out.push_back({true, p0 + deriv(t0) * alpha, p1 - deriv(t1) * alpha, p1});
    }
}

}  // namespace

bool parse_path_data(const std::string& d, Path& out, std::string& err) {
    Scanner sc(d);
    P cur{0, 0}, start{0, 0}, lastCtrl{0, 0};
    char cmd = 0, prev = 0;
    bool haveStart = false;
    out.clear();
    SubPath* sub = nullptr;
    auto bad = [&](const std::string& what) {
        err = std::format("{} at character {} of the path data", what, sc.i);
        return false;
    };
    auto begin_sub = [&](P at) {
        out.push_back(SubPath{});
        sub = &out.back();
        sub->start = at;
    };
    auto line_to = [&](P p) {
        if (!sub) begin_sub(cur);
        sub->segs.push_back({false, {}, {}, p});
    };
    auto cubic_to = [&](P c1, P c2, P p) {
        if (!sub) begin_sub(cur);
        sub->segs.push_back({true, c1, c2, p});
    };
    while (!sc.at_end()) {
        const char c = d[sc.i];
        const bool isLetter = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
        if (isLetter) {
            if (std::strchr("MmLlHhVvCcSsQqTtAaZz", c) == nullptr) return bad(std::format("unknown path command '{}'", c));
            cmd = c;
            ++sc.i;
        } else if (cmd == 0) {
            return bad("the path data must start with M (move to)");
        } else if (cmd == 'M') {
            cmd = 'L';
        } else if (cmd == 'm') {
            cmd = 'l';
        } else if (cmd == 'Z' || cmd == 'z') {
            return bad("numbers after Z");
        }
        const bool rel = cmd >= 'a';
        const char up = char(rel ? cmd - 32 : cmd);
        if (!haveStart && up != 'M') return bad("the path data must start with M (move to)");
        double v[7];
        auto read = [&](int n) {
            for (int k = 0; k < n; ++k)
                if (!sc.number(v[k])) return false;
            return true;
        };
        const P base = rel ? cur : P{0, 0};
        switch (up) {
            case 'M':
                if (!read(2)) return bad("expected two numbers after M");
                cur = start = {base.x + v[0], base.y + v[1]};
                sub = nullptr;
                begin_sub(cur);
                haveStart = true;
                break;
            case 'L':
                if (!read(2)) return bad("expected two numbers after L");
                cur = {base.x + v[0], base.y + v[1]};
                line_to(cur);
                break;
            case 'H':
                if (!read(1)) return bad("expected a number after H");
                cur.x = base.x + v[0];
                line_to(cur);
                break;
            case 'V':
                if (!read(1)) return bad("expected a number after V");
                cur.y = (rel ? cur.y : 0.0) + v[0];
                line_to(cur);
                break;
            case 'C': {
                if (!read(6)) return bad("expected six numbers after C");
                const P p1{base.x + v[0], base.y + v[1]}, p2{base.x + v[2], base.y + v[3]}, p3{base.x + v[4], base.y + v[5]};
                cubic_to(p1, p2, p3);
                lastCtrl = p2;
                cur = p3;
                break;
            }
            case 'S': {
                if (!read(4)) return bad("expected four numbers after S");
                const P p1 = (prev == 'C' || prev == 'S') ? cur * 2.0 - lastCtrl : cur;
                const P p2{base.x + v[0], base.y + v[1]}, p3{base.x + v[2], base.y + v[3]};
                cubic_to(p1, p2, p3);
                lastCtrl = p2;
                cur = p3;
                break;
            }
            case 'Q': {
                if (!read(4)) return bad("expected four numbers after Q");
                const P q{base.x + v[0], base.y + v[1]}, p2{base.x + v[2], base.y + v[3]};
                cubic_to(cur + (q - cur) * (2.0 / 3.0), p2 + (q - p2) * (2.0 / 3.0), p2);
                lastCtrl = q;
                cur = p2;
                break;
            }
            case 'T': {
                if (!read(2)) return bad("expected two numbers after T");
                const P q = (prev == 'Q' || prev == 'T') ? cur * 2.0 - lastCtrl : cur;
                const P p2{base.x + v[0], base.y + v[1]};
                cubic_to(cur + (q - cur) * (2.0 / 3.0), p2 + (q - p2) * (2.0 / 3.0), p2);
                lastCtrl = q;
                cur = p2;
                break;
            }
            case 'A': {
                if (!read(3) || !sc.flag(v[3]) || !sc.flag(v[4]) || !sc.number(v[5]) || !sc.number(v[6])) return bad("expected rx ry rotation large-arc sweep x y after A");
                const P to{base.x + v[5], base.y + v[6]};
                if (!sub) begin_sub(cur);
                arc_to_cubics(cur, v[0], v[1], v[2], v[3] != 0, v[4] != 0, to, sub->segs);
                cur = to;
                break;
            }
            case 'Z':
                if (sub) sub->closed = true;
                cur = start;
                sub = nullptr;  // drawing goes on from the start point in a new subpath
                break;
        }
        prev = up;
    }
    // A closed subpath that came back to its start with a line needs no closing line: drop that one. Subpaths that only moved are noise.
    Path clean;
    for (SubPath& s : out) {
        if (s.segs.empty()) continue;
        if (s.closed && !s.segs.back().cubic && dist(s.segs.back().p, s.start) < 1e-9 && s.segs.size() > 1) s.segs.pop_back();
        clean.push_back(std::move(s));
    }
    out = std::move(clean);
    if (out.empty()) {
        err = "the path data draws nothing";
        return false;
    }
    return true;
}

std::string path_to_data(const Path& p, int decimals) {
    std::string out;
    auto pt = [&](P q) { return format_number(q.x, decimals) + " " + format_number(q.y, decimals); };
    for (const SubPath& s : p) {
        if (!out.empty()) out += " ";
        out += "M" + pt(s.start);
        for (const Seg& g : s.segs) out += g.cubic ? " C" + pt(g.c1) + " " + pt(g.c2) + " " + pt(g.p) : " L" + pt(g.p);
        if (s.closed) out += " Z";
    }
    return out;
}

Path transform_path(const Path& p, const Mat& m) {
    Path out = p;
    for (SubPath& s : out) {
        s.start = m.apply(s.start);
        for (Seg& g : s.segs) {
            g.p = m.apply(g.p);
            if (g.cubic) {
                g.c1 = m.apply(g.c1);
                g.c2 = m.apply(g.c2);
            }
        }
    }
    return out;
}

int node_count(const Path& p) {
    int n = 0;
    for (const SubPath& s : p) {
        n += int(s.segs.size()) + 1;
        if (s.closed && !s.segs.empty() && dist(s.segs.back().p, s.start) < 1e-9) --n;
    }
    return n;
}

bool has_curves(const Path& p) {
    for (const SubPath& s : p)
        for (const Seg& g : s.segs)
            if (g.cubic) return true;
    return false;
}

bool has_closed(const Path& p) {
    for (const SubPath& s : p)
        if (s.closed) return true;
    return false;
}

namespace {

void cubic_extrema(double p0, double c1, double c2, double p3, std::vector<double>& ts) {
    const double d0 = c1 - p0, d1 = c2 - c1, d2 = p3 - c2;
    const double a = d0 - 2 * d1 + d2, b = 2 * (d1 - d0), c = d0;
    if (std::fabs(a) < 1e-12) {
        if (std::fabs(b) > 1e-12) ts.push_back(-c / b);
        return;
    }
    const double disc = b * b - 4 * a * c;
    if (disc < 0) return;
    const double sq = std::sqrt(disc);
    ts.push_back((-b + sq) / (2 * a));
    ts.push_back((-b - sq) / (2 * a));
}

P cubic_at(P p0, P c1, P c2, P p3, double t) {
    const double u = 1 - t;
    return p0 * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t) + p3 * (t * t * t);
}

}  // namespace

Rect path_bounds(const Path& p) {
    Rect r;
    for (const SubPath& s : p) {
        P prev = s.start;
        r.add(prev);
        for (const Seg& g : s.segs) {
            r.add(g.p);
            if (g.cubic) {
                std::vector<double> ts;
                cubic_extrema(prev.x, g.c1.x, g.c2.x, g.p.x, ts);
                cubic_extrema(prev.y, g.c1.y, g.c2.y, g.p.y, ts);
                for (double t : ts)
                    if (t > 0 && t < 1) r.add(cubic_at(prev, g.c1, g.c2, g.p, t));
            }
            prev = g.p;
        }
    }
    return r;
}

// ---- flattening ---------------------------------------------------------------------------------------------------

namespace {

double turn_between(P a, P b) {  // the unsigned angle between two directions, 0 when either has no length
    if (len(a) < 1e-12 || len(b) < 1e-12) return 0;
    return std::fabs(std::atan2(cross(a, b), dot(a, b)));
}

void flatten_cubic(P p0, P c1, P c2, P p3, double tol, std::vector<P>& out) {
    const P dd1 = p0 - c1 * 2.0 + c2, dd2 = c1 - c2 * 2.0 + p3;
    const double dd = std::max(len(dd1), len(dd2));
    int n = int(std::ceil(std::sqrt(0.75 * dd / std::max(tol, 1e-9))));
    const double turn = turn_between(c1 - p0, c2 - c1) + turn_between(c2 - c1, p3 - c2);
    n = std::max(n, int(std::ceil(turn / 0.105)));
    n = std::clamp(n, 1, 400);
    for (int k = 1; k <= n; ++k) out.push_back(k == n ? p3 : cubic_at(p0, c1, c2, p3, double(k) / n));
}

}  // namespace

std::vector<Ring> flatten_path(const Path& p, double tol) {
    std::vector<Ring> rings;
    for (const SubPath& s : p) {
        Ring r;
        r.closed = s.closed;
        r.pts.push_back(s.start);
        P prev = s.start;
        for (const Seg& g : s.segs) {
            if (g.cubic) flatten_cubic(prev, g.c1, g.c2, g.p, tol, r.pts);
            else r.pts.push_back(g.p);
            prev = g.p;
        }
        // no repeated points; a closed ring does not repeat its first point
        Poly clean;
        for (const P& q : r.pts)
            if (clean.empty() || dist(clean.back(), q) > 1e-9) clean.push_back(q);
        while (r.closed && clean.size() > 1 && dist(clean.front(), clean.back()) <= 1e-9) clean.pop_back();
        r.pts = std::move(clean);
        if (!r.pts.empty() && !s.segs.empty()) rings.push_back(std::move(r));  // a degenerate one (a dot) stays: the stroker draws it
    }
    return rings;
}

std::vector<Poly> fill_rings(const Path& p, double tol) {
    std::vector<Poly> out;
    for (Ring& r : flatten_path(p, tol)) {
        // a fill closes every subpath, open or not
        if (r.pts.size() >= 3) out.push_back(std::move(r.pts));
    }
    return out;
}

Path path_from_rings(const std::vector<Ring>& rings) {
    Path out;
    for (const Ring& r : rings) {
        if (r.pts.size() < 2) continue;
        SubPath s;
        s.start = r.pts[0];
        for (std::size_t i = 1; i < r.pts.size(); ++i) s.segs.push_back({false, {}, {}, r.pts[i]});
        s.closed = r.closed;
        out.push_back(std::move(s));
    }
    return out;
}

Path ellipse_path(double cx, double cy, double rx, double ry) {
    SubPath s;
    s.closed = true;
    s.start = {cx + rx, cy};
    const double kx = rx * kKappa, ky = ry * kKappa;
    s.segs.push_back({true, {cx + rx, cy + ky}, {cx + kx, cy + ry}, {cx, cy + ry}});
    s.segs.push_back({true, {cx - kx, cy + ry}, {cx - rx, cy + ky}, {cx - rx, cy}});
    s.segs.push_back({true, {cx - rx, cy - ky}, {cx - kx, cy - ry}, {cx, cy - ry}});
    s.segs.push_back({true, {cx + kx, cy - ry}, {cx + rx, cy - ky}, {cx + rx, cy}});
    return {s};
}

Path rect_path(double x, double y, double w, double h, double rx, double ry) {
    rx = std::clamp(rx, 0.0, w * 0.5);
    ry = std::clamp(ry, 0.0, h * 0.5);
    SubPath s;
    s.closed = true;
    auto line = [&](double px, double py) { s.segs.push_back({false, {}, {}, {px, py}}); };
    if (rx <= 0 || ry <= 0) {
        s.start = {x, y};
        line(x + w, y);
        line(x + w, y + h);
        line(x, y + h);
        return {s};
    }
    const double kx = rx * kKappa, ky = ry * kKappa;
    s.start = {x + rx, y};
    line(x + w - rx, y);
    s.segs.push_back({true, {x + w - rx + kx, y}, {x + w, y + ry - ky}, {x + w, y + ry}});
    line(x + w, y + h - ry);
    s.segs.push_back({true, {x + w, y + h - ry + ky}, {x + w - rx + kx, y + h}, {x + w - rx, y + h}});
    line(x + rx, y + h);
    s.segs.push_back({true, {x + rx - kx, y + h}, {x, y + h - ry + ky}, {x, y + h - ry}});
    line(x, y + ry);
    s.segs.push_back({true, {x, y + ry - ky}, {x + rx - kx, y}, {x + rx, y}});
    return {s};
}

}  // namespace fa::vec
