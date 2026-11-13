// Curve fitting for the vector.* commands: polylines back to lines and cubic Beziers (Schneider, "An Algorithm for Automatically
// Fitting Digitized Curves", Graphics Gems), plus simplify and smooth. See vector.h.
#include <algorithm>
#include <cmath>
#include <numeric>

#include "vector.h"

namespace fa::vec {

namespace {

constexpr double kPi = 3.14159265358979323846;

struct Bez {
    P v[4];
};

P bez_at(const Bez& b, double t) {
    const double u = 1 - t;
    return b.v[0] * (u * u * u) + b.v[1] * (3 * u * u * t) + b.v[2] * (3 * u * t * t) + b.v[3] * (t * t * t);
}
P bez_d1(const Bez& b, double t) {
    const double u = 1 - t;
    return (b.v[1] - b.v[0]) * (3 * u * u) + (b.v[2] - b.v[1]) * (6 * u * t) + (b.v[3] - b.v[2]) * (3 * t * t);
}
P bez_d2(const Bez& b, double t) {
    return ((b.v[2] - b.v[1] * 2.0 + b.v[0]) * (1 - t) + (b.v[3] - b.v[2] * 2.0 + b.v[1]) * t) * 6.0;
}

std::vector<double> chord_params(const Poly& d) {
    std::vector<double> u(d.size(), 0.0);
    for (std::size_t i = 1; i < d.size(); ++i) u[i] = u[i - 1] + dist(d[i], d[i - 1]);
    const double total = u.back();
    if (total > 0)
        for (std::size_t i = 1; i < d.size(); ++i) u[i] /= total;
    return u;
}

Bez generate_bezier(const Poly& d, const std::vector<double>& u, P t1, P t2) {
    const std::size_t n = d.size();
    double c00 = 0, c01 = 0, c11 = 0, x0 = 0, x1 = 0;
    const P first = d.front(), last = d.back();
    for (std::size_t i = 0; i < n; ++i) {
        const double t = u[i], s = 1 - t;
        const double b0 = s * s * s, b1 = 3 * s * s * t, b2 = 3 * s * t * t, b3 = t * t * t;
        const P a0 = t1 * b1, a1 = t2 * b2;
        c00 += dot(a0, a0);
        c01 += dot(a0, a1);
        c11 += dot(a1, a1);
        const P tmp = d[i] - (first * (b0 + b1) + last * (b2 + b3));
        x0 += dot(a0, tmp);
        x1 += dot(a1, tmp);
    }
    const double det01 = c00 * c11 - c01 * c01, det0x = c00 * x1 - c01 * x0, detx1 = x0 * c11 - x1 * c01;
    const double alphaL = det01 == 0 ? 0 : detx1 / det01, alphaR = det01 == 0 ? 0 : det0x / det01;
    const double seg = dist(first, last), eps = 1e-6 * seg;
    Bez b;
    b.v[0] = first;
    b.v[3] = last;
    if (alphaL < eps || alphaR < eps) {
        b.v[1] = first + t1 * (seg / 3.0);
        b.v[2] = last + t2 * (seg / 3.0);
    } else {
        b.v[1] = first + t1 * alphaL;
        b.v[2] = last + t2 * alphaR;
    }
    return b;
}

double newton_step(const Bez& b, P p, double u) {
    const P diff = bez_at(b, u) - p, d1 = bez_d1(b, u), d2 = bez_d2(b, u);
    const double num = dot(diff, d1), den = dot(d1, d1) + dot(diff, d2);
    return std::fabs(den) < 1e-12 ? u : u - num / den;
}

double max_error_sq(const Poly& d, const Bez& b, const std::vector<double>& u, std::size_t& split) {
    double worst = 0;
    split = d.size() / 2;
    for (std::size_t i = 1; i + 1 < d.size(); ++i) {
        const P diff = bez_at(b, u[i]) - d[i];
        const double e = dot(diff, diff);
        if (e >= worst) {
            worst = e;
            split = i;
        }
    }
    return worst;
}

// t1: unit tangent pointing from the first point into the curve; t2 the same from the last point.
void fit_cubic(const Poly& d, P t1, P t2, double tol2, std::vector<Seg>& out) {
    if (d.size() == 2) {
        const double l = dist(d[0], d[1]) / 3.0;
        out.push_back({true, d[0] + t1 * l, d[1] + t2 * l, d[1]});
        return;
    }
    std::vector<double> u = chord_params(d);
    Bez b = generate_bezier(d, u, t1, t2);
    std::size_t split = 0;
    double err = max_error_sq(d, b, u, split);
    if (err < tol2) {
        out.push_back({true, b.v[1], b.v[2], b.v[3]});
        return;
    }
    if (err < tol2 * 16) {
        for (int it = 0; it < 6; ++it) {
            for (std::size_t i = 0; i < d.size(); ++i) u[i] = newton_step(b, d[i], u[i]);
            // keep the parameters increasing
            for (std::size_t i = 1; i < d.size(); ++i) u[i] = std::clamp(std::max(u[i], u[i - 1]), 0.0, 1.0);
            b = generate_bezier(d, u, t1, t2);
            err = max_error_sq(d, b, u, split);
            if (err < tol2) {
                out.push_back({true, b.v[1], b.v[2], b.v[3]});
                return;
            }
        }
    }
    // Split near the middle of the run (by length): the point of the largest error of a badly fitted curve is often not where the
    // curve should be cut, and cutting in halves needs the fewest pieces for a run that turns evenly (an arc, a circle).
    {
        std::size_t mid = 1;
        for (std::size_t i = 1; i + 1 < d.size(); ++i)
            if (std::fabs(u[i] - 0.5) < std::fabs(u[mid] - 0.5)) mid = i;
        split = mid;
    }
    split = std::clamp<std::size_t>(split, 1, d.size() - 2);
    P center = unit(d[split - 1] - d[split + 1]);
    if (len(center) < 0.5) center = unit(P{-(d[split + 1] - d[split - 1]).y, (d[split + 1] - d[split - 1]).x});
    const Poly left(d.begin(), d.begin() + std::ptrdiff_t(split) + 1),
        right(d.begin() + std::ptrdiff_t(split), d.end());
    fit_cubic(left, t1, center, tol2, out);
    fit_cubic(right, center * -1.0, t2, tol2, out);
}

// Douglas-Peucker over pts[a..b] (indices into `pts`, inclusive); marks the points to keep.
void rdp(const Poly& pts, std::size_t a, std::size_t b, double tol, std::vector<char>& keep) {
    if (b <= a + 1) return;
    const P pa = pts[a], pb = pts[b], ab = pb - pa;
    const double l2 = dot(ab, ab);
    double worst = -1;
    std::size_t at = a;
    for (std::size_t i = a + 1; i < b; ++i) {
        const double t = l2 < 1e-24 ? 0 : std::clamp(dot(pts[i] - pa, ab) / l2, 0.0, 1.0);
        const double dd = dist(pts[i], pa + ab * t);
        if (dd > worst) {
            worst = dd;
            at = i;
        }
    }
    if (worst <= tol) return;
    keep[at] = 1;
    rdp(pts, a, at, tol, keep);
    rdp(pts, at, b, tol, keep);
}

double turn_at(P before, P at, P after) {  // the angle the direction changes by at `at`, in radians (0..pi)
    const P a = at - before, b = after - at;
    if (len(a) < 1e-12 || len(b) < 1e-12) return 0;
    return std::fabs(std::atan2(cross(a, b), dot(a, b)));
}

double deviation(const Poly& pts, std::size_t a, std::size_t b, std::size_t n, bool wrap) {
    // the largest distance of the points strictly between index a and b (cyclic when `wrap`) from the segment a-b
    const P pa = pts[a % n], pb = pts[b % n];
    const P ab = pb - pa;
    const double l2 = dot(ab, ab);
    double worst = 0;
    for (std::size_t i = a + 1; i < b; ++i) {
        const P q = pts[wrap ? i % n : i];
        const double t = l2 < 1e-24 ? 0 : std::clamp(dot(q - pa, ab) / l2, 0.0, 1.0);
        worst = std::max(worst, dist(q, pa + ab * t));
    }
    return worst;
}

SubPath fit_ring(const Ring& ring, const FitOptions& opt) {
    SubPath out;
    out.closed = ring.closed;
    // Vertices much closer than the tolerance are noise of the integer grid (a boolean result has steps of one grid unit): they would
    // read as corners and as the "short edges" the straight-edge test compares with.
    const double minGap = std::max(1e-9, opt.tolerance * 0.2);
    Poly pts;
    for (const P& q : ring.pts)
        if (pts.empty() || dist(pts.back(), q) > minGap) pts.push_back(q);
    while (ring.closed && pts.size() > 1 && dist(pts.front(), pts.back()) <= minGap) pts.pop_back();
    // Points on a straight run (the sides of a stroke, the many vertices a boolean leaves on a line) carry no shape: drop those within a
    // tenth of the tolerance of the line through their neighbours, so the edges that remain are the ones that matter.
    if (pts.size() > 4) {
        const double eps = opt.tolerance * 0.1;
        std::vector<char> keep(pts.size() + 1, 0);
        Poly work = pts;
        if (ring.closed) {
            work.push_back(pts[0]);
            std::size_t far = 0;
            double best = -1;
            for (std::size_t i = 0; i < pts.size(); ++i)
                if (dist(pts[i], pts[0]) > best) {
                    best = dist(pts[i], pts[0]);
                    far = i;
                }
            keep[0] = keep[far] = keep[pts.size()] = 1;
            rdp(work, 0, far, eps, keep);
            rdp(work, far, pts.size(), eps, keep);
        } else {
            keep[0] = keep[pts.size() - 1] = 1;
            rdp(work, 0, pts.size() - 1, eps, keep);
        }
        Poly reduced;
        for (std::size_t i = 0; i < pts.size(); ++i)
            if (keep[i]) reduced.push_back(pts[i]);
        if (reduced.size() >= 3) pts = std::move(reduced);
    }
    const std::size_t n = pts.size();
    if (n == 0) return out;
    out.start = pts[0];
    if (n == 1) return out;
    if (n == 2) {
        out.segs.push_back({false, {}, {}, pts[1]});
        return out;
    }
    const bool closed = ring.closed;
    const double cornerRad = opt.cornerAngle * kPi / 180.0, tol = opt.tolerance;

    auto at = [&](long i) { return pts[std::size_t(((i % long(n)) + long(n)) % long(n))]; };
    // corners (a closed ring can have them anywhere, an open one has its two ends as splits already)
    std::vector<char> corner(n, 0), split(n, 0);
    if (closed) {
        for (std::size_t i = 0; i < n; ++i) corner[i] = turn_at(at(long(i) - 1), pts[i], at(long(i) + 1)) > cornerRad;
    } else {
        for (std::size_t i = 1; i + 1 < n; ++i) corner[i] = turn_at(pts[i - 1], pts[i], pts[i + 1]) > cornerRad;
        corner[0] = corner[n - 1] = 1;
    }
    // long straight edges: much longer than the edges of the curves around them
    const std::size_t edges = closed ? n : n - 1;
    std::vector<double> el(edges);
    for (std::size_t i = 0; i < edges; ++i) el[i] = dist(pts[i], at(long(i) + 1));
    std::vector<double> sorted = el;
    std::nth_element(sorted.begin(), sorted.begin() + std::ptrdiff_t(sorted.size() / 2), sorted.end());
    const double median = sorted[sorted.size() / 2];
    std::vector<char> straight(edges, 0);
    for (std::size_t i = 0; i < edges; ++i) straight[i] = el[i] > 3.5 * median && el[i] > 6 * tol;
    for (std::size_t i = 0; i < n; ++i) split[i] = corner[i];
    for (std::size_t i = 0; i < edges; ++i)
        if (straight[i]) split[i] = split[(i + 1) % n] = 1;
    std::vector<std::size_t> cuts;
    for (std::size_t i = 0; i < n; ++i)
        if (split[i]) cuts.push_back(i);
    if (closed && cuts.size() < 2) {
        // a ring with no corner (a circle) or one: cut it in two halves at points far from each other
        std::size_t first = cuts.empty() ? 0 : cuts[0], far = first;
        double best = -1;
        for (std::size_t i = 0; i < n; ++i)
            if (dist(pts[i], pts[first]) > best) {
                best = dist(pts[i], pts[first]);
                far = i;
            }
        if (cuts.empty()) cuts.push_back(first);
        split[far] = 1;
        cuts.push_back(far);
        std::sort(cuts.begin(), cuts.end());
    }
    if (!closed && cuts.size() < 2) cuts = {0, n - 1};

    const double lineTol = tol * 0.6, tol2 = tol * tol;
    auto dir_after = [&](std::size_t i) { return unit(at(long(i) + 1) - pts[i]); };
    auto dir_before = [&](std::size_t i) { return unit(pts[i] - at(long(i) - 1)); };
    auto edge_straight = [&](long i) {
        return closed ? straight[std::size_t(((i % long(n)) + long(n)) % long(n))] != 0
                      : (i >= 0 && i < long(edges) && straight[std::size_t(i)] != 0);
    };

    // Emits the segments from cut a to cut b (indices into pts, b may wrap past n for a closed ring).
    auto emit_run = [&](std::size_t a, std::size_t b) {
        const std::size_t count = b - a + 1;
        Poly run;
        run.reserve(count);
        for (std::size_t i = a; i <= b; ++i) run.push_back(at(long(i)));
        const P last = run.back();
        if (count == 2 || (dist(run.front(), last) > 1e-9 && deviation(run, 0, count - 1, count, false) <= lineTol)) {
            out.segs.push_back({false, {}, {}, last});
            return;
        }
        const std::size_t ia = a % n, ib = b % n;
        P t1, t2;
        // start tangent
        if (corner[ia] || (!closed && ia == 0))
            t1 = dir_after(ia);
        else if (edge_straight(long(ia) - 1))
            t1 = dir_before(ia);
        else
            t1 = unit(dir_before(ia) + dir_after(ia));
        // end tangent (pointing back into the run)
        if (corner[ib] || (!closed && ib == n - 1))
            t2 = unit(at(long(ib) - 1) - pts[ib]);
        else if (edge_straight(long(ib)))
            t2 = dir_after(ib) * -1.0;
        else
            t2 = unit(dir_before(ib) + dir_after(ib)) * -1.0;
        if (len(t1) < 0.5) t1 = unit(run[1] - run[0]);
        if (len(t2) < 0.5) t2 = unit(run[count - 2] - run[count - 1]);
        fit_cubic(run, t1, t2, tol2, out.segs);
    };

    if (closed) {
        out.start = pts[cuts[0]];
        for (std::size_t k = 0; k < cuts.size(); ++k) {
            const std::size_t a = cuts[k], b = k + 1 < cuts.size() ? cuts[k + 1] : cuts[0] + n;
            emit_run(a, b);
        }
    } else {
        for (std::size_t k = 0; k + 1 < cuts.size(); ++k) emit_run(cuts[k], cuts[k + 1]);
    }
    return out;
}

}  // namespace

Path fit_rings(const std::vector<Ring>& rings, const FitOptions& opt) {
    Path out;
    for (const Ring& r : rings) {
        SubPath s = fit_ring(r, opt);
        if (!s.segs.empty()) out.push_back(std::move(s));
    }
    return out;
}

Path simplify_path(const Path& p, double tolerance, double cornerAngle) {
    if (has_curves(p)) {
        FitOptions o;
        o.tolerance = tolerance;
        o.cornerAngle = cornerAngle;
        return fit_rings(flatten_path(p, tolerance * 0.25), o);
    }
    Path out;
    for (const SubPath& s : p) {
        Poly pts{s.start};
        for (const Seg& g : s.segs) pts.push_back(g.p);
        while (s.closed && pts.size() > 1 && dist(pts.front(), pts.back()) < 1e-9) pts.pop_back();
        std::vector<char> keep(pts.size(), 0);
        if (pts.size() <= 2) {
            std::fill(keep.begin(), keep.end(), 1);
        } else if (s.closed) {
            // split the ring at the point farthest from the first one and simplify both halves
            std::size_t far = 0;
            double best = -1;
            for (std::size_t i = 0; i < pts.size(); ++i)
                if (dist(pts[i], pts[0]) > best) {
                    best = dist(pts[i], pts[0]);
                    far = i;
                }
            Poly ring = pts;
            ring.push_back(pts[0]);
            keep[0] = keep[far] = 1;
            std::vector<char> k2(ring.size(), 0);
            k2[0] = k2[far] = k2.back() = 1;
            rdp(ring, 0, far, tolerance, k2);
            rdp(ring, far, ring.size() - 1, tolerance, k2);
            for (std::size_t i = 0; i < pts.size(); ++i) keep[i] = k2[i];
        } else {
            keep[0] = keep.back() = 1;
            rdp(pts, 0, pts.size() - 1, tolerance, keep);
        }
        SubPath o;
        o.closed = s.closed;
        bool first = true;
        for (std::size_t i = 0; i < pts.size(); ++i) {
            if (!keep[i]) continue;
            if (first) {
                o.start = pts[i];
                first = false;
            } else {
                o.segs.push_back({false, {}, {}, pts[i]});
            }
        }
        if (!o.segs.empty()) out.push_back(std::move(o));
    }
    return out;
}

Path smooth_path(const Path& p, double smoothness, double cornerAngle) {
    const double k = std::clamp(smoothness, 0.0, 1.0) / 3.0, cornerRad = cornerAngle * kPi / 180.0;
    Path out;
    for (const SubPath& s : p) {
        // The segments as (from, to, curve handles): a closed path's closing line is made explicit. Curves stay as they are; only the
        // straight segments get handles, so smoothing a path that is already round changes nothing.
        struct E {
            P from, to;
            bool curve;
            P c1, c2;
        };
        std::vector<E> e;
        P cur = s.start;
        for (const Seg& g : s.segs) {
            e.push_back({cur, g.p, g.cubic, g.c1, g.c2});
            cur = g.p;
        }
        const bool implicitClose = s.closed && dist(cur, s.start) > 1e-9;
        if (implicitClose) e.push_back({cur, s.start, false, {}, {}});
        const std::size_t m = e.size();
        SubPath o;
        o.start = s.start;
        o.closed = s.closed;
        if (m < 2 || (!s.closed && m < 2)) {
            out.push_back(s);
            continue;
        }
        // The direction a segment arrives at its end and leaves its start.
        auto dir_in = [&](const E& x) {
            return unit(x.curve && dist(x.c2, x.to) > 1e-9 ? x.to - x.c2 : x.to - x.from);
        };
        auto dir_out = [&](const E& x) {
            return unit(x.curve && dist(x.c1, x.from) > 1e-9 ? x.c1 - x.from : x.to - x.from);
        };
        // node i is the start of segment i; the tangent there, or sharp
        std::vector<P> tan(m);
        std::vector<char> sharp(m, 0);
        for (std::size_t i = 0; i < m; ++i) {
            if (!s.closed && i == 0) {
                sharp[i] = 1;
                continue;
            }
            const E& in = e[(i + m - 1) % m];
            const E& outE = e[i];
            const P d0 = dir_in(in), d1 = dir_out(outE);
            const double turn = std::fabs(std::atan2(cross(d0, d1), dot(d0, d1)));
            P t = unit(d0 + d1);
            if (in.curve && !outE.curve)
                t = d0;
            else if (!in.curve && outE.curve)
                t = d1;
            if (turn > cornerRad + 1e-9 || len(t) < 0.5)
                sharp[i] = 1;
            else
                tan[i] = t;
        }
        // the end node of an open path is sharp
        const std::size_t last = m;  // node index of the last end (open path)
        for (std::size_t i = 0; i < m; ++i) {
            const E& x = e[i];
            if (x.curve) {
                o.segs.push_back({true, x.c1, x.c2, x.to});
                continue;
            }
            const std::size_t j = (i + 1) % m;
            const bool endSharp = (!s.closed && i + 1 == last) || sharp[j];
            const double l = dist(x.from, x.to);
            const P c1 = sharp[i] ? x.from : x.from + tan[i] * (l * k);
            const P c2 = endSharp ? x.to : x.to - tan[j] * (l * k);
            if ((sharp[i] && endSharp) || k <= 1e-9) {
                if (!(implicitClose && i + 1 == m))
                    o.segs.push_back({false, {}, {}, x.to});  // the closing line is the path's own
            } else {
                o.segs.push_back({true, c1, c2, x.to});
            }
        }
        out.push_back(std::move(o));
    }
    return out;
}

}  // namespace fa::vec
